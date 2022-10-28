decompose = function(parameters, item_bundle)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-audiotransport"
    )

    local interpolation = parameters[1].value
    local fftsettings = reacoma.utils.form_fft_string(
        parameters[2].value, 
        parameters[3].value, 
        parameters[4].value
    )

    -- If there is a source without a target remove it
    if #item_bundle % 2 ~= 0 then
        table.remove(item_bundle, #item_bundle)
    end

    -- iterate over the bundle in strides of 2
    for i=1, #item_bundle, 2 do
        local source_a = reacoma.container.get_take_info_from_item(item_bundle[i])
        local source_b = reacoma.container.get_take_info_from_item(item_bundle[i+1])
        local output = source_b.path .. "_audiotransport_" .. reacoma.utils.uuid(i) .. ".wav"

		local cli = exe .. 
		" -sourcea " .. reacoma.utils.wrap_quotes(source_a.full_path) ..
		" -sourceb " .. reacoma.utils.wrap_quotes(source_b.full_path) ..
		" -destination " .. reacoma.utils.wrap_quotes(output) ..
		" -interpolation " .. interpolation ..
		" -fftsettings " .. fftsettings ..
        " -numframesa " .. source_a.item_len_samples .. 
        " -numframesb " .. source_b.item_len_samples ..
        " -startframea " .. source_a.take_ofs_samples ..
        " -startframeb " .. source_b.take_ofs_samples

        reacoma.utils.cmdline(cli)
        reacoma.layers.matrix_output_exists(output)
        reaper.SelectAllMediaItems(0, 0)
        local append_target = 0
        if source_a.item_len_samples > source_b.item_len_samples then
            append_target = 1
        end
        reacoma.layers.process_matrix(source_a, source_b, output, append_target)
        reaper.UpdateArrange()
    end
end

audiotransport = {
    info = {
        algorithm_name = 'Interpolates between the spectra of two sounds.',
        ext_name = 'reacoma.audiotransport',
        action = 'decompose',
        source_target_matrix = true,
		column_a = 'Source A',
        column_b = 'Source B'
    },
    parameters =  {
        {
            name = 'interpolation',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 1.0,
            value = 0.5,
            desc = 'The amount to interpolate between A and B (0-1, 0 = A, 1 = B)'
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

return audiotransport
