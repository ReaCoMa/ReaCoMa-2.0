local configuration = {}

local r = reaper

configuration.get_ini_value = function(ini_file_name, section, key)
	-- Check that file exists in the first place
	if not reaper.file_exists(ini_file_name) then return false end

	local section_found = false
	local key_found = false
	for line in io.lines(ini_file_name) do
		-- Try to find the section
		if not section_found and line == "[" .. section .. "]" then
			section_found = true
		end
		
		-- Section was found, but it has no keys (-> return and show error message)
		if section_found and starts_with(line, "[") and line ~= "[" .. section .. "]" then
			if section_found and not key_found then 
				-- r.ShowConsoleMsg("Couldn't find key: " .. key .. "\n") 
			end
			return false
		end
		
		-- Section found -> try to find the key
		if section_found then
			if not starts_with(line, ";") then
				local temp_line = line:match("([^=]+)")
				if temp_line ~= nil and temp_line:trim() ~= nil then
					temp_line = temp_line:trim()
					if temp_line == key then
						key_found = true
						
						-- Key found -> Try to get the value
						local val = ({line:split("=")})[2]
						-- No value set for this key -> return an empty string
						if val == nil then
							val = ""
						end
						return val:trim()
					end
				end
			end
		end
	end
	
	-- Section was not found
	if not section_found then 
		-- r.ShowConsoleMsg("Couldn't find section: " .. section .. "\n")
		return false
	end
	if not key_found then 
		if section_found and not key_found then 
			-- r.ShowConsoleMsg("Couldn't find key: " .. key .. "\n") 
		end
		return false
	end
end


-- String functions from Haywoods DROPP Script..
function starts_with(text,prefix)
	return string.sub(text, 1, string.len(prefix)) == prefix
end

function string:split(sep)
	return self:match("([^" .. sep .. "]+)[" .. sep .. "]+(.+)")
end

function string:trim()
	return self:match("^%s*(.-)%s*$")
end

return configuration