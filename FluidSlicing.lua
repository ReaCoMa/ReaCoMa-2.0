local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")

SlicingContainer = {
    full_path = {},
    item_pos = {},
    item_pos_samples = {},
    take_ofs = {},
    take_ofs_samples = {},
    item_len_samples = {},
    cmd = {},
    slice_points_string = {},
    tmp = {},
    item = {},
    sr = {},
    playrate = {}
}

function get_data(item_index, data)
    -- Function to grab all essential information from media item --
    -- item_index is passed from num_selected_items
    -- data_table is a container for the tables of data

    local item = reaper.GetSelectedMediaItem(0, item_index-1)
    local take = reaper.GetActiveTake(item)
    local src = reaper.GetMediaItemTake_Source(take)
    local sr = reaper.GetMediaSourceSampleRate(src)
    local full_path = reaper.GetMediaSourceFileName(src, "")
    
    local tmp_idx = full_path .. uuid(item_index) .. "fs.csv"

    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local src_len = reaper.GetMediaSourceLength(src)
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > src_len then item_len = src_len end

    -- Convert everything to samples for CLI --
    local take_ofs_samples = stosamps(take_ofs, sr)
    local item_pos_samples = stosamps(item_pos, sr)
    local item_len_samples = math.floor(stosamps(item_len, sr) * playrate)

    table.insert(data.item, item)
    table.insert(data.sr, sr)
    table.insert(data.full_path, full_path)
    table.insert(data.take_ofs, take_ofs)
    table.insert(data.take_ofs_samples, take_ofs_samples)
    table.insert(data.item_pos, item_pos)
    table.insert(data.item_pos_samples, item_pos_samples)
    table.insert(data.item_len_samples, item_len_samples)
    table.insert(data.tmp, tmp_idx)
    table.insert(data.playrate, playrate)
end

function perform_splitting(item_index, data)
    local slice_points = commasplit(data.slice_points_string[item_index])
    for j=2, #slice_points do
        slice_pos = sampstos(tonumber(slice_points[j]), data.sr[item_index])
        slice_pos = slice_pos * (1.0 / data.playrate[item_index]) -- account for playback rate
        data.item[item_index] = reaper.SplitMediaItem(
            data.item[item_index], data.item_pos[item_index] + (slice_pos - data.take_ofs[item_index])
        )
    end
end
