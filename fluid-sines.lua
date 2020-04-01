local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "/FluidPlumbing/FluidLayers.lua")

if FluidPaths.sanity_check() == false then goto exit; end
local exe = FluidUtils.doublequote(FluidPaths.get_fluid_path() .. "/fluid-sines")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    
    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.sines
    FluidParams.check_params(processor)
    local param_names = "birthhighthreshold,birthlowthreshold,detectionthreshold,trackfreqrange,trackingmethod,trackmagrange,trackprob,bandwidth,fftsettings,mintracklen"
    local param_values = FluidParams.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Sines Parameters", 10, param_names, param_values)
    if confirm then 
        FluidParams.store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = FluidUtils.commasplit(user_inputs)
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

        local data = FluidLayers.container

        data.outputs = {
            sines = {},
            residual = {}
        }

        for i=1, num_selected_items do
            FluidLayers.get_data(i, data)

            table.insert(
                data.outputs.sines,
                FluidUtils.basename(data.full_path[i]) .. "_sines-s_" .. FluidUtils.uuid(i) .. ".wav"
            )

            table.insert(
                data.outputs.residual,
                FluidUtils.basename(data.full_path[i]) .. "_sines-r_" .. FluidUtils.uuid(i) .. ".wav"
            )
            
            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. FluidUtils.doublequote(data.full_path[i]) .. 
                " -sines " .. FluidUtils.doublequote(data.outputs.sines[i]) .. 
                " -residual " .. FluidUtils.doublequote(data.outputs.residual[i]) .. 
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
            FluidUtils.cmdline(data.cmd[i])
        end

        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            FluidLayers.perform_layers(i, data)
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("FluidSines", 0)
    end
end
::exit::
