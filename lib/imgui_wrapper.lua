imgui_wrapper = {}

local r = reaper
local path_valid = false
local show_modal = false
open = true
visible = true

local path_width = 500
local path_height = 285
-- FRAME LOOP --
imgui_wrapper.loop = function(ctx, viewport, state, obj)

    local pos = { r.ImGui_Viewport_GetWorkPos(viewport) }
    local w, h = reaper.ImGui_Viewport_GetSize(viewport)

    reaper.ImGui_SetNextWindowPos(ctx, pos[1] + 100, pos[2] + 100, r.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowSize(ctx, 
        reacoma.global_state.width,
        reacoma.global_state.height, 
        r.ImGui_Cond_FirstUseEver()
    )
    
    visible, open = reaper.ImGui_Begin(ctx, obj.info.algorithm_name, true, r.ImGui_WindowFlags_NoCollapse())

    local restored = false
    
    if reaper.ImGui_Button(ctx, obj.info.action) or (reacoma.global_state.active == 0 and reaper.ImGui_IsKeyPressed(ctx, 13)) then
        state = reacoma.imgui_helpers.process(obj) -- TODO: make this respond to slicer/layers
    end

    if obj.info.action == 'segment' then
        reaper.ImGui_SameLine(ctx)
        _, reacoma.settings.slice_preview = reaper.ImGui_Checkbox(ctx,
            'preview',
            reacoma.settings.slice_preview
        )
        if not reacoma.settings.slice_preview then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_SameLine(ctx)
        _,  reacoma.settings.immediate_preview = reaper.ImGui_Checkbox(ctx,
            'immediate',
            reacoma.settings.immediate_preview
        )
        if not reacoma.settings.slice_preview then reaper.ImGui_EndDisabled(ctx) end
    else
        reacoma.settings.slice_preview = false
        reacoma.settings.immediate_preview = false
    end

    if obj.defaults ~= nil then
        if reaper.ImGui_Button(ctx, "defaults") then
            state = params.restore_defaults(obj)
            restored = true
        end
    end

    state = reacoma.imgui_helpers.update_state(ctx, obj, restored)

    reaper.ImGui_End(ctx)

    if open then
        reaper.defer(
            function() 
                imgui_wrapper.loop(ctx, viewport, state, obj) 
            end
        )
    else
        reaper.ImGui_DestroyContext(ctx)
        reaper.Undo_EndBlock2(0, obj.info.ext_name, 4)
        reacoma.params.set(obj)
        reaper.SetExtState('reacoma', 'slice_preview', utils.bool_to_string[reacoma.settings.slice_preview], true)
        reaper.SetExtState('reacoma', 'immediate_preview', utils.bool_to_string[reacoma.settings.immediate_preview], true)
        return
    end
end

return imgui_wrapper