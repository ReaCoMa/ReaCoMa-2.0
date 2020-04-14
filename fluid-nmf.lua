local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.paths.sanity_check() == false then return end
local exe = reacoma.utils.doublequote(reacoma.paths.get_fluid_path() .. "/fluid-nmf")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.archetype.nmf
    reacoma.params.check_params(processor)
    local param_names = "components,iterations,fftsettings"
    local param_values = reacoma.params.parse_params(param_names, processor)
    
    local confirm, user_inputs = reaper.GetUserInputs("NMF Parameters", 3, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        local params = reacoma.utils.commasplit(user_inputs)
        local components = params[1]
        local iterations = params[2]
        local fftsettings = params[3]

        local data = reacoma.layers.container

        data.outputs = {
            components = {}
        }

        for i=1, num_selected_items do

            reacoma.layers.get_data(i, data)

            table.insert(
                data.outputs.components,
                reacoma.utils.basename(data.full_path[i]) .. "_nmf_" .. reacoma.utils.uuid(i) .. ".wav"
            )

            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
                " -resynth " .. reacoma.utils.doublequote(data.outputs.components[i]) ..
                " -components " .. components .. 
                " -fftsettings " .. fftsettings ..
                " -numframes " .. data.item_len_samples[i] .. 
                " -startframe " .. data.take_ofs_samples[i]
            )
        end

        -- Execute NMF Process
        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.cmd[i])
        end
        
        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            reacoma.layers.process(i, data)
        end
        
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("NMF", 0)
    end
end

