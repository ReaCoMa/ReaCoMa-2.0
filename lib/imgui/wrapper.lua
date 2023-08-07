local r = reaper
local wrapper = {}
local rt_items, swap_items = {}, {} -- for matrix algorithms
presets = {1, 2, 3, 4, 5}

-- ANIMATION LOOP --
wrapper.loop = function(args)
    local pos = { r.ImGui_Viewport_GetWorkPos(args.viewport) }
    -- local w, h = r.ImGui_Viewport_GetSize(args.viewport)
    
    r.ImGui_SetNextWindowPos(args.ctx, pos[1] + 100, pos[2] + 100, r.ImGui_Cond_FirstUseEver())
    r.ImGui_SetNextWindowSize(args.ctx, 
        reacoma.global_state.width,
        reacoma.global_state.height, 
        r.ImGui_Cond_FirstUseEver()
    )

    visible, open = r.ImGui_Begin(args.ctx, args.obj.info.algorithm_name, true, r.ImGui_WindowFlags_NoCollapse())

    local restored = false

    if r.ImGui_Button(args.ctx, args.obj.info.action) or (reacoma.global_state.active == 0 and r.ImGui_IsKeyPressed(args.ctx, 13)) then
        if args.obj.info.source_target_matrix == true then
            args.state = reacoma.imgui.helpers.process(args.obj, 'cross', swap_items)
        else
            args.state = reacoma.imgui.helpers.process(args.obj, 'split')
        end
    end

    if args.obj.info.action == 'segment' then
        r.ImGui_SameLine(args.ctx)
        if r.ImGui_Button(args.ctx, 'create markers') then
            args.state = reacoma.imgui.helpers.process(args.obj, 'marker')
        end
        
        r.ImGui_SameLine(args.ctx)
        _, reacoma.settings.slice_preview = r.ImGui_Checkbox(args.ctx,'preview',reacoma.settings.slice_preview)
        if not reacoma.settings.slice_preview then r.ImGui_BeginDisabled(args.ctx) end
        r.ImGui_SameLine(args.ctx)
        _,  reacoma.settings.immediate_preview = r.ImGui_Checkbox(args.ctx,'immediate',reacoma.settings.immediate_preview)
        if not reacoma.settings.slice_preview then r.ImGui_EndDisabled(args.ctx) end
    else
        reacoma.settings.slice_preview = false
        reacoma.settings.immediate_preview = false
    end

    args.state = reacoma.imgui.helpers.update_state(args.ctx, args.obj, restored)

    -- TODO: don't rely here on duplication of code
    -- reacoma.imgui.helpers.matrix_gui(args, rt_items, swap_items)
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

    -- TODO: Preset System
    -- if r.ImGui_CollapsingHeader(ctx, 'Presets', nil, r.ImGui_TreeNodeFlags_None()) then
        -- for i = 1, #presets do
            -- if r.ImGui_Button(ctx, i) then
                -- if r.ImGui_IsKeyDown(ctx, r.ImGui_Mod_Super()) then
                    -- reacoma.params.store_preset(args.obj, i)
                -- else
                    -- reacoma.params.get_preset(args.obj, i)
                -- end
                -- ImGui_IsKeyDown(ctx, ImGui_Mod_Shift())
                -- ImGui_IsKeyDown(ctx, ImGui_Mod_Alt())
                -- ImGui_IsKeyDown(ctx, ImGui_Mod_Super())
            -- end
        -- end
        -- if r.ImGui_Button(ctx, '+ add preset') then
        --     presets[#presets+1] = #presets+1
        -- end
    -- end

    r.ImGui_End(args.ctx)
    
    if open then
        r.defer(
            function() 
                wrapper.loop({
                    ctx=args.ctx, 
                    viewport=args.viewport, 
                    state=args.state, 
                    obj=args.obj
                })
            end
        )
    else
        r.ImGui_DestroyContext(args.ctx)
        r.Undo_EndBlock2(0, args.obj.info.ext_name, 4)
        reacoma.params.set(args.obj)
        r.SetExtState('reacoma', 'slice_preview', reacoma.utils.bool_to_string[reacoma.settings.slice_preview], true)
        r.SetExtState('reacoma', 'immediate_preview', reacoma.utils.bool_to_string[reacoma.settings.immediate_preview], true)
        return
    end
end

return wrapper