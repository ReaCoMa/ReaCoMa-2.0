local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "../FluidPlumbing/" .. "fluidUtils.lua")
dofile(script_path .. "../FluidPlumbing/" .. "fluidParams.lua")
dofile(script_path .. "../FluidPlumbing/" .. "fluidTagging.lua")

if sanity_check() == false then goto exit; end
local anal_exe = doublequote(get_fluid_path() .. "/fluid-loudness")
local stats_exe = doublequote(get_fluid_path() .. "/fluid-stats")

local num_selected_items = reaper.CountSelectedMediaItems(0)
    if num_selected_items > 0 then
        data = TaggingContainer

        for i=1, num_selected_items do
            get_tag_data(i, data)
            
            local analcmd = anal_exe ..
            " -source " .. doublequote(data.full_path[i]) ..
            " -features " .. doublequote(data.analtmp[i]) ..
            " -windowsize " .. "17640" ..
            " -hopsize " .. "4410"
            table.insert(data.analcmd, analcmd)
            
            local statscmd = stats_exe ..
            " -source " .. doublequote(data.analtmp[i]) ..
            " -stats " .. doublequote(data.statstmp[i])
            table.insert(data.statscmd, statscmd)
        end

        for i=1, num_selected_items do
            cmdline(data.analcmd[i])
            cmdline(data.statscmd[i])

            local channel1 = linesplit(
                readfile(data.statstmp[i])
            )[1]

            local analysis_data = commasplit(channel1) -- whatver your numbers are basically

            update_notes(data.item[i], "-- Loudness Analysis --")
            local details = "Average: " .. analysis_data[1] .. "\r\n" ..
            "Min: " .. analysis_data[5] .. "\r\n" ..
            "Max: " .. analysis_data[7] .. "\r\n" ..
            "Median: " .. analysis_data[6] .. "\r\n"
            update_notes(data.item[i], details)
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("TagLoudness", 0)
        cleanup(data.analtmp)
        cleanup(data.statstmp)
    end
::exit::