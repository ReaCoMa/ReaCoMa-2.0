imgui_wrapper = {}

local r = reaper

local path_width = 500
local path_height = 285

local rt_items, swap_items = {}, {}

-- FRAME LOOP --
imgui_wrapper.loop = function(args)
    
    local pos = { r.ImGui_Viewport_GetWorkPos(args.viewport) }
    local w, h = reaper.ImGui_Viewport_GetSize(args.viewport)
    
    reaper.ImGui_SetNextWindowPos(args.ctx, pos[1] + 100, pos[2] + 100, r.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowSize(args.ctx, 
        reacoma.global_state.width,
        reacoma.global_state.height, 
        r.ImGui_Cond_FirstUseEver()
    )

    visible, open = reaper.ImGui_Begin(args.ctx, args.obj.info.algorithm_name, true, r.ImGui_WindowFlags_NoCollapse())

    local restored = false

    if reaper.ImGui_Button(args.ctx, args.obj.info.action) or (reacoma.global_state.active == 0 and reaper.ImGui_IsKeyPressed(args.ctx, 13)) then
        if args.obj.info.source_targset_matrix == true then
            args.state = reacoma.imgui_helpers.process(args.obj, 'cross', swap_items)
        else
            args.state = reacoma.imgui_helpers.process(args.obj, 'split')
        end
    end

    if args.obj.info.action == 'segment' then
        reaper.ImGui_SameLine(args.ctx)
        if reaper.ImGui_Button(args.ctx, 'create markers') then
            args.state = reacoma.imgui_helpers.process(args.obj, 'marker')
        end
        
        reaper.ImGui_SameLine(args.ctx)
        _, reacoma.settings.slice_preview = reaper.ImGui_Checkbox(args.ctx,'preview',reacoma.settings.slice_preview)
        if not reacoma.settings.slice_preview then reaper.ImGui_BeginDisabled(args.ctx) end
        reaper.ImGui_SameLine(args.ctx)
        _,  reacoma.settings.immediate_preview = reaper.ImGui_Checkbox(args.ctx,'immediate',reacoma.settings.immediate_preview)
        if not reacoma.settings.slice_preview then reaper.ImGui_EndDisabled(args.ctx) end
    else
        reacoma.settings.slice_preview = false
        reacoma.settings.immediate_preview = false
    end

    if args.obj.defaults ~= nil then
        if reaper.ImGui_Button(args.ctx, "defaults") then
            args.state = params.restore_defaults(args.obj)
            restored = true
        end
    end

    args.state = reacoma.imgui_helpers.update_state(args.ctx, args.obj, restored)

    if args.obj.info.source_targset_matrix == true then 
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
                if r.ImGui_BeginDragDropTargset(args.ctx) then
                    local rv, payload = r.ImGui_AcceptDragDropPayload(args.ctx, 'DND_DEMO_CELL')
                    if rv then
                        local payload_i = tonumber(payload)
                        swap_items[i] = swap_items[payload_i]
                        swap_items[payload_i] = v
                    end
                    r.ImGui_EndDragDropTargset(args.ctx)
                end
                r.ImGui_PopID(args.ctx)
            end
            r.ImGui_EndTable(args.ctx)
        end
    end

    reaper.ImGui_End(args.ctx)

    if args.test then
        open = false
    end
    
    if open then
        reaper.defer(
            function() 
                imgui_wrapper.loop({
                    ctx=args.ctx, 
                    viewport=args.viewport, 
                    state=args.state, 
                    obj=args.obj
                })
            end
        )
    else
        reaper.ImGui_DestroyContext(args.ctx)
        reaper.Undo_EndBlock2(0, args.obj.info.ext_name, 4)
        reacoma.params.set(args.obj)
        reaper.SetExtState('reacoma', 'slice_preview', utils.bool_to_string[reacoma.settings.slice_preview], true)
        reaper.SetExtState('reacoma', 'immediate_preview', utils.bool_to_string[reacoma.settings.immediate_preview], true)
        return
    end
end

return imgui_wrapper