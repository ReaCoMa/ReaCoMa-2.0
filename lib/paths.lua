paths = {}

paths.get_reacoma_path = function()
    -- Returns the current value for the flucoma executable path state
    return reaper.GetExtState("reacoma", "exepath")
end

paths.expandtilde = function(path)
    -- Crudely expands tilde to the user home folder
    local first = path:sub(1, 1)

    if first:match("~") then
        opsys = reaper.GetOS()
        if opsys == "OSX64" or opsys == "Other" then
            home = reacoma.utils.capture("echo $HOME")
        else
            home = reacoma.utils.capture("echo %USERPROFILE%")
        end
        path = home .. path:sub(2)
    end
    return path
end

paths.file_exists = function(path)
    path = paths.expandtilde(path)

    -- Returns boolean for the existence of a file at <path>
    -- Expand the tilde if exists
    if reaper.file_exists(path) then return true else return false end
end

paths.is_path_valid = function(input_string, warning_message)
    -- Checks whether or not the <input_string> is a valid FluidPath
    -- Optionally provide a warning message on success/failure
    input_string = paths.expandtilde(input_string)
    
    local operating_system = reaper.GetOS()
    local check_table = {}
    check_table["Win64"] = "/fluid-noveltyslice.exe"
    check_table["OSX64"] = "/fluid-noveltyslice"
    check_table["Other"] = "/fluid-noveltyslice"

    local ns_path = input_string .. check_table[operating_system]

    if paths.file_exists(ns_path) then
        reaper.SetExtState("reacoma", "exepath", input_string, 1)
        if warning_message then
            reaper.ShowMessageBox("The path you set looks good!", "Path Configuration", 0)
        end
        return true
    else
        reaper.ShowMessageBox("The path you set doesn't seem to contain the FluCoMa tools. Please try again.", "Path Configuration", 0)
        reaper.DeleteExtState("reacoma", "exepath", 1)
        paths.path_setter()
    end
end

paths.path_setter = function()
    -- Function to give the user a GUI the fluid path as an ExtState in REAPER
    local cancel, input = reaper.GetUserInputs("Set path to FluCoMa Executables", 1, "Path:, extrawidth=200", "/usr/local/bin")
    input = paths.expandtilde(input)
    if cancel ~= false then
        local input_path = utils.rmtrailslash(input)
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
    if paths.check_state() == false then
        reaper.ShowMessageBox("The path to the FluCoMa CLI tools is not set. Please follow the next prompt to configure it. Doing so remains persistent across projects and sessions of reaper. If you need to change it please use the FluidEditPath.lua script.", "Warning!", 0)
        if paths.set_reacoma_path() == true then return true else return false end
    end

    if paths.check_state() == true then 
        local possible_path = paths.get_reacoma_path()
        if paths.is_path_valid(possible_path, false) == true then return true else return false end -- make sure the path is still okay, perhaps its moved...
    end
end

return paths