local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end

obj = reacoma.algorithms.transientslice
reacoma.params.get(obj)

reacoma.global_state.width = 445
reacoma.global_state.height = 261

ctx, viewport = reacoma.imgui.helpers.create_context(obj.info.algorithm_name)

reaper.defer(
    function()
        reacoma.imgui.wrapper.loop({
			ctx=ctx, 
			viewport=viewport, 
			state={}, 
			obj=obj
		})
    end
)