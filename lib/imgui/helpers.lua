local r = reaper

local helpers = {}

helpers.create_context = function(name)
    local context = r.ImGui_CreateContext(name)
    local viewport = r.ImGui_GetMainViewport(context)
    return context, viewport
end

helpers.help_marker = function(ctx, desc)
    r.ImGui_SameLine(ctx)
    r.ImGui_TextDisabled(ctx, '(?)')
    if r.ImGui_IsItemHovered(ctx) then
      r.ImGui_BeginTooltip(ctx)
      r.ImGui_PushTextWrapPos(
          ctx, 
          r.ImGui_GetFontSize(ctx) * 15.0
        )
      r.ImGui_Text(ctx, desc)
      r.ImGui_PopTextWrapPos(ctx)
      r.ImGui_EndTooltip(ctx)
    end
  end

helpers.draw_gui = function(ctx, obj)
    local change = 0
    local active = 0
    local rv = nil

    for _, param in pairs(obj.parameters) do
        if param.widget == r.ImGui_SliderInt then
            rv, param.value = 
                param.widget(ctx, param.name, param.value, param.min, param.max)
        elseif param.widget == r.ImGui_SliderDouble then
            rv, param.value = param.widget(ctx, 
                param.name, param.value, param.min, param.max, '%.3f', param.flag or 0)
        elseif param.widget == r.ImGui_Combo then
            rv, param.value = 
                param.widget(ctx, param.name, param.value, param.items)
        elseif reacoma.utils.table_has(reacoma.imgui.widgets, param.widget) then
            rv, param.index = r.ImGui_SliderInt(
                    ctx, 
                    param.name, 
                    param.index, 
                    1, #param.widget.opts,
                    param.widget.opts[param.index]
                )
            param.value = param.widget.opts[param.index]
        end
        local widget_active = r.ImGui_IsItemActive(ctx)
        -- Draw the mouseover description
        local help_text = param.desc or 'no help available'
        helpers.help_marker(ctx, help_text)
        active = active + reacoma.utils.bool_to_number[widget_active]
        -- TODO:
        -- If something is active (edited currently)...
        -- ... we don't want to trigger a change
        change = change + reacoma.utils.bool_to_number[rv]
    end

    reacoma.global_state.active = active
    return change
end

helpers.do_preview = function(ctx, obj, change)
    if obj.info.action ~= 'segment' or not reacoma.settings.slice_preview then
        return false
    end
    local drag_preview = change > 0 and reacoma.settings.immediate_preview
    local end_drag_preview = (
        not reacoma.settings.immediate_preview and 
        not r.ImGui_IsMouseDown(ctx, r.ImGui_MouseButton_Left()) and 
        reacoma.global_state.preview_pending
    )
    reacoma.global_state.preview_pending = not end_drag_preview and (reacoma.global_state.preview_pending or (change > 0 and not reacoma.settings.immediate_preview))
    return drag_preview or end_drag_preview
end

helpers.update_state = function(ctx, obj, update)
    local change = helpers.draw_gui(ctx, obj)
    if helpers.do_preview(ctx, obj, change + reacoma.utils.bool_to_number[update]) then
        return obj.perform_update(obj.parameters)
    end
end

helpers.process = function(obj, mode, optional_item_bundle)
    -- This is called everytime there is a process button pressed
    -- This button is uniform across layers/slices and is found at the top left
    local processed_items = {}

    reaper.Undo_BeginBlock2(0)
    -- if the mode is cross or transport we provide an optional item bundle which contains the pairs of items
    if mode == 'cross' then
        processed_items = obj.perform_update(obj.parameters, optional_item_bundle)
    else
        processed_items = obj.perform_update(obj.parameters)
    end

    -- This block performs segmentation related tasks with markers
    if obj.info.action == 'segment' then
        for i=1, #processed_items do
            local item = r.GetSelectedMediaItem(0, i-1)
            local take = r.GetActiveTake(item)
            local num_markers = r.GetNumTakeMarkers(take)
            
            -- Collect the take markers
            local take_markers = {}
            for j=1, num_markers do
                local marker = r.GetTakeMarker(take, j-1)
                table.insert(take_markers, marker)
            end
            
            -- Now remove them from the item
            for j=1, num_markers do
                r.DeleteTakeMarker(take, num_markers-j)
            end

            for j=1, #take_markers do
                local slice_pos = take_markers[j]
                local real_position = slice_pos + processed_items[i].item_pos -- adjust for offset of item
                if mode == 'split' then
                    item = r.SplitMediaItem(item, real_position)
                elseif mode == 'marker' then
                    local scheme = reacoma.colors.scheme[i] or { r=255, g=0, b=0 }
                    local color = r.ColorToNative( scheme.r, scheme.g, scheme.b ) | 0x1000000
                    r.AddProjectMarker2(0, false, real_position, real_position, '', -1, color)
                end
            end
        end
        r.UpdateArrange()
    end
    reaper.Undo_EndBlock2(0, obj.info.ext_name, -1)
    return processed_items
end

helpers.grab_selected_items = function(temp_items, rt_items, swap_items) end

helpers.matrix_gui = function(args, rt_items, swap_items)
    if args.obj.info.source_target_matrix == true then 
        local temp_items = reacoma.utils.grab_selected_items()
        if not reacoma.utils.compare_item_tables(temp_items, rt_items) then
            rt_items = reacoma.utils.deep_copy(temp_items)
            swap_items = reacoma.utils.deep_copy(temp_items)
        end
    
        if r.ImGui_BeginTable(args.ctx, 'mappings', 2) then
            r.ImGui_TableSetupColumn(args.ctx, args.obj.info.column_a)
            r.ImGui_TableSetupColumn(args.ctx, args.obj.info.column_b)
            r.ImGui_TableHeadersRow(args.ctx)
            r.ImGui_TableNextRow(args.ctx)
            
            for i, v in ipairs(swap_items) do
                r.ImGui_PushID(args.ctx, i)
                r.ImGui_TableNextColumn(args.ctx)
                local name = r.GetTakeName(r.GetActiveTake(v))
                r.ImGui_PushStyleVar(args.ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0, 0)
                r.ImGui_Button(args.ctx, name, 150, 20)
                r.ImGui_PopStyleVar(args.ctx)
                if r.ImGui_BeginDragDropSource(args.ctx, r.ImGui_DragDropFlags_None()) then
                    r.ImGui_SetDragDropPayload(args.ctx, 'DND_DEMO_CELL', tostring(i))
                    r.ImGui_Text(args.ctx, ('Swap %s'):format(name))
                    r.ImGui_EndDragDropSource(args.ctx)
                end
                if r.ImGui_BeginDragDropTarget(args.ctx) then
                    local rv, payload = r.ImGui_AcceptDragDropPayload(args.ctx, 'DND_DEMO_CELL')
                    if rv then
                        local payload_i = tonumber(payload)
                        swap_items[i] = swap_items[payload_i]
                        swap_items[payload_i] = v
                    end
                    r.ImGui_EndDragDropTarget(args.ctx)
                end
                r.ImGui_PopID(args.ctx)
            end
            r.ImGui_EndTable(args.ctx)
        end
    end
end

return helpers
