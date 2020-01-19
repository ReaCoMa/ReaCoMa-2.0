local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local transients_suf = cli_path .. "/fluid-transients"
local transients_exe = doublequote(transients_suf)
------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    local captions = "order,blocksize,padsize,skew,threshfwd,threshback,windowsize,clumplength"
    local caption_defaults = "20, 256, 128, 0.0, 2.0, 1.1, 14, 25"
    local confirm, user_inputs = reaper.GetUserInputs("Transients Parameters", 8, captions, caption_defaults)
    if confirm then 
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
        local identifier = rmdelim(order .. blocksize .. padsize .. skew .. threshfwd .. threshback .. windowsize .. clumplength)

        local item_t = {}
        local sr_t = {}
        local full_path_t = {}
        local take_ofs_t = {}
        local take_ofs_samples_t = {}
        local item_pos_t = {}
        local item_len_t = {}
        local item_pos_samples_t = {}
        local item_len_samples_t = {}
        local transients_cmd_t = {}
        local trans_t = {}
        local resid_t = {}

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

            -- Now make the name for the separated parts using the offset to create a unique id --
            -- Using the offset means that slices won't share names at the output in the situation where you nmf on segments --
            table.insert(trans_t, basename(full_path) .. "_ts-tra_" .. tostring(take_ofs) .. identifier .. ".wav")
            table.insert(resid_t, basename(full_path) .. "_ts-res_" .. tostring(take_ofs) .. identifier .. ".wav")

            local take_ofs_samples = stosamps(take_ofs, sr)
            local item_pos_samples = stosamps(item_pos, sr)
            local item_len_samples = stosamps(item_len, sr)
            table.insert(take_ofs_samples_t, take_ofs_samples)
            table.insert(item_pos_samples_t, item_pos_samples)
            table.insert(item_len_samples_t, item_len_samples)
            
            -- Form the commands to shell and store in a table --
            table.insert(transients_cmd_t, transients_exe .. " -source " .. doublequote(full_path) .. 
                " -transients " .. doublequote(trans_t[i]) .. 
                " -residual " .. doublequote(resid_t[i]) .. 
                " -order " .. order .. " -blocksize " .. blocksize .. 
                " -padsize " .. padsize .. " -skew " .. skew .. 
                " -threshfwd " .. threshfwd .. " -threshback " .. threshback ..
                " -windowsize " .. windowsize .. " -clumplength " .. clumplength ..
                " -numframes " .. item_len_samples .. " -startframe " .. take_ofs_samples)
        end

        -- Execute NMF Process
        for i=1, num_selected_items do
            reaper.ExecProcess(transients_cmd_t[i], 0)
        end
        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            if i > 1 then reaper.SetMediaItemSelected(item_t[i-1], false) end
            reaper.SetMediaItemSelected(item_t[i], true)
            reaper.InsertMedia(trans_t[i],3)
            reaper.InsertMedia(resid_t[i],3)     
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("transients", 0)
    end
end
::exit::
