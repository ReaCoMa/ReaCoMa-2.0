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

    reacoma.imgui.helpers.matrix_gui(args, rt_items, swap_items)

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