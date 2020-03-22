local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/" .. "FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidLayers.lua")
dofile(script_path .. "/FluidPlumbing/" .. "OrderedTables.lua")

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local suf = cli_path .. "/fluid-hpss"
local exe = doublequote(suf)
------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.hpss
    check_params(processor)
    local param_names = "harmfiltersize,percfiltersize,maskingmode,fftsettings,harmthresh,percthresh"
    local param_values = parse_params(param_names, processor)
    
    local confirm, user_inputs = reaper.GetUserInputs("HPSS Parameters", 6, param_names, param_values)
    if confirm then 
        store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local hfs = params[1]
        local pfs = params[2]
        local maskingmode = params[3]
        local fftsettings = params[4]
        local hthresh = params[5]
        local pthresh = params[6]

        data = LayersContainer

        -- Set up the outputs
        if maskingmode == "0" or maskingmode == "1" then
            data.outputs = {
                harmonic = {},
                percussive = {},
            }
        else
            data.outputs = {
                harmonic = {},
                percussive = {},
                residual = {},
            }
        end

        for i=1, num_selected_items do

            get_layers_data(i, data)

            table.insert(
                data.outputs.harmonic,
                basename(data.full_path[i]) .. "_hpss-h_" .. uuid(i) .. ".wav"
            )
            table.insert(
                data.outputs.percussive,
                basename(data.full_path[i]) .. "_hpss-p_" .. uuid(i) .. ".wav"
            )

            if maskingmode == "2" then 
                table.insert(
                    data.outputs.residual, 
                    basename(data.full_path[i]) .. "_hpss-r_" .. uuid(i) .. ".wav"
                ) 
            end

            if maskingmode == "0" then
                table.insert(
                    data.cmd, 
                    exe .. 
                    " -source " .. data.full_path[i] .. 
                    " -harmonic " .. data.outputs.harmonic[i] .. 
                    " -percussive " .. data.outputs.percussive[i] ..  
                    " -harmfiltersize " .. hfs .. 
                    " -percfiltersize " .. pfs .. 
                    " -maskingmode " .. maskingmode ..
                    " -fftsettings " .. fftsettings .. 
                    " -numframes " .. data.item_len_samples[i] .. 
                    " -startframe " .. data.take_ofs_samples[i]
                )
            end

            if maskingmode == "1" then
                table.insert(
                    data.cmd, 
                    exe .. 
                    " -source " .. doublequote(data.full_path[i]) .. 
                    " -harmonic " .. doublequote(data.outputs.harmonic[i]) .. 
                    " -percussive " .. doublequote(data.outputs.percussive[i]) ..  
                    " -harmfiltersize " .. hfs .. 
                    " -percfiltersize " .. pfs .. 
                    " -maskingmode " .. maskingmode .. 
                    " -harmthresh " .. hthresh ..
                    " -fftsettings " .. fftsettings .. 
                    " -numframes " .. data.item_len_samples[i] .. 
                    " -startframe " .. data.take_ofs_samples[i]
                )
            end
            
            if maskingmode == "2" then
                table.insert(
                    data.cmd, 
                    exe .. 
                    " -source " .. doublequote(data.full_path[i]) .. 
                    " -harmonic " .. doublequote(data.outputs.harmonic[i]) .. 
                    " -percussive " .. doublequote(data.outputs.percussive[i]) .. 
                    " -residual " .. doublequote(data.outputs.residual[i]) .. 
                    " -harmfiltersize " .. hfs .. 
                    " -percfiltersize " .. pfs .. 
                    " -maskingmode " .. maskingmode .. 
                    " -harmthresh " .. hthresh .. 
                    " -percthresh " .. pthresh ..
                    " -fftsettings " .. fftsettings .. 
                    " -numframes " .. data.item_len_samples[i] .. 
                    " -startframe " .. data.take_ofs_samples[i]
                )
            end
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
        reaper.Undo_EndBlock("HPSS", 0)
    end
end
::exit::
