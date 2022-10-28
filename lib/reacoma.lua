-----------------------------------------------------------
-- ReaCoMa by James Bradbury | reacoma@jamesbradbury.net --
-----------------------------------------------------------

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. script_path .. "?.lua"

-- Require the modules
local r = reaper
reacoma = {}
reacoma.settings = {}
reacoma.lib = script_path
reacoma.global_state = {}
reacoma.global_state.active = false
state = {}
loadfile(script_path .. "../config.lua")() -- load the config

if reaper.HasExtState("reacoma", "slice_preview") then
    local preview = reaper.GetExtState("reacoma", "slice_preview")
    if preview == 'false' then preview = false else preview = true end
    local immediate = reaper.GetExtState("reacoma", "immediate_preview")
    if immediate == 'false' then immediate = false else immediate = true end
    reacoma.settings.slice_preview = preview
    reacoma.settings.immediate_preview = immediate
    reacoma.global_state.preview_pending = false
else
    reacoma.settings.slice_preview = false
    reacoma.settings.immediate_preview = false
    reacoma.global_state.preview_pending = false
end

-- Add modules to reacoma table
reacoma.container = require("container")
reacoma.layers    = require("layers")
reacoma.slicing   = require("slicing")
reacoma.params    = require("params")
reacoma.paths     = require("paths")
reacoma.sorting   = require("sorting")
reacoma.tagging   = require("tagging")
reacoma.utils     = require("utils")

-- Check that we are not running in restricted mode
if not os then
    reacoma.settings.restricted = true
    reacoma.settings.fatal = true
    reaper.ShowMessageBox(
        "You have executed the ReaCoMa script in 'Restricted Mode'.\n\nReaCoMa needs this setting to be turned OFF.\n\nYou can disable resitrcted mode on the file selection pane when choosing a script.",
        "Restricted mode warning",
        0
    )
    return
end

app_version = r.GetAppVersion()
app_version = app_version:sub(1, 4)
app_version = app_version:gsub('%.', '')
app_version = tonumber(app_version)

if app_version < 609 then
    reacoma.settings.fatal = true
    reaper.ShowMessageBox(
        "ReaCoMa 2.0 requires a minimum of version 6.09 for REAPER.\n\nPlease update REAPER.",
        "Version Warning",
        0
    )
    return
end

reacoma.binaries = reacoma.binaries or "default"
if reacoma.binaries == "default" then 
    reacoma.settings.path = script_path:gsub("lib/", "bin")
    if not reacoma.paths.is_path_valid(reacoma.settings.path) then
        reaper.ShowMessageBox(
            "The default binary location (" .. reacoma.settings.path .. ") does not contain valid FluCoMa binaries. Check that this folder contains the binaries.",
            "Binary folder invalid",
            0
        )
        reacoma.settings.fatal = true
    end
else
    reacoma.settings.path = reacoma.paths.expandtilde(reacoma.binaries)
    if not reacoma.paths.is_path_valid(reacoma.settings.path) then
        reaper.ShowMessageBox(
            "The custom path set in config.lua (" .. reacoma.binaries .. ") does not contain valid FluCoMa binaries.",
            "Custom binary path invalid",
            0
        )
        reacoma.settings.fatal = true
    end
end

reacoma.output = reacoma.output or "source" -- If this isn't set we set a default.
if reacoma.output ~= "source" and reacoma.output ~= "media" then
    reacoma.output = reacoma.paths.expandtilde(reacoma.output)
    if not reacoma.utils.dir_exists(reacoma.output) then
        reacoma.utils.DEBUG("The custom output directory ".."'"..reacoma.output.."'".." does not exist. Please make it or adjust the configuration")
        reacoma.utils.assert(false)
    end
end

-- Check that ReaImGui exists
local IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION = reaper.ImGui_GetVersion()
local version_satisfied = IMGUI_VERSION_NUM >= 18800 or nil
if not reaper.ImGui_GetVersion or not version_satisfied then
    local rv = r.ShowMessageBox(
        "ReaImGui 0.7 or greater is a dependency of ReaCoMa version 2.0 and needs to be installed. \n\nReaCoMa can not install it for you, but it is simple to install. I suggest managing its installation through ReaPack. If you click OK, you will be taken to the ReaPack website which has instructions for installation.",
        "Dependency Missing", 1
    )
    if rv == 1 then
        reacoma.utils.open_browser("https://reapack.com/")
    end
    reacoma.settings.fatal = true
else
    dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.7') -- shim the version we want
    reacoma.colors = require("colors")
    reacoma.imgui_helpers = require("imgui_helpers")
    reacoma.imgui_wrapper = require("imgui_wrapper")

    -- Slicing
    reacoma.noveltyslice = require("algorithms/noveltyslice")
    reacoma.ampslice = require("algorithms/ampslice")
    reacoma.transientslice = require("algorithms/transientslice")
    reacoma.onsetslice = require("algorithms/onsetslice")
    reacoma.ampgate = require("algorithms/ampgate")
    -- Layers
    reacoma.hpss = require("algorithms/hpss")
    reacoma.nmf = require("algorithms/nmf")
    reacoma.sines = require("algorithms/sines")
    reacoma.transients = require("algorithms/transients")
    reacoma.nmfcross = require("algorithms/nmfcross")
    reacoma.audiotransport = require("algorithms/audiotransport")
end
