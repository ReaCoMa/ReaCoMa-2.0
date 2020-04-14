local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "../FluidPlumbing/" .. "FluidParams.lua")
dofile(script_path .. "../FluidPlumbing/" .. "FluidUtils.lua")


-- A script for getting rid of all FluCoMa related variables stored in the state table --
for k, v in pairs(reacoma.params.archetype) do
    for i, j in pairs(v) do
        reaper.DeleteExtState(v.name, i, true)
    end
end