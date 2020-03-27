local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/" .. "FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidUtils.lua")

for k, v in pairs(fluid_archetype) do
    DEBUG(v.name)
    for i, j in pairs(v) do
        DEBUG(i)
        reaper.DeleteExtState(v.name, i, true)
    end
end