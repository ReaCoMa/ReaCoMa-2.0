local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/" .. "FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidParams.lua")

local item = reaper.GetSelectedMediaItem(0, 0)
string_to_be = "woaiwadosiaodiso"
-- Get any previous notes
_, current_notes = reaper.GetSetMediaItemInfo_String(
    item, 
    "P_NOTES", 
    "foobie", 
    false
)

concat_string = current_notes .. "\r\n" .. string_to_be


reval, bigstr = reaper.GetSetMediaItemInfo_String(
    item, 
    "P_NOTES", 
    concat_string, 
    true
)
-- local take = reaper.GetActiveTake(item)
-- local src = reaper.GetMediaItemTake_Source(take)
-- local src_parent = reaper.GetMediaSourceParent(src)
-- local sr = nil
-- local full_path = nil

-- if src_parent ~= nil then
--     sr = reaper.GetMediaSourceSampleRate(src_parent)
--     full_path = reaper.GetMediaSourceFileName(src_parent, "")
--     table.insert(data.reverse, true)
-- else
--     sr = reaper.GetMediaSourceSampleRate(src)
--     full_path = reaper.GetMediaSourceFileName(src, "")
--     table.insert(data.reverse, false)
-- end

-- local take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
-- local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
-- local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") * playrate
-- local src_len = reaper.GetMediaSourceLength(src)
-- local playtype  = reaper.GetMediaItemTakeInfo_Value(take, "I_PITCHMODE")

-- if data.reverse[item_index] then
--     take_ofs = math.abs(src_len - (item_len + take_ofs))
-- end

-- -- This line caps the analysis at one loop
-- if (item_len + take_ofs) > src_len then 
--     item_len = src_len 
-- end

-- local take_ofs_samples = stosamps(take_ofs, sr)
-- local item_len_samples = math.floor(stosamps(item_len, sr))

