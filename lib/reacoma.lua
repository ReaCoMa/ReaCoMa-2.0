-----------------------------------------------------------
-- ReaCoMa by James Bradbury | reacoma@jamesbradbury.net --
-----------------------------------------------------------

local info = debug.getinfo(1,'S')
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
package.path = package.path .. ";" .. script_path .. "?.lua"

-- Require the modules
local reaper = reaper
reacoma = {}
reacoma.settings = {}
reacoma.lib = script_path
reacoma.version = "2.2.0a"
reacoma.global_state = {}
reacoma.global_state.active = false
state = {}

if not reaper.HasExtState("reacoma", "exepath") then
    -- Check if the default location might have the executables
    local resource_path = reaper.GetResourcePath()
    local ext = ''
    if reaper.GetOS() == 'Win64' then ext = '.exe' end
    local bin = resource_path..'/Scripts/ReaCoMa-2.0/bin'
    local exists = reaper.file_exists(bin..'/fluid-noveltyslice'..ext)
    if exists then reaper.SetExtState('reacoma', 'exepath', bin, true) end
end

reacoma.settings.path = reaper.GetExtState("reacoma", "exepath")

if reaper.HasExtState("reacoma", "slice_preview") then
    local preview = reaper.GetExtState("reacoma", "slice_preview")
    if preview == 'false' then preview = false else preview = true end
    local immediate = reaper.GetExtState("reacoma", "immediate_preview")
    if immediate == 'false' then immediate = false else immediate = true end
    reacoma.settings.slice_preview = preview
    reacoma.settings.immediate_preview = immediate
    reacoma.settings.preview_pending = false
else
    reacoma.settings.slice_preview = false
    reacoma.settings.immediate_preview = false
    reacoma.settings.preview_pending = false
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
    _ = reaper.ShowMessageBox(
        "You have executed the ReaCoMa script in 'Restricted Mode'.\n\nReaCoMa needs this setting to be turned OFF.\n\nYou can disable resitrcted mode on the file selection pane when choosing a script.",
        "Restricted mode warning",
        0)
    return
end

app_version = reaper.GetAppVersion()
app_version = app_version:sub(1, 4)
app_version = app_version:gsub('%.', '')
app_version = tonumber(app_version)

if app_version < 609 then
    reacoma.settings.fatal = true
    _ = reaper.ShowMessageBox(
        "ReaCoMa 2.0 requires a minimum of version 6.09 for REAPER.\n\nPlease update REAPER.",
        "Version Warning",
        0)
    return
end

-- Check that ReaImGui exists
local IMGUI_VERSION, IMGUI_VERSION_NUM, REAIMGUI_VERSION = reaper.ImGui_GetVersion()
local version_satisfied = IMGUI_VERSION_NUM >= 18800 or nil
if not reaper.ImGui_GetVersion or not version_satisfied then
    local rv = reaper.ShowMessageBox(
        "ReaImGui 0.7 or greater is a dependency of ReaCoMa version 2.0 and needs to be installed. \n\nReaCoMa can not install it for you, but it is simple to install. I suggest managing its installation through ReaPack. If you click OK, you will be taken to the ReaPack website which has instructions for installation.",
        "Dependency Missing", 1
    )
    if rv == 1 then
        reacoma.utils.open_browser("https://reapack.com/")
    end
    reacoma.settings.fatal = true
else
    dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.7') -- shim the version we want
    -- ImGui Specific Stuff
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
end

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


reaper.Undo_BeginBlock2(0)