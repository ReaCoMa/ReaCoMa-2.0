FluidUtils = {}

function DEBUG(string)
    reaper.ShowConsoleMsg(string)
    reaper.ShowConsoleMsg("\n")
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

function linesplit(input_string)
    -- splits by line endings
    local t = {}
    for word in string.gmatch(input_string,"(.-)\r?\n") do
        table.insert(t, word)
    end
    return t
end

function lacetables(table1, table2)
    laced = {}
    for i=1, #table1 do
        table.insert(laced, table1[i])
        table.insert(laced, table2[i])
    end
    return laced
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