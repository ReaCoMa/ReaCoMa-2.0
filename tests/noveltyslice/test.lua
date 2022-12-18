local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../../lib/reacoma.lua")()
dofile(script_path .. "slice_stats.lua")


obj = reacoma.noveltyslice
reacoma.global_state.width = 445
reacoma.global_state.height = 245
local ctx, viewport = imgui_helpers.create_context(obj.info.algorithm_name)

function test()
	reacoma.utils.deselect_all_items()

	local voice_media_item = reaper.GetMediaItem(0, 1)
	local track = reaper.GetTrack(0, 1)
	local _, track_name  = reaper.GetTrackName(track)
	assert(track_name == 'voice')
	
	reaper.SetMediaItemSelected(voice_media_item, true)
	reacoma.imgui_helpers.process(obj, 'split')
	local splits = reaper.CountTrackMediaItems(track)

	assert(splits == 68)
	for i=1, splits do
		local item = reaper.GetTrackMediaItem(track, i-1)
		local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		local position = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		assert(reacoma.utils.precise_equals(lengths[i], length, 0.0001))
		assert(
			reacoma.utils.precise_equals(
				positions[i],
				position,
				0.0001
			)
		)
	end
	reaper.Undo_DoUndo2(0)
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

		reaper.ExecProcess("sleep 0.25", 0)

		test()
	end
)
