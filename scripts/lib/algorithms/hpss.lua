-- @noindex
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

    local data = reacoma.utils.deep_copy(reacoma.container.generic)
    data.outputs = {
        harmonic = {},
        percussive = {}
    }

    for i=1, num_selected_items do
        reacoma.container.get_data(i, data)

        table.insert(
            data.outputs.harmonic,
            data.path[i] .. "_hpss-h_" .. reacoma.utils.uuid(i) .. ".wav"
        )
        table.insert(
            data.outputs.percussive,
            data.path[i] .. "_hpss-p_" .. reacoma.utils.uuid(i) .. ".wav"
        )

        table.insert(
            data.cmd, 
            exe .. 
            " -source " .. reacoma.utils.wrap_quotes(data.full_path[i]) .. 
            " -harmonic " .. reacoma.utils.wrap_quotes(data.outputs.harmonic[i]) .. 
            " -maxfftsize " .. reacoma.utils.get_max_fft_size(fftsettings) ..
            " -maxharmfiltersize " .. hfs ..
            " -maxpercfiltersize " .. pfs ..
            " -percussive " .. reacoma.utils.wrap_quotes(data.outputs.percussive[i]) ..  
            " -harmfiltersize " .. hfs .. 
            " -percfiltersize " .. pfs .. 
            " -maskingmode " .. maskingmode ..
            " -fftsettings " .. fftsettings .. 
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
        )
        reacoma.utils.cmdline(data.cmd[i])
        reacoma.layers.exist(i, data)
        reaper.SelectAllMediaItems(0, 0)
        reacoma.layers.process(i, data)
        reaper.UpdateArrange()
    end
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
            type = 'sliderint',
            desc = 'The size, in spectral frames, of the median filter for the harmonic component.'
        },
        {
            name = 'percfiltersize',
            widget = reaper.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 31,
            type = 'sliderint',
            desc = 'The size, in spectral bins, of the median filter for the percussive component.'
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
    perform_update = decompose
}

return hpss