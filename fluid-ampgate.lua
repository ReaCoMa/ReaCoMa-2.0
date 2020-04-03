local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "/FluidPlumbing/FluidSlicing.lua")

if fluidPaths.sanity_check() == false then goto exit; end
local exe = fluidUtils.doublequote(fluidPaths.get_fluid_path() .. "/fluid-ampgate")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    local processor = fluid_archetype.ampgate
    fluidParams.check_params(processor)
    local param_names = "rampup,rampdown,onthreshold,offthreshold,minslicelength,minsilencelength,minlengthabove,minlengthbelow,lookback,lookahead,highpassfreq"
    param_values = fluidParams.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Ampgate Parameters", 11, param_names, param_values)
    if confirm then
        fluidParams.store_params(processor, param_names, user_inputs)
        
        reaper.Undo_BeginBlock()
        local params = fluidUtils.commasplit(user_inputs)
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

        local data = fluidSlicing.container

        for i=1, num_selected_items do
            fluidSlicing.get_data(i, data)

            local cmd = exe .. 
            " -source " .. fluidUtils.doublequote(data.full_path[i]) .. 
            " -indices " .. fluidUtils.doublequote(data.tmp[i]) ..
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
            fluidUtils.cmdline(data.cmd[i])
            var = fluidUtils.readfile(data.tmp[i])
            channel_split = fluidUtils.linesplit(var)
            onsets = fluidUtils.commasplit(channel_split[1])
            offsets = fluidUtils.commasplit(channel_split[2])
            laced = fluidUtils.lacetables(onsets, offsets)
            dumb_string = ""
            local state_state = nil
            
            if laced[1] == data.take_ofs_samples[i] then 
                start_state = 0 -- if there is a 0 at the start we start 'off/unmuted'
            else 
                start_state = 1 -- if there is something else at the start we start muted and prepend a 0
            end

            for j=1, #laced do
                dumb_string = dumb_string .. laced[j] .. ","
            end
            table.insert(data.slice_points_string, dumb_string)
            fluidSlicing.perform_gate_splitting(i, data, start_state)
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("ampgate", 0)
        fluidUtils.cleanup(data.tmp)
    end
end
::exit::
