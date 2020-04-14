local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "../" .. "FluidUtils.lua")
dofile(script_path .. "../" .. "FluidParams.lua")

--------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then return end
local cli_path = reacoma.paths.get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local fl_suf = cli_path .. "/fluid-loudness"
local fl_exe = doublequote(fl_suf)
local st_suf = cli_path .. "/fluid-stats"
local st_exe = doublequote(st_suf)
------------------------------------------------------------------------------------
local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = fluid_multitype.loudness_filter
    check_params(processor)
    local param_names = "operator,threshold,hopsize,windowsize,kweighting,truepeak"
    local param_values = parse_params(param_names, processor)
    local confirm, user_inputs = reaper.GetUserInputs("Filter by Loudness", 6, param_names, param_values)

    if confirm then 
        store_params(processor, param_names, user_inputs)
        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = reacoma.utils.commasplit(user_inputs)
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
        local chans_t = {}
        local loudness_t = {} -- centroid data   
        local string_data_t = {} -- all the output data as raw strings   
        local tmp_file_t = {} -- annoying tmp files made by os.tmpname()
        local tmp_anal_t = {} -- analysis files made by processor
        local tmp_stat_t = {} -- stats files made by fluid.bufstats~

        for i=1, num_selected_items do
            local tmp_file = os.tmpname()
            local tmp_anal = tmp_file .. uuid(i) .. "anal" .. ".wav"
            local tmp_stat = tmp_file .. uuid(i) .. "stat" .. ".csv"
            table.insert(tmp_file_t, tmp_file)
            table.insert(tmp_anal_t, tmp_anal)
            table.insert(tmp_stat_t, tmp_stat)

            local item = reaper.GetSelectedMediaItem(0, i-1)
            local take = reaper.GetActiveTake(item)
            local src = reaper.GetMediaItemTake_Source(take)
            local full_path = reaper.GetMediaSourceFileName(src, "")
            local sr = reaper.GetMediaSourceSampleRate(src)
            
            table.insert(chans_t, reaper.GetMediaSourceNumChannels(src))
            table.insert(item_t, item)

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
            cmdline(fl_cmd_t[i])
            cmdline(st_cmd_t[i])
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
        cleanup(tmp_file_t)
        cleanup(tmp_anal_t)
        cleanup(tmp_stat_t)

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("LoudnessSelect", 0)
    end
end

