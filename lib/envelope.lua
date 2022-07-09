envelope = {}

envelope.get_take_info = function(take)
	local info = {}
	local item = r.GetMediaItemTake_Item(take)
	local take_markers = r.GetNumTakeMarkers(take)
    local src = r.GetMediaItemTake_Source(take)
    local src_parent = r.GetMediaSourceParent(src)
    local sr = nil
    local full_path = nil
    local reverse = nil
    
    if src_parent ~= nil then
        sr = r.GetMediaSourceSampleRate(src_parent)
        full_path = r.GetMediaSourceFileName(src_parent, "")
        reverse = true
    else
        sr = r.GetMediaSourceSampleRate(src)
        full_path = r.GetMediaSourceFileName(src, "")
        reverse = false
    end
    
    -- Now check the full path works
    reacoma.utils.check_extension(full_path)

    local playrate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local take_ofs = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
    local src_len = r.GetMediaSourceLength(src)
    local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate
    local playtype  = r.GetMediaItemTakeInfo_Value(take, "I_PITCHMODE")

    if reverse then
        take_ofs = abs(src_len - (item_len + take_ofs))
    end
    
    if (item_len + take_ofs) > (src_len * (1 / playrate)) then 
        item_len = ((src_len-take_ofs) * (1 / playrate))
    end

    local take_ofs_samples = utils.stosamps(take_ofs, sr)
    local item_pos_samples = utils.stosamps(item_pos, sr)
    local item_len_samples = floor(utils.stosamps(item_len, sr))

    -- Yeah this is verbose but it makes it cleaner
    info.item = item
    info.take = take
    info.take_markers = take_markers
    info.sr = sr
    info.full_path = full_path
    info.take_ofs = take_ofs
    info.take_ofs_samples = take_ofs_samples
    info.item_len = item_len
    info.item_len_samples = item_len_samples
    info.item_pos = item_pos
    info.item_pos_samples = item_pos_samples
    info.playrate = playrate
    info.reverse = reverse
    info.playtype = playtype
    info.tmp = full_path .. utils.uuid2() .. "feature.csv"
    return info
end

return envelope