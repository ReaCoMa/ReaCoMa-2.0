floor = math.floor
abs = math.abs

slicing = {}

-- TODO: These are the same in now between slicing and layers we should create a new module
-- Perhaps something like... containters/data/item_processing
slicing.container = {
    full_path = {},
    item_pos = {},
    item_pos_samples = {},
    take_ofs = {},
    take_ofs_samples = {},
    item_len = {},
    item_len_samples = {},
    cmd = {},
    slice_points_string = {},
    tmp = {},
    item = {},
    reverse = {},
    sr = {},
    playrate = {},
    take = {},
    path = {},
    playtype = {},
    outputs = {}
}

slicing.get_data = function(item_index, data)
    local info = reacoma.utils.get_item_info(item_index)
    for k, v in pairs(info) do
        table.insert(data[tostring(k)], v)
    end
end

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
