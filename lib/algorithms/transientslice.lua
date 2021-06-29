function segment(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-transientslice"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local order = parameters[1].value
    local blocksize = parameters[2].value
    local padsize = parameters[3].value
    local skew = parameters[4].value
    local threshfwd = parameters[5].value
    local threshback = parameters[6].value
    local windowsize = parameters[7].value
    local clumplength = parameters[8].value
    local minslicelength = parameters[9].value

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
        " -order " .. order .. 
        " -blocksize " .. blocksize .. 
        " -padsize " .. padsize .. 
        " -skew " .. skew .. 
        " -threshfwd " .. threshfwd .. 
        " -threshback " .. threshback ..
        " -windowsize " .. windowsize .. 
        " -clumplength " .. clumplength .. 
        " -minslicelength " .. minslicelength ..
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

transientslice = {
    info = {
        algorithm_name = 'Transient Slice',
        ext_name = 'reacoma.transientslice',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'order',
            widget = reaper.ImGui_SliderInt,
            min = 10,
            max = 400,
            value = 20,
            type = 'sliderint'
        },
        {
            name = 'blocksize',
            widget = reaper.ImGui_SliderInt,
            min = 100,
            max = 1024,
            value = 256,
            type = 'sliderint'
        },
        {
            name = 'padsize',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 512,
            value = 128,
            type = 'sliderint'
        },
        {
            name = 'skew',
            widget = reaper.ImGui_SliderDouble,
            min = -10.0,
            max = 10.0,
            value = 0.0,
            type = 'sliderdouble'
        },
        {
            name = 'threshfwd',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 8.0,
            value = 2.0,
            type = 'sliderdouble'
        },
        {
            name = 'threshback',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 8.0,
            value = 1.1,
            type = 'sliderdouble'
        },
        {
            name = 'windowsize',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 400,
            value = 14,
            type = 'sliderint'
        },
        {
            name = 'clumplength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 1000,
            value = 25,
            type = 'sliderint'
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 1000,
            type = 'sliderint'
        },
    },
    perform_update = segment
}

return transientslice