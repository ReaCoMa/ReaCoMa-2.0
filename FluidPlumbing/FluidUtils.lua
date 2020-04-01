FluidUtils = {}

FluidUtils.DEBUG = function(string)
    reaper.ShowConsoleMsg(string)
    reaper.ShowConsoleMsg("\n")
end

FluidUtils.uuid = function(idx)
    local time = tostring(reaper.time_precise()):gsub("%.+", "")
    return time .. idx
end

FluidUtils.cmdline = function(string)
    local opsys = reaper.GetOS()
    if opsys == "Win64" then reaper.ExecProcess(string, 0) end
    if opsys == "OSX64" or opsys == "Other" then os.execute(string) end
end

FluidUtils.sampstos = function(samps_in, sr)
    return samps_in / sr
end

FluidUtils.stosamps = function(secs_in, sr) 
    return math.floor((secs_in * sr) + 0.5)
end

FluidUtils.basedir = function(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

FluidUtils.basename = function(input_string)
    return input_string:match("(.+)%..+")
end

FluidUtils.rm_trailing_slash = function(s)
    -- Remove trailing slash from string. 
    -- Will not remove slash if it is the only character.
    return s:gsub('(.)%/$', '%1')
end

FluidUtils.cleanup = function(path_table)
    for i=1, #path_table do
        os.remove(path_table[i])
    end
end

FluidUtils.capture = function(cmd, raw)
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

FluidUtils.readfile = function(file)
    local f = assert(io.open(file, "r"))
    local content = f:read("*all")
    f:close()
    return content
end

FluidUtils.commasplit = function(input_string)
    -- splits by ,
    local t = {}
    for word in string.gmatch(input_string, '([^,]+)') do
        table.insert(t, word)
    end
    return t
end

FluidUtils.linesplit = function(input_string)
    -- splits by line endings
    local t = {}
    for word in string.gmatch(input_string,"(.-)\r?\n") do
        table.insert(t, word)
    end
    return t
end

FluidUtils.lacetables = function(table1, table2)
    laced = {}
    for i=1, #table1 do
        table.insert(laced, table1[i])
        table.insert(laced, table2[i])
    end
    return laced
end

FluidUtils.statstotable = function(string)
    local t = {}
    for word in string:gmatch('([^,]+)') do
        table.insert(t, tonumber(word))
    end
    return t
end

FluidUtils.spacesplit = function(input_string)
    local t = {}
    for word in input_string:gmatch("%w+") do table.insert(t, word) end
    return t
end

FluidUtils.rmdelim = function(input_string)
    local nodots = input_string.gsub(input_string, "%.", "")
    local nospace = nodots.gsub(nodots, "%s", "")
    return nospace
end

FluidUtils.tablelen = function(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

FluidUtils.doublequote = function(input_string)
    return '"'..input_string..'"'
end

---------- Custom operators ----------
matchers = {
    ['>'] = function (x, y) return x > y end,
    ['<'] = function (x, y) return x < y end,
    ['>='] = function (x, y) return x >= y end,
    ['<='] = function (x, y) return x <= y end
}