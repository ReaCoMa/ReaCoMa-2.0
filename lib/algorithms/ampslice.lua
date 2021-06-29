function segment(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-ampslice"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local fastrampup = parameters[1].value
    local fastrampdown = parameters[2].value
    local slowrampup = parameters[3].value
    local slowrampdown = parameters[4].value
    local onthreshold = parameters[5].value
    local offthreshold = parameters[6].value
    local floor = parameters[7].value
    local minslicelength = parameters[8].value
    local highpassfreq = parameters[9].value

    local data = reacoma.utils.deep_copy(reacoma.container.generic)
    for i=1, num_selected_items do
        reacoma.container.get_data(i, data)

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
        " -fastrampup " .. fastrampup ..
        " -fastrampdown " .. fastrampdown ..
        " -slowrampup " .. slowrampup ..
        " -slowrampdown " .. slowrampdown ..
        " -onthreshold " .. onthreshold ..
        " -offthreshold " .. offthreshold ..
        " -floor " .. floor ..
        " -minslicelength " .. minslicelength ..
        " -highpassfreq " .. highpassfreq ..
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

ampslice = {
    info = {
        algorithm_name = 'Ampslice Slicing',
        ext_name = 'reacoma.ampslice',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'fastrampdown',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            type = 'sliderint'
        },
        {
            name = 'fastrampup',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            type = 'sliderint'
        },
        {
            name = 'slowrampdown',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            type = 'sliderint'
        },
        {
            name = 'slowrampup',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            type = 'sliderint'
        },
        {
            name = 'onthreshold',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = 144,
            type = 'sliderdouble'
        },
        {
            name = 'offthreshold',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = -144,
            type = 'sliderdouble'
        },
        {
            name = 'floor',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = -145,
            type = 'sliderdouble'
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 2,
            type = 'sliderint'
        },
        {
            name = 'highpassfreq',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 20000,
            value = 22000,
            type = 'sliderdouble',
            flag = reaper.ImGui_SliderFlags_Logarithmic()
        },

    },
    perform_update = segment
}

return ampslice