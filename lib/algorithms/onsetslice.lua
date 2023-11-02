local r = reaper

function segment(params)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-onsetslice"
        )
    )

    local num_selected_items = r.CountSelectedMediaItems(0)
    local fftsettings = reacoma.utils.form_fft_string(
        reacoma.params.find_by_name(params, 'window size'), 
        reacoma.params.find_by_name(params, 'hop size'), 
        reacoma.params.find_by_name(params, 'fft size')
    )

    local processed_items = {}
    for i=1, num_selected_items do
        local data = reacoma.container.get_item_info(i)

        -- Remove any existing take markers
        for j=1, data.take_markers do
            r.DeleteTakeMarker(
                data.take, 
                data.take_markers - j
            )
        end
        
        local cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -indices " .. reacoma.utils.wrap_quotes(data.tmp) ..
        " -metric " .. reacoma.params.find_by_name(params, 'metric') .. 
        " -minslicelength " .. reacoma.params.find_by_name(params, 'minslicelength') ..
        " -threshold " .. reacoma.params.find_by_name(params, 'threshold') .. 
        " -filtersize " .. reacoma.params.find_by_name(params, 'filtersize') .. 
        " -framedelta " .. reacoma.params.find_by_name(params, 'framedelta') ..
        " -fftsettings " .. fftsettings .. 
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples

        reacoma.utils.cmdline(cmd)
        data.slice_points_string = reacoma.utils.readfile(data.tmp)
        
        reacoma.slicing.process(data)
        reacoma.utils.cleanup2(data.tmp)
        table.insert(processed_items, data)
    end
    
    r.UpdateArrange()
    return processed_items
end

local onsetslice = {
    info = {
        algorithm_name = 'Onset Slice',
        ext_name = 'reacoma.onsetslice',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'metric',
            widget = r.ImGui_Combo,
            value = 0,
            items = 'energy\0high frequency content\0spectral flux\0modified kullback-leibler\0itakura-saito\0cosine\0phase deviation\0weighted phase deviation\0complex domain\0rectified complex domain\0',
            desc = 'The metric used to derive a difference curve between spectral frames'
        },
        {
            name = 'threshold',
            widget = r.ImGui_SliderDouble,
            min = 0.0,
            max = 2.0,
            value = 0.5,
            desc = 'The thresholding of a new slice. Value ranges are different for each metric, from 0 upwards.'
        },
        {
            name = 'minslicelength',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 2,
            desc = 'The minimum duration of a slice in number of hop size.'
        },
        {
            name = 'filtersize',
            widget = reacoma.imgui.widgets.FilterSlider,
            value = 5,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FilterSlider.opts, 17),
            desc = 'The size of a smoothing filter that is applied on the novelty curve. A larger filter filter size allows for cleaner cuts on very sharp changes.'
        },
        {
            name = 'framedelta',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 0,
            desc = 'For certain metrics the distance does not have to be computed between consecutive frames. By default it is, otherwise this sets the distance between the comparison window in samples.'
        },
        {
            name = 'window size',
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 1024,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 1024),
            desc = 'window size'
        },
        {
            name = 'hop size',
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 512,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 512),
            desc = 'hop size'
        },
        {
            name = 'fft size',
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 1024,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 1024),
            desc = 'fft size',
        }
    },
    perform_update = segment
}

return onsetslice