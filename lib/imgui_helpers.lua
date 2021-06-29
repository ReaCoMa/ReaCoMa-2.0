imgui_helpers = {}

imgui_helpers.draw_gui = function(obj)
    local change = 0
    for parameter, d in pairs(obj.parameters) do
        if d.type == 'slider' or d.type == 'snapslider' then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.min, d.max 
            )
        end
        -- TODO: find a better way of snapping FFT values
        -- if d.type == 'snapslider' then
        --     -- local fftvalue = reacoma.utils.next_pow_str(d.value, 'number')
        --     temp, d.value = d.widget(
        --         ctx, 
        --         d.name, d.value, d.min, d.max 
        --     )
        --     d.value = reacoma.utils.next_pow_str(d.value, 'number')
        -- end
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

imgui_helpers.slice = function(obj, preview)
    local change = imgui_helpers.draw_gui(obj)

    if change > 0 and preview then
        return obj.slice(obj.parameters)
    end
end

imgui_helpers.layers = function(obj)
end


imgui_helpers.button_segment = function(slicer)
    local state = slicer.slice(slicer.parameters)

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
    return state
end

return imgui_helpers