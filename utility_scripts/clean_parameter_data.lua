local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../lib/reacoma.lua")()
if reacoma.settings.fatal then return end

for k, v in pairs(reacoma.algorithms) do
	for i=1, #v.parameters do
		param = v.parameters[i]
		reaper.DeleteExtState(v.info.ext_name, param.name, true)
	end
end

