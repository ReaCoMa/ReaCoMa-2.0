local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. script_path .. "?.lua"

dofile(script_path .. 'noveltyslice/test.lua')
dofile(script_path .. 'onsetslice/test.lua')
dofile(script_path .. 'transientslice/test.lua')

reaper.ShowConsoleMsg('All tests passed :)')