decompose = function(parameters, item_bundle)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-nmfcross"
    )

    local timesparsity = parameters[1].value
    local polyphony = parameters[2].value
    local continuity = parameters[3].value
    local iterations = parameters[4].value
    local fftsettings = reacoma.utils.form_fft_string(
        parameters[5].value, 
        parameters[6].value, 
        parameters[7].value
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
		" -timesparsity " .. timesparsity ..
		" -polyphony " .. polyphony ..
		" -continuity " .. continuity ..
		" -iterations " .. iterations ..
		" -fftsettings " .. fftsettings

        reacoma.utils.cmdline(cli)
        reacoma.layers.matrix_output_exists(output)
        reaper.SelectAllMediaItems(0, 0)
        reacoma.layers.process_matrix(source_info, target_info, output)
        reaper.UpdateArrange()
    end
end

nmfcross = {
    info = {
        algorithm_name = 'Resynthesise a target sound based on a source sound',
        ext_name = 'reacoma.nmfcross',
        action = 'decompose',
        source_target_matrix = true,
        column_a = 'Source',
        column_b = 'Target'
    },
    parameters =  {
        {
            name = 'time sparsity',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 7,
            desc = 'Control the repetition of source templates in the reconstruction by specifying a number of frames within which a template should not be re-used. Units are spectral frames.'
        },
		{
            name = 'polyphony',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 10,
            desc = 'Control the spectral density of the output sound by restricting the number of simultaneous templates that can be used. Units are spectral bins.'
        },
		{
            name = 'continuity',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 7,
            desc = 'Promote the use of N successive source frames, giving greater continuity in the result. This can not be bigger than the size of the source buffer, but useful values tend to be much lower (in the tens).'
        },
        {
            name = 'iterations',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 300,
            value = 50,
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

return nmfcross
