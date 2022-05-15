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
    local data = reacoma.utils.deep_copy(reacoma.container.generic)
    for i=1, num_selected_items do
        reacoma.container.get_data(i, data)

        -- Remove any existing take markers
        for j=1, data.take_markers[i] do
            reaper.DeleteTakeMarker(
                data.take[i], 
                data.take_markers[i] - j
            )
        end
        
        local cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path[i]) .. 
        " -indices " .. reacoma.utils.wrap_quotes(data.tmp[i]) ..
        " -metric " .. metric .. 
        " -minslicelength " .. minslicelength ..
        " -threshold " .. threshold .. 
        " -filtersize " .. filtersize .. 
        " -framedelta " .. framedelta ..
        " -fftsettings " .. fftsettings .. 
        " -numframes " .. data.item_len_samples[i] .. 
        " -startframe " .. data.take_ofs_samples[i]

        reacoma.utils.cmdline(cmd)
        table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
        reacoma.slicing.process(i, data)
    end
    
    reaper.UpdateArrange()
    reacoma.utils.cleanup(data.tmp)
    return data
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
            items = 'energy\31high frequency content\31spectral flux\31modified kullback-leibler\31itakura-saito\31cosine\31phase deviation\31weighted phase deviation\31complex domain\31rectified complex domain\31',
            type = 'combo',
            desc = 'The metric used to derive a difference curve between spectral frames'
        },
        {
            name = 'threshold',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 2.0,
            value = 0.5,
            type = 'sliderdouble',
            desc = 'The thresholding of a new slice. Value ranges are different for each metric, from 0 upwards.'
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 2,
            type = 'sliderint',
            desc = 'The minimum duration of a slice in number of hop size.'
        },
        {
            name = 'filtersize',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 101,
            value = 5,
            type = 'sliderint',
            desc = 'The size of a smoothing filter that is applied on the novelty curve. A larger filter filter size allows for cleaner cuts on very sharp changes.'
        },
        {
            name = 'framedelta',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 0,
            type = 'sliderint',
            desc = 'For certain metrics the distance does not have to be computed between consecutive frames. By default it is, otherwise this sets the distance between the comparison window in samples.'
        },
        {
            name = 'window size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            type = 'sliderint',
            desc = 'window size'
        },
        {
            name = 'hop size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 512,
            type = 'sliderint',
            desc = 'hop size'
        },
        {
            name = 'fft size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            type = 'sliderint',
            desc = 'fft size'
        }
    },
    perform_update = segment
}

return onsetslice