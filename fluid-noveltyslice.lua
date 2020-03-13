local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")
dofile(script_path .. "FluidParams.lua")

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local ns_suf = cli_path .. "/fluid-noveltyslice"
local ns_exe = doublequote(ns_suf)
------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.noveltyslice
    check_params(processor)
    local param_names = "feature,threshold,kernelsize,filtersize,fftsettings"
    local param_values = parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Novelty Slice Parameters", 5, param_names, param_values)
    if confirm then
        store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local feature = params[1]
        local threshold = params[2]
        local kernelsize = params[3]
        local filtersize = params[4]
        local fftsettings = params[5]

        local item_pos_t = {}
        local take_ofs_t = {}
        local ns_cmd_t = {}
        local slice_points_string_t = {}
        local tmp_idx_t = {}
        local item_t = {}
        local sr_t = {}

        for i=1, num_selected_items do

            local item = reaper.GetSelectedMediaItem(0, i-1)
            local take = reaper.GetActiveTake(item)
            local src = reaper.GetMediaItemTake_Source(take)
            local sr = reaper.GetMediaSourceSampleRate(src)
            local full_path = reaper.GetMediaSourceFileName(src, '')
            table.insert(item_t, item)
            table.insert(sr_t, sr)

            local tmp_idx = full_path .. i .. "reacoma_tmp.csv"
            table.insert(tmp_idx_t, tmp_idx)
            
            local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            table.insert(take_ofs_t, take_ofs)
            table.insert(item_pos_t, item_pos)
        
            -- Convert everything to samples for CLI --
            local take_ofs_samples = stosamps(take_ofs, sr)
            local item_pos_samples = stosamps(item_pos, sr)
            local item_len_samples = stosamps(item_len, sr)

            local ns_cmd = ns_exe .. 
            " -source " .. doublequote(full_path) .. 
            " -indices " .. doublequote(tmp_idx) .. 
            " -feature " .. feature .. 
            " -kernelsize " .. kernelsize .. 
            " -threshold " .. threshold .. 
            " -filtersize " .. filtersize .. 
            " -fftsettings " .. fftsettings .. 
            " -numframes " .. item_len_samples .. 
            " -startframe " .. take_ofs_samples
            table.insert(ns_cmd_t, ns_cmd)
        end

        -- Fill the table with slice points
        for i=1, num_selected_items do
            cmdline(ns_cmd_t[i])
            table.insert(slice_points_string_t, readfile(tmp_idx_t[i]))
        end

        -- Execution
        for i=1, num_selected_items do
            local slice_points = commasplit(slice_points_string_t[i])
            for j=2, #slice_points do
                slice_pos = sampstos(
                    tonumber(slice_points[j]), sr_t[i]
                )
                item_t[i] = reaper.SplitMediaItem(item_t[i], item_pos_t[i] + (slice_pos - take_ofs_t[i]))
            end
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("noveltyslice", 0)
        cleanup(tmp_idx_t)
    end
end
::exit::
