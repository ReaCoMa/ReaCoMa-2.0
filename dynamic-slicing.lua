local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local data = {
  threshold = 0.5,
}

local history = reacoma.utils.deep_copy(data)

local frame_count = 0

reaper.defer(function()
  ctx = reaper.ImGui_CreateContext('Dynamic Slicing', 350, 50)
  viewport = reaper.ImGui_GetMainViewport(ctx)
  loop()
end)

function frame()
  -- per frame stuff
  if reaper.ImGui_Button(ctx, 'Click me!') then
  end

  if history.threshold ~= data.threshold then
    history = data
    reaper.ShowConsoleMsg('not the same')
    -- slice()
  end


  frame_count = frame_count + 1
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_Text(ctx, tostring(frame_count)) 
  reaper.ImGui_Text(ctx, tostring(history.threshold))   
  _, data.threshold = reaper.ImGui_SliderDouble(ctx, 'Threshold', data.threshold, 0.0, 1.0)
  
end

function loop()
  local rv
  if reaper.ImGui_IsCloseRequested(ctx) then
    reaper.ImGui_DestroyContext(ctx)
    return
  end

  reaper.ImGui_SetNextWindowPos(ctx, reaper.ImGui_Viewport_GetPos(viewport))
  reaper.ImGui_SetNextWindowSize(ctx, reaper.ImGui_Viewport_GetSize(viewport))
  reaper.ImGui_Begin(ctx, 'wnd', nil, reaper.ImGui_WindowFlags_NoDecoration())
  frame() -- stuff to do in the loop
  reaper.ImGui_End(ctx)
  reaper.defer(loop)
end

function slice()
  local exe = reacoma.utils.wrap_quotes(
      reacoma.settings.path .. "/fluid-noveltyslice"
  )

  local num_selected_items = reaper.CountSelectedMediaItems(0)
  if num_selected_items > 0 then
    local feature = 0
    local threshold = data.threshold
    local kernelsize = 3
    local filtersize = 2
    local fftsettings = '1024 512 1024'
    local minslicelength = 2
    
    local data = reacoma.slicing.container

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
    end

    for i=1, num_selected_items do
        reacoma.utils.cmdline(data.cmd[i])
        table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
        reacoma.slicing.process(i, data)
    end

    reacoma.utils.arrange("reacoma-noveltyslice")
    reacoma.utils.cleanup(data.tmp)
  end
end