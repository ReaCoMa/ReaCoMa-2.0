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
require("download")
require("slicing")
require("sorting")
require("tagging")
require("utils")

-- Create a table containing vital reacoma information
reacoma = {}
reacoma.lib = script_path
reacoma.v = "1.4.1"
reacoma.dep = "Fluid Corpus Manipulation Toolkit, version 1.0.0-RC1"

-- Add modules
reacoma.layers = layers
reacoma.params = params
reacoma.paths = paths
reacoma.download = download
reacoma.slicing = slicing
reacoma.sorting = sorting
reacoma.tagging = tagging
reacoma.utils = utils

reacoma.settings = {}

-- This stuff here is common code
if reacoma.paths.sanity_check() == false then return end
reacoma.settings.path = reacoma.paths.get_reacoma_path() 

-- Check for versions