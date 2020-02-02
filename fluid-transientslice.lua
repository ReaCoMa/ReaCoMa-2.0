local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")
dofile(script_path .. "FluidParams.lua")

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local ts_suf = cli_path .. "/fluid-transientslice"
local ts_exe = doublequote(ts_suf)
------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.transientslice
    check_params(processor)
    local param_names = "order,blocksize,padsize,skew,threshfwd,threshback,windowsize,clumplength,minslicelength"
    local param_values = parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Transient Slice Parameters", 9, param_names, param_values)
    if confirm then
        store_params(processor, param_names, user_inputs)
        
        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local order = params[1]
        local blocksize = params[2]
        local padsize = params[3]
        local skew = params[4]
        local threshfwd = params[5]
        local threshback = params[6]
        local windowsize = params[7]
        local clumplength = params[8]
        local minslicelength = params[9]

        local item_pts_t = {}
        local item_len_t = {}
        local item_pts_samples_t = {}
        local item_len_samples_t = {}
        local ts_cmd_t = {}
        local slice_points_string_t = {}
        local tmp_idx_t = {}
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

            local tmp_idx = full_path .. i .. "reacoma_tmp.csv"
            table.insert(tmp_idx_t, tmp_idx)
            
            local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            local item_pts = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            table.insert(take_ofs_t, take_ofs)
            table.insert(item_pts_t, item_pts)
            table.insert(item_len_t, item_len)
        
            -- Convert everything to samples for CLI --
            local take_ofs_samples = stosamps(take_ofs, sr)
            local item_pts_samples = stosamps(item_pts, sr)
            local item_len_samples = stosamps(item_len, sr)
            table.insert(take_ofs_samples_t, take_ofs_samples)
            table.insert(item_pts_samples_t, item_pts_samples)
            table.insert(item_len_samples_t, item_len_samples)

            local ts_cmd = ts_exe .. " -source " .. doublequote(full_path) .. " -indices " .. doublequote(tmp_idx) .. 
            " -order " .. order .. " -blocksize " .. blocksize .. 
            " -padsize " .. padsize .. " -skew " .. skew .. 
            " -threshfwd " .. threshfwd .. " -threshback " .. threshback ..
            " -windowsize " .. windowsize .. " -clumplength " .. clumplength .. " -minslicelength " .. minslicelength ..
            " -numframes " .. item_len_samples .. " -startframe " .. take_ofs_samples

            table.insert(ts_cmd_t, ts_cmd)
        end

        -- Fill the table with slice points
        for i=1, num_selected_items do
            cmdline(ts_cmd_t[i])
            table.insert(slice_points_string_t, readfile(tmp_idx_t[i]))
        end
        -- Execution
        for i=1, num_selected_items do
            slice_points = commasplit(slice_points_string_t[i])
            for j=2, #slice_points do
                local slice_pts = sampstos(
                    tonumber(slice_points[j]), sr_t[i]
                )
                item_t[i] = reaper.SplitMediaItem(item_t[i], item_pts_t[i] + (slice_pts - take_ofs_t[i]))
            end
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("transientslice", 0)
        cleanup(tmp_idx_t)
    end
end
::exit::
