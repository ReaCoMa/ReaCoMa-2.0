imgui_helpers = {}

imgui_helpers.draw_gui = function(obj)
    local change = 0
    for parameter, d in pairs(obj.parameters) do
        if d.type == 'sliderint' then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.min, d.max
            )
        end
        if d.type == 'sliderdouble' then
            temp, d.value = d.widget(
                ctx,
                d.name, d.value, d.min, d.max,
                '%.3f',
                d.flag or 0
            )
        end
        if d.type == 'combo' then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.items
            )
        end

        change = change + reacoma.utils.bool_to_number[temp]
    end
    return change
end

imgui_helpers.update_state = function(obj, preview)
    -- TODO: this could possibly be refactored into a single if statement but for now lets keep it verbose
    -- Updates the state within each frame loop
    local change = imgui_helpers.draw_gui(obj)

    -- We only need to update the state intermittently if the object is for segmenting...
    -- ... and if the preview is checked
    if obj.info.action == 'segment' then
        -- Perform a slices process
        if change > 0 and preview then
            return obj.perform_update(obj.parameters)
        end
    end 
end

imgui_helpers.process = function(obj)
    local state = obj.perform_update(obj.parameters)

    if obj.info.action == 'segment' then
        local num_selected_items = reaper.CountSelectedMediaItems(0)
        for i=1, num_selected_items do
            item = reaper.GetSelectedMediaItem(0, i-1)
            take = reaper.GetActiveTake(item)
            take_markers = reaper.GetNumTakeMarkers(take)

            for j=1, take_markers do
                local slice_pos, _, _ = reaper.GetTakeMarker(take, j-1)
                item = reaper.SplitMediaItem(
                    item, 
                    slice_pos + state.item_pos[i]
                )
            end
        end
        reaper.UpdateArrange()
    end

    return state
end

return imgui_helpers