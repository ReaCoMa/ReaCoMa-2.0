-- @noindex
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
            type = 'sliderint',
            desc = 'The number of samples the relative envelope follower will take to reach the next value when falling.'
        },
        {
            name = 'fastrampup',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            type = 'sliderint',
            desc = 'The number of samples the relative envelope follower will take to reach the next value when raising.'
        },
        {
            name = 'slowrampdown',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            type = 'sliderint',
            desc = 'The number of samples the absolute envelope follower will take to reach the next value when falling.'
        },
        {
            name = 'slowrampup',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            type = 'sliderint',
            desc = 'The number of samples the absolute envelope follower will take to reach the next value when raising.'
        },
        {
            name = 'onthreshold',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = 144,
            type = 'sliderdouble',
            desc = 'The threshold in dB of the relative envelope follower to trigger an onset, aka to go ON when in OFF state. It is computed on the difference between the two envelope followers.'
        },
        {
            name = 'offthreshold',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = -144,
            type = 'sliderdouble',
            desc = 'The threshold in dB of the relative envelope follower to reset, aka to allow the differential envelop to trigger again.'
        },
        {
            name = 'floor',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = -60,
            type = 'sliderdouble',
            desc = 'The level in dB the slowRamp needs to be above to consider a detected difference valid, allowing to ignore the slices in the noise floor.'
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 2,
            type = 'sliderint',
            desc = 'The length in samples that the Slice will stay ON. Changes of states during that period will be ignored.'
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

return ampslice