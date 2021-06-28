----------------------------------------------------------
--   ReaCoMa by James Bradbury | hello@jamesbradbury.xyz   --
----------------------------------------------------------
-- This is the entry point to the REACOMA library
-- Taking the path of THIS script we then append that folder to the package path
-- We then require all of the modules into this file which is loaded by any top level scripts
-- This means 1 import for every file that uses the library.

local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. script_path .. "?.lua"

-- Require the modules
local reaper = reaper
reacoma = {}

-- Add modules to reacoma table
reacoma.layers = require("layers")
reacoma.params = require("params")
reacoma.paths = require("paths")
reacoma.slicing = require("slicing")
reacoma.sorting = require("sorting")
reacoma.tagging = require("tagging")
reacoma.utils = require("utils")
reacoma.imgui_helpers = require("imgui_helpers")

-- Import algorithms
reacoma.noveltyslice = require("algos/noveltyslice")
reacoma.settings = {}

-- High level information about reacoma
loadfile(script_path .. "../config.lua")() -- Load the config as a chunk to get the values
reacoma.output = reacoma.output or "source" -- If this isn't set we set a default.
-- If the user has set a custom path then lets check if it exists
if reacoma.output ~= "source" and reacoma.output ~= "media" then
    reacoma.output = reacoma.paths.expandtilde(reacoma.output)
    if not reacoma.utils.dir_exists(reacoma.output) then
        reacoma.utils.DEBUG("The custom output directory ".."'"..reacoma.output.."'".." does not exist. Please make it or adjust the configuration")
        reacoma.utils.assert(false)
    end
end
-- Now set the paths up for where new files will be located
reacoma.lib = script_path
reacoma.version = "1.6.1"
reacoma.dep = "Fluid Corpus Manipulation Toolkit, version 1"

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

-- Store the path in a known place
reacoma.settings.path = reacoma.paths.get_reacoma_path() 

-- Check for versions
local get_version = reacoma.utils.wrap_quotes(
    reacoma.settings.path .. "/fluid-noveltyslice"
) .. " -v"

-- Get the current version by capturing the output of the -v flag
local installed_tools_version = reacoma.utils.capture(get_version)

-- Find out if the dependency string matches the version of the cli
-- From this we can deduce a sort of minimum version
local valid_version = installed_tools_version:find(reacoma.dep)

-- Check that the version of installed tools matches the marked version in the code
if not reacoma.bypass_version then
    if valid_version < 1 then
        local rv = reaper.ShowMessageBox(
            "The version of ReaCoMa is not tested with the currently installed command-line tools version and may fail or produce undefined behaviour. \n\nReaCoMa can take you to the download page by clicking OK, or you can move on by clicking Cancel. Alternatively, to disable this message forever change reacoma.bypass_version in config.lua to true.",
            "Version Incompatability", 1)
        if retval == 1 then
            reacoma.utils.open_browser("https://www.flucoma.org/download/")
        end
        reacoma.settings.fatal = false -- for now everything is fine, we dont need to test versions that thoroughly anymore
    end
end

-- Check tht imgui exists
if not reaper.ImGui_GetVersion then
    local rv = reaper.ShowMessageBox(
        "ReaImGui is a dependency of ReaCoMa version 2.0 and needs to be installed. \n\nReaCoMa can not install it for you, but it is simple to install. I suggest managing its installation through ReaPack. If you click OK, you will be taken to the ReaPack website which has instructions for installation.",
        "Dependency Missing", 1
    )
    if rv == 1 then
        reacoma.utils.open_browser("https://reapack.com/")
    end
    reacoma.settings.fatal = true
end

reaper.Undo_BeginBlock2(0)
reaper.Undo_BeginBlock2(0)
