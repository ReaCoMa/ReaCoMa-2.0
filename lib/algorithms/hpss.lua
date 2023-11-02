local r = reaper

local find_by_name = reacoma.params.find_by_name

function decompose(params)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-hpss"
        )
    )

    local num_selected_items = r.CountSelectedMediaItems(0)
    local hfs = find_by_name(params, 'harmfiltersize')
    local pfs = find_by_name(params, 'percfiltersize')
    local fftsettings = reacoma.utils.form_fft_string(
        find_by_name(params, 'window size'), 
        find_by_name(params, 'hop size'), 
        find_by_name(params, 'fft size')
    )

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
        " -maskingmode " .. '0' ..
        " -fftsettings " .. fftsettings .. 
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples

        table.insert(processed_items, data)
    end
    reacoma.layers.process_all_items(processed_items)
end

local hpss = {
    info = {
        algorithm_name = 'Harmonic-percussive source separation',
        ext_name = 'reacoma.hpss',
        action = 'decompose'
    },
    parameters =  {
        {
            name = 'harmfiltersize',
            widget = reacoma.imgui.widgets.FilterSlider,
            value = 17,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FilterSlider.opts, 17),
            desc = 'The size in spectral frames of the median filter for the harmonic component.'
        },
        {
            name = 'percfiltersize',
            widget = r.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 31,
            desc = 'The size in spectral bins of the median filter for the percussive component.'
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
    perform_update = decompose
}

return hpss