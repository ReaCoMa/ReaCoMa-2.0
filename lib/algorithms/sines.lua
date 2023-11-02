local r = reaper

function decompose(params)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-sines"
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

        data.outputs = {
            sines = data.path .. "_sines-s_" .. reacoma.utils.uuid(i) .. ".wav",
            residual = data.path .. "_sines-r_" .. reacoma.utils.uuid(i) .. ".wav"
        }

        data.cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -sines " .. reacoma.utils.wrap_quotes(data.outputs.sines) ..
        " -residual " .. reacoma.utils.wrap_quotes(data.outputs.residual) .. 
        " -birthhighthreshold " .. reacoma.params.find_by_name(params, 'birthhighthreshold') ..
        " -birthlowthreshold " .. reacoma.params.find_by_name(params, 'birthlowthreshold') ..
        " -detectionthreshold " .. reacoma.params.find_by_name(params, 'detectionthreshold') ..
        " -trackfreqrange " .. reacoma.params.find_by_name(params, 'trackfreqrange') ..
        " -trackmethod " .. reacoma.params.find_by_name(params, 'trackmethod') ..
        " -trackmagrange " .. reacoma.params.find_by_name(params, 'trackmagrange') ..
        " -trackprob " .. reacoma.params.find_by_name(params, 'trackprob') ..
        " -bandwidth " .. reacoma.params.find_by_name(params, 'bandwidth') ..
        " -mintracklen " .. reacoma.params.find_by_name(params, 'mintracklen') ..
        " -fftsettings " .. fftsettings ..
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples
        
        table.insert(processed_items, data)
    end
    layers.process_all_items(processed_items)
end

local sines = {
    info = {
        algorithm_name = 'Sines',
        ext_name = 'reacoma.sines',
        action = 'decompose'
    },
    parameters =  {
        {
            name = 'trackmethod',
            widget = r.ImGui_Combo,
            value = 0,
            items = 'greedy\0hungarian\0',
            desc = 'The algorithm used to track the sinusoidal continuity between spectral frames.'
        },
        {
            name = 'trackfreqrange',
            widget = r.ImGui_SliderDouble,
            min = 1.0,
            max = 10000.0,
            value = 50.0,
            desc = 'The frequency difference allowed for a track to diverge between frames, in Hertz.'
        },
        {
            name = 'trackmagrange',
            widget = r.ImGui_SliderDouble,
            min = 1.0,
            max = 200.0,
            value = 15.0,
            desc = 'The amplitude difference allowed for a track to diverge between frames, in dB.'
        },
        {
            name = 'trackprob',
            widget = r.ImGui_SliderDouble,
            min = 0.0,
            max = 1.0,
            value = 0.5,
            desc = 'The probability of the tracking algorithm to find a track.'
        },
        {
            name = 'bandwidth',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 1024,
            value = 76,
            desc = 'The number of bins used to resynthesises a peak.'
        },
        {
            name = 'birthhighthreshold',
            widget = r.ImGui_SliderDouble,
            min = -144,
            max = 0,
            value = -60,
            desc = 'The threshold in dB above which to consider a peak to start a sinusoidal component tracking, for the high end of the spectrum.'
        },
        {
            name = 'birthlowthreshold',
            widget = r.ImGui_SliderDouble,
            min = -144,
            max = 0,
            value = -24,
            desc = 'The threshold in dB above which to consider a peak to start a sinusoidal component tracking, for the low end of the spectrum.'
        },
        {
            name = 'detectionthreshold',
            widget = r.ImGui_SliderDouble,
            min = -144,
            max = 0,
            value = -96,
            desc = 'The threshold in dB above which a magnitude peak is considered to be a sinusoidal component.'
        },
        {
            name = 'mintracklen',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 40,
            value = 15,
            desc = 'The minimum duration, in spectral frames, for a sinusoidal track to be accepted as a partial.'
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

return sines