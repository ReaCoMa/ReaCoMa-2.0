local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")

TaggingContainer = {
    full_path = {},
    item_pos = {},
    item_pos_samples = {},
    take_ofs = {},
    take_ofs_samples = {},
    item_len_samples = {},
    analcmd = {},
    statscmd = {},
    analysis_data = {},
    analtmp = {},
    statstmp = {},
    item = {},
    reverse = {},
    sr = {},
    playrate = {}
}

function get_tag_data(item_index, data)
    local item = reaper.GetSelectedMediaItem(0, item_index-1)
    local take = reaper.GetActiveTake(item)
    local src = reaper.GetMediaItemTake_Source(take)
    local src_parent = reaper.GetMediaSourceParent(src)
    local sr = nil
    local full_path = nil
    
    if src_parent ~= nil then
        sr = reaper.GetMediaSourceSampleRate(src_parent)
        full_path = reaper.GetMediaSourceFileName(src_parent, "")
        table.insert(data.reverse, true)
    else
        sr = reaper.GetMediaSourceSampleRate(src)
        full_path = reaper.GetMediaSourceFileName(src, "")
        table.insert(data.reverse, false)
    end
    
    local analtmp = full_path .. uuid(item_index) .. "ttag.wav"
    local statstmp = full_path .. uuid(item_index) .. "tstats.csv"
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local src_len = reaper.GetMediaSourceLength(src)
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    
    if data.reverse[item_index] then
        take_ofs = math.abs((src_len - (item_len * playrate)) + take_ofs)
    end
    
    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > src_len then 
        item_len = src_len 
    end

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
    table.insert(data.playrate, playrate)
    table.insert(data.analtmp, analtmp)
    table.insert(data.statstmp, statstmp)
end

function update_notes(item, text)

    _, current_notes = reaper.GetSetMediaItemInfo_String(
        item, 
        "P_NOTES", 
        "foobie", 
        false
    )
    concat_string = current_notes .. "\r\n" .. text

    _, _ = reaper.GetSetMediaItemInfo_String(
        item, 
        "P_NOTES", 
        concat_string, 
        true
    )

end

