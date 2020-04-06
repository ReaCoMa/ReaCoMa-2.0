local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "FluidPlumbing/FluidParams.lua")
dofile(script_path .. "FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "FluidPlumbing/FluidLayers.lua")

if fluidPaths.sanity_check() == false then goto exit; end
local exe = fluidUtils.doublequote(fluidPaths.get_fluid_path() .. "/fluid-sines")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    
    local processor = fluid_archetype.sines
    fluidParams.check_params(processor)
    local param_names = "birthhighthreshold,birthlowthreshold,detectionthreshold,trackfreqrange,trackingmethod,trackmagrange,trackprob,bandwidth,fftsettings,mintracklen"
    local param_values = fluidParams.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Sines Parameters", 10, param_names, param_values)
    if confirm then 
        fluidParams.store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        local params = fluidUtils.commasplit(user_inputs)
        local bhthresh = params[1]
        local blthresh = params[2]
        local dethresh = params[3]
        local trackfreqrange = params[4]
        local trackingmethod = params[5]
        local trackmagrange = params[6]
        local trackprob = params[7]
        local bandwidth = params[8]
        local fftsettings = params[9]
        local mintracklen = params[10]

        local data = fluidLayers.container

        data.outputs = {
            sines = {},
            residual = {}
        }

        for i=1, num_selected_items do
            fluidLayers.get_data(i, data)

            table.insert(
                data.outputs.sines,
                fluidUtils.basename(data.full_path[i]) .. "_sines-s_" .. fluidUtils.uuid(i) .. ".wav"
            )

            table.insert(
                data.outputs.residual,
                fluidUtils.basename(data.full_path[i]) .. "_sines-r_" .. fluidUtils.uuid(i) .. ".wav"
            )
            
            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. fluidUtils.doublequote(data.full_path[i]) .. 
                " -sines " .. fluidUtils.doublequote(data.outputs.sines[i]) ..
                " -maxfftsize " .. fluidUtils.getmaxfftsize(fftsettings) ..
                " -residual " .. fluidUtils.doublequote(data.outputs.residual[i]) .. 
                " -birthhighthreshold " .. bhthresh ..
                " -birthlowthreshold " .. blthresh ..
                " -detectionthreshold " .. dethresh ..
                " -trackfreqrange " .. trackfreqrange ..
                " -trackingmethod " .. trackingmethod ..
                " -trackmagrange " .. trackmagrange ..
                " -trackprob " .. trackprob ..
                " -bandwidth " .. bandwidth ..
                " -fftsettings " .. fftsettings ..
                " -mintracklen " .. mintracklen ..
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
        reaper.Undo_EndBlock("fluidSines", 0)
    end
end
::exit::
