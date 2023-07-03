local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../lib/reacoma.lua")()
if reacoma.settings.fatal then return end

for _, v in pairs(reacoma.algorithms) do
	for i=1, #v.parameters do
		param = v.parameters[i]
		if reaper.HasExtState(reacoma.settings.version..v.info.ext_name, param.name) then
			reaper.DeleteExtState(reacoma.settings.version..v.info.ext_name, param.name, true)
			reaper.ShowConsoleMsg('Deleted '..param.name..'\n')
		else
			reaper.ShowConsoleMsg(param.name..' did not have anything stored\n')
		end
	end
end

