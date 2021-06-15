local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local data = {
  threshold = {
    value = 0.5,
  },
  kernelsize = {
    value = 3,
  }
}

local state = {} -- contains recent changes to undo
local undo = false

local frame_count = 0
local code = ''
local last = ''

-- local data = reacoma.utils.deep_copy(reacoma.slicing.container)


reaper.defer(function()
  ctx = reaper.ImGui_CreateContext('Dynamic Slicing', 350, 50)
  viewport = reaper.ImGui_GetMainViewport(ctx)
  loop()
end)

function frame()
  -- per frame stuff
  if reaper.ImGui_Button(ctx, 'Click me!') then
    if #touched_items >= 1 then
      for i=1, #touched_items do

      end
    end
  end

  data.threshold.change, data.threshold.value = reaper.ImGui_SliderDouble(ctx, 'Threshold', data.threshold.value, 0.0, 1.0)
  data.kernelsize.change, data.kernelsize.value = reaper.ImGui_SliderInt(ctx, 'Kernelsize', data.kernelsize.value, 3, 21)

  if data.threshold.change or data.kernelsize.change then

    -- if undo then
    --   code = reaper.Undo_CanUndo2(0)
    -- end

    -- if code == 'dynamic-slicing' then
    --   reaper.Undo_DoUndo2(0)
    -- end

    for i=1, #state do
      for j=1, #state
    end
    reaper.Undo_BeginBlock2(0)
    slice(data)
    reaper.Undo_EndBlock2(0, 'dynamic-slicing', 4)
    undo = true
  end

  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_Text(ctx, tostring(frame_count)) 
  reaper.ImGui_Text(ctx, tostring(code))   
  reaper.ImGui_Text(ctx, tostring(last))   
  data.change = 0
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

function slice(data)
  local exe = reacoma.utils.wrap_quotes(
      reacoma.settings.path .. "/fluid-noveltyslice"
  )

  local num_selected_items = reaper.CountSelectedMediaItems(0)
  if num_selected_items > 0 then
    local feature = 0
    local threshold = data.threshold.value
    local kernelsize = data.kernelsize.value
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
    end

    touched_items[#touched_items+1] = data 

    for i=1, num_selected_items do
        reacoma.utils.cmdline(data.cmd[i])
        table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
        local take, points = reacoma.slicing.process(i, data)
        state[#state+1] = { take, points }
    end

    reaper.UpdateArrange()
    reacoma.utils.cleanup(data.tmp)
  end
end