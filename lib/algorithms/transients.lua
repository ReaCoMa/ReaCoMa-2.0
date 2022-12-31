function decompose(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-transients"
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

    local processed_items = {}
    for i=1, num_selected_items do
        local data = reacoma.container.get_item_info(i)

        data.outputs = {
            transients = data.path .. "_ts-t_" .. reacoma.utils.uuid(i) .. ".wav",
            residual = data.path .. "_ts-r_" .. reacoma.utils.uuid(i) .. ".wav"
        }

        data.cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -transients " .. reacoma.utils.wrap_quotes(data.outputs.transients) .. 
        " -residual " .. reacoma.utils.wrap_quotes(data.outputs.residual) ..
        " -order " .. order ..
        " -blocksize " .. blocksize ..
        " -padsize " .. padsize ..
        " -skew " .. skew ..
        " -threshfwd " .. threshfwd .. 
        " -threshback " .. threshback ..
        " -windowsize " .. windowsize .. 
        " -clumplength " .. clumplength ..
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples
    end
    reacoma.layers.process_all_items(processed_items)
end

transients = {
    info = {
        algorithm_name = 'Transient Extraction',
        ext_name = 'reacoma.transients',
        action = 'decompose'
    },
    parameters =  {
        {
            name = 'order',
            widget = reaper.ImGui_SliderInt,
            min = 10,
            max = 400,
            value = 20,
            desc = 'The order in samples of the impulse response filter used to model the estimated continuous signal.'
        },
        {
            name = 'blocksize',
            widget = reaper.ImGui_SliderInt,
            min = 100,
            max = 1024,
            value = 256,
            desc = 'The size in samples of frame on which it the algorithm is operating.'
        },
        {
            name = 'padsize',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 512,
            value = 128,
            desc = 'The size of the handles on each sides of the block simply used for analysis purpose and avoid boundary issues.'
        },
        {
            name = 'skew',
            widget = reaper.ImGui_SliderDouble,
            min = -10.0,
            max = 10.0,
            value = 0.0,
            desc = 'The nervousness of the bespoke detection function with values from -10 to 10. High values increase the sensitivity to small variations.'
        },
        {
            name = 'threshfwd',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 8.0,
            value = 2.0,
            desc = 'The threshold of the onset of the smoothed error function. It allows tight start of the identification of the anomaly as it proceeds forward.'
        },
        {
            name = 'threshback',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 8.0,
            value = 1.1,
            desc = 'The threshold of the offset of the smoothed error function. As it proceeds backwards in time, it allows tight ending of the identification of the anomaly.'
        },
        {
            name = 'windowsize',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 400,
            value = 14,
            desc = 'The averaging window of the error detection function. It needs smoothing as it is very jittery. The longer the window, the less precise, but the less false positives.'
        },
        {
            name = 'clumplength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 1000,
            value = 25,
            desc = 'The window size in sample within with positive detections will be clumped together to avoid overdetecting in time.'
        }
    },
    perform_update = decompose
}

return transients