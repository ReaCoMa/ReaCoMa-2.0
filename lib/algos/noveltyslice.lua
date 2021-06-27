function perform_slice(GUI)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-noveltyslice"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local feature = GUI[1].value
    local threshold = GUI[2].value
    local kernelsize = GUI[3].value
    local filtersize = GUI[4].value
    local minslicelength = GUI[5].value
    local fftsettings = utils.form_fft_string(
        GUI[6].value, 
        GUI[7].value, 
        GUI[8].value
    )
    local data = reacoma.utils.deep_copy(reacoma.slicing.container)
    for i=1, num_selected_items do
        reacoma.slicing.get_data(i, data)

        -- Remove any existing take markers
        for j=1, data.take_markers[i] do
            reaper.DeleteTakeMarker(
                data.take[i], 
                data.take_markers[i] - j
            )
        end
        
        local cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path[i]) .. 
        " -indices " .. reacoma.utils.wrap_quotes(data.tmp[i]) .. 
        " -maxfftsize " .. reacoma.utils.get_max_fft_size(fftsettings) ..
        " -maxkernelsize " .. kernelsize ..
        " -maxfiltersize " .. filtersize ..
        " -feature " .. feature .. 
        " -kernelsize " .. kernelsize .. 
        " -threshold " .. threshold .. 
        " -filtersize " .. filtersize .. 
        " -fftsettings " .. fftsettings .. 
        " -minslicelength " .. minslicelength ..
        " -numframes " .. data.item_len_samples[i] .. 
        " -startframe " .. data.take_ofs_samples[i]

        reacoma.utils.cmdline(cmd)
        table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
        reacoma.slicing.process(i, data)
    end
    
    reaper.UpdateArrange()
    reacoma.utils.cleanup(data.tmp)
    return data
end

noveltyslice = {
    info = {
        algorithm_name = 'Novelty Slice'
    },
    parameters =  {
        {
            name = 'feature',
            widget = reaper.ImGui_Combo,
            value = 0,
            items = 'spectrum\31mfcc\31pitch\31loudness\31',
            type = 'combo' 
        },
        {
            name = 'threshold',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 1.0,
            value = 0.5,
            type = 'slider'
        },
        {
            name = 'kernelsize',
            widget = reaper.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 3,
            type = 'slider'
        },
        {
            name = 'filtersize',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 100,
            value = 1,
            type = 'slider' 
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 2,
            type = 'slider'
        },
        {
            name = 'window size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            type = 'slider' 
        },
        {
            name = 'hop size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 512,
            type = 'slider' 
        },
        {
            name = 'fft size',
            widget = reaper.ImGui_SliderInt,
            min = 32,
            max = 8192,
            value = 1024,
            type = 'slider' 
        }
    },
    slice = perform_slice
}

return noveltyslice