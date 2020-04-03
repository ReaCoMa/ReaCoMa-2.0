fluidUtils = {}

fluidUtils.DEBUG = function(string)
    reaper.ShowConsoleMsg(string)
    reaper.ShowConsoleMsg("\n")
end

fluidUtils.nextpowstr = function(x)
    return tostring(
        math.floor(2^math.ceil(math.log(x)/math.log(2)))
    )
end

fluidUtils.getmaxfftsize = function(fft_string)
    local split_settings = fluidUtils.spacesplit(fft_string)
    local window = split_settings[1] 
    local fft = split_settings[3]
    local adjusted_fft = ""

    if fft == "1" then 
        adjusted_fft = fluidUtils.nextpowstr(tonumber(window)) 
        return adjusted_fft
    else
        return fft
    end
end


fluidUtils.uuid = function(idx)
    local time = tostring(reaper.time_precise()):gsub("%.+", "")
    return time .. idx
end

fluidUtils.cmdline = function(string)
    local opsys = reaper.GetOS()
    if opsys == "Win64" then reaper.ExecProcess(string, 0) end
    if opsys == "OSX64" or opsys == "Other" then os.execute(string) end
end

fluidUtils.sampstos = function(samps_in, sr)
    return samps_in / sr
end

fluidUtils.stosamps = function(secs_in, sr) 
    return math.floor((secs_in * sr) + 0.5)
end

fluidUtils.basedir = function(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

fluidUtils.basename = function(input_string)
    return input_string:match("(.+)%..+")
end

fluidUtils.rm_trailing_slash = function(s)
    -- Remove trailing slash from string. 
    -- Will not remove slash if it is the only character.
    return s:gsub('(.)%/$', '%1')
end

fluidUtils.cleanup = function(path_table)
    for i=1, #path_table do
        os.remove(path_table[i])
    end
end

fluidUtils.capture = function(cmd, raw)
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

fluidUtils.readfile = function(file)
    local f = assert(io.open(file, "r"))
    local content = f:read("*all")
    f:close()
    return content
end

fluidUtils.commasplit = function(input_string)
    -- splits by ,
    local t = {}
    for word in string.gmatch(input_string, '([^,]+)') do
        table.insert(t, word)
    end
    return t
end

fluidUtils.linesplit = function(input_string)
    -- splits by line endings
    local t = {}
    for word in string.gmatch(input_string,"(.-)\r?\n") do
        table.insert(t, word)
    end
    return t
end

fluidUtils.lacetables = function(table1, table2)
    laced = {}
    for i=1, #table1 do
        table.insert(laced, table1[i])
        table.insert(laced, table2[i])
    end
    return laced
end

fluidUtils.statstotable = function(string)
    local t = {}
    for word in string:gmatch('([^,]+)') do
        table.insert(t, tonumber(word))
    end
    return t
end

fluidUtils.spacesplit = function(input_string)
    local t = {}
    for word in input_string:gmatch("%w+") do table.insert(t, word) end
    return t
end

fluidUtils.rmdelim = function(input_string)
    local nodots = input_string.gsub(input_string, "%.", "")
    local nospace = nodots.gsub(nodots, "%s", "")
    return nospace
end

fluidUtils.tablelen = function(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

fluidUtils.doublequote = function(input_string)
    return '"'..input_string..'"'
end

---------- Custom operators ----------
matchers = {
    ['>'] = function (x, y) return x > y end,
    ['<'] = function (x, y) return x < y end,
    ['>='] = function (x, y) return x >= y end,
    ['<='] = function (x, y) return x <= y end
}