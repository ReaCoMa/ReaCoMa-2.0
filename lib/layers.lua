local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "ordered_tables.lua")

layers = {}

layers.output_exists = function(output)
    if not reacoma.paths.file_exists(output) then
        reacoma.utils.DEBUG(output .. " failed to be made by the command line.")
        reacoma.utils.assert(false)
    end
end

layers.exist = function(data)
    for _, output in pairs(data.outputs) do
        layers.output_exists(output)
    end
end

layers.process = function(data)
    reacoma.utils.deselect_all_items()
    reaper.SetMediaItemSelected(data.item, true)
    for k, v in ordered_pairs(data.outputs) do
        reaper.InsertMedia(data.outputs[k], 3)
        reaper.SetMediaItemTakeInfo_Value(data.take, "D_PLAYRATE", data.playrate)
        reaper.SetMediaItemTakeInfo_Value(data.take, "I_PITCHMODE", data.playtype)
        if data.reverse then 
            reaper.Main_OnCommand(41051, 0) 
        end
    end
end

layers.process_all_items = function(data_table)
    -- A function that just performs repetitive task of calling layers.process on each item
    for i=1, #data_table do
        local data = data_table[i]
        reacoma.utils.cmdline(data.cmd)
        reacoma.layers.exist(data)
        reacoma.layers.process(data)
    end
    reaper.UpdateArrange()
end

layers.process_matrix = function(a, b, output, append_target)
    if append_target == 0 then
        reaper.SetMediaItemSelected(a.item, true)
    else
        reaper.SetMediaItemSelected(b.item, true)
    end
    reaper.InsertMedia(output, 3)
    local item = reaper.GetSelectedMediaItem(0, 0) -- get the newly added take
    local take = reaper.GetActiveTake(item)
    reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", b.playrate)
    reaper.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", b.playtype)
    if b.reverse then reaper.Main_OnCommand(41051, 0) end
end

return layers