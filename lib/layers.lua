local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "OrderedTables.lua")
floor = math.floor
abs = math.abs

layers = {}

layers.exist = function(item_index, data)
    for k, _ in pairs(data.outputs) do
        if not reacoma.paths.file_exists(data.outputs[k][item_index]) then
            reacoma.utils.DEBUG(data.outputs[k][item_index].." failed to be made by the command line.")
            reacoma.utils.assert(false)
        end
    end
end

layers.matrix_output_exists = function(output)
    if not reacoma.paths.file_exists(output) then
        reacoma.utils.DEBUG(output .. " failed to be made by the command line.")
        reacoma.utils.assert(false)
    end
end

layers.process = function(item_index, data)
    if item_index > 1 then reaper.SetMediaItemSelected(data.item[item_index-1], false) end
    reaper.SetMediaItemSelected(data.item[item_index], true)
    for k, v in orderedPairs(data.outputs) do
        reaper.InsertMedia(data.outputs[k][item_index], 3)
        local item = reaper.GetSelectedMediaItem(0, 0)
        local take = reaper.GetActiveTake(item)
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", data.playrate[item_index])
        reaper.SetMediaItemTakeInfo_Value(take, "I_PITCHMODE", data.playtype[item_index])
        if data.reverse[item_index] then reaper.Main_OnCommand(41051, 0) end
    end
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