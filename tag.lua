local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/" .. "FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidTagging.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidSlicing.lua")

if sanity_check() == false then goto exit; end
local loudness_exe = doublequote(get_fluid_path() .. "/fluid-loudness")
local stats_exe = doublequote(get_fluid_path() .. "/fluid-loudness")

local num_selected_items = reaper.CountSelectedMediaItems(0)
    if num_selected_items > 0 then