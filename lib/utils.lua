utils = {}

utils.DEBUG = function(string)
    -- Handy function for quickly debugging strings
    reaper.ShowConsoleMsg(string)
    reaper.ShowConsoleMsg("\n")
end

utils.arrange = function(undo_msg)
    reaper.Undo_BeginBlock()
    reaper.UpdateArrange()
    reaper.Undo_EndBlock(undo_msg, 0)
end

utils.spairs = function(t, order)
    -- This function orders a table given a function as <order>
    -- If no function is passed then it used the default sort function

    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

utils.reversetable = function(t)
    -- Reverse a table in place
	local i, j = 1, #t
	while i < j do
		t[i], t[j] = t[j], t[i]
		i = i + 1
		j = j - 1
	end
end

utils.nextpowstr = function(x)
    -- Finds the next power of <x> and returns it as a string
    return tostring(
        math.floor(2^math.ceil(math.log(x)/math.log(2)))
    )
end

utils.getmaxfftsize = function(fft_string)
    -- Given the three fftsettings values find the maximum fft size
    -- We have to do this because you can pass 1 as a valid argument
    local split_settings = utils.spacesplit(fft_string)
    local window = split_settings[1] 
    local fft = split_settings[3]
    local adjusted_fft = ""

    if fft == "1" then 
        adjusted_fft = utils.nextpowstr(tonumber(window)) 
        return adjusted_fft
    else
        return fft
    end
end


utils.uuid = function(idx)
    -- Generates a universally unique identifier string
    -- Increases uniqueness by appending a number <idx>
    -- <idx> is generally taken as a loop value
    return tostring(reaper.time_precise()):gsub("%.+", "") .. idx
end

utils.cmdline = function(command)
    -- Calls the <command> at the system's shell
    -- The implementation slightly differs for each operating system
    -- local opsys = reaper.GetOS()
    if opsys == "Win64" then retval = reaper.ExecProcess(command, 0) end

    if opsys == "OSX64" or opsys == "Other" then  retval = reaper.ExecProcess(command, 0) end
    local retval = reaper.ExecProcess(command, 0)
    
    if not retval then
        utils.DEBUG("There was an error executing the command: "..command)
        utils.DEBUG("See the return value and error below:\n")
        utils.DEBUG(tostring(retval))
        utils.assert(false)
    end
end

utils.assert = function(test)
    -- A template for asserting and dumping the stack
    -- You should embed this into a function and check against some value
    -- Avoid putting it at the top level and make the asserts granular
    reacoma.utils.DEBUG(debug.traceback())
    assert(test, "Fatal ReaCoMa error! An assertion has failed. Refer to the console for more information. If you provide a bug report it is useful to include the output of this window and the console.")
end

utils.website = function(website)
    local opsys = reaper.GetOS()
    local retval = ""
    if opsys == "Win64" then
        utils.cmdline("explorer " .. website)
    else
        retval = os.execute("open "..website)
        reacoma.utils.assert(retval)
    end
end

utils.sampstos = function(samples, samplerate)
    -- Return the number of <samples> given a time in seconds and a <samplerate>
    return samples / samplerate
end

utils.stosamps = function(seconds, samplerate) 
    -- Return the number of <seconds> given a time in samples and a <samplerate>
    return math.floor((seconds * samplerate) + 0.5)
end

utils.basedir = function(path, separator)
    -- Returns the base directory of a <path>
    -- for example /foo/bar/script.lua >>> /foo/bar/
    -- Optionally provide a <separator>
    local separator = separator or'/'
    return path:match("(.*"..separator..")")
end

utils.basename = function(path)
    -- Returns the basename of a <path>
    -- for example /foo/bar/script.lua >>> script.lua
    return path:match("(.+)%..+")
end

utils.rmtrailslash = function(input_string)
    -- Remove trailing slash from an <input_string>. 
    -- Will not remove slash if it is the only character.
    return input_string:gsub('(.)%/$', '%1')
end

utils.cleanup = function(path_table)
    -- Given a table of strings (<path_table>) that are paths call os.remove() on them
    for i=1, #path_table do
        os.remove(path_table[i])
    end
end

utils.capture = function(cmd, raw)
    -- Captures and returns the output of a command line call
    -- <cmd> is the command and <raw> is flag determining raw or sanitised return
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end

utils.readfile = function(file)
    -- Returns the contents of a <file> a string
    if not reacoma.paths.file_exists(file) then 
        utils.DEBUG(file.." could not be read because it does not exist.") 
        utils.assert(false)
    end
    local f = assert(io.open(file, "r"))
    local content = f:read("*all")
    f:close()
    return content
end

utils.commasplit = function(input_string)
    -- Splits an <input_string> seperated by "," into a table
    local t = {}
    for word in string.gmatch(input_string, '([^,]+)') do
        table.insert(t, word)
    end
    return t
end

utils.linesplit = function(input_string)
    -- Splits an <input_string> seperated by line endings into a table
    local t = {}
    for word in string.gmatch(input_string,"(.-)\r?\n") do
        table.insert(t, word)
    end
    return t
end

utils.spacesplit = function(input_string)
    -- Splits an <input_string> seperated by spaces into a table
    local t = {}
    for word in input_string:gmatch("%w+") do table.insert(t, word) end
    return t
end

utils.lacetables = function(table1, table2)
    -- Lace the contents of <table1> and <table2> together
    -- 1, 2, 3  and foo, bar, baz become..gfx.a
    -- 1, foo, 2, bar, 3, baz
    local laced = {}
    for i=1, #table1 do
        table.insert(laced, table1[i])
        table.insert(laced, table2[i])
    end
    return laced
end

utils.rmdelim = function(input_string)
    -- Removes delimiters from an <input_string>
    local nodots = input_string.gsub(input_string, "%.", "")
    local nospace = nodots.gsub(nodots, "%s", "")
    return nospace
end

utils.doublequote = function(input_string)
    -- Surrounds an <input_string> with quotation marks
    -- This is almost always required for passing things to the command line
    return '"'..input_string..'"'
end


utils.dataquery = function(idx, data)
    -- Takes in some 'data' and makes a nice print out
    reaper.ShowConsoleMsg("Item Length Samples: " .. data.item_len_samples[idx] .. "\n")
    if data.slice_points_string then
        reaper.ShowConsoleMsg("Slice Points: " .. data.slice_points_string[idx] .. "\n")
    end
end

---------- Custom operators ----------
-- These are used in the experimental functions that perform comparisons
matchers = {
    ['>'] = function (x, y) return x > y end,
    ['<'] = function (x, y) return x < y end,
    ['>='] = function (x, y) return x >= y end,
    ['<='] = function (x, y) return x <= y end
}

return utils