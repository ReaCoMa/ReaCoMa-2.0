local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "../FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "../FluidPlumbing/FluidParams.lua")
dofile(script_path .. "../FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "../FluidPlumbing/FluidSorting.lua")


if fluidPaths.sanity_check() == false then return end
local cli_path = fluidPaths.get_fluid_path()
local descr_exe = fluidUtils.doublequote(cli_path .. "/fluid-spectralshape")
local stats_exe = fluidUtils.doublequote(cli_path .. "/fluid-stats")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = fluid_experimental.centroid_sort
    fluidParams.check_params(processor)
    local param_names = "fftsettings"
    local param_values = fluidParams.parse_params(param_names, processor)
    local confirm, user_inputs = reaper.GetUserInputs("Sort by Centroid", 1, param_names, param_values)

    if confirm then
        fluidParams.store_params(processor, param_names, user_inputs)
        reaper.Undo_BeginBlock()
        local params = fluidUtils.commasplit(user_inputs)
        local fftsettings = params[1]

        local data = fluidSorting.container

        for i=1, num_selected_items do
            fluidSorting.get_data(i, data)

            local descr_cmd = descr_exe .. 
            " -source " .. fluidUtils.doublequote(data.full_path[i]) .. 
            " -features " .. fluidUtils.doublequote(data.tmp_descr[i]) .. 
            " -fftsettings " .. fftsettings ..
            " -startframe " .. data.take_ofs_samples[i] ..
            " -numframes " .. data.item_len_samples[i]
            table.insert(data.descr_cmd, descr_cmd)

            local stats_cmd = stats_exe .. 
            " -source " .. fluidUtils.doublequote(data.tmp_descr[i]) .. 
            " -stats " .. fluidUtils.doublequote(data.tmp_stats[i]) ..
            " -numderivs 0"

            table.insert(data.stats_cmd, stats_cmd)
        end

        for i=1, num_selected_items do
            fluidUtils.cmdline(data.descr_cmd[i])
            fluidUtils.cmdline(data.stats_cmd[i])
        end
        
        -- Extract descriptor data and store as a table --
        -- This part here is not generic and can change for each process --
        -- The extracted data has to end up in the descriptor_data table of the container --
        for i=1, num_selected_items do
            local temporary_stats = {}

            for line in io.lines(data.tmp_stats[i]) do
                table.insert(temporary_stats, fluidUtils.statstotable(line))
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
        for k, v in fluidUtils.spairs(data.descriptor_data, function(t,a,b) return t[a] < t[b] end) do
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

        fluidUtils.cleanup(data.tmp_descr)
        fluidUtils.cleanup(data.tmp_stats)

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("CentroidSort", 0)
    end
end

