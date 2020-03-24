function DEBUG(string)
    reaper.ShowConsoleMsg(string)
    reaper.ShowConsoleMsg("\n")
end

function normalise(value, min_in, max_in, min_out, max_out)
    -- Go to 0 > 1
    value = tonumber(value)
    if value > max_in then value = max_in end
    if value < min_in then value = min_in end

    denom = max_in - min_in
    numer = tonumber(value) - min_in
    norm = numer / denom

    -- Scale to output
    out_range = max_out - min_out
    norm = (norm * out_range) + min_out
    return norm
end

function uuid(idx)
    local time = tostring(reaper.time_precise()):gsub("%.+", "")
    return time .. idx
end

function cmdline(string)
    local opsys = reaper.GetOS()
    if opsys == "Win64" then reaper.ExecProcess(string, 0) end
    if opsys == "OSX64" or opsys == "Other" then os.execute(string) end
end

function sampstos(samps_in, sr)
    return samps_in / sr
end

function stosamps(secs_in, sr) 
    return math.floor((secs_in * sr) + 0.5)
end

function basedir(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

function basename(input_string)
    return input_string:match("(.+)%..+")
end

function rm_trailing_slash(s)
    -- Remove trailing slash from string. 
    -- Will not remove slash if it is the only character.
    return s:gsub('(.)%/$', '%1')
end

function cleanup(path_table)
    for i=1, #path_table do
        os.remove(path_table[i])
    end
end

function capture(cmd, raw)
    -- usage: local output = capture("ls", false)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end

function readfile(file)
    local f = assert(io.open(file, "r"))
    local content = f:read("*all")
    f:close()
    return content
end

function commasplit(input_string)
    -- splits by ,
    local t = {}
    for word in string.gmatch(input_string, '([^,]+)') do
        table.insert(t, word)
    end
    return t
end

function statstotable(string)
    local t = {}
    for word in string:gmatch('([^,]+)') do
        table.insert(t, tonumber(word))
    end
    return t
end

function spacesplit(input_string)
    local t = {}
    for word in input_string:gmatch("%w+") do table.insert(t, word) end
    return t
end

function rmdelim(input_string)
    local nodots = input_string.gsub(input_string, "%.", "")
    local nospace = nodots.gsub(nodots, "%s", "")
    return nospace
end

function tablelen(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

function doublequote(input_string)
    return '"'..input_string..'"'
end

---------- Custom operators ----------
matchers = {
    ['>'] = function (x, y) return x > y end,
    ['<'] = function (x, y) return x < y end,
    ['>='] = function (x, y) return x >= y end,
    ['<='] = function (x, y) return x <= y end
}

---------- Functions for to setting state ----------
function get_fluid_path()
    return reaper.GetExtState("flucoma", "exepath")
end

function file_exists(name)
    if reaper.file_exists(name) then return true else return false end
end

---------- FluidPath setting ----------
function is_path_valid(input_string, warning_message)
    -- Checks to 
    local operating_system = reaper.GetOS()
    local check_table = {}
    check_table["Win64"] = "/fluid-noveltyslice.exe"
    check_table["OSX64"] = "/fluid-noveltyslice"

    local ns_path = input_string .. check_table[operating_system]

    if file_exists(ns_path) then
        reaper.SetExtState("flucoma", "exepath", input_string, 1)
        if warning_message then
            reaper.ShowMessageBox("The path you set looks good!", "Path Configuration", 0)
        end
        return true
    else
        reaper.ShowMessageBox("The path you set doesn't seem to contain the FluCoMa tools. Please try again.", "Path Configuration", 0)
        reaper.DeleteExtState("flucoma", "exepath", 1)
        path_setter()
    end
end

function path_setter()
    local cancel, input = reaper.GetUserInputs("Set path to FluCoMa Executables", 1, "Path:, extrawidth=100", "/usr/local/bin")
    if cancel ~= false then
        local input_path = rm_trailing_slash(input)
        -- local sanitised_input_path = doublequote(input_path)
        if is_path_valid(input_path, true) == true then return true end
    else
        reaper.ShowMessageBox("Your path remains unconfigured. The script will now exit.", "Warning", 0)
        reaper.DeleteExtState("flucoma", "exepath", 1)
        return false
    end
end

function set_fluid_path()
    if path_setter() == true then return true else return false end
end

function check_state()
    -- Check that the reaper Key "exepath" has been set
    return reaper.HasExtState("flucoma", "exepath")
end

function sanity_check()
    if check_state() == false then
        reaper.ShowMessageBox("The path to the FluCoMa CLI tools is not set. Please follow the next prompt to configure it. Doing so remains persistent across projects and sessions of reaper. If you need to change it please use the FluidEditPath.lua script.", "Warning!", 0)
        if set_fluid_path() == true then return true else return false end
    end

    if check_state() == true then 
        local possible_path = reaper.GetExtState("flucoma", "exepath")
        if is_path_valid(possible_path, false) == true then return true else return false end -- make sure the path is still okay, perhaps its moved...
    end
end