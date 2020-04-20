-- This is the entry point to the REACOMA library
-- Taking the path of THIS script we then append that folder to the package path
-- We then require all of the modules into this file which is loaded by any top level scripts
-- This means 1 import for every file that uses the library.

local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. script_path .. "?.lua"

-- Require the modules
local reaper = reaper
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
reacoma.version = "1.4.1"
reacoma.dep = "Fluid Corpus Manipulation Toolkit, version 1.0.0-RC2"

-- Add modules to reacoma table
reacoma.layers = layers
reacoma.params = params
reacoma.paths = paths
reacoma.download = download
reacoma.slicing = slicing
reacoma.sorting = sorting
reacoma.tagging = tagging
reacoma.utils = utils
reacoma.settings = {}

-- Execute common code
if reacoma.paths.sanity_check() == false then return end
reacoma.settings.path = reacoma.paths.get_reacoma_path() 

-- Check for versions
local get_version = reacoma.settings.path .. "/fluid-noveltyslice -v"
local installed_tools_version = reacoma.utils.capture(get_version)

if reacoma.dep ~= installed_tools_version then
    if reaper.GetExtState("reacoma", "version_warned") ~= "yes" then
        retval = reaper.ShowMessageBox(
            "The version of ReaCoMa is not compatible with the currently installed command line tools version and may fail or produce undefined behaviour.\n\nPlease update to version" .. reacoma.dep .. "\n\nReaCoMa can take you to the download page by clicking OK.\n\nThis warning will not bother you again.",
            "Version Incompatability", 1)
        if retval == 1 then
            -- Download
            reacoma.utils.website("https://www.flucoma.org/download/")
            reaper.SetExtState("reacoma", "version_warned", "yes", true)
        elseif retval == 2 then
            -- Leave them alone
            reaper.SetExtState("reacoma", "version_warned", "yes", true)
        end
    else
        print('Check for updates')
    end
end
