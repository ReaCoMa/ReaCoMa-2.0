local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../lib/reacoma.lua")()

if reacoma.paths.sanity_check() == false then return end
local anal_exe = reacoma.utils.doublequote(reacoma.paths.get_fluid_path() .. "/fluid-loudness")
local stats_exe = reacoma.utils.doublequote(reacoma.paths.get_fluid_path() .. "/fluid-stats")

local num_selected_items = reaper.CountSelectedMediaItems(0)
    if num_selected_items > 0 then
        local data = reacoma.tagging.container

        for i=1, num_selected_items do
            reacoma.tagging.get_data(i, data)
            
            local analcmd = anal_exe ..
            " -source " .. reacoma.utils.doublequote(data.full_path[i]) ..
            " -features " .. reacoma.utils.doublequote(data.analtmp[i]) ..
            " -windowsize " .. "17640" ..
            " -hopsize " .. "4410"
            table.insert(data.analcmd, analcmd)
            
            local statscmd = stats_exe ..
            " -source " .. reacoma.utils.doublequote(data.analtmp[i]) ..
            " -stats " .. reacoma.utils.doublequote(data.statstmp[i])
            table.insert(data.statscmd, statscmd)
        end

        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.analcmd[i])
            reacoma.utils.cmdline(data.statscmd[i])

            local channel1 = reacoma.utils.linesplit(
                reacoma.utils.readfile(data.statstmp[i])
            )[1]

            local analysis_data = reacoma.utils.commasplit(channel1) -- whatver your numbers are basically

            reacoma.tagging.update_notes(data.item[i], "-- Loudness Analysis --")
            local details = "Average: " .. analysis_data[1] .. "\r\n" ..
            "Min: " .. analysis_data[5] .. "\r\n" ..
            "Max: " .. analysis_data[7] .. "\r\n" ..
            "Median: " .. analysis_data[6] .. "\r\n"
            reacoma.tagging.update_notes(data.item[i], details)
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("TagLoudness", 0)
        reacoma.utils.cleanup(data.analtmp)
        reacoma.utils.cleanup(data.statstmp)
    end
