local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end

obj = reacoma.ampslice
reacoma.params.get(obj)

ctx, viewport = imgui_helpers.create_context(obj.info.algorithm_name, 426, 243)

reaper.defer(
    function()
        reacoma.imgui_wrapper.loop(ctx, viewport, state, obj)
    end
)