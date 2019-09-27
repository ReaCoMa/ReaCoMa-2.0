local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")

------------------------------------------------------------------------------------
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
local ie_suf = cli_path .. "/index_extractor"
local ie_exe = doublequote(ie_suf)
local ns_suf = cli_path .. "/noveltyslice"
local ns_exe = doublequote(ns_suf)
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- Some scripts specific to this kind of automatic processing --
function noveltyslice(source, indices, feature, threshold, kernelsize, filtersize, fftsettings)
    os.execute(
        ns_exe ..
        " -source " .. source ..
        " -indices " .. indices ..
        " -feature " .. feature .. 
        " -threshold " .. threshold .. 
        " -kernelsize " .. kernelsize .. 
        " -filtersize " .. filtersize .. 
        " -fftsettings " .. fftsettings)
end
------------------------------------------------------------------------------------

math.randomseed(os.clock() * 100000000000) -- random seed

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    local confirm, user_inputs = reaper.GetUserInputs("Novelty Slice Parameters", 6, "feature,threshold,kernelsize,filtersize,fftsettings,number of slices", "0,0.5,3,1,1024 512 1024,7")
    if confirm then
        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local feature = params[1]
        local threshold = params[2]
        local kernelsize = params[3]
        local filtersize = params[4]
        local fftsettings = params[5]
        local target_slices = tonumber(params[6])


        local item_pos_t = {}
        local item_len_t = {}
        local full_path_t = {}
        local item_pos_samples_t = {}
        local item_len_samples_t = {}
        local slice_points_string_t = {}
        local item_t = {}
        local sr_t = {}
        local take_ofs_t = {}
        local take_ofs_samples_t = {}

        for i=1, num_selected_items do
            local item = reaper.GetSelectedMediaItem(0, i-1)
            local take = reaper.GetActiveTake(item)
            local src = reaper.GetMediaItemTake_Source(take)
            local sr = reaper.GetMediaSourceSampleRate(src)
            local full_path = reaper.GetMediaSourceFileName(src, '')
            table.insert(item_t, item)
            table.insert(sr_t, sr)
            table.insert(full_path_t, full_path)
            
            local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            table.insert(take_ofs_t, take_ofs)
            table.insert(item_pos_t, item_pos)
            table.insert(item_len_t, item_len)
        
            -- Convert everything to samples for CLI --
            local take_ofs_samples = stosamps(take_ofs, sr)
            local item_pos_samples = stosamps(item_pos, sr)
            local item_len_samples = stosamps(item_len, sr)
            table.insert(take_ofs_samples_t, take_ofs_samples)
            table.insert(item_pos_samples_t, item_pos_samples)
            table.insert(item_len_samples_t, item_len_samples)
        end

        -- Optimisation
        -- Generate a temporary idx file and keep it for the duration of the optimisation
        local tmp_bse = os.tmpname()
        local tmp_idx = doublequote(tmp_bse .. ".wav")
        local read_cmd = ie_exe .. " " .. tmp_idx
        for i=1, num_selected_items do
            -- Set up some values in memory
            local max_iter = 1000
            local iter = 0
            local init_thresh = tonumber(threshold)
            curr_thresh = 0.0
            num_slices = 0

            -- Make an initial pass
            noveltyslice(full_path_t[i], tmp_idx, feature, tostring(init_thresh), kernelsize, filtersize, fftsettings)
            prev_slices = tablelen(spacesplit(capture(read_cmd, false)))

            -- Make a second pass based on first pass
            if prev_slices < target_slices then curr_thresh = init_thresh * 0.5 end
            if prev_slices > target_slices then curr_thresh = init_thresh * 2.0 end
            noveltyslice(full_path_t[i], tmp_idx, feature, tostring(curr_thresh), kernelsize, filtersize, fftsettings)
            curr_slices = tablelen(spacesplit(capture(read_cmd, false)))

            -- start searching --
            while iter ~= max_iter do
                if num_slices == target_slices then -- if it is already solved
                    table.insert(slice_points_string_t, capture(read_cmd, false))
                    goto finish_search;
                end

                delta_slices = 

                if num_slices > target_slices then 
                    curr_thresh = curr_thresh * (1.23 + (math.random() * 0.05))
                    noveltyslice(full_path_t[i], tmp_idx, feature, tostring(curr_thresh), kernelsize, filtersize, fftsettings)
                    num_slices = tablelen(spacesplit(capture(read_cmd, false)))
                end

                if num_slices < target_slices then
                    curr_thresh = curr_thresh * (0.8 + (math.random() * 0.05))
                    noveltyslice(full_path_t[i], tmp_idx, feature, tostring(curr_thresh), kernelsize, filtersize, fftsettings)
                    num_slices = tablelen(spacesplit(capture(read_cmd, false)))
                end
                iter = iter + 1 -- move forward in our iterations
            end
        end
        ::finish_search::

        -- Execution
        for i=1, num_selected_items do
            local slice_points = spacesplit(slice_points_string_t[i])
            for j=2, #slice_points do
                slice_pos = sampstos(
                    tonumber(slice_points[j]), sr_t[i]
                )
                item_t[i] = reaper.SplitMediaItem(item_t[i], item_pos_t[i] + (slice_pos - take_ofs_t[i]))
            end
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("noveltyslice", 0)
        for i=1, num_selected_items do
            remove_file(tmp_idx)
            remove_file(tmp_bse)
        end
    end
end
::exit::