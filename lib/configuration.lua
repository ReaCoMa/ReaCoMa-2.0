local configuration = {}

local r = reaper

function parse_ini_file(file_path)
    local ini_data = {}
    local current_section = nil

    for line in io.lines(file_path) do
        -- Remove inline comments (anything after ';' or '#')
        line = line:gsub("[%s;#].*", "")

        -- Check for section headers
        local section = line:match("^%[([^%]]+)%]$")
        if section then
            current_section = section
            ini_data[current_section] = {}
        else
            -- Check for key-value pairs within sections
            local key, value = line:match("^([^=]+)=([^=]+)$")
            if key and value and current_section then
                key = key:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                value = value:match("^%s*(.-)%s*$")
                ini_data[current_section][key] = value
            end
        end
    end

    return ini_data
end

configuration.get_ini_value = function(ini_file_name, section, key)
    -- Check that file exists in the first place
    if not reaper.file_exists(ini_file_name) then return false end
	local ini_data = parse_ini_file(ini_file_name)
		return ini_data[section][key] or false
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