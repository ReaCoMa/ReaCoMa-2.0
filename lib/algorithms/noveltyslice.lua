function segment(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-noveltyslice"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local algorithm = parameters[1].value
    local threshold = parameters[2].value
    local kernelsize = parameters[3].value
    local filtersize = parameters[4].value
    local minslicelength = parameters[5].value
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
        " -algorithm " .. algorithm .. 
        " -kernelsize " .. kernelsize .. " " .. kernelsize ..
        " -filtersize " .. filtersize .. " " .. filtersize ..
        " -threshold " .. threshold .. 
        " -fftsettings " .. fftsettings .. 
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

noveltyslice = {
    info = {
        algorithm_name = 'Novelty Slice',
        ext_name = 'reacoma.noveltyslice',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'algorithm',
            widget = reaper.ImGui_Combo,
            value = 0,
            items = 'spectrum\0mfcc\0chroma\0pitch\0loudness\0',
            type = 'combo',
            desc = 'The feature on which novelty is computed.'
        },
        {
            name = 'threshold',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 1.0,
            value = 0.5,
            type = 'sliderdouble',
            desc = 'The normalised threshold, between 0 an 1, on the novelty curve to consider it a segmentation point.'
        },
        {
            name = 'kernelsize',
            widget = reaper.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 3,
            type = 'sliderint',
            desc = 'The granularity of the window in which the algorithm looks for change, in FFT frames.'
        },
        {
            name = 'filtersize',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 1,
            type = 'sliderint',
            desc = 'The size of a smoothing filter that is applied on the novelty curve. A larger filter filter size allows for cleaner cuts on very sharp changes.'
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

return noveltyslice