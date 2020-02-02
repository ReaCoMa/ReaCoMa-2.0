local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")
dofile(script_path .. "FluidParams.lua")

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local sines_suf = cli_path .. "/fluid-sines"
local sines_exe = doublequote(sines_suf)
------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then
    
    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.sines
    check_params(processor)
    local param_names = "bandwidth,threshold,mintracklen,magweight,freqweight,fftsettings"
    local param_values = parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Sines Parameters", 6, param_names, param_values)
    if confirm then 
        store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local bandwidth = params[1]
        local threshold = params[2]
        local mintracklen = params[3]
        local magweight = params[4]
        local freqweight = params[5]
        local fftsettings = params[6]
        local identifier = rmdelim(bandwidth .. threshold .. mintracklen .. magweight .. freqweight .. fftsettings)

        local item_t = {}
        local sr_t = {}
        local take_ofs_t = {}
        local take_ofs_samples_t = {}
        local item_pos_t = {}
        local item_len_t = {}
        local item_pos_samples_t = {}
        local item_len_samples_t = {}
        local sines_cmd_t = {}
        local sines_t = {}
        local resid_t = {}

        for i=1, num_selected_items do
            local item = reaper.GetSelectedMediaItem(0, i-1)
            local take = reaper.GetActiveTake(item)
            local src = reaper.GetMediaItemTake_Source(take)
            local sr = reaper.GetMediaSourceSampleRate(src)
            local full_path = reaper.GetMediaSourceFileName(src, '')
            table.insert(item_t, item)
            table.insert(sr_t, sr)
        
            local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            table.insert(take_ofs_t, take_ofs)
            table.insert(item_pos_t, item_pos)
            table.insert(item_len_t, item_len)

            -- Now make the name for the separated parts using the offset to create a unique id --
            -- Using the offset means that slices won't share names at the output in the situation where you nmf on segments --
            table.insert(sines_t, basename(full_path) .. "_sines-s_" .. tostring(take_ofs) .. identifier .. ".wav")
            table.insert(resid_t, basename(full_path) .. "_sines-r_" .. tostring(take_ofs) .. identifier .. ".wav")

            local take_ofs_samples = stosamps(take_ofs, sr)
            local item_pos_samples = stosamps(item_pos, sr)
            local item_len_samples = stosamps(item_len, sr)
            table.insert(take_ofs_samples_t, take_ofs_samples)
            table.insert(item_pos_samples_t, item_pos_samples)
            table.insert(item_len_samples_t, item_len_samples)
            
            -- Form the commands to shell and store in a table --
            table.insert(sines_cmd_t, sines_exe .. " -source " .. doublequote(full_path) .. 
                " -sines " .. doublequote(sines_t[i]) .. 
                " -residual " .. doublequote(resid_t[i]) .. 
                " -bandwidth " .. bandwidth .. " -threshold " .. threshold ..
                " -mintracklen " .. mintracklen .. " -magweight " .. magweight .. " -freqweight " .. freqweight ..
                " -fftsettings " .. fftsettings .. " -numframes " .. item_len_samples .. " -startframe " .. take_ofs_samples)
        end

        -- Execute NMF Process
        for i=1, num_selected_items do
            cmdline(sines_cmd_t[i])
        end
        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            if i > 1 then reaper.SetMediaItemSelected(item_t[i-1], false) end
            reaper.SetMediaItemSelected(item_t[i], true)
            reaper.InsertMedia(sines_t[i],3)
            reaper.InsertMedia(resid_t[i],3)      
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("sines", 0)
    end
end
::exit::
