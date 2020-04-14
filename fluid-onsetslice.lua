local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

local exe = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-onsetslice"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.archetype.onsetslice
    reacoma.params.check_params(processor)
    local param_names = "metric,threshold,minslicelength,filtersize,framedelta,fftsettings"
    local param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Onset Slice Parameters", 6, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, param_values)

        reaper.Undo_BeginBlock()
        local params = reacoma.utils.commasplit(user_inputs)
        local metric = params[1]
        local threshold = params[2]
        local minslicelength = params[3]
        local filtersize = params[4]
        local framedelta = params[5]
        local fftsettings = params[6]

        local data = reacoma.slicing.container

        for i=1, num_selected_items do
            reacoma.slicing.get_data(i, data)

            local cmd = exe .. 
            " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
            " -indices " .. reacoma.utils.doublequote(data.tmp[i]) ..
            " -maxfftsize " .. reacoma.utils.getmaxfftsize(fftsettings) .. 
            " -metric " .. metric .. 
            " -minslicelength " .. minslicelength ..
            " -threshold " .. threshold .. 
            " -filtersize " .. filtersize .. 
            " -framedelta " .. framedelta ..
            " -fftsettings " .. fftsettings .. 
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]

            table.insert(data.cmd, cmd)
        end

        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.cmd[i])
            table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
            reacoma.slicing.process(i, data)
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("onsetslice", 0)
        reacoma.utils.cleanup(data.tmp)
    end
end

