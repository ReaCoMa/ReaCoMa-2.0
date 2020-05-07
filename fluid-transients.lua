local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-transients"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    
    local processor = reacoma.params.archetype.transients
    reacoma.params.check_params(processor)
    local param_names = "order,blocksize,padsize,skew,threshfwd,threshback,windowsize,clumplength"
    local param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Transients Parameters", 8, param_names, param_values)
    if confirm then 
        reacoma.params.store_params(processor, param_names, user_inputs)
        
        local params = reacoma.utils.commasplit(user_inputs)
        local order = params[1]
        local blocksize = params[2]
        local padsize = params[3]
        local skew = params[4]
        local threshfwd = params[5]
        local threshback = params[6]
        local windowsize = params[7]
        local clumplength = params[8]

        local data = reacoma.layers.container

        data.outputs = {
            transients = {},
            residual = {}
        }

        for i=1, num_selected_items do

            reacoma.layers.get_data(i, data)

            table.insert(
                data.outputs.transients,
                reacoma.utils.basename(data.full_path[i]) .. "_ts-t_" .. reacoma.utils.uuid(i) .. ".wav"
            )

            table.insert(
                data.outputs.residual,
                reacoma.utils.basename(data.full_path[i]) .. "_ts-r_" .. reacoma.utils.uuid(i) .. ".wav"
            )

            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
                " -transients " .. reacoma.utils.doublequote(data.outputs.transients[i]) .. 
                " -residual " .. reacoma.utils.doublequote(data.outputs.residual[i]) ..
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
            reacoma.utils.cmdline(data.cmd[i])
        end

        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do  
            reacoma.layers.process(i, data)
        end

        reacoma.utils.arrange("reacoma-transients")
    end
end

