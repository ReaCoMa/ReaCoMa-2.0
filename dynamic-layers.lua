local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end

parameters = reacoma.noveltyslice.parameters
slicer = reacoma.noveltyslice
reacoma.params.get(slicer)

ctx = reaper.ImGui_CreateContext(slicer.info.algorithm_name, 350, 225)
viewport = reaper.ImGui_GetMainViewport(ctx)

reaper.defer(
    function()
        reacoma.imgui_wrapper.loop(ctx, viewport, state, slicer, preview)
    end
)