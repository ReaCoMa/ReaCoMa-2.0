local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.doublequote(
    reacoma.settings.path .. "/fluid-ampslice"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.archetype.ampslice
    reacoma.params.check_params(processor)
    local param_names = "fastrampup,fastrampdown,slowrampup,slowrampdown,onthreshold,offthreshold,floor,minslicelength,highpassfreq"
    local param_values = reacoma.params.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Ampslice Parameters", 9, param_names, param_values)
    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)

        local params = reacoma.utils.commasplit(user_inputs)
        local fastrampup = params[1]
        local fastrampdown = params[2]
        local slowrampup = params[3]
        local slowrampdown = params[4]
        local onthreshold = params[5]
        local offthreshold = params[6]
        local floor = params[7]
        local minslicelength = params[8]
        local highpassfreq = params[9]

        local data = reacoma.slicing.container

        for i=1, num_selected_items do
            reacoma.slicing.get_data(i, data)

            local cmd = exe .. 
            " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
            " -indices " .. reacoma.utils.doublequote(data.tmp[i]) .. 
            " -fastrampup " .. fastrampup ..
            " -fastrampdown " .. fastrampdown ..
            " -slowrampup " .. slowrampup ..
            " -slowrampdown " .. slowrampdown ..
            " -onthreshold " .. onthreshold ..
            " -offthreshold " .. offthreshold ..
            " -floor " .. floor ..
            " -minslicelength " .. minslicelength ..
            " -highpassfreq " .. highpassfreq ..
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
            table.insert(data.cmd, cmd)
        end

        for i=1, num_selected_items do
            local cliret = reacoma.utils.cmdline(data.cmd[i])
            if cliret then
                if reaper.file_exists(data.tmp[i]) then
                    table.insert(data.slice_points_string, reacoma.utils.readfile(data.tmp[i]))
                    reacoma.slicing.process(i, data)
                else
                    reaper.ShowConsoleMsg("There was no CSV file to read for:\n"..data.full_path[i].."\n".."Selected file number: "..i.."\n")
                    reaper.ShowConsoleMsg("-----------------------------")
                end
            end
        end

        reacoma.utils.arrange("reacoma-ampslice")
        reacoma.utils.cleanup(data.tmp)
    end
end

