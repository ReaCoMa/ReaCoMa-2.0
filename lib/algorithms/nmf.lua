local r = reaper


function decompose(params)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-nmf"
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
            components = data.path .. "_nmf_" .. reacoma.utils.uuid(i) .. ".wav"
        }

        data.cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -resynth " .. reacoma.utils.wrap_quotes(data.outputs.components) ..
        " -resynthmode " .. 1 ..
        " -iterations " .. reacoma.params.find_by_name(params, 'iterations') ..
        " -components " .. reacoma.params.find_by_name(params, 'components') .. 
        " -fftsettings " .. fftsettings ..
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples
        
        table.insert(processed_items, data)
    end
    reacoma.layers.process_all_items(processed_items)
end

local nmf = {
    info = {
        algorithm_name = 'Non-negative matrix factorisation',
        ext_name = 'reacoma.nmf',
        action = 'decompose'
    },
    parameters =  {
        {
            name = 'components',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 10,
            value = 2,
            desc = 'The number of elements the NMF algorithm will try to divide the spectrogram of the source in.'
        },
        {
            name = 'iterations',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 300,
            value = 100,
            desc = 'The NMF process is iterative, trying to converge to the smallest error in its factorisation. The number of iterations will decide how many times it tries to adjust its estimates. Higher numbers here will be more CPU expensive, lower numbers will be more unpredictable in quality.'
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

return nmf