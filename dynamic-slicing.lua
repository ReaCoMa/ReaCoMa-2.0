local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

reaper.Undo_BeginBlock2(0)

local parameters = {
    threshold = {
        value = 0.5,
    },
    kernelsize = {
        value = 3,
    }
}

local state = {}

local frame_count = 0
local code = ''

reaper.defer(function()
    ctx = reaper.ImGui_CreateContext('Dynamic Slicing', 350, 50)
    viewport = reaper.ImGui_GetMainViewport(ctx)
    loop()
end)

function frame()
    
    if reaper.ImGui_Button(ctx, 'segment') then
        -- Slices need to be based on the markers not any other data
        local num_selected_items = reaper.CountSelectedMediaItems(0)
        for i=1, num_selected_items do
            local item = reaper.GetSelectedMediaItem(0, i-1)

            local take = reaper.GetActiveTake(item)
            local take_markers = reaper.GetNumTakeMarkers(take)
            for j=1, take_markers do
                local slice_pos, _, _ = reaper.GetTakeMarker(take, j-1)

                item = reaper.SplitMediaItem(
                    item, 
                    slice_pos + state.item_pos[i]
                )
            end
        end
        reaper.UpdateArrange()
    end

    parameters.threshold.change, parameters.threshold.value = reaper.ImGui_SliderDouble(ctx, 'Threshold', parameters.threshold.value, 0.0, 1.0)
    parameters.kernelsize.change, parameters.kernelsize.value = reaper.ImGui_SliderInt(ctx, 'Kernelsize', parameters.kernelsize.value, 3, 21)

    if parameters.threshold.change or parameters.kernelsize.change then
        
        -- Remove any previously made take markers
        local num_selected_items = reaper.CountSelectedMediaItems(0)
        for i=1, num_selected_items do
            local take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i-1))
            local take_markers = reaper.GetNumTakeMarkers(take)
            for j=1, take_markers do
                reaper.DeleteTakeMarker(take, take_markers - j)
            end
        end
        slice(data)
    end

    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, tostring(frame_count)) 
    reaper.ImGui_Text(ctx, tostring(code))   
    reaper.ImGui_Text(ctx, tostring(last))   
end

function loop()
    local rv
    if reaper.ImGui_IsCloseRequested(ctx) then
        reaper.ImGui_DestroyContext(ctx)
        reaper.Undo_EndBlock2(0, 'dynamic-slicing', 4)
        return
    end
    
    reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
    reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))
    reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())
    frame() -- stuff to do in the loop
    reaper.ImGui_End(ctx)
    reaper.defer(loop)
end

function slice(data)
    local exe = reacoma.utils.wrap_quotes(
        reacoma.settings.path .. "/fluid-noveltyslice"
    )

    local num_selected_items = reaper.CountSelectedMediaItems(0)
    local feature = 0
    local threshold = parameters.threshold.value
    local kernelsize = parameters.kernelsize.value
    local filtersize = 2
    local fftsettings = '1024 512 1024'
    local minslicelength = 2
    local data = reacoma.utils.deep_copy(reacoma.slicing.container)
    for i=1, num_selected_items do
        reacoma.slicing.get_data(i, data)
        
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
        table.insert(data.cmd, cmd)

        reacoma.utils.cmdline(data.cmd[i])
        table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
        reacoma.slicing.process(i, data)
    end
    
    reaper.UpdateArrange()
    reacoma.utils.cleanup(data.tmp)
    state = data
end