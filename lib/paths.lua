local r = reaper

paths = {}

paths.get_reacoma_path = function()
    -- Returns the current value for the flucoma executable path state
    return reaper.GetExtState("reacoma", "exepath")
end

paths.set_reacoma_path = function(path)
    return reaper.SetExtState('reacoma', 'exepath', path, true)
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


return paths