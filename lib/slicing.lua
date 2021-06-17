floor = math.floor
abs = math.abs

slicing = {}

slicing.container = {
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
    reverse = {},
    sr = {},
    playrate = {},
    take = {}
}

slicing.rm_dup = function(slice_table)
    -- Removes duplicate entries from a table
    local hash = {}
    local res = {}
    for _,v in ipairs(slice_table) do
        if not hash[v] then
            res[#res+1] = v -- you could print here instead of saving to result table if you wanted
            hash[v] = true
        end 
    end
    return res
end

slicing.get_data = function(item_index, data)

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

    reacoma.utils.check_extension(full_path)
    
    local tmp = full_path .. utils.uuid(item_index) .. "fs.csv"
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
    local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local src_len = reaper.GetMediaSourceLength(src)
    local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate

    if data.reverse[item_index] then
        take_ofs = abs(src_len - (item_len + take_ofs))
    end
    
    -- This line caps the analysis at one loop
    if (item_len + take_ofs) > (src_len * (1 / playrate)) then 
        item_len = ((src_len-take_ofs) * (1 / playrate))
    end

    local take_ofs_samples = utils.stosamps(take_ofs, sr)
    local item_pos_samples = utils.stosamps(item_pos, sr)
    local item_len_samples = floor(utils.stosamps(item_len, sr))

    table.insert(data.item, item)
    table.insert(data.sr, sr)
    table.insert(data.full_path, full_path)
    table.insert(data.take_ofs, take_ofs)
    table.insert(data.take_ofs_samples, take_ofs_samples)
    table.insert(data.item_pos, item_pos)
    table.insert(data.item_pos_samples, item_pos_samples)
    table.insert(data.item_len_samples, item_len_samples)
    table.insert(data.tmp, tmp)
    table.insert(data.playrate, playrate)
    table.insert(data.take, take)
end

slicing.process = function(item_index, data, mute_state)
    -- Thank you to Francesco Cameli for helping me debug this absolute NIGHTMARE --
    local slice_points = utils.split_comma(
        data.slice_points_string[item_index]
    )

    -- slice_points = slicing.rm_dup(slice_points)

    -- If the init_mute_state is passed its a gate-baseds slice (fluid.ampgate~)
    -- Otherwise its not
    local gate_based_slicer = false

    if mute_state == 0 or mute_state == 1 then 
        gate_based_slicer = true

        -- Also test if the slice points are logical, otherwise exit
        if slice_points[1] == "-1" or slice_points[2] == "-1" then 
            return 
        end
    end

    -- Invert the table around the middle point (mirror!)
    if data.reverse[item_index] then
        for i=1, #slice_points do
            slice_points[i] = (
                data.item_len_samples[item_index] - slice_points[i]
            )   
        end
        utils.reverse_table(slice_points)
    end
    
    -- if the left boundary is the start remove it
    -- This protects situations where the slice point is implicit in the boundaries of the media item
    if tonumber(slice_points[1]) == data.take_ofs_samples[item_index] then 
        table.remove(slice_points, 1) 
    end

    -- now sanitise the numbers to adjust for the take offset and playback rate
    for i=1, #slice_points do
        if data.reverse[item_index] then
            slice_points[i] = (slice_points[i] + data.take_ofs_samples[item_index]) / data.playrate[item_index]
        else
            slice_points[i] = (slice_points[i] - data.take_ofs_samples[item_index]) / data.playrate[item_index]
        end
        -- and convert to seconds for REAPER
        slice_points[i] = utils.sampstos(
            tonumber(slice_points[i]),
            data.sr[item_index]
        )
    end

    for i=1, #slice_points do
        local slice_pos = slice_points[i]
        -- slice_pos = data.item_pos[item_index] + slice_pos

        -- Handle muting for fluid.ampgate
        -- if gate_based_slicer then
        --     reaper.SetMediaItemInfo_Value(
        --         data.item[item_index], 
        --         "B_MUTE", 
        --         mute_state
        --     )
        --     -- invert the mute state
        --     if mute_state == 1 then 
        --         mute_state = 0 else 
        --         mute_state = 1 
        --     end
        -- end
        local colour = reaper.ColorToNative(0, 0, 0) | 0x1000000
        reaper.SetTakeMarker(
            data.take[item_index], 
            -1, 
            '', 
            slice_pos, 
            colour
        )
    end
end

return slicing
