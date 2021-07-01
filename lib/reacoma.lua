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
reacoma.settings = {}

-- Add modules to reacoma table
reacoma.container = require("container")
reacoma.layers = require("layers")
reacoma.slicing = require("slicing")
reacoma.params = require("params")
reacoma.paths = require("paths")
reacoma.sorting = require("sorting")
reacoma.tagging = require("tagging")
reacoma.utils = require("utils")
reacoma.imgui_helpers = require("imgui_helpers")
reacoma.imgui_wrapper = require("imgui_wrapper")

-- Slicing
reacoma.noveltyslice = require("algorithms/noveltyslice")
reacoma.ampslice = require("algorithms/ampslice")
reacoma.transientslice = require("algorithms/transientslice")
reacoma.onsetslice = require("algorithms/onsetslice")
-- reacoma.ampgate = require("algorithms/ampgate")
-- Layers
reacoma.hpss = require("algorithms/hpss")
reacoma.nmf = require("algorithms/nmf")
reacoma.sines = require("algorithms/sines")
reacoma.transients = require("algorithms/transients")

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
reacoma.version = "2.0.0a"

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

-- Check that ReaImGui exists
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

if reacoma.paths.is_path_valid(reacoma.paths.get_reacoma_path()) then
    -- quickly check that its valid
    -- local reacoma_exe_path = reacoma.paths.get_reacoma_path()

    -- if not valid go into setter
    -- if not reacoma.paths.is_path_valid(reacoma_exe_path) then
else
    reaper.defer(
        function()
            paths.gui(ctx, vp)
        end
    )
end
-- Store the path in a known place
reacoma.settings.path = reacoma.paths.get_reacoma_path() 

reaper.Undo_BeginBlock2(0)
state = {}
preview = true