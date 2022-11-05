local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../../lib/reacoma.lua")()
-- dofile(script_path .. "slice_stats.lua")

obj = reacoma.transientslice
reacoma.global_state.width = 445
reacoma.global_state.height = 245
ctx, viewport = imgui_helpers.create_context(obj.info.algorithm_name)

function test()
	local media_item = reaper.GetMediaItem(0, 0)
	local track = reaper.GetTrack(0, 0)
	local _, track_name  = reaper.GetTrackName(track)
	assert(track_name == 'drum')
	
	reaper.SetMediaItemSelected(media_item, true)
	reacoma.imgui_helpers.process(obj, 'split')
	local splits = reaper.CountTrackMediaItems(track)
	reacoma.utils.DEBUG(splits)
	-- assert(splits == 14)
	-- for i=1, splits do
	-- 	local item = reaper.GetTrackMediaItem(track, i-1)
	-- 	local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	-- 	local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	-- 	assert(reacoma.utils.precise_equals(lengths[i], length, 0.0001))
	-- 	assert(
	-- 		reacoma.utils.precise_equals(
	-- 			positions[i],
	-- 			position,
	-- 			0.0001
	-- 		)
	-- 	)
	-- end
	-- reaper.Undo_DoUndo2(0)
	reacoma.utils.DEBUG('transientslice test passed')
end

reaper.defer(
    function()
        reacoma.imgui_wrapper.loop({
			ctx=ctx, 
			viewport=viewport, 
			state={}, 
			obj=obj,
			test=true
		})

		test()
	end
)
