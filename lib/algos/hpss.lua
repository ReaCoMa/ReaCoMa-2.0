function decompose(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-hpss"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)

end

noveltyslice = {
    info = {
        algorithm_name = 'Novelty Slice',
        ext_name = 'reacoma.noveltyslice',
        action = 'segment'
    },
    parameters =  {
        -- {
        --     name = 'masking mode',
        --     widget = reaper.ImGui_Combo,
        --     value = 0,
        --     items = 'classic\31coupled\31advanced\31',
        --     type = 'combo' 
        -- },
        {
            name = 'harmonic filter size',
            widget = reaper.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 17,
            type = 'slider'
        },
        {
            name = 'percussive filter size',
            widget = reaper.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 31,
            type = 'slider'
        },
        {
            name = 'window size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            type = 'snapslider' 
        },
        {
            name = 'hop size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 512,
            type = 'snapslider' 
        },
        {
            name = 'fft size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            type = 'snapslider' 
        }
    },
    perform_update = decompose
}

return noveltyslice