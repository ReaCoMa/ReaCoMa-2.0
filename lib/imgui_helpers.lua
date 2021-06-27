imgui_helpers = {}

imgui_helpers.button_segment = function(state)
    state = slicer.slice(parameters)

    num_selected_items = reaper.CountSelectedMediaItems(0)
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

imgui_helpers.update_slicing = function(parameters, preview)
    local change = 0
    for parameter, d in pairs(parameters) do
        if d.type == 'slider' then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.min, d.max 
            )
        end
        if d.type == 'combo' then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.items
            )
        end

        change = change + utils.bool_to_number[temp]
    end

    if change > 0 and preview then
        return slicer.slice(parameters)
    end
end

return imgui_helpers