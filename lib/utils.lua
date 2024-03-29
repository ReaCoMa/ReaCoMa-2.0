local r = reaper
local utils = {}

utils.bool_to_number = { [true]=1, [false]=0 }
utils.string_to_bool = { ['true']=true, ['false']=false }
utils.bool_to_string = { [true]='true', [false]='false' }

utils.DEBUG = function(string)
    -- Handy function for quickly debugging strings
    r.ShowConsoleMsg(tostring(string))
    r.ShowConsoleMsg("\n")

    if not reacoma.debug.cli_already_posted and reacoma.debug.cli_already_posted ~= '' then 
        r.ShowConsoleMsg(
            '\nThe most recent CLI call was:\n\n'..reacoma.debug.cli..'\n\n'
        )
        reacoma.debug.cli_already_posted = true
    end
end

utils.deep_copy = function(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[utils.deep_copy(k, s)] = utils.deep_copy(v, s) end
  return res
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

utils.reverse_table = function(t)
    -- Reverse a table in place
	local i, j = 1, #t
	while i < j do
		t[i], t[j] = t[j], t[i]
		i = i + 1
		j = j - 1
	end
end

utils.form_fft_string = function(window, hop, fft)
    -- always append -1 so that maxfftsize matches fft
    return string.format('%d %d %d -1', window, hop, fft)
end

utils.uuid = function(idx)
    -- Generates a universally unique identifier string
    -- Increases uniqueness by appending a number <idx>
    -- <idx> is generally taken as a loop value
    return tostring(r.time_precise()):gsub("%.+", "") .. idx
end

utils.cross_platform_executable = function(executable)
    -- Returns the executable with the correct extension for the platform
    local opsys = r.GetOS()
    if opsys == "Win64" then
        return executable .. ".exe"
    else
        return executable
    end
end
    
    
utils.cmdline = function(invocation)
    reacoma.debug.cli = invocation
    local retval = r.ExecProcess(invocation, 0)
    
    if not retval then
        utils.DEBUG("There was an error executing the command: " .. invocation .. "\n")
        utils.DEBUG("See the return value and error below:\n")
        utils.DEBUG(tostring(retval))
        utils.assert(false)
    end
end

utils.assert = function(test)
    -- A template for asserting and dumping the stack
    -- You should embed this into a function and check against some value
    -- Avoid putting it at the top level and make the asserts granular
    if not test then
        reacoma.utils.DEBUG(debug.traceback())
    end
    assert(test, "Fatal ReaCoMa error! An assertion has failed. Refer to the console for more information. If you provide a bug report it is useful to include the output of this window and the console.")
end

utils.open_browser = function(url)
    local opsys = r.GetOS()
    local retval = ""
    if opsys == "Win64" then
        utils.cmdline("explorer " .. url)
    else
        retval = os.execute("open " .. url)
        utils.assert(retval)
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

utils.dir_parent = function(path, separator)
    -- Returns the base directory of a <path>
    -- for example /foo/bar/script.lua >>> /foo/bar/
    -- Optionally provide a <separator>
    local separator = separator or'/'
    return path:match("(.*"..separator..")")
end

utils.dir_exists = function(path)
    local cross_platform_string = path.."/"
    local ok, err, code = os.rename(path, path)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true
       end
    end
    return ok, err
end

utils.basename = function(path)
    -- Returns the basename of a <path>
    -- for example /foo/bar/script.lua >>> /foo/bar/script
    return path:match("(.+)%..+")
end

utils.name = function(path)
    -- Returns the name from a path
    -- /foo/bar/script.lua >> script.lua
    return path:match("^.+/(.+)$")
end

utils.stem = function(path)
    -- Returns the stem of a path
    -- /foo/bar/script.lua >> script
    local _, file, _ = path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
    return file
end

utils.form_path = function(path)
    -- Forms a path given the reacoma.output settings
    if reacoma.output == "source" then
        return utils.basename(path)
    elseif reacoma.output == "media" then
        local stem = utils.stem(path)
        return reacoma.paths.expandtilde("~/Documents/REAPER Media/") .. stem
    else
        local stem = utils.stem(path)
        return reacoma.output.."/".. stem
    end
end

utils.table_contains = function(tbl, value)
    for i=1, #tbl do
        if tbl[i] == value then return true end
    end
    return false
end

-- Tests if val is a property of a table (tbl)
utils.table_has = function(tbl, val)
	for _, v in pairs(tbl) do
		if v == val then
			return true 
		end
	end
	return false
end

utils.check_extension = function(path)
    local _, name, ext = path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
    local valid_ext = {'wav', 'aif', 'aiff', 'WAV', 'AIF', 'AIFF'}
    local valid = utils.table_contains(valid_ext, ext)
    if not valid then
        utils.DEBUG(name.." is not in WAV or AIFF format. ReaCoMa currently only works on WAV or AIFF files.")
        utils.assert(false)
    end
end

utils.rm_trailing_slash = function(input_string)
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

utils.cleanup2 = function(path)
    os.remove(path)
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

utils.split_comma = function(input_string)
    -- Splits an <input_string> seperated by "," into a table
    local t = {}
    for word in string.gmatch(input_string, '([^,]+)') do
        table.insert(t, word)
    end
    return t
end

utils.split_line = function(input_string)
    -- Splits an <input_string> seperated by line endings into a table
    local t = {}
    for word in string.gmatch(input_string,"(.-)\r?\n") do
        table.insert(t, word)
    end
    return t
end

utils.split_space = function(input_string)
    -- Splits an <input_string> seperated by spaces into a table
    local t = {}
    for word in input_string:gmatch("%S+") do 
        table.insert(t, word) 
    end
    return t
end

utils.lace_tables = function(table1, table2)
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

utils.wrap_quotes = function(input_string)
    -- Surrounds an <input_string> with quotation marks
    -- This is almost always required for passing things to the command line
    return '"'..input_string..'"'
end

utils.indexof = function(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

utils.split_table = function(t, point)
	local l, r = {}, {}

	for k, v in ipairs(t) do
		if k <= point then
			table.insert(l, v)
		else
			table.insert(r, v)
		end
	end
    return l, r
end

utils.compare_item_tables = function(a, b)
    if #a ~= #b then return false end
    if type(a) ~= type(b) then return false end

    for i=1, #a do
        if a[i] ~= b[i] then return false end
    end

    return true
end

utils.grab_selected_items = function()
    local temp_items = {}
    local num_items = r.CountSelectedMediaItems(0)
    for i=1, num_items do
        temp_items[i] = r.GetSelectedMediaItem(0, i-1)
    end
    return temp_items
end

utils.deselect_all_items = function()
    while r.CountSelectedMediaItems(0) > 0 do
        local item = r.GetSelectedMediaItem(0, 0)
        r.SetMediaItemSelected(item, false)
    end
end

return utils