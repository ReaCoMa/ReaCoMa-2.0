local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../lib/reacoma.lua")()

reacoma.paths.set_reacoma_path()
