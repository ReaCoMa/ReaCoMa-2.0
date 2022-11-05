local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

dofile(script_path .. 'test_noveltyslice/test.lua')
dofile(script_path .. 'test_onsetslice/test.lua')