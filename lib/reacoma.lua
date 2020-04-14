-- This is the entry point to the REACOMA library
-- Taking the path of THIS script we then append that folder to the package path
-- We then require all of the modules into this file which is loaded by any top level scripts
-- This means 1 import for every file that uses the library.

local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. script_path .. "?.lua"

require("layers")
require("params")
require("paths")
require("slicing")
require("sorting")
require("tagging")
require("utils")

reacoma = {}
reacoma.layers = layers
reacoma.params = params
reacoma.paths = paths
reacoma.slicing = slicing
reacoma.sorting = sorting
reacoma.tagging = tagging
reacoma.utils = utils

reacoma.settings = {
    copyfx = true,
    path = reacoma.paths.get_reacoma_path()
    
}

if reacoma.paths.sanity_check() == false then return end
