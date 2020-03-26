local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/" .. "FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidTagging.lua")

if sanity_check() == false then goto exit; end
local loudness_exe = doublequote(get_fluid_path() .. "/fluid-loudness")
local stats_exe = doublequote(get_fluid_path() .. "/fluid-stats")

local num_selected_items = reaper.CountSelectedMediaItems(0)
    if num_selected_items > 0 then
        data = TaggingContainer

        for i=1, num_selected_items do
            get_tag_data(i, data)
            
            local analcmd = loudness_exe ..
            " -source " .. doublequote(data.full_path[i]) ..
            " -features " .. doublequote(data.analtmp[i])
            table.insert(data.analcmd, analcmd)
            
            local statscmd = stats_exe ..
            " -source " .. doublequote(data.analtmp[i]) ..
            " -stats " .. doublequote(data.statstmp[i])
            table.insert(data.statscmd, statscmd)
        end

        for i=1, num_selected_items do
            cmdline(data.analcmd[i])
            cmdline(data.statscmd[i])
            local loudness = commasplit(
                readfile(data.statstmp[i])
            )
            update_notes(data.item[i], "-- Loudness Analysis --")
            local details = 
            "Average: " .. loudness[1] .. "\r\n" ..
            "Min: " .. loudness[5] .. "\r\n" ..
            "Max: " .. loudness[7] .. "\r\n" ..
            "Median: " .. loudness[6]
            update_notes(data.item[i], details)
        end
    end

::exit::