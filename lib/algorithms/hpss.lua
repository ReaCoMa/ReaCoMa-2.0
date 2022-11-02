function decompose(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-hpss"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local hfs = parameters[1].value
    local pfs = parameters[2].value
    local fftsettings = reacoma.utils.form_fft_string(
        parameters[3].value,
        parameters[4].value,
        parameters[5].value
    )

    local maskingmode = '0'

    local processed_items = {}
    for i=1, num_selected_items do
        local data = reacoma.container.get_item_info(i)

        data.outputs = {
            harmonic = data.path .. "_hpss-h_" .. reacoma.utils.uuid(i) .. ".wav",
            percussive = data.path .. "_hpss-p_" .. reacoma.utils.uuid(i) .. ".wav"
        }

        data.cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -harmonic " .. reacoma.utils.wrap_quotes(data.outputs.harmonic) .. 
        " -percussive " .. reacoma.utils.wrap_quotes(data.outputs.percussive) ..  
        " -harmfiltersize " .. hfs .. " " .. hfs ..
        " -percfiltersize " .. pfs .. " " .. pfs ..
        " -maskingmode " .. maskingmode ..
        " -fftsettings " .. fftsettings .. 
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples

        table.insert(processed_items, data)
    end
    reacoma.layers.process_all_items(processed_items)
end

hpss = {
    info = {
        algorithm_name = 'Harmonic Percussive Source Separation',
        ext_name = 'reacoma.hpss',
        action = 'decompose'
    },
    parameters =  {
        {
            name = 'harmfiltersize',
            widget = reaper.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 17,
            desc = 'The size, in spectral frames, of the median filter for the harmonic component.'
        },
        {
            name = 'percfiltersize',
            widget = reaper.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 31,
            desc = 'The size, in spectral bins, of the median filter for the percussive component.'
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

return hpss