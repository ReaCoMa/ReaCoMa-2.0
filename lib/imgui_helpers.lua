local r = reaper

imgui_helpers = {}

imgui_helpers.create_context = function(name)
    local context = reaper.ImGui_CreateContext(name)
    local viewport = reaper.ImGui_GetMainViewport(context)
    return context, viewport
end

imgui_helpers.HelpMarker = function(ctx, desc)
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_TextDisabled(ctx, '(?)')
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_BeginTooltip(ctx)
      reaper.ImGui_PushTextWrapPos(
          ctx, 
          reaper.ImGui_GetFontSize(ctx) * 15.0
        )
      reaper.ImGui_Text(ctx, desc)
      reaper.ImGui_PopTextWrapPos(ctx)
      reaper.ImGui_EndTooltip(ctx)
    end
  end

imgui_helpers.draw_gui = function(ctx, obj)
    local change = 0
    local active = 0
    local temp = nil
    for parameter, d in pairs(obj.parameters) do
        if d.widget == reaper.ImGui_SliderInt then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.min, d.max
            )
        end
        if d.widget == reaper.ImGui_SliderDouble then
            temp, d.value = d.widget(
                ctx,
                d.name, d.value, d.min, d.max,
                '%.3f',
                d.flag or 0
            )
        end
        if d.widget == reaper.ImGui_Combo then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.items
            )
        end
        local widget_active = reaper.ImGui_IsItemActive(ctx)
        -- Draw the mouseover description
        local help_text = d.desc or 'no help available'
        imgui_helpers.HelpMarker(ctx, help_text)
        active = active + reacoma.utils.bool_to_number[widget_active]
        -- TODO:
        -- If something is active (edited currently)...
        -- ... we don't want to trigger a change
        change = change + reacoma.utils.bool_to_number[temp]
    end

    reacoma.global_state.active = active
    return change
end

imgui_helpers.do_preview = function(ctx, obj, change)
    if obj.info.action ~= 'segment' or not reacoma.settings.slice_preview then
        return false
    end
    local drag_preview = change > 0 and reacoma.settings.immediate_preview
    local end_drag_preview = (
        not reacoma.settings.immediate_preview and 
        not reaper.ImGui_IsMouseDown(ctx, reaper.ImGui_MouseButton_Left()) and 
        reacoma.global_state.preview_pending
    )
    reacoma.global_state.preview_pending = not end_drag_preview and (reacoma.global_state.preview_pending or (change > 0 and not reacoma.settings.immediate_preview))
    return drag_preview or end_drag_preview
end

imgui_helpers.update_state = function(ctx, obj, update)
    local change = imgui_helpers.draw_gui(ctx, obj)
    if imgui_helpers.do_preview(ctx, obj, change + utils.bool_to_number[update]) then
        return obj.perform_update(obj.parameters)
    end
end

imgui_helpers.process = function(obj, mode, optional_item_bundle)
    -- This is called everytime there is a process button pressed
    -- This button is uniform across layers/slices and is found at the top left
    local processed_items = {}

    -- if the mode is cross or transport we provide an optional item bundle which contains the pairs of items
    if mode == 'cross' then
        processed_items = obj.perform_update(obj.parameters, optional_item_bundle)
    else
        processed_items = obj.perform_update(obj.parameters)
    end

    -- This block performs segmentation related tasks with markers
    if obj.info.action == 'segment' then
        for i=1, #processed_items do
            item = reaper.GetSelectedMediaItem(0, i-1)
            take = reaper.GetActiveTake(item)
            num_markers = reaper.GetNumTakeMarkers(take)
            
            -- Collect the take markers
            take_markers = {}
            for j=1, num_markers do
                marker = reaper.GetTakeMarker(take, j-1)
                table.insert(take_markers, marker)
            end
            
            -- Now remove them from the item
            for j=1, num_markers do
                reaper.DeleteTakeMarker(take, num_markers-j)
            end

            reaper.Undo_BeginBlock()
            for j=1, #take_markers do
                local slice_pos = take_markers[j]
                local real_position = slice_pos + processed_items[i].item_pos -- adjust for offset of item
                if mode == 'split' then
                    item = reaper.SplitMediaItem(item, real_position)
                elseif mode == 'marker' then
                    local scheme = reacoma.colors.scheme[i] or { r=255, g=0, b=0 }
                    local color = reaper.ColorToNative( scheme.r, scheme.g, scheme.b ) | 0x1000000
                    reaper.AddProjectMarker2(0, false, real_position, real_position, '', -1, color)
                end
            end
            reaper.Undo_EndBlock2(0, 'reacoma process markers', -1)
        end
        reaper.UpdateArrange()
    end
    return processed_items
end

imgui_helpers.grab_selected_items = function(temp_items, rt_items, swap_items)

end

return imgui_helpers