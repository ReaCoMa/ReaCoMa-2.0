local r = reaper

function segment(params)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-ampslice"
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
        " -fastrampup " .. reacoma.params.find_by_name(params, 'fastrampup') ..
        " -fastrampdown " .. reacoma.params.find_by_name(params, 'fastrampdown') ..
        " -slowrampup " .. reacoma.params.find_by_name(params, 'slowrampup') ..
        " -slowrampdown " .. reacoma.params.find_by_name(params, 'slowrampdown') ..
        " -onthreshold " .. reacoma.params.find_by_name(params, 'onthreshold') ..
        " -offthreshold " .. reacoma.params.find_by_name(params, 'offthreshold') ..
        " -floor " .. reacoma.params.find_by_name(params, 'floor') ..
        " -minslicelength " .. reacoma.params.find_by_name(params, 'minslicelength') ..
        " -highpassfreq " .. reacoma.params.find_by_name(params, 'highpassfreq') ..
        " -numframes " .. data.item_len_samples .. 
        " -startframe " .. data.take_ofs_samples

        reacoma.utils.cmdline(cmd)
        data.slice_points_string = reacoma.utils.readfile(data.tmp)
        
        reacoma.slicing.process(data)
        reacoma.utils.cleanup2(data.tmp)
        table.insert(processed_items, data)
    end
    
    r.UpdateArrange()
    return processed_items
end

local ampslice = {
    info = {
        algorithm_name = 'Ampslice Slicing',
        ext_name = 'reacoma.ampslice',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'fastrampdown',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 100,
            desc = 'The number of samples the relative envelope follower will take to reach the next value when falling.'
        },
        {
            name = 'fastrampup',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 1000,
            value = 100,
            desc = 'The number of samples the relative envelope follower will take to reach the next value when raising.'
        },
        {
            name = 'slowrampdown',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 10000,
            value = 1000,
            desc = 'The number of samples the absolute envelope follower will take to reach the next value when falling.'
        },
        {
            name = 'slowrampup',
            widget = r.ImGui_SliderInt,
            min = 1,
            max = 10000,
            value = 1000,
            desc = 'The number of samples the absolute envelope follower will take to reach the next value when raising.'
        },
        {
            name = 'onthreshold',
            widget = r.ImGui_SliderDouble,
            min = -48,
            max = 48,
            value = 12,
            desc = 'The threshold in dB of the relative envelope follower to trigger an onset, aka to go ON when in OFF state. It is computed on the difference between the two envelope followers.'
        },
        {
            name = 'offthreshold',
            widget = r.ImGui_SliderDouble,
            min = -48,
            max = 48,
            value = 0,
            desc = 'The threshold in dB of the relative envelope follower to reset, aka to allow the differential envelop to trigger again.'
        },
        {
            name = 'floor',
            widget = r.ImGui_SliderDouble,
            min = 0,
            max = 144,
            value = -60,
            desc = 'The level in dB the slowRamp needs to be above to consider a detected difference valid, allowing to ignore the slices in the noise floor.'
        },
        {
            name = 'minslicelength',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 3000,
            value = 2,
            desc = 'The length in samples that the Slice will stay ON. Changes of states during that period will be ignored.'
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

return ampslice