function decompose(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-nmf"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local components = parameters[1].value
    local iterations = parameters[2].value
    local fftsettings = reacoma.utils.form_fft_string(
        parameters[3].value, 
        parameters[4].value, 
        parameters[5].value
    )

    local data = reacoma.utils.deep_copy(reacoma.container.generic)


    local processed_items = {}
    for i=1, num_selected_items do
        local data = reacoma.container.get_item_info(i)

        data.outputs = {
            components = data.path .. "_nmf_" .. reacoma.utils.uuid(i) .. ".wav"
        }

        data.cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -resynth " .. reacoma.utils.wrap_quotes(data.outputs.components) ..
        " -resynthmode " .. 1 ..
        " -iterations " .. iterations ..
        " -components " .. components .. 
        " -fftsettings " .. fftsettings ..
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples
        
        table.insert(processed_items, data)
    end
    reacoma.layers.process_all_items(processed_items)
end

nmf = {
    info = {
        algorithm_name = 'Non-negative matrix factorisation',
        ext_name = 'reacoma.nmf',
        action = 'decompose'
    },
    parameters =  {
        {
            name = 'components',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 10,
            value = 2,
            desc = 'The number of elements the NMF algorithm will try to divide the spectrogram of the source in.'
        },
        {
            name = 'iterations',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 300,
            value = 100,
            desc = 'The NMF process is iterative, trying to converge to the smallest error in its factorisation. The number of iterations will decide how many times it tries to adjust its estimates. Higher numbers here will be more CPU expensive, lower numbers will be more unpredictable in quality.'
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
    perform_update = decompose
}

return nmf