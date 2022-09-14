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
    local changing = change ~= 0
    local dragging = reaper.ImGui_IsMouseDragging(ctx, reaper.ImGui_MouseButton_Left())
    local mousedown = reaper.ImGui_IsMouseDown(ctx, reaper.ImGui_MouseButton_Left())
    local mouseup = reacoma.global_state.mousedown and not mousedown
    local immediate_preview = changing and dragging and reacoma.settings.slice_preview and reacoma.settings.immediate_preview
    local mouseup_preview = mouseup and reacoma.settings.slice_preview
    
    -- now store the state of the mousedown after checking
    -- this lets you check the difference between mouse state
    reacoma.global_state.mousedown = reaper.ImGui_IsMouseDown(ctx, reaper.ImGui_MouseButton_Left())
    return immediate_preview or mouseup_preview
end

imgui_helpers.update_state = function(ctx, obj, update)
    local change = imgui_helpers.draw_gui(ctx, obj)
    if imgui_helpers.do_preview(ctx, obj, change + utils.bool_to_number[update]) then
        return obj.perform_update(obj.parameters)
    end
end

imgui_helpers.process = function(obj)
    -- This is called everytime there is a process button pressed
    -- This button is uniform across layers/slices and is found at the top left
    local state = obj.perform_update(obj.parameters)

    if obj.info.action == 'segment' then
        -- Handle muting
        -- local mute = 0
        -- reaper.SetMediaItemInfo_Value(
        --     data.item[item_index], 
        --     "B_MUTE", 
        --     mute_state
        -- )
        -- if mute_state == 1 then mute_state = 0 else mute_state = 1 end
        local num_selected_items = reaper.CountSelectedMediaItems(0)
        for i=1, num_selected_items do
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

            for j=1, #take_markers do
                local slice_pos = take_markers[j]
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