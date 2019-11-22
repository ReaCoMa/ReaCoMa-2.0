local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")

--------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local fl_suf = cli_path .. "/fluid-loudness"
local fl_exe = doublequote(fl_suf)
local st_suf = cli_path .. "/fluid-stats"
local st_exe = doublequote(st_suf)
------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items ~= 0 then
    local captions = "operator,amp (dB),windowsize,hopsize,kweighting,truepeak"
    local caption_defaults = ">,-24,1024,512,1,1"
    local confirm, user_inputs = reaper.GetUserInputs("Configuration", 6, captions, caption_defaults)
    if confirm then 
        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local operator = params[1]
        local loudness = tonumber(params[2])
        local windowsize = params[3]
        local hopsize = params[4]
        local kweighting = params[5]
        local truepeak = params[6]
        
        -- Create storage --
        local item_t = {} -- table of selected items
        local fl_cmd_t = {} -- command line arguments for spectralshape
        local st_cmd_t = {} -- command line arguments for stats
        chans_t = {}
        loudness_t = {} -- centroid data   
        local string_data_t = {} -- all the output data as raw strings   
        local tmp_file_t = {} -- annoying tmp files made by os.tmpname()
        local tmp_anal_t = {} -- analysis files made by processor
        local tmp_stat_t = {} -- stats files made by fluid.bufstats~
        local full_path_t = {} -- full paths to media items
        shape_t = {}

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

            local fl_cmd = fl_exe .. 
            " -source " .. doublequote(full_path) .. 
            " -features " .. doublequote(tmp_anal) .. 
            " -windowsize " .. windowsize .. 
            " -hopsize " .. hopsize ..
            " -kweighting " .. kweighting ..
            " -truepeak " .. truepeak

            local st_cmd = st_exe .. 
            " -source " .. doublequote(tmp_anal) .. 
            " -stats " .. doublequote(tmp_stat) 

            table.insert(fl_cmd_t, fl_cmd)
            table.insert(st_cmd_t, st_cmd)
        end

        -- Fill the table with data --
        for i=1, num_selected_items do
            os.execute(fl_cmd_t[i])
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
            -- local lookup = (1 * 7) - 6
            local lookup = temporary_stats[1][6]
            table.insert(loudness_t, lookup)
        end

        -- Selection logic --
        for i=1, num_selected_items do
            reaper.SetMediaItemSelected(item_t[i], matchers[operator](loudness_t[i], loudness))
        end

        -- Cleanup --
        for i=1, num_selected_items do
            remove_file(tmp_file_t[i])
            remove_file(tmp_anal_t[i])
            remove_file(tmp_stat_t[i])
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("LoudnessSelect", 0)
    end
end
::exit::
