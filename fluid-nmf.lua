local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/" .. "FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidLayers.lua")

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local suf = cli_path .. "/fluid-nmf"
local exe = doublequote(suf)
------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.nmf
    check_params(processor)
    local param_names = "components,iterations,fftsettings"
    local param_values = parse_params(param_names, processor)
    
    local confirm, user_inputs = reaper.GetUserInputs("NMF Parameters", 3, param_names, param_values)
    if confirm then
        store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local components = params[1]
        local iterations = params[2]
        local fftsettings = params[3]

        data = LayersContainer

        data.outputs = {
            components = {}
        }

        for i=1, num_selected_items do

            get_layers_data(i, data)

            table.insert(
                data.outputs.components,
                basename(data.full_path[i]) .. "_nmf_" .. uuid(i) .. ".wav"
            )

            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. doublequote(data.full_path[i]) .. 
                " -resynth " .. doublequote(data.outputs.components[i]) ..  
                " -components " .. components .. 
                " -fftsettings " .. fftsettings ..
                " -numframes " .. data.item_len_samples[i] .. 
                " -startframe " .. data.take_ofs_samples[i]
            )
        end

        -- Execute NMF Process
        for i=1, num_selected_items do
            cmdline(data.cmd[i])
        end
        
        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            perform_layers(i, data)
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("NMF", 0)
    end
end
::exit::
