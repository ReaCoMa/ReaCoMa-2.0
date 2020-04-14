local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "../FluidPlumbing/FluidUtils.lua")

if sanity_check() == false then return end
local cli_path = reacoma.paths.get_reacoma_path()
--   Then we form some calls to the tools that will live in that folder --
local ss_exe = doublequote(cli_path .. "/fluid-spectralshape")
local st_exe = doublequote(cli_path .. "/fluid-stats")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    local captions = "operator,centroid,fftsettings"
    local caption_defaults = ">,500,2048 -1 -1"
    local confirm, user_inputs = reaper.GetUserInputs("Configuration", 3, captions, caption_defaults)
    if confirm then 
        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = reacoma.utils.commasplit(user_inputs)
        local operator = params[1]
        local centroid = tonumber(params[2])
        local fftsettings = params[3]

        -- Create storage --
        local item_t = {} -- table of selected items
        local ss_cmd_t = {} -- command line arguments for spectralshape
        local st_cmd_t = {} -- command line arguments for stats
        local chans_t = {}
        local centroid_t = {} -- centroid data   
        local string_data_t = {} -- all the output data as raw strings   
        local tmp_file_t = {} -- annoying tmp files made by os.tmpname()
        local tmp_anal_t = {} -- analysis files made by processor (spectralshape, loudness)
        local tmp_stat_t = {} -- stats files made by fluid.bufstats~
        local full_path_t = {} -- full paths to media items
        local shape_t = {}

        for i=1, num_selected_items do
            local tmp_file = os.tmpname()
            local tmp_anal = tmp_file .. "anal" .. ".wav"
            local tmp_stat = tmp_file .. "stat" .. ".csv"
            table.insert(tmp_file_t, tmp_file)
            table.insert(tmp_anal_t, tmp_anal)
            table.insert(tmp_stat_t, tmp_stat)

            local item = reaper.GetSelectedMediaItem(0, i-1)
            local take = reaper.GetActiveTake(item)
            local src = reaper.GetMediaItemTake_Source(take)
            local full_path = reaper.GetMediaSourceFileName(src, '')
            local sr = reaper.GetMediaSourceSampleRate(src)
            
            table.insert(chans_t, reaper.GetMediaSourceNumChannels(src))
            table.insert(item_t, item)
            table.insert(full_path_t, full_path)

            local take_ofs = stosamps(reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS"), sr)
            local item_len = stosamps(reaper.GetMediaItemInfo_Value(item, "D_LENGTH"), sr)

            local ss_cmd = ss_exe .. 
            " -source " .. doublequote(full_path) .. 
            " -features " .. doublequote(tmp_anal) .. 
            " -fftsettings " .. fftsettings .. 
            " -numframes " .. item_len .. 
            " -startframe " .. take_ofs

            local st_cmd = st_exe .. 
            " -source " .. doublequote(tmp_anal) .. 
            " -stats " .. doublequote(tmp_stat) 

            table.insert(ss_cmd_t, ss_cmd)
            table.insert(st_cmd_t, st_cmd)
        end

        -- Fill the table with data --
        for i=1, num_selected_items do
            os.execute(ss_cmd_t[i])
            os.execute(st_cmd_t[i])
        end
        
        -- Convert the CSV into a table --
        for i=1, num_selected_items do
            temporary_stats = {}

            for line in io.lines(tmp_stat_t[i]) do
                table.insert(temporary_stats, statstotable(line))
            end

            -- Take the median of every channel --
            -- if there is more than 1 average the medians --
            local accum = 0
            for j=1, chans_t[i] do --loop over the amount of channels
                local lookup = (j * 7) - 6
                accum = accum + temporary_stats[lookup][6]
            end
            accum = accum / chans_t[i]
            table.insert(centroid_t, accum)
        end

        -- Selection logic --
        for i=1, num_selected_items do
            reaper.SetMediaItemSelected(item_t[i], matchers[operator](centroid_t[i], centroid))
        end

        -- Cleanup --
        for i=1, num_selected_items do
            remove_file(tmp_file_t[i])
            remove_file(tmp_anal_t[i])
            remove_file(tmp_stat_t[i])
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("CentroidSelect", 0)
    end
end

