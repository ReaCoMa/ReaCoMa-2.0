-- Register ReaCoMa scripts as actions
local r = reaper
local resourcePath = r.GetResourcePath()
local scriptPath = string.format('%s/Scripts', resourcePath)
local reacomaPath = string.format('%s/ReaCoMa 2.0', scriptPath)

function getFileExtension(filePath)
    return filePath:match("%.([^.]+)$") or ''
end

local i = 0
repeat
	local retval = reaper.EnumerateFiles( reacomaPath, i )
	if retval and getFileExtension(retval) == 'lua' then
		local luaScriptPath = string.format('%s/%s', reacomaPath, retval)
		reaper.AddRemoveReaScript(true, 0, luaScriptPath, true)
	end
	i = i + 1
until not retval