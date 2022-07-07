decompose = function(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-nmfcross"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local timesparsity = parameters[1].value
    local polyphony = parameters[2].value
    local continuity = parameters[3].value
    local iterations = parameters[4].value
    local fftsettings = reacoma.utils.form_fft_string(
        parameters[5].value, 
        parameters[6].value, 
        parameters[7].value
    )

    local data = reacoma.utils.deep_copy(reacoma.container.generic)
    data.outputs = {
        output = {}
    }

    -- get mappings and convert to a matrix...? or get the matrix...?
    -- gets a matrix of items to process
    -- get_data as per normalbut cross the items and return an output
    -- append the result to the target


    for source, target in pairs(matrix) do
        
    end

--     for i=1, num_selected_items do
--         reacoma.container.get_data(i, data)

--         table.insert(
--             data.outputs.output,
--             data.path[i] .. "_nmfcross_" .. reacoma.utils.uuid(i) .. ".wav"
--         )

-- 		local cli = exe .. 
-- 		" -source " .. reacoma.utils.wrap_quotes(data.full_path[i]) ..
-- 		" -target " .. reacoma.utils.wrap_quotes(data.full_path[i]) ..
-- 		" -output " .. reacoma.utils.wrap_quotes(data.outputs.components[i]) ..
-- 		" -timesparsity " .. timesparsity ..
-- 		" -polyphony " .. polyphony ..
-- 		" -continuity " .. continuity ..
-- 		" -iterations " .. iterations ..
-- 		" -fftsettings " .. fftsettings
--         table.insert(data.cmd, cli)

--         reacoma.utils.cmdline(data.cmd[i])
--         reacoma.layers.exist(i, data)
--         reaper.SelectAllMediaItems(0, 0)
--         reacoma.layers.process(i, data)
--         reaper.UpdateArrange()
--     end
-- end

nmfcross = {
    info = {
        algorithm_name = 'Resynthesise a target sound based on a source sound',
        ext_name = 'reacoma.nmfcross',
        action = 'decompose',
        source_target_matrix = true

    },
    parameters =  {
        {
            name = 'time sparsity',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 7,
            type = 'sliderint',
            desc = 'Control the repetition of source templates in the reconstruction by specifying a number of frames within which a template should not be re-used. Units are spectral frames.'
        },
		{
            name = 'polyphony',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 10,
            type = 'sliderint',
            desc = 'Control the spectral density of the output sound by restricting the number of simultaneous templates that can be used. Units are spectral bins.'
        },
		{
            name = 'continuity',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 7,
            type = 'sliderint',
            desc = 'Promote the use of N successive source frames, giving greater continuity in the result. This can not be bigger than the size of the source buffer, but useful values tend to be much lower (in the tens).'
        },
        {
            name = 'iterations',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 300,
            value = 50,
            type = 'sliderint',
            desc = 'The NMF process is iterative, trying to converge to the smallest error in its factorisation. The number of iterations will decide how many times it tries to adjust its estimates. Higher numbers here will be more CPU expensive, lower numbers will be more unpredictable in quality.'
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

return nmfcross
