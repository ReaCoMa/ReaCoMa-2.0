local r = reaper

function segment(params)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.utils.cross_platform_executable(
            reacoma.settings.path .. "/fluid-noveltyslice"
        )
    )

    local num_selected_items = r.CountSelectedMediaItems(0)
    local kernelsize = reacoma.params.find_by_name(params, 'kernelsize')
    local filtersize = reacoma.params.find_by_name(params, 'filtersize')
    local fftsettings = reacoma.utils.form_fft_string(
        reacoma.params.find_by_name(params, 'window size'), 
        reacoma.params.find_by_name(params, 'hop size'), 
        reacoma.params.find_by_name(params, 'fft size')
    )

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
        " -algorithm " .. reacoma.params.find_by_name(params, 'algorithm') .. 
        " -kernelsize " .. kernelsize .. " " .. kernelsize ..
        " -filtersize " .. filtersize .. " " .. filtersize ..
        " -threshold " .. reacoma.params.find_by_name(params, 'threshold') .. 
        " -fftsettings " .. fftsettings .. 
        " -minslicelength " .. reacoma.params.find_by_name(params, 'minslicelength') ..
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

local noveltyslice = {
    info = {
        algorithm_name = 'Novelty Slice',
        ext_name = 'reacoma.noveltyslice',
        action = 'segment'
    },
    parameters =  {
        {
            name = 'algorithm',
            widget = r.ImGui_Combo,
            value = 0,
            items = 'spectrum\0mfcc\0chroma\0pitch\0loudness\0',
            desc = 'The feature on which novelty is computed.'
        },
        {
            name = 'threshold',
            widget = r.ImGui_SliderDouble,
            min = 0.0,
            max = 1.0,
            value = 0.5,
            desc = 'The normalised threshold, between 0 an 1, on the novelty curve to consider it a segmentation point.'
        },
        {
            name = 'kernelsize',
            widget = reacoma.imgui.widgets.KernelSlider,
            value = 3,
            index = reacoma.params.find_index(reacoma.imgui.widgets.KernelSlider.opts, 3),
            desc = 'The granularity of the window in which the algorithm looks for change, in FFT frames.'
        },
        {
            name = 'filtersize',
            widget = reacoma.imgui.widgets.FilterSlider,
            value = 1,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FilterSlider.opts, 17),
            desc = 'The size of a smoothing filter that is applied on the novelty curve. A larger filter filter size allows for cleaner cuts on very sharp changes.'
        },
        {
            name = 'minslicelength',
            widget = r.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 2,
            desc = 'The minimum duration of a slice in number of hop size.'
        },
        {
            name = 'window size',
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 1024,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 1024),
            desc = 'window size'
        },
        {
            name = 'hop size',
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 512,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 512),
            desc = 'hop size'
        },
        {
            name = 'fft size',
            widget = reacoma.imgui.widgets.FFTSlider,
            value = 1024,
            index = reacoma.params.find_index(reacoma.imgui.widgets.FFTSlider.opts, 1024),
            desc = 'fft size',
        }
    },
    perform_update = segment
}

return noveltyslice