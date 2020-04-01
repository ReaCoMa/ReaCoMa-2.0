local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "../FluidPlumbing/" .. "fluidUtils.lua")
dofile(script_path .. "../FluidPlumbing/" .. "fluidParams.lua")
dofile(script_path .. "../FluidPlumbing/" .. "fluidTagging.lua")

if fluidPaths.sanity_check() == false then goto exit; end
local loudness_exe = fluidUtils.doublequote(fluidPaths.get_fluid_path() .. "/fluid-spectralshape")
local stats_exe = fluidUtils.doublequote(fluidPaths.get_fluid_path() .. "/fluid-stats")

local num_selected_items = reaper.CountSelectedMediaItems(0)
    if num_selected_items > 0 then
        local data = fluidTagging.container

        for i=1, num_selected_items do
            fluidTagging.get_data(i, data)
            
            local analcmd = loudness_exe ..
            " -source " .. fluidUtils.doublequote(data.full_path[i]) ..
            " -features " .. fluidUtils.doublequote(data.analtmp[i]) ..
            " -fftsettings " .. "4096 1024 4096"
            table.insert(data.analcmd, analcmd)
            
            local statscmd = stats_exe ..
            " -source " .. fluidUtils.doublequote(data.analtmp[i]) ..
            " -stats " .. fluidUtils.doublequote(data.statstmp[i])
            table.insert(data.statscmd, statscmd)
        end

        for i=1, num_selected_items do
            cmdline(data.analcmd[i])
            cmdline(data.statscmd[i])

            local channel1 = linesplit(
                fluidUtils.readfile(data.statstmp[i])
            )[1]

            local analysis_data = fluidUtils.commasplit(channel1) -- whatver your numbers are basically

            fluidTagging.update_notes(data.item[i], "-- Centroid Analysis --")
            local details = "Average: " .. analysis_data[1] .. "\r\n" ..
            "Min: " .. analysis_data[5] .. "\r\n" ..
            "Max: " .. analysis_data[7] .. "\r\n" ..
            "Median: " .. analysis_data[6] .. "\r\n"
            fluidTagging.update_notes(data.item[i], details)
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("TagLoudness", 0)
        fluidUtils.cleanup(data.analtmp)
        fluidUtils.cleanup(data.statstmp)
    end
::exit::