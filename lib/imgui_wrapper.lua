imgui_wrapper = {}

-- FRAME LOOP --
imgui_wrapper.loop = function(ctx, viewport, state, slicer, preview)
    if reaper.ImGui_IsCloseRequested(ctx) then
        reaper.ImGui_DestroyContext(ctx)
        reaper.Undo_EndBlock2(0, 'dynamic-slicing', 4)
        reacoma.params.set(slicer)
        return
    end
    
    reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
    reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))
    reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

    ---------------------------------  FRAME  -------------------------
    if reaper.ImGui_Button(ctx, 'segment') then
        state = reacoma.imgui_helpers.button_segment(slicer)
    end
    
    reaper.ImGui_SameLine(ctx)
    _, preview = reaper.ImGui_Checkbox(ctx, 'preview', preview)
    state = reacoma.imgui_helpers.update_slicing(slicer, preview)
    -------------------------------------------------------------------

    reaper.ImGui_End(ctx)
    reaper.defer(
        function() 
            imgui_wrapper.loop(ctx, viewport, state, slicer, preview) 
        end
    )
end

return imgui_wrapper