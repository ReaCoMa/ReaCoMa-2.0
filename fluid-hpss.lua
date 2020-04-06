local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "FluidPlumbing/FluidParams.lua")
dofile(script_path .. "FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "FluidPlumbing/fluidLayers.lua")

if fluidPaths.sanity_check() == false then goto exit; end
local exe = fluidUtils.doublequote(fluidPaths.get_fluid_path() .. "/fluid-hpss")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = fluid_archetype.hpss
    fluidParams.check_params(processor)
    local param_names = "harmfiltersize,percfiltersize,maskingmode,fftsettings,harmthresh,percthresh"
    local param_values = fluidParams.parse_params(param_names, processor)
    
    local confirm, user_inputs = reaper.GetUserInputs("HPSS Parameters", 6, param_names, param_values)
    if confirm then 
        fluidParams.store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        local params = fluidUtils.commasplit(user_inputs)
        local hfs = params[1]
        local pfs = params[2]
        local maskingmode = params[3]
        local fftsettings = params[4]
        local hthresh = params[5]
        local pthresh = params[6]

        local data = fluidLayers.container

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

            fluidLayers.get_data(i, data)

            table.insert(
                data.outputs.harmonic,
                fluidUtils.basename(data.full_path[i]) .. "_hpss-h_" .. fluidUtils.uuid(i) .. ".wav"
            )
            table.insert(
                data.outputs.percussive,
                fluidUtils.basename(data.full_path[i]) .. "_hpss-p_" .. fluidUtils.uuid(i) .. ".wav"
            )

            if maskingmode == "2" then 
                table.insert(
                    data.outputs.residual, 
                    fluidUtils.basename(data.full_path[i]) .. "_hpss-r_" .. fluidUtils.uuid(i) .. ".wav"
                ) 
            end

            if maskingmode == "0" then
                table.insert(
                    data.cmd, 
                    exe .. 
                    " -source " .. fluidUtils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. fluidUtils.doublequote(data.outputs.harmonic[i]) .. 
                    " -maxfftsize " .. fluidUtils.getmaxfftsize(fftsettings) ..
                    " -maxharmfiltersize " .. hfs ..
                    " -maxpercfiltersize " .. pfs ..
                    " -percussive " .. fluidUtils.doublequote(data.outputs.percussive[i]) ..  
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
                    " -source " .. fluidUtils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. fluidUtils.doublequote(data.outputs.harmonic[i]) ..
                    " -maxfftsize " .. fluidUtils.getmaxfftsize(fftsettings) ..
                    " -maxharmfiltersize " .. hfs ..
                    " -maxpercfiltersize " .. pfs .. 
                    " -percussive " .. fluidUtils.doublequote(data.outputs.percussive[i]) ..  
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
                    " -source " .. fluidUtils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. fluidUtils.doublequote(data.outputs.harmonic[i]) ..
                    " -maxfftsize " .. fluidUtils.getmaxfftsize(fftsettings) ..
                    " -maxharmfiltersize " .. hfs ..
                    " -maxpercfiltersize " .. pfs .. 
                    " -percussive " .. fluidUtils.doublequote(data.outputs.percussive[i]) .. 
                    " -residual " .. fluidUtils.doublequote(data.outputs.residual[i]) .. 
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
            fluidUtils.cmdline(data.cmd[i])
        end

        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            fluidLayers.perform_layers(i, data)
        end
        
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("HPSS", 0)
    end
end
::exit::
