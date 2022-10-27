imgui_wrapper = {}

local r = reaper

local path_width = 500
local path_height = 285

local rt_items = reacoma.utils.deep_copy(reacoma.container.generic)

-- FRAME LOOP --
open = true
visible = true
imgui_wrapper.loop = function(ctx, viewport, state, obj)
    
    local pos = { r.ImGui_Viewport_GetWorkPos(viewport) }
    local w, h = reaper.ImGui_Viewport_GetSize(viewport)
    
    reaper.ImGui_SetNextWindowPos(ctx, pos[1] + 100, pos[2] + 100, r.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowSize(ctx, 
        reacoma.global_state.width,
        reacoma.global_state.height, 
        r.ImGui_Cond_FirstUseEver()
    )

    visible, open = reaper.ImGui_Begin(ctx, obj.info.algorithm_name, true, r.ImGui_WindowFlags_NoCollapse())

    local restored = false

    if reaper.ImGui_Button(ctx, obj.info.action) or (reacoma.global_state.active == 0 and reaper.ImGui_IsKeyPressed(ctx, 13)) then
        state = reacoma.imgui_helpers.process(obj, 'split') -- TODO: make this respond to slicer/layers
    end

    if obj.info.action == 'segment' then
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, 'create markers') then
            state = reacoma.imgui_helpers.process(obj, 'marker')
        end
        
        reaper.ImGui_SameLine(ctx)
        _, reacoma.settings.slice_preview = reaper.ImGui_Checkbox(ctx,'preview',reacoma.settings.slice_preview)
        if not reacoma.settings.slice_preview then reaper.ImGui_BeginDisabled(ctx) end
        reaper.ImGui_SameLine(ctx)
        _,  reacoma.settings.immediate_preview = reaper.ImGui_Checkbox(ctx,'immediate',reacoma.settings.immediate_preview)
        if not reacoma.settings.slice_preview then reaper.ImGui_EndDisabled(ctx) end
    else
        reacoma.settings.slice_preview = false
        reacoma.settings.immediate_preview = false
    end

    if obj.defaults ~= nil then
        if reaper.ImGui_Button(ctx, "defaults") then
            state = params.restore_defaults(obj)
            restored = true
        end
    end

    state = reacoma.imgui_helpers.update_state(ctx, obj, restored)

    local temp_items = reacoma.utils.deep_copy(reacoma.container.generic)
    local num_items = reaper.CountSelectedMediaItems(0)
    for i=1, num_items do
        reacoma.container.get_data(i, temp_items)
    end
    -- if reacoma.utils.compare_tables(temp_items, rt_items) then
    --     rt_items = temp_items
        -- reacoma.utils.DEBUG("The are the same")
    -- end

    -- if r.ImGui_BeginTable(ctx, 'mappings', 2) then
    --     r.ImGui_TableSetupColumn(ctx, 'Source')
    --     r.ImGui_TableSetupColumn(ctx, 'Target')
    --     r.ImGui_TableHeadersRow(ctx)
    --     r.ImGui_TableNextRow(ctx)
        
    --     for i, v in ipairs(items) do
    --         r.ImGui_PushID(ctx, i)
    --         r.ImGui_TableNextColumn(ctx)
    --         r.ImGui_Button(ctx, items[i], 60, 20)
    --         if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_None()) then
    --             r.ImGui_SetDragDropPayload(ctx, 'DND_DEMO_CELL', tostring(i))
    --             r.ImGui_Text(ctx, ('Swap %s'):format(items[i]))
    --             r.ImGui_EndDragDropSource(ctx)
    --         end
    --         if r.ImGui_BeginDragDropTarget(ctx) then
    --             local rv, payload = r.ImGui_AcceptDragDropPayload(ctx, 'DND_DEMO_CELL')
    --             if rv then
    --                 local payload_i = tonumber(payload)
    --                 items[i] = items[payload_i]
    --                 items[payload_i] = v
    --             end
    --             r.ImGui_EndDragDropTarget(ctx)
    --         end
    --         r.ImGui_PopID(ctx)
    --     end
    --     r.ImGui_EndTable(ctx)
    -- end

    reaper.ImGui_End(ctx)
    if open then
        reaper.defer(
            function() 
                imgui_wrapper.loop(ctx, viewport, state, obj) 
            end
        )
    else
        reaper.ImGui_DestroyContext(ctx)
        reaper.Undo_EndBlock2(0, obj.info.ext_name, 4)
        reacoma.params.set(obj)
        reaper.SetExtState('reacoma', 'slice_preview', utils.bool_to_string[reacoma.settings.slice_preview], true)
        reaper.SetExtState('reacoma', 'immediate_preview', utils.bool_to_string[reacoma.settings.immediate_preview], true)
        return
    end
end

return imgui_wrapper