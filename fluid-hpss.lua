local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-hpss"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.archetype.hpss
    reacoma.params.check_params(processor)
    local param_names = "harmfiltersize,percfiltersize,maskingmode,fftsettings,harmthresh,percthresh"
    local param_values = reacoma.params.parse_params(param_names, processor)
    
    local confirm, user_inputs = reaper.GetUserInputs("HPSS Parameters", 6, param_names, param_values)
    if confirm then 
        reacoma.params.store_params(processor, param_names, user_inputs)

        local params = reacoma.utils.commasplit(user_inputs)
        local hfs = params[1]
        local pfs = params[2]
        local maskingmode = params[3]
        local fftsettings = params[4]
        local hthresh = params[5]
        local pthresh = params[6]

        local data = reacoma.layers.container

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

            reacoma.layers.get_data(i, data)

            table.insert(
                data.outputs.harmonic,
                reacoma.utils.basename(data.full_path[i]) .. "_hpss-h_" .. reacoma.utils.uuid(i) .. ".wav"
            )
            table.insert(
                data.outputs.percussive,
                reacoma.utils.basename(data.full_path[i]) .. "_hpss-p_" .. reacoma.utils.uuid(i) .. ".wav"
            )

            if maskingmode == "2" then 
                table.insert(
                    data.outputs.residual, 
                    reacoma.utils.basename(data.full_path[i]) .. "_hpss-r_" .. reacoma.utils.uuid(i) .. ".wav"
                ) 
            end

            if maskingmode == "0" then
                table.insert(
                    data.cmd, 
                    exe .. 
                    " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. reacoma.utils.doublequote(data.outputs.harmonic[i]) .. 
                    " -maxfftsize " .. reacoma.utils.getmaxfftsize(fftsettings) ..
                    " -maxharmfiltersize " .. hfs ..
                    " -maxpercfiltersize " .. pfs ..
                    " -percussive " .. reacoma.utils.doublequote(data.outputs.percussive[i]) ..  
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
                    " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. reacoma.utils.doublequote(data.outputs.harmonic[i]) ..
                    " -maxfftsize " .. reacoma.utils.getmaxfftsize(fftsettings) ..
                    " -maxharmfiltersize " .. hfs ..
                    " -maxpercfiltersize " .. pfs .. 
                    " -percussive " .. reacoma.utils.doublequote(data.outputs.percussive[i]) ..  
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
                    " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
                    " -harmonic " .. reacoma.utils.doublequote(data.outputs.harmonic[i]) ..
                    " -maxfftsize " .. reacoma.utils.getmaxfftsize(fftsettings) ..
                    " -maxharmfiltersize " .. hfs ..
                    " -maxpercfiltersize " .. pfs .. 
                    " -percussive " .. reacoma.utils.doublequote(data.outputs.percussive[i]) .. 
                    " -residual " .. reacoma.utils.doublequote(data.outputs.residual[i]) .. 
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
        
        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.cmd[i])
            reacoma.layers.exist(i, data)
        end

        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            reacoma.layers.process(i, data)
        end
        
        reacoma.utils.arrange("reacoma-hpss")
    end
end

