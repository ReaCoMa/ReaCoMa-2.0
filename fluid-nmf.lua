local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "FluidPlumbing/FluidParams.lua")
dofile(script_path .. "FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "FluidPlumbing/FluidLayers.lua")

if fluidPaths.sanity_check() == false then return end
local exe = fluidUtils.doublequote(fluidPaths.get_fluid_path() .. "/fluid-nmf")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = fluid_archetype.nmf
    fluidParams.check_params(processor)
    local param_names = "components,iterations,fftsettings"
    local param_values = fluidParams.parse_params(param_names, processor)
    
    local confirm, user_inputs = reaper.GetUserInputs("NMF Parameters", 3, param_names, param_values)
    if confirm then
        fluidParams.store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        local params = fluidUtils.commasplit(user_inputs)
        local components = params[1]
        local iterations = params[2]
        local fftsettings = params[3]

        local data = fluidLayers.container

        data.outputs = {
            components = {}
        }

        for i=1, num_selected_items do

            fluidLayers.get_data(i, data)

            table.insert(
                data.outputs.components,
                fluidUtils.basename(data.full_path[i]) .. "_nmf_" .. fluidUtils.uuid(i) .. ".wav"
            )

            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. fluidUtils.doublequote(data.full_path[i]) .. 
                " -resynth " .. fluidUtils.doublequote(data.outputs.components[i]) ..
                " -components " .. components .. 
                " -fftsettings " .. fftsettings ..
                " -numframes " .. data.item_len_samples[i] .. 
                " -startframe " .. data.take_ofs_samples[i]
            )
        end

        -- Execute NMF Process
        for i=1, num_selected_items do
            fluidUtils.cmdline(data.cmd[i])
        end
        
        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            fluidLayers.perform_layers(i, data)
        end
        
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("NMF", 0)
    end
end

