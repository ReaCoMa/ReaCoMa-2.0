local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/" .. "FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidLayers.lua")

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local suf = cli_path .. "/fluid-transients"
local exe = doublequote(suf)
------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    local processor = fluid_archetype.transients
    check_params(processor)
    local param_names = "order,blocksize,padsize,skew,threshfwd,threshback,windowsize,clumplength"
    local param_values = parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Transients Parameters", 8, param_names, param_values)
    if confirm then 
        store_params(processor, param_names, user_inputs)
        reaper.Undo_BeginBlock()

        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local order = params[1]
        local blocksize = params[2]
        local padsize = params[3]
        local skew = params[4]
        local threshfwd = params[5]
        local threshback = params[6]
        local windowsize = params[7]
        local clumplength = params[8]

        data = LayersContainer

        data.outputs = {
            transients = {},
            residual = {}
        }

        for i=1, num_selected_items do

            get_layers_data(i, data)

            table.insert(
                data.outputs.transients,
                basename(data.full_path[i]) .. "_ts-t_" .. uuid(i) .. ".wav"
            )

            table.insert(
                data.outputs.residual,
                basename(data.full_path[i]) .. "_ts-r_" .. uuid(i) .. ".wav"
            )

            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. doublequote(data.full_path[i]) .. 
                " -transients " .. doublequote(data.outputs.transients[i]) .. 
                " -residual " .. doublequote(data.outputs.residual[i]) .. 
                " -order " .. order .. 
                " -blocksize " .. blocksize .. 
                " -padsize " .. padsize .. 
                " -skew " .. skew .. 
                " -threshfwd " .. threshfwd .. 
                " -threshback " .. threshback ..
                " -windowsize " .. windowsize .. 
                " -clumplength " .. clumplength ..
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
        reaper.Undo_EndBlock("transients", 0)
    end
end
::exit::
