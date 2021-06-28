imgui_wrapper = {}

-- FRAME LOOP --
imgui_wrapper.loop = function(ctx, viewport, state, obj, preview)
    if reaper.ImGui_IsCloseRequested(ctx) then
        reaper.ImGui_DestroyContext(ctx)
        reaper.Undo_EndBlock2(0, slicer.info.ext_name, 4)
        reacoma.params.set(obj)
        return
    end
    
    reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
    reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))
    reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

    ---------------------------------  FRAME  -------------------------
    if reaper.ImGui_Button(ctx, obj.info.action) then
        state = reacoma.imgui_helpers.button_segment(obj)
    end
    
    reaper.ImGui_SameLine(ctx)
    _, preview = reaper.ImGui_Checkbox(ctx, 'preview', preview)
    state = reacoma.imgui_helpers.slice(obj, preview)
    -------------------------------------------------------------------

    reaper.ImGui_End(ctx)
    reaper.defer(
        function() 
            imgui_wrapper.loop(ctx, viewport, state, obj, preview) 
        end
    )
end

return imgui_wrapper