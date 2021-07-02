local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end

obj = reacoma.ampgate
reacoma.params.get(obj)

reacoma.global_state.width = 484
reacoma.global_state.height = 307

ctx, viewport = imgui_helpers.create_context(obj.info.algorithm_name)

reaper.defer(
    function()
        reacoma.imgui_wrapper.loop(ctx, viewport, state, obj)
    end
)