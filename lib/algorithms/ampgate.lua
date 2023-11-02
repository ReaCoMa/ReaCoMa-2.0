local r = reaper

function segment(params)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-ampgate"
        )
    )

    local num_selected_items = r.CountSelectedMediaItems(0)

    local processed_items = {}
    for i=1, num_selected_items do
        local data = reacoma.container.get_item_info(i)

        -- Remove any existing take markers
        for j=1, data.take_markers do
            r.DeleteTakeMarker(
                data.take, 
                data.take_markers - j
            )
        end
        
        local cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -indices " .. reacoma.utils.wrap_quotes(data.tmp) ..
        " -rampup " .. reacoma.params.find_by_name(params, 'rampup') ..
        " -rampdown " .. reacoma.params.find_by_name(params, 'rampdown') ..
        " -onthreshold " .. reacoma.params.find_by_name(params, 'onthreshold') ..
        " -offthreshold " .. reacoma.params.find_by_name(params, 'offthreshold') ..
        " -minslicelength " .. reacoma.params.find_by_name(params, 'minslicelength') ..
        " -minsilencelength " .. reacoma.params.find_by_name(params, 'minsilencelength') ..
        " -minlengthabove " .. reacoma.params.find_by_name(params, 'minlengthabove') ..
        " -minlengthbelow " .. reacoma.params.find_by_name(params, 'minlengthbelow') ..
        " -lookback " .. reacoma.params.find_by_name(params, 'lookback') ..
        " -lookahead " .. reacoma.params.find_by_name(params, 'lookahead') ..
        " -highpassfreq " .. reacoma.params.find_by_name(params, 'highpassfreq') ..
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples

        reacoma.utils.cmdline(cmd)

        data.slice_points_string = reacoma.utils.readfile(data.tmp)

        reacoma.slicing.gateslice(data)
        reacoma.utils.cleanup2(data.tmp)
        table.insert(processed_items, data)
    end
    
    r.UpdateArrange()
    return processed_items
end

local ampgate = {
    info = {
        algorithm_name = 'Ampgate Slicing',
        ext_name = 'reacoma.ampgate',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'rampup',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 10000,
            value = 100,
            desc = 'The number of samples the envelope follower will take to reach the next value when rising.'
        },
        {
            name = 'rampdown',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 10000,
            value = 100,
            desc = 'The number of samples the envelope follower will take to reach the next value when falling.'
        },
        {
            name = 'onthreshold',
            widget = r.ImGui_SliderDouble,
            min = -90,
            max = 24,
            value = -24,
            desc = 'The threshold in dB of the envelope follower to trigger an onset, aka to go ON when in OFF state.'
        },
        {
            name = 'offthreshold',
            widget = r.ImGui_SliderDouble,
            min = -90,
            max = 24,
            value = -48,
            desc = 'The threshold in dB of the envelope follower to trigger an offset, , aka to go ON when in OFF state.'
        },
        {
            name = 'minslicelength',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 10000,
            value = 1,
            desc = 'The length in samples that the Slice will stay ON. Changes of states during that period will be ignored.'
        },
        {
            name = 'minsilencelength',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 10000,
            value = 1,
            desc = 'The length in samples that the Slice will stay ON. Changes of states during that period will be ignored.'
        },
        {
            name = 'minlengthabove',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 3000,
            value = 1,
            desc = 'The length in samples that the envelope have to be above the threshold to consider it a valid transition to ON. The Slice will start at the first sample when the condition is met. Therefore, this affects the latency.'
        },
        {
            name = 'minlengthbelow',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 10000,
            value = 1,
            desc = 'The length in samples that the envelope have to be below the threshold to consider it a valid transition to OFF. The Slice will end at the first sample when the condition is met. Therefore, this affects the latency.'
        },
        {
            name = 'lookback',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 0,
            desc = 'The length of the buffer kept before an onset to allow the algorithm, once a new slice is detected, to go back in time (up to that many samples) to find the minimum amplitude as the Slice onset point. This affects the latency of the algorithm.'
        },
        {
            name = 'lookahead',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 0,
            desc = 'The length of the buffer kept after an offset to allow the algorithm, once the slice is considered finished, to wait further in time (up to that many samples) to find a minimum amplitude as the slice offset point. This affects the latency of the algorithm.'
        },
        {
            name = 'highpassfreq',
            widget = r.ImGui_SliderDouble,
            min = 0,
            max = 20000,
            value = 85,
            flag = r.ImGui_SliderFlags_Logarithmic(),
            desc = 'The frequency of the fourth-order Linkwitz-Riley high-pass filter.'
        },
    },
    perform_update = segment
}

return ampgate