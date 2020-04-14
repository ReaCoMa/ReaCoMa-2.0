local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

dofile(script_path .. "FluidUtils.lua")

reacoma.paths = {}

---------- Functions for to setting state ----------
reacoma.paths.get_fluid_path = function()
    -- Returns the current value for the flucoma executable path state
    return reaper.GetExtState("flucoma", "exepath")
end

reacoma.paths.file_exists = function(path)
    -- Returns boolean for the existence of a file at <path>
    if reaper.file_exists(path) then return true else return false end
end

---------- fluidPath setting ----------
reacoma.paths.is_path_valid = function(input_string, warning_message)
    -- Checks whether or not the <input_string> is a valid FluidPath
    -- Optionally provide a warning message on success/failure
    local operating_system = reaper.GetOS()
    local check_table = {}
    check_table["Win64"] = "/fluid-noveltyslice.exe"
    check_table["OSX64"] = "/fluid-noveltyslice"
    check_table["Other"] = "/fluid-noveltyslice"

    local ns_path = input_string .. check_table[operating_system]

    if reacoma.paths.file_exists(ns_path) then
        reaper.SetExtState("flucoma", "exepath", input_string, 1)
        if warning_message then
            reaper.ShowMessageBox("The path you set looks good!", "Path Configuration", 0)
        end
        return true
    else
        reaper.ShowMessageBox("The path you set doesn't seem to contain the FluCoMa tools. Please try again.", "Path Configuration", 0)
        reaper.DeleteExtState("flucoma", "exepath", 1)
        reacoma.paths.path_setter()
    end
end

reacoma.paths.path_setter = function()
    -- Function to give the user a GUI the fluid path as an ExtState in REAPER
    local cancel, input = reaper.GetUserInputs("Set path to FluCoMa Executables", 1, "Path:, extrawidth=100", "/usr/local/bin")
    if cancel ~= false then
        local input_path = reacoma.utils.rmtrailslash(input)
        -- local sanitised_input_path = doublequote(input_path)
        if reacoma.paths.is_path_valid(input_path, true) == true then return true end
    else
        reaper.ShowMessageBox("Your path remains unconfigured. The script will now exit.", "Warning", 0)
        reaper.DeleteExtState("flucoma", "exepath", 1)
        return false
    end
end

reacoma.paths.set_fluid_path = function()
    if reacoma.paths.path_setter() == true then return true else return false end
end

reacoma.paths.check_state = function()
    -- Check that the REAPER ExtState "exepath" exists (has been set)
    return reaper.HasExtState("flucoma", "exepath")
end

reacoma.paths.sanity_check = function()
    -- Function to call at the start of every script
    -- This ensures that the path has been set otherwise it prompts the user to go through the process
    if reacoma.paths.check_state() == false then
        reaper.ShowMessageBox("The path to the FluCoMa CLI tools is not set. Please follow the next prompt to configure it. Doing so remains persistent across projects and sessions of reaper. If you need to change it please use the FluidEditPath.lua script.", "Warning!", 0)
        if reacoma.paths.set_fluid_path() == true then return true else return false end
    end

    if reacoma.paths.check_state() == true then 
        local possible_path = reacoma.paths.get_fluid_path()
        if reacoma.paths.is_path_valid(possible_path, false) == true then return true else return false end -- make sure the path is still okay, perhaps its moved...
    end
end