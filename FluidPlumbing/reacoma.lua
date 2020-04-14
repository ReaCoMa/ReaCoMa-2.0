local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
-- dofile(script_path .. "FluidSlicing.lua")

package.path = package.path .. ";" .. script_path .. "?.lua"
require("tester")

reacoma = {}

reacoma.settings = {
    copyfx = true
}
