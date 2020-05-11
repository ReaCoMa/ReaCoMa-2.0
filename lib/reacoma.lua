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
require("slicing")
require("sorting")
require("tagging")
require("utils")

-- Create a table containing vital reacoma information
reacoma = {}
reacoma.lib = script_path
reacoma.version = "1.4.1"
reacoma.dep = "Fluid Corpus Manipulation Toolkit, version 1.0.0-RC1"

-- Add modules to reacoma table
reacoma.layers = layers
reacoma.params = params
reacoma.paths = paths
reacoma.slicing = slicing
reacoma.sorting = sorting
reacoma.tagging = tagging
reacoma.utils = utils
reacoma.settings = {}

-- Check that we are not running in restricted mode
if not os then
    reacoma.settings.restricted = true
    reacoma.settings.fatal = true
    local restr = reaper.ShowMessageBox(
        "You have executed the ReaCoMa script in 'Restricted Mode'.\n\nReaCoMa needs this setting to be turned OFF.\n\nYou can disable resitrcted mode on the file selection pane when choosing a script.",
        "Restricted mode warning",
        0)
    return
end

-- Execute common code
if reacoma.paths.sanity_check() == false then 
    reacoma.settings.fatal = true
    return
end

reacoma.settings.path = reacoma.paths.get_reacoma_path() 

-- Check for versions
local get_version = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-noveltyslice"
) .. " -v"

local installed_tools_version = reacoma.utils.capture(get_version)

if reacoma.dep ~= installed_tools_version then
    local retval = reaper.ShowMessageBox(
        "The version of ReaCoMa is not compatible with the currently installed command line tools version and may fail or produce undefined behaviour.\n\nPlease update to version" .. reacoma.dep .. "\n\nReaCoMa can take you to the download page by clicking OK.",
        "Version Incompatability", 1)
    if retval then
        reacoma.utils.assert(
            reacoma.utils.website("https://www.flucoma.org/download/")
        )
    end
    reacoma.settings.fatal = true
end
