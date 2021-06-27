local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
 
if reacoma.settings.fatal then return end
reaper.Undo_BeginBlock2(0)

local GUI = reacoma.noveltyslice.parameters
local slicer = reacoma.noveltyslice
local state = {}
local preview = true

function frame()
    if reaper.ImGui_Button(ctx, 'segment') then
        -- Slices need to be based on the markers not any other data
        local num_selected_items = reaper.CountSelectedMediaItems(0)
        for i=1, num_selected_items do
            local item = reaper.GetSelectedMediaItem(0, i-1)

            -- If we have never sliced anything we need to do something
            state = slicer.slice(GUI)

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
    
    reaper.ImGui_SameLine(ctx)

    _, preview = reaper.ImGui_Checkbox(ctx, 'preview', preview)

    local change = 0
    for parameter, d in pairs(GUI) do
        if d.type == 'slider' then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.min, d.max 
            )
        end
        if d.type == 'combo' then
            temp, d.value = d.widget(
                ctx, 
                d.name, d.value, d.items
            )
        end

        change = change + utils.bool_to_number[temp]
    end
    
    if change > 0 and preview then
        state = slicer.slice(GUI)
    end

    reaper.ImGui_SameLine(ctx)
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