local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end

obj = reacoma.algorithms.transients
reacoma.params.get(obj)

reacoma.global_state.width = 391
reacoma.global_state.height = 239

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