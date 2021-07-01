imgui_wrapper = {}

local r = reaper
local path_valid = false
local show_modal = true
local confirmed_path_valid = reacoma.paths.is_path_valid(reacoma.settings.path)

-- FRAME LOOP --
imgui_wrapper.loop = function(ctx, viewport, state, obj)
    path_valid = reacoma.paths.is_path_valid(reacoma.settings.path)

    if reaper.ImGui_IsCloseRequested(ctx) then
        reaper.ImGui_DestroyContext(ctx)
        reaper.Undo_EndBlock2(0, obj.info.ext_name, 4)
        reacoma.params.set(obj)
        reaper.SetExtState('reacoma', 'slice_preview', utils.bool_to_string[reacoma.settings.slice_preview], true)
        return
    end

    reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
    reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))

    if confirmed_path_valid == false then
        -- PATH CHECKING --
    
        if show_modal then
            r.ImGui_OpenPopup(ctx, 'Set ReaCoMa Path')

            -- Always center this window when appearing
            local center = {r.ImGui_Viewport_GetCenter(r.ImGui_GetMainViewport(ctx))}
            local window_size = r.ImGui_Viewport_GetSize(viewport)
            -- r.ImGui_SetNextWindowSize(ctx, 400, 230, 0)
            -- r.ImGui_SetNextWindowPos(ctx, center[1], center[2], r.ImGui_Cond_Appearing(), 0.5, 0.5)

            -- ENTER MODAL --
            r.ImGui_BeginPopupModal(ctx, 'Set ReaCoMa Path', nil, r.ImGui_WindowFlags_AlwaysAutoResize())
            r.ImGui_TextWrapped(ctx, 'The path to the FluCoMa CLI tools is not set. Please follow the next prompt to configure it. Doing so remains persistent across projects and sessions of reaper.')
            r.ImGui_TextWrapped(ctx, "For example, if you've just downloaded the tools from the flucoma.org/download then you'll need to provide the path to the 'bin' folder which is inside 'Fluid Corpus Manipulation'.")
            
            if r.ImGui_Button(ctx, 'OK', 120, 0) then 
                show_modal = false
                r.ImGui_CloseCurrentPopup(ctx) 
            end
            r.ImGui_EndPopup(ctx)
            -- EXIT MODAL --
        end

        reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

        r.ImGui_Text(ctx, 'FluCoMa Command Line Tools Path')


        if path_valid then 
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), colors.green)
        else
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), colors.red)
        end

        _, reacoma.settings.path = r.ImGui_InputText(ctx, '', reacoma.settings.path)
        r.ImGui_PopStyleColor(ctx)
        if path_valid then
            r.ImGui_SameLine(ctx)
            r.ImGui_Text(ctx, 'Path looks good!')
        end

        r.ImGui_BeginChildFrame(ctx, '##file-drop', 0, 100)
        r.ImGui_Text(ctx, 'Drag and drop the bin folder here...')
        r.ImGui_EndChildFrame(ctx)

        if r.ImGui_BeginDragDropTarget(ctx) then
            local rv, count = r.ImGui_AcceptDragDropPayloadFiles(ctx)
            if rv then
                _, reacoma.settings.path = r.ImGui_GetDragDropPayloadFile(ctx, 0)
            end
            r.ImGui_EndDragDropTarget(ctx)
        end

        -- CONFIRM BUTTON --
        if path_valid then 
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), colors.dark_green)
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), colors.mid_green)
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), colors.green)
        else
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), colors.dark_grey)
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), colors.mid_grey)
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), colors.grey)
        end

        if reaper.ImGui_Button(ctx, 'confirm path') then
            if path_valid then
                confirmed_path_valid = path_valid
                reacoma.paths.set_reacoma_path(reacoma.settings.path)
            end
        end
        r.ImGui_PopStyleColor(ctx, 3)
        
        if path_valid then
            r.ImGui_SameLine(ctx)
            r.ImGui_Text(ctx, '<-- Now hit this button to store the path!')
        end
        reaper.ImGui_End(ctx)
    end
    
    -- GUI --
    if confirmed_path_valid == true then

        reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

        if reaper.ImGui_Button(ctx, obj.info.action) or (reacoma.global_state.active == 0 and reaper.ImGui_IsKeyPressed(ctx, 13)) then
            state = reacoma.imgui_helpers.process(obj) -- TODO: make this respond to slicer/layers
        end
        -- DEBUG SIZE --
        -- w, h = reaper.ImGui_Viewport_GetSize(viewport)
        -- reaper.ImGui_Text(ctx, w..' x '..h)

        if obj.info.action == 'segment' then
            reaper.ImGui_SameLine(ctx)
            _, reacoma.settings.slice_preview = reaper.ImGui_Checkbox(ctx, 
                'preview', 
                reacoma.settings.slice_preview
            )
        else
            reacoma.settings.slice_preview = false
        end
        state = reacoma.imgui_helpers.update_state(ctx, obj, reacoma.settings.slice_preview)
        reaper.ImGui_End(ctx)
    end
    reaper.defer(
        function() 
            imgui_wrapper.loop(ctx, viewport, state, obj) 
        end
    )
end

return imgui_wrapper