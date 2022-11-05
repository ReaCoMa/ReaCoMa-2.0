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

    local processed_items = {}
    for i=1, num_selected_items do
        local data = reacoma.container.get_item_info(i)

        -- Remove any existing take markers
        for j=1, data.take_markers do
            reaper.DeleteTakeMarker(
                data.take, 
                data.take_markers - j
            )
        end
        
        local cmd = exe .. 
        " -source " .. reacoma.utils.wrap_quotes(data.full_path) .. 
        " -indices " .. reacoma.utils.wrap_quotes(data.tmp) .. 
        " -fastrampup " .. fastrampup ..
        " -fastrampdown " .. fastrampdown ..
        " -slowrampup " .. slowrampup ..
        " -slowrampdown " .. slowrampdown ..
        " -onthreshold " .. onthreshold ..
        " -offthreshold " .. offthreshold ..
        " -floor " .. floor ..
        " -minslicelength " .. minslicelength ..
        " -highpassfreq " .. highpassfreq ..
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples

        reacoma.utils.cmdline(cmd)
        data.slice_points_string = reacoma.utils.readfile(data.tmp)
        
        reacoma.slicing.process(data)
        reacoma.utils.cleanup2(data.tmp)
        table.insert(processed_items, data)
    end
    
    reaper.UpdateArrange()
    return processed_items
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
            desc = 'The number of samples the relative envelope follower will take to reach the next value when falling.'
        },
        {
            name = 'fastrampup',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            desc = 'The number of samples the relative envelope follower will take to reach the next value when raising.'
        },
        {
            name = 'slowrampdown',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            desc = 'The number of samples the absolute envelope follower will take to reach the next value when falling.'
        },
        {
            name = 'slowrampup',
            widget = reaper.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 1,
            desc = 'The number of samples the absolute envelope follower will take to reach the next value when raising.'
        },
        {
            name = 'onthreshold',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = 144,
            desc = 'The threshold in dB of the relative envelope follower to trigger an onset, aka to go ON when in OFF state. It is computed on the difference between the two envelope followers.'
        },
        {
            name = 'offthreshold',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = -144,
            desc = 'The threshold in dB of the relative envelope follower to reset, aka to allow the differential envelop to trigger again.'
        },
        {
            name = 'floor',
            widget = reaper.ImGui_SliderDouble,
            min = -144,
            max = 144,
            value = -60,
            desc = 'The level in dB the slowRamp needs to be above to consider a detected difference valid, allowing to ignore the slices in the noise floor.'
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 2,
            desc = 'The length in samples that the Slice will stay ON. Changes of states during that period will be ignored.'
        },
        {
            name = 'highpassfreq',
            widget = reaper.ImGui_SliderDouble,
            min = 0,
            max = 20000,
            value = 85,
            flag = reaper.ImGui_SliderFlags_Logarithmic(),
            desc = 'The frequency of the fourth-order Linkwitz-Riley high-pass filter.'
        },
    },
    perform_update = segment
}

return ampslice