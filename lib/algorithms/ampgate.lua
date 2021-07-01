function segment(parameters)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-ampgate"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local rampup = parameters[1].value
    local rampdown = parameters[2].value
    local onthreshold = parameters[3].value
    local offthreshold = parameters[4].value
    local minslicelength = parameters[5].value
    local minsilencelength = parameters[6].value
    local minlengthabove = parameters[7].value
    local minlengthbelow = parameters[8].value
    local lookback = parameters[9].value
    local lookahead = parameters[10].value
    local highpassfreq = parameters[11].value

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
        " -maxsize "  .. math.max(tonumber(minlengthabove) + tonumber(lookback), math.max(tonumber(minlengthbelow),tonumber(lookahead))) ..
        " -rampup " .. rampup ..
        " -rampdown " .. rampdown ..
        " -onthreshold " .. onthreshold ..
        " -offthreshold " .. offthreshold ..
        " -minslicelength " .. minslicelength ..
        " -minsilencelength " .. minsilencelength ..
        " -minlengthabove " .. minlengthabove ..
        " -minlengthbelow " .. minlengthbelow ..
        " -lookback " .. lookback ..
        " -lookahead " .. lookahead ..
        " -highpassfreq " .. highpassfreq ..
        " -numframes " .. data.item_len_samples[i] .. 
        " -startframe " .. data.take_ofs_samples[i]

        reacoma.utils.cmdline(cmd)
        table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
        reacoma.slicing.process(i, data, true)
    end
    
    reaper.UpdateArrange()
    reacoma.utils.cleanup(data.tmp)
    return data
end

ampgate = {
    info = {
        algorithm_name = 'Ampgate Slicing',
        ext_name = 'reacoma.ampgate',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'rampup',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 3000,
            value = 10,
            type = 'sliderint',
            desc = 'The number of samples the envelope follower will take to reach the next value when rising.'
        },
        {
            name = 'rampdown',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 3000,
            value = 10,
            type = 'sliderint',
            desc = 'The number of samples the envelope follower will take to reach the next value when falling.'
        },
        {
            name = 'onthreshold',
            widget = reaper.ImGui_SliderDouble,
            min = -144.0,
            max = 144.0,
            value = -90.0,
            type = 'sliderdouble',
            desc = 'The threshold in dB of the envelope follower to trigger an onset, aka to go ON when in OFF state.'
        },
        {
            name = 'offthreshold',
            widget = reaper.ImGui_SliderDouble,
            min = -144.0,
            max = 144.0,
            value = -90.0,
            type = 'sliderdouble',
            desc = 'The threshold in dB of the envelope follower to trigger an offset, , aka to go ON when in OFF state.'
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 3000,
            value = 1,
            type = 'sliderint',
            desc = 'The length in samples that the Slice will stay ON. Changes of states during that period will be ignored.'
        },
        {
            name = 'minsilencelength',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 3000,
            value = 1,
            type = 'sliderint',
            desc = 'The length in samples that the Slice will stay ON. Changes of states during that period will be ignored.'
        },
        {
            name = 'minlengthabove',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 3000,
            value = 1,
            type = 'sliderint',
            desc = 'The length in samples that the envelope have to be above the threshold to consider it a valid transition to ON. The Slice will start at the first sample when the condition is met. Therefore, this affects the latency.'
        },
        {
            name = 'minlengthbelow',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 3000,
            value = 1,
            type = 'sliderint',
            desc = 'The length in samples that the envelope have to be below the threshold to consider it a valid transition to OFF. The Slice will end at the first sample when the condition is met. Therefore, this affects the latency.'
        },
        {
            name = 'lookback',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 0,
            type = 'sliderint',
            desc = 'The length of the buffer kept before an onset to allow the algorithm, once a new Slice is detected, to go back in time (up to that many samples) to find the minimum amplitude as the Slice onset point. This affects the latency of the algorithm.'
        },
        {
            name = 'lookahead',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 0,
            type = 'sliderint',
            desc = 'The length of the buffer kept after an offset to allow the algorithm, once the slice is considered finished, to wait further in time (up to that many samples) to find a minimum amplitude as the slice offset point. This affects the latency of the algorithm.'
        },
        {
            name = 'highpassfreq',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 20000,
            value = 85,
            type = 'sliderdouble',
            flag = reaper.ImGui_SliderFlags_Logarithmic(),
            desc = 'The frequency of the fourth-order Linkwitz-Riley high-pass filter.'
        },

    },
    perform_update = segment
}

return ampgate