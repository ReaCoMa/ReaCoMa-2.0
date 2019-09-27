
local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "FluidUtils.lua")

--------------------------------------------------------------------------------------------------------------

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items ~= 0 then
    local captions = "centroid >=:"
    local caption_defaults = "500"
    local confirm, user_inputs = reaper.GetUserInputs("centroid", 1, captions, caption_defaults)
    if confirm then 
        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = commasplit(user_inputs)
        local centroid = params[1]

        -- Create storage --
        local item_t = {}
        local centroid_t = {}

        for i=1, num_selected_items do

            -- Pre-processing --
            local tmp_file = os.tmpname()
            local tmp_idx = tmp_file .. ".csv"
            table.insert(tmp_file_t, tmp_file)
            table.insert(tmp_idx_t, tmp_idx)

            local item = reaper.GetSelectedMediaItem(0, i-1)
            local take = reaper.GetActiveTake(item)
            local src = reaper.GetMediaItemTake_Source(take)
            local sr = reaper.GetMediaSourceSampleRate(src)
            local full_path = reaper.GetMediaSourceFileName(src, '')
            table.insert(item_t, item)

            local take_ofs = stosamps(reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS"))
            local item_pos = stosamps(reaper.GetMediaItemInfo_Value(item, "D_POSITION"))
            local item_len = stosamps(reaper.GetMediaItemInfo_Value(item, "D_LENGTH"))

        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("CentroidSelect", 0)
    end
end
::exit::
