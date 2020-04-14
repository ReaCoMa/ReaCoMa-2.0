local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../lib/reacoma.lua")()

if reacoma.paths.sanity_check() == false then return end
local cli_path = reacoma.paths.get_fluid_path()
local descr_exe = reacoma.utils.doublequote(cli_path .. "/fluid-loudness")
local stats_exe = reacoma.utils.doublequote(cli_path .. "/fluid-stats")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.experimental.loudness_sort
    reacoma.params.check_params(processor)
    local param_names = "windowsize,hopsize"
    local param_values = reacoma.params.parse_params(param_names, processor)
    local confirm, user_inputs = reaper.GetUserInputs("Sort by Loudness", 2, param_names, param_values)

    if confirm then
        reacoma.params.store_params(processor, param_names, user_inputs)
        reaper.Undo_BeginBlock()
        local params = reacoma.utils.commasplit(user_inputs)
        local windowsize = params[1]
        local hopsize = params[2]

        local data = reacoma.sorting.container

        for i=1, num_selected_items do
            reacoma.sorting.get_data(i, data)

            local descr_cmd = descr_exe .. 
            " -source " .. reacoma.utils.doublequote(data.full_path[i]) .. 
            " -features " .. reacoma.utils.doublequote(data.tmp_descr[i]) .. 
            " -windowsize " ..  windowsize ..
            " -hopsize " .. hopsize ..
            " -startframe " .. data.take_ofs_samples[i] ..
            " -numframes " .. data.item_len_samples[i]
            table.insert(data.descr_cmd, descr_cmd)

            local stats_cmd = stats_exe .. 
            " -source " .. reacoma.utils.doublequote(data.tmp_descr[i]) .. 
            " -stats " .. reacoma.utils.doublequote(data.tmp_stats[i]) ..
            " -numderivs 0"

            table.insert(data.stats_cmd, stats_cmd)
        end

        for i=1, num_selected_items do
            reacoma.utils.cmdline(data.descr_cmd[i])
            reacoma.utils.cmdline(data.stats_cmd[i])
        end
        
        -- Extract descriptor data and store as a table --
        -- This part here is not generic and can change for each process --
        -- The extracted data has to end up in the descriptor_data table of the container --
        for i=1, num_selected_items do
            local temporary_stats = {}

            for line in io.lines(data.tmp_stats[i]) do
                table.insert(temporary_stats, reacoma.utils.commasplit(line))
            end
        
            -- Take the median of every channel --
            -- if there is more than 1 average the medians --
            local accum = 0
            -- local lookup = (1 * 7) - 6
            -- TODO Work on multichannel files by averaging medians
            local lookup = temporary_stats[1][6]
            table.insert(data.descriptor_data, tonumber(lookup))
        end

        -- Sort the table --
        for k, v in reacoma.utils.spairs(data.descriptor_data, function(t,a,b) return t[a] < t[b] end) do
            table.insert(data.sorted_items, k)
        end

        -- CONTIGUOUS ITEMS MODE --
        -- This can eventually just be merged with the above function
        accum_offset = data.item_pos[1]
        
        for i=1, #data.sorted_items do
            
            local index = data.sorted_items[i]
            local item = data.item[index]
            local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", accum_offset)
            accum_offset = accum_offset + len
        end

        -- POSITION REPLACEMENT MODE --
        -- for i=1, #sorted_items do
            
        --     local index = sorted_items[i]
        --     local item = item_t[index]
        --     local unordered_pos = item_pos_t[i]
            
        --     reaper.SetMediaItemInfo_Value(item, "D_POSITION", unordered_pos)
        -- end

        reacoma.utils.cleanup(data.tmp_descr)
        reacoma.utils.cleanup(data.tmp_stats)

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("CentroidSort", 0)
    end
end

