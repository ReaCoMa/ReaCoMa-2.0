container = {}

container.generic = {
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
    take_markers = {},
    path = {},
    playtype = {},
    outputs = {}
}

container.get_data = function(item_index, data)
    local info = reacoma.utils.get_item_info(item_index)
    for k, v in pairs(info) do
        table.insert(data[tostring(k)], v)
    end
end

return container