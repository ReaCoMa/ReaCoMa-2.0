local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "fluidUtils.lua")

set_fluid_path()
