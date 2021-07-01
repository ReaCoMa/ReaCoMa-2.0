local r = reaper

paths = {}

paths.get_reacoma_path = function()
    -- Returns the current value for the flucoma executable path state
    return reaper.GetExtState("reacoma", "exepath")
end

paths.expandtilde = function(path)
    -- Crudely expands tilde to the user home folder
    local first = path:sub(1, 1)

    -- Codes representing operating systems which are unix
    -- This was updated 10/06/2021 for new ARM macs
    local unix_codes = {
        'macOS-arm64',
        'OSX64',
        'Other'
    }

    if first:match("~") then
        opsys = reaper.GetOS()
        if reacoma.utils.table_contains(unix_codes, opsys) then
            home = reacoma.utils.capture("echo $HOME")
        else
            home = reacoma.utils.capture("echo %USERPROFILE%")
        end
        path = home .. path:sub(2)
    end
    return path
end

paths.file_exists = function(path)
    local path = paths.expandtilde(path)
    -- Returns boolean for the existence of a file at <path>
    -- Expand the tilde if exists
    if reaper.file_exists(path) then return true else return false end
end

-- paths.is_path_valid = function(input_string, warning_message)
--     -- Checks whether or not the <input_string> is valid
--     -- Optionally provide a warning message on success/failure
--     local input_string = paths.expandtilde(input_string)
--     local opsys = reaper.GetOS()
--     -- macOS-arm64 is the new ARM architecture code (worth remembering when it breaks something later...)
--     local f = "/fluid-noveltyslice"
--     if opsys == "Win64" or opsys == "Win32" then f = "/fluid-noveltyslice.exe" end
--     local ns_path = input_string .. f
--     if paths.file_exists(ns_path) then
--         reaper.SetExtState("reacoma", "exepath", input_string, 1)
--         if warning_message then
--             reaper.ShowMessageBox("The path you set looks good!", "Path Configuration", 0)
--         end
--         return true
--     else
--         reaper.ShowMessageBox("The path you set doesn't seem to contain the FluCoMa tools. Please try again.", "Path Configuration", 0)
--         reaper.DeleteExtState("reacoma", "exepath", 1)
--         paths.path_setter()
--     end
-- end

paths.path_setter = function()
    -- Function to give the user a GUI the fluid path as an ExtState in REAPER
    local cancel, input = reaper.GetUserInputs("Set path to FluCoMa Executables", 1, "Path:, extrawidth=200", "/usr/local/bin")
    input = paths.expandtilde(input)
    if cancel ~= false then
        local input_path = utils.rm_trailing_slash(input)
        if paths.is_path_valid(input_path, true) == true then return true end
    else
        reaper.ShowMessageBox("Your path remains unconfigured. The script will now exit.", "Warning", 0)
        reaper.DeleteExtState("reacoma", "exepath", 1)
        return false
    end
end

paths.set_reacoma_path = function()
    if paths.path_setter() == true then return true else return false end
end

paths.check_state = function()
    -- Check that the REAPER ExtState "exepath" exists (has been set)
    return reaper.HasExtState("reacoma", "exepath")
end

paths.sanity_check = function()
    -- Function to call at the start of every script
    -- This ensures that the path has been set otherwise it prompts the user to go through the process
    if paths.check_state() == false then -- path never set
        local warning_msg = "The path to the FluCoMa CLI tools is not set. Please follow the next prompt to configure it. Doing so remains persistent across projects and sessions of reaper.\n\n" .. 
        "If you need to change it please use the FluidEditPath.lua script.\n\n" ..
        "For example, if you've just downloaded the tools from the flucoma.org/download then you'll need to provide the path to the 'bin' folder which is inside 'Fluid Corpus Manipulation'.\n\n"
        reaper.ShowMessageBox(warning_msg, "Warning!", 0)
        if paths.set_reacoma_path() == true then return true else return false end
    end

    if paths.check_state() == true then -- if it is set we need to check that it is valid
        local possible_path = paths.get_reacoma_path()
        if paths.is_path_valid(possible_path, false) == true then return true else return false end -- make sure the path is still okay, perhaps its moved...
    end
end

-- IMGUI way of doing it

paths.is_path_valid = function(input_string)
    -- Checks whether or not the <input_string> is valid
    -- Returns true if it exists, otherwise returns false
    local input_string = paths.expandtilde(input_string)
    local opsys = reaper.GetOS()
    local f = "/fluid-noveltyslice"
    if opsys == "Win64" or opsys == "Win32" then 
        f = "/fluid-noveltyslice.exe" 
    end

    local ns_path = input_string .. f

    if paths.file_exists(ns_path) then
        return true
    else
        return false
    end
end

local ctx = reaper.ImGui_CreateContext('ReaCoMa Path Setter', 500, 240)
local vp = reaper.ImGui_GetMainViewport(ctx)

local path_valid = false
local show_modal = true

paths.gui = function()
    reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(vp))
    reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(vp))

    if show_modal then
        r.ImGui_OpenPopup(ctx, 'Set ReaCoMa Path')

        -- Always center this window when appearing
        local center = {r.ImGui_Viewport_GetCenter(r.ImGui_GetMainViewport(ctx))}
        local window_size = r.ImGui_Viewport_GetSize(vp) * 0.8
        r.ImGui_SetNextWindowSize(ctx, 400, 230, 0)
        r.ImGui_SetNextWindowPos(ctx, center[1], center[2], r.ImGui_Cond_Appearing(), 0.5, 0.5)

        -- ENTER MODAL --
        r.ImGui_BeginPopupModal(ctx, 'Set ReaCoMa Path', nil, r.ImGui_WindowFlags_AlwaysAutoResize())
        r.ImGui_TextWrapped(ctx, 'The path to the FluCoMa CLI tools is not set. Please follow the next prompt to configure it. Doing so remains persistent across projects and sessions of reaper.')
        r.ImGui_TextWrapped(ctx, "For example, if you've just downloaded the tools from the flucoma.org/download then you'll need to provide the path to the 'bin' folder which is inside 'Fluid Corpus Manipulation'.")
        r.ImGui_Separator(ctx)
        

        if r.ImGui_Button(ctx, 'OK', 120, 0) then 
            show_modal = false
            r.ImGui_CloseCurrentPopup(ctx) 
        end
        r.ImGui_EndPopup(ctx)
        -- EXIT MODAL --
    end

    reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(vp))
    reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(vp))
    reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())

    r.ImGui_Text(ctx, 'FluCoMa Command Line Tools Path')
    local red = r.ImGui_ColorConvertHSVtoRGB(0.0, 0.7, 1.0, 1.0)
    local green = r.ImGui_ColorConvertHSVtoRGB(0.3, 1.0, 0.5, 1.0)

    if path_valid then 
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), green)
    else
        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), red)
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

    if reaper.ImGui_Button(ctx, 'confirm path') then
        reaper.ImGui_End(ctx)
        reaper.ImGui_DestroyContext(ctx)
        return
    end

    if path_valid then
        r.ImGui_SameLine(ctx)
        r.ImGui_Text(ctx, '<-- Now hit this button to store the path!')
    end

    path_valid = reacoma.paths.is_path_valid(reacoma.settings.path)

    reaper.ImGui_End(ctx)

    if reaper.ImGui_IsCloseRequested(ctx) then
        reaper.ImGui_DestroyContext(ctx)
        return
    end

    reaper.defer(paths.gui)
end


return paths