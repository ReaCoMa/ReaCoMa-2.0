local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.wrap_quotes(
    reacoma.settings.path .. "/fluid-ampgate"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    local processor = reacoma.params.archetype.ampgate
    reacoma.params.check_params(processor)
    local param_names = "rampup,rampdown,onthreshold,offthreshold,minslicelength,minsilencelength,minlengthabove,minlengthbelow,lookback,lookahead,highpassfreq,mute,onsetsonly"
    param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Ampgate Parameters", 13, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)
        
        local params = reacoma.utils.split_comma(user_inputs)
        local rampup = params[1]
        local rampdown = params[2]
        local onthreshold = params[3]
        local offthreshold = params[4]
        local minslicelength = params[5]
        local minsilencelength = params[6]
        local minlengthabove = params[7]
        local minlengthbelow = params[8]
        local lookback = params[9]
        local lookahead = params[10]
        local highpassfreq = params[11]
        local mute = tonumber(params[12])
        local onsetsonly = tonumber(params[13])

        local data = reacoma.slicing.container

        for i=1, num_selected_items do
            reacoma.slicing.get_data(i, data)

            local cmd = exe .. 
            " -source " .. reacoma.utils.wrap_quotes(data.full_path[i]) .. 
            " -indices " .. reacoma.utils.wrap_quotes(data.tmp[i]) ..
            " -maxsize "  .. math.max(tonumber(minlengthabove) + tonumber(lookback), math.max(tonumber(minlengthbelow),tonumber(lookahead))) ..
            " -rampup " .. rampup ..
            " -rampdown " .. rampdown ..
            " -onthreshold " .. onthreshold ..
            " -offthreshold " .. offthreshold ..
            " -minslicelength " .. minslicelength ..
            " -minsilencelength " .. minsilencelength ..
            " -minlengthabove " .. minlengthabove ..
            " -minlengthbelow " .. minlengthbelow ..
            " -lookback " .. lookback ..
            " -lookahead " .. lookahead ..
            " -highpassfreq " .. highpassfreq ..
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
            table.insert(data.cmd, cmd)
        end

        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.cmd[i])
            local raw_data = reacoma.utils.readfile(data.tmp[i])
            local channel_split = reacoma.utils.split_line(raw_data)
            local onsets = reacoma.utils.split_comma(channel_split[1])
            local offsets = reacoma.utils.split_comma(channel_split[2])
            local laced = nil
            if onsetsonly == 1 then
                laced = onsets
                mute = 0
            else 
                laced = reacoma.utils.lace_tables(onsets, offsets)
            end

            -- We reform a string which is comma-separated values
            local comma_separated_points = ''
            for j=1, #laced do
                comma_separated_points = (
                    comma_separated_points .. laced[j] .. ","
                )   
            end

            table.insert(data.slice_points_string, comma_separated_points)
            
            if mute == 1 then
                reacoma.slicing.process(i, data, 1)
            else
                reacoma.slicing.process(i, data)
            end
        end

        reacoma.utils.arrange("reacoma-ampgate")
        reacoma.utils.cleanup(data.tmp)
    end
end

