local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-sines"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    
    local processor = reacoma.params.archetype.sines
    reacoma.params.check_params(processor)
    local param_names = "birthhighthreshold,birthlowthreshold,detectionthreshold,trackfreqrange,trackingmethod,trackmagrange,trackprob,bandwidth,fftsettings,mintracklen"
    local param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Sines Parameters", 10, param_names, param_values)
    if confirm then 
        reacoma.params.store_params(processor, param_names, user_inputs)

        local params = reacoma.utils.commasplit(user_inputs)
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

        local data = reacoma.layers.container

        data.outputs = {
            sines = {},
            residual = {}
        }

        for i=1, num_selected_items do
            reacoma.layers.get_data(i, data)

            table.insert(
                data.outputs.sines,
                reacoma.utils.basename(data.full_path[i]) .. "_sines-s_" .. reacoma.utils.uuid(i) .. ".wav"
            )

            table.insert(
                data.outputs.residual,
                reacoma.utils.basename(data.full_path[i]) .. "_sines-r_" .. reacoma.utils.uuid(i) .. ".wav"
            )
            
            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
                " -sines " .. reacoma.utils.doublequote(data.outputs.sines[i]) ..
                " -maxfftsize " .. reacoma.utils.getmaxfftsize(fftsettings) ..
                " -residual " .. reacoma.utils.doublequote(data.outputs.residual[i]) .. 
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
            reacoma.utils.cmdline(data.cmd[i])
        end

        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            reacoma.layers.process(i, data)
        end

        reacoma.utils.arrange("reacoma-sines")
    end
end

