local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "/FluidPlumbing/FluidLayers.lua")

if FluidPaths.sanity_check() == false then goto exit; end
local exe = FluidUtils.doublequote(FluidPaths.get_fluid_path() .. "/fluid-hpss")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.hpss
    FluidParams.check_params(processor)
    local param_names = "harmfiltersize,percfiltersize,maskingmode,fftsettings,harmthresh,percthresh"
    local param_values = FluidParams.parse_params(param_names, processor)
    
    local confirm, user_inputs = reaper.GetUserInputs("HPSS Parameters", 6, param_names, param_values)
    if confirm then 
        FluidParams.store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = FluidUtils.commasplit(user_inputs)
        local hfs = params[1]
        local pfs = params[2]
        local maskingmode = params[3]
        local fftsettings = params[4]
        local hthresh = params[5]
        local pthresh = params[6]

        local data = FluidLayers.container

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

            FluidLayers.get_data(i, data)

            table.insert(
                data.outputs.harmonic,
                FluidUtils.basename(data.full_path[i]) .. "_hpss-h_" .. FluidUtils.uuid(i) .. ".wav"
            )
            table.insert(
                data.outputs.percussive,
                FluidUtils.basename(data.full_path[i]) .. "_hpss-p_" .. FluidUtils.uuid(i) .. ".wav"
            )

            if maskingmode == "2" then 
                table.insert(
                    data.outputs.residual, 
                    FluidUtils.basename(data.full_path[i]) .. "_hpss-r_" .. FluidUtils.uuid(i) .. ".wav"
                ) 
            end

            if maskingmode == "0" then
                table.insert(
                    data.cmd, 
                    exe .. 
                    " -source " .. FluidUtils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. FluidUtils.doublequote(data.outputs.harmonic[i]) .. 
                    " -percussive " .. FluidUtils.doublequote(data.outputs.percussive[i]) ..  
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
                    " -source " .. FluidUtils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. FluidUtils.doublequote(data.outputs.harmonic[i]) .. 
                    " -percussive " .. FluidUtils.doublequote(data.outputs.percussive[i]) ..  
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
                    " -source " .. FluidUtils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. FluidUtils.doublequote(data.outputs.harmonic[i]) .. 
                    " -percussive " .. FluidUtils.doublequote(data.outputs.percussive[i]) .. 
                    " -residual " .. FluidUtils.doublequote(data.outputs.residual[i]) .. 
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
            FluidUtils.cmdline(data.cmd[i])
        end

        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            FluidLayers.perform_layers(i, data)
        end
        
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("HPSS", 0)
    end
end
::exit::
