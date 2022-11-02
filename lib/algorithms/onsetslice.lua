function segment(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-onsetslice"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local metric = parameters[1].value
    local threshold = parameters[2].value
    local minslicelength = parameters[3].value
    local filtersize = parameters[4].value
    local framedelta = parameters[5].value
    local fftsettings = reacoma.utils.form_fft_string(
        parameters[6].value, 
        parameters[7].value, 
        parameters[8].value
    )

    local processed_items = {}
    for i=1, num_selected_items do
        local data = reacoma.container.get_item_info(i)

        -- Remove any existing take markers
        for j=1, data.take_markers do
            reaper.DeleteTakeMarker(
                data.take, 
                data.take_markers - j
            )
        end
        
        local cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -indices " .. reacoma.utils.wrap_quotes(data.tmp) ..
        " -metric " .. metric .. 
        " -minslicelength " .. minslicelength ..
        " -threshold " .. threshold .. 
        " -filtersize " .. filtersize .. 
        " -framedelta " .. framedelta ..
        " -fftsettings " .. fftsettings .. 
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples

        reacoma.utils.cmdline(cmd)
        data.slice_points_string = reacoma.utils.readfile(data.tmp)
        
        reacoma.slicing.process(data)
        reacoma.utils.cleanup2(data.tmp)
        table.insert(processed_items, data)
    end
    
    reaper.UpdateArrange()
    return processed_items
end

onsetslice = {
    info = {
        algorithm_name = 'Onset Slice',
        ext_name = 'reacoma.onsetslice',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'metric',
            widget = reaper.ImGui_Combo,
            value = 0,
            items = 'energy\0high frequency content\0spectral flux\0modified kullback-leibler\0itakura-saito\0cosine\0phase deviation\0weighted phase deviation\0complex domain\0rectified complex domain\0',
            desc = 'The metric used to derive a difference curve between spectral frames'
        },
        {
            name = 'threshold',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 2.0,
            value = 0.5,
            desc = 'The thresholding of a new slice. Value ranges are different for each metric, from 0 upwards.'
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 2,
            desc = 'The minimum duration of a slice in number of hop size.'
        },
        {
            name = 'filtersize',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 101,
            value = 5,
            desc = 'The size of a smoothing filter that is applied on the novelty curve. A larger filter filter size allows for cleaner cuts on very sharp changes.'
        },
        {
            name = 'framedelta',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 0,
            desc = 'For certain metrics the distance does not have to be computed between consecutive frames. By default it is, otherwise this sets the distance between the comparison window in samples.'
        },
        {
            name = 'window size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            desc = 'window size'
        },
        {
            name = 'hop size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 512,
            desc = 'hop size'
        },
        {
            name = 'fft size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            desc = 'fft size'
        }
    },
    perform_update = segment
}

return onsetslice