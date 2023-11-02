local r = reaper

function segment(params)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-transientslice"
        )
    )

    local num_selected_items = r.CountSelectedMediaItems(0)
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
        " -order " .. reacoma.params.find_by_name(params, 'order') .. 
        " -blocksize " .. reacoma.params.find_by_name(params, 'blocksize') .. 
        " -padsize " .. reacoma.params.find_by_name(params, 'padsize') .. 
        " -skew " .. reacoma.params.find_by_name(params, 'skew') .. 
        " -threshfwd " .. reacoma.params.find_by_name(params, 'threshfwd') .. 
        " -threshback " .. reacoma.params.find_by_name(params, 'threshback') ..
        " -windowsize " .. reacoma.params.find_by_name(params, 'windowsize') .. 
        " -clumplength " .. reacoma.params.find_by_name(params, 'clumplength') .. 
        " -minslicelength " .. reacoma.params.find_by_name(params, 'minslicelength') ..
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

local transientslice = {
    info = {
        algorithm_name = 'Transient Slice',
        ext_name = 'reacoma.transientslice',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'order',
            widget = r.ImGui_SliderInt,
            min = 10,
            max = 400,
            value = 20,
            desc = 'The order in samples of the impulse response filter used to model the estimated continuous signal.'
        },
        {
            name = 'blocksize',
            widget = r.ImGui_SliderInt,
            min = 100,
            max = 1024,
            value = 256,
            desc = 'The size in samples of frame on which it the algorithm is operating.'
        },
        {
            name = 'padsize',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 512,
            value = 128,
            desc = 'The size of the handles on each sides of the block simply used for analysis purpose and avoid boundary issues.'
        },
        {
            name = 'skew',
            widget = r.ImGui_SliderDouble,
            min = -10.0,
            max = 10.0,
            value = 0.0,
            desc = 'The nervousness of the bespoke detection function with values from -10 to 10. High values increase the sensitivity to small variations.'
        },
        {
            name = 'threshfwd',
            widget = r.ImGui_SliderDouble,
            min = 0.0,
            max = 8.0,
            value = 2.0,
            desc = 'The threshold of the onset of the smoothed error function. It allows tight start of the identification of the anomaly as it proceeds forward.'
        },
        {
            name = 'threshback',
            widget = r.ImGui_SliderDouble,
            min = 0.0,
            max = 8.0,
            value = 1.1,
            desc = 'The threshold of the offset of the smoothed error function. As it proceeds backwards in time, it allows tight ending of the identification of the anomaly.'
        },
        {
            name = 'windowsize',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 400,
            value = 14,
            desc = 'The averaging window of the error detection function. It needs smoothing as it is very jittery. The longer the window, the less precise, but the less false positives.'
        },
        {
            name = 'clumplength',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 1000,
            value = 25,
            desc = 'The window size in sample within with positive detections will be clumped together to avoid overdetecting in time.'
        },
        {
            name = 'minslicelength',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 1000,
            desc = 'The minimum duration of a slice in samples.'
        },
    },
    perform_update = segment
}

return transientslice