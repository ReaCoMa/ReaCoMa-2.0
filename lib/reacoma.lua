-----------------------------------------------------------
-- ReaCoMa by James Bradbury | reacoma@jamesbradbury.net --
-----------------------------------------------------------

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. script_path .. "?.lua"

local r = reaper
reacoma = {}
reacoma.debug = { cli = '' }
reacoma.settings = { version = 210 } -- this needs to be changed on major version releases
reacoma.global_state = { active = false }


-- Add modules to reacoma table
reacoma.container = require("container")
reacoma.layers    = require("layers")
reacoma.slicing   = require("slicing")
reacoma.params    = require("params")
reacoma.paths     = require("paths")
reacoma.utils     = require("utils")

-- Check that we are not running in restricted mode
if not os then
    reacoma.settings.restricted = true
    reacoma.settings.fatal = true
    r.ShowMessageBox(
        "You have executed the ReaCoMa script in 'Restricted Mode'.\n\nReaCoMa needs this setting to be turned OFF.\n\nYou can disable resitrcted mode on the file selection pane when choosing a script.",
        "Restricted mode warning",
        0
    )
    return
end

-- Check that REAPER is at least the minimum version
app_version = r.GetAppVersion()
app_version = app_version:sub(1, 4)
app_version = app_version:gsub('%.', '')
app_version = tonumber(app_version)

if app_version < 609 then
    reacoma.settings.fatal = true
    r.ShowMessageBox(
        "ReaCoMa 2.0 requires a minimum of version 6.09 for r.\n\nPlease update r.",
        "Version Warning",
        0
    )
    return
end

local configuration = require 'configuration'
local config_path = r.GetResourcePath()..'/Scripts/reacoma.ini'

-- Check that the FluCoMa Binaries exist
reacoma.binaries = configuration.get_ini_value(config_path, 'reacoma', 'binaries')
if reacoma.binaries == false then 
    reacoma.settings.path = script_path:gsub("lib/", "bin")
    if not reacoma.paths.is_path_valid(reacoma.settings.path) then
        r.ShowMessageBox(
            "The default binary location (" .. reacoma.settings.path .. ") does not contain valid FluCoMa binaries. Check that this folder contains the binaries.",
            "Binary folder invalid",
            0
        )
        reacoma.settings.fatal = true
    end
else
    reacoma.settings.path = reacoma.paths.expandtilde(reacoma.binaries)
    if not reacoma.paths.is_path_valid(reacoma.settings.path) then
        r.ShowMessageBox(
            "The custom path set in config.lua (" .. reacoma.binaries .. ") does not contain valid FluCoMa binaries.",
            "Custom binary path invalid",
            0
        )
        reacoma.settings.fatal = true
    end
end

-- Now determine if the configuration file has a custom flucoma binaries path
reacoma.output = 
    configuration.get_ini_value(config_path, 'reacoma', 'output') or 'source'

if reacoma.output ~= "source" and reacoma.output ~= "media" then
    reacoma.output = reacoma.paths.expandtilde(reacoma.output)
    if not reacoma.utils.dir_exists(reacoma.output) then
        reacoma.utils.DEBUG("The custom output directory ".."'"..reacoma.output.."'".." does not exist. Please make it or adjust the configuration")
        reacoma.utils.assert(false)
    end
end

-- Check that ReaImGui exists and is at least the ninimum version
local IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION = r.ImGui_GetVersion()
local version_satisfied = IMGUI_VERSION_NUM >= 18800 or nil
if not r.ImGui_GetVersion or not version_satisfied then
    local rv = r.ShowMessageBox(
        "ReaImGui 0.8.6 or greater is a dependency of ReaCoMa 2.0 and needs to be installed. \n\nReaCoMa can not install it for you, but it is simple to install. I suggest managing its installation through ReaPack. If you click OK, you will be taken to the ReaPack website which has instructions for installation.",
        "Dependency Missing", 1
    )
    if rv == 1 then
        reacoma.utils.open_browser("https://reapack.com/")
    end
    reacoma.settings.fatal = true
else
    dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8.6') -- shim the version we want
    reacoma.colors = require("colors")
    reacoma.imgui = {
        helpers = require("imgui/helpers"),
        wrapper = require("imgui/wrapper"),
        widgets = require('imgui/widgets')
    }
    reacoma.algorithms = {}
    reacoma.algorithms.noveltyslice = require("algorithms/noveltyslice")
    reacoma.algorithms.ampslice = require("algorithms/ampslice")
    reacoma.algorithms.transientslice = require("algorithms/transientslice")
    reacoma.algorithms.onsetslice = require("algorithms/onsetslice")
    reacoma.algorithms.ampgate = require("algorithms/ampgate")
    reacoma.algorithms.hpss = require("algorithms/hpss")
    reacoma.algorithms.nmf = require("algorithms/nmf")
    reacoma.algorithms.sines = require("algorithms/sines")
    reacoma.algorithms.transients = require("algorithms/transients")
    reacoma.algorithms.nmfcross = require("algorithms/nmfcross")
    reacoma.algorithms.audiotransport = require("algorithms/audiotransport")
end

-- Update the slice preview settings
if r.HasExtState("reacoma", "slice_preview") then
    local preview = r.GetExtState("reacoma", "slice_preview")
    if preview == 'false' then preview = false else preview = true end
    local immediate = r.GetExtState("reacoma", "immediate_preview")
    if immediate == 'false' then immediate = false else immediate = true end
    reacoma.settings.slice_preview = preview
    reacoma.settings.immediate_preview = immediate
    reacoma.global_state.preview_pending = false
else
    reacoma.settings.slice_preview = false
    reacoma.settings.immediate_preview = false
    reacoma.global_state.preview_pending = false
end

