local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end

-- Define parameters and type of slicer
-- Establish a place to hold the "state"
parameters = reacoma.noveltyslice.parameters
slicer = reacoma.noveltyslice
state = {}
preview = true

function frame()
    if reaper.ImGui_Button(ctx, 'segment') then
        reacoma.imgui_helpers.button_segment(state)
    end
    
    reaper.ImGui_SameLine(ctx)
    _, preview = reaper.ImGui_Checkbox(ctx, 'preview', preview)
    state = reacoma.imgui_helpers.update_slicing(parameters, preview)
end

-- FRAME LOOP --
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


reaper.defer(function()
    ctx = reaper.ImGui_CreateContext(slicer.info.algorithm_name, 350, 225)
    viewport = reaper.ImGui_GetMainViewport(ctx)
    loop()
end)