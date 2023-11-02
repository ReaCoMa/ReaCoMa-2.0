local r = reaper

function decompose(params, item_bundle)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-nmfcross"
        )
    )

    local fftsettings = reacoma.utils.form_fft_string(
        reacoma.params.find_by_name(params, 'window size'), 
        reacoma.params.find_by_name(params, 'hop size'), 
        reacoma.params.find_by_name(params, 'fft size')
    )

    -- If there is a source without a target remove it
    if #item_bundle % 2 ~= 0 then
        table.remove(item_bundle, #item_bundle)
    end

    -- iterate over the bundle in strides of 2
    for i=1, #item_bundle, 2 do
        local source_info = reacoma.container.get_take_info_from_item(item_bundle[i])
        local target_info = reacoma.container.get_take_info_from_item(item_bundle[i+1])
        local output = target_info.path .. "_nmfcross_" .. reacoma.utils.uuid(i) .. ".wav"

		local cli = exe .. 
		" -source " .. reacoma.utils.wrap_quotes(source_info.full_path) ..
		" -target " .. reacoma.utils.wrap_quotes(target_info.full_path) ..
		" -output " .. reacoma.utils.wrap_quotes(output) ..
		" -timesparsity " .. reacoma.params.find_by_name(params, 'time sparsity') ..
		" -polyphony " .. reacoma.params.find_by_name(params, 'polyphony') ..
		" -continuity " .. reacoma.params.find_by_name(params, 'continuity') ..
		" -iterations " .. reacoma.params.find_by_name(params, 'iterations') ..
		" -fftsettings " .. fftsettings

        reacoma.utils.cmdline(cli)
        reacoma.layers.output_exists(output)
        r.SelectAllMediaItems(0, 0)
        reacoma.layers.process_matrix(source_info, target_info, output)
        r.UpdateArrange()
    end
end

local nmfcross = {
    info = {
        algorithm_name = 'Resynthesise a target sound based on a source sound',
        ext_name = 'reacoma.nmfcross',
        action = 'decompose',
        source_target_matrix = true,
        column_a = 'Source',
        column_b = 'Target'
    },
    parameters = {
        {
            name = "time sparsity",
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 7,
            desc = 'Control the repetition of source templates in the reconstruction by specifying a number of frames within which a template should not be re-used. Units are spectral frames.'
        },
        {
            name = "polyphony",
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 10,
            desc = 'Control the spectral density of the output sound by restricting the number of simultaneous templates that can be used. Units are spectral bins.'
        },
        {
            name = "continuity",
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 7,
            desc = 'Promote the use of N successive source frames, giving greater continuity in the result. This can not be bigger than the size of the source buffer, but useful values tend to be much lower (in the tens).'
        },
        {
            name = "iterations",
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 300,
            value = 50,
            desc = 'The NMF process is iterative, trying to converge to the smallest error in its factorisation. The number of iterations will decide how many times it tries to adjust its estimates. Higher numbers here will be more CPU expensive, lower numbers will be more unpredictable in quality.'
        },
        {
            name = "window size",
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 1024,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 1024),
            desc = 'window size'
        },
        {
            name = "hop size",
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 512,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 512),
            desc = 'hop size'
        },
        {
            name = "fft size",
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 1024,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 1024),
            desc = 'fft size',
        }
    },
    perform_update = decompose
}

return nmfcross
