imgui_wrapper = {}

-- FRAME LOOP --
imgui_wrapper.loop = function(ctx, viewport, state, obj, preview)
    if reaper.ImGui_IsCloseRequested(ctx) then
        reaper.ImGui_DestroyContext(ctx)
        reaper.Undo_EndBlock2(0, obj.info.ext_name, 4)
        reacoma.params.set(obj)
        return
    end
    
    reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
    reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))
    reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

    w, h = reaper.ImGui_Viewport_GetSize(viewport)
    ---------------------------------  FRAME  -------------------------
    -- If you touch the process button, or press enter
    if reaper.ImGui_Button(ctx, obj.info.action) or reaper.ImGui_IsKeyPressed(ctx, 13) then
        state = reacoma.imgui_helpers.process(obj) -- TODO: make this respond to slicer/layers
    end
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, w..' x '..h)

    if obj.info.action == 'segment' then
        reaper.ImGui_SameLine(ctx)
        _, preview = reaper.ImGui_Checkbox(ctx, 'preview', preview)
    else
        preview = 0
    end
    state = reacoma.imgui_helpers.update_state(ctx, obj, preview)
    -------------------------------------------------------------------

    reaper.ImGui_End(ctx)
    reaper.defer(
        function() 
            imgui_wrapper.loop(ctx, viewport, state, obj, preview) 
        end
    )
end

return imgui_wrapper