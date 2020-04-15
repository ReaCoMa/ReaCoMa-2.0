local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../lib/reacoma.lua")()

--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local exe = reacoma.utils.doublequote(reacoma.settings.path .. "/fluid-loudness")
------------------------------------------------------------------------------------
tenv = reaper.GetSelectedEnvelope(0)

-- Get take of selected envelope
take = reaper.Envelope_GetParentTake(tenv)
item = reaper.GetMediaItemTake_Item(take)
src = reaper.GetMediaItemTake_Source(take)
src_parent = reaper.GetMediaSourceParent(src)
sr = nil
full_path = nil

if src_parent ~= nil then
    sr = reaper.GetMediaSourceSampleRate(src_parent)
    full_path = reaper.GetMediaSourceFileName(src_parent, "")
else
    sr = reaper.GetMediaSourceSampleRate(src)
    full_path = reaper.GetMediaSourceFileName(src, "")
end

tmp = full_path .. reacoma.utils.uuid(0) .. "fs.csv"

take_ofs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
src_len = reaper.GetMediaSourceLength(src)
playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")


-- if data.reverse[item_index] then
--     take_ofs = math.abs((src_len - (item_len * playrate)) + take_ofs)
-- end

-- This line caps the analysis at one loop
if (item_len + take_ofs) > src_len then 
    item_len = src_len 
end

take_ofs_samples = stosamps(take_ofs, sr)
item_pos_samples = stosamps(item_pos, sr)
item_len_samples = math.floor(stosamps(item_len, sr) * playrate)


-- Wipe all the envelope points

-- Processing
hopsize = 4410
windowsize = 17640
cmd = exe .. 
" -source " .. doublequote(full_path) .. 
" -features " .. doublequote(tmp) ..  
" -hopsize " .. tostring(hopsize) ..
" -windowsize " .. tostring(windowsize) ..
" -numframes " .. item_len_samples .. 
" -startframe " .. take_ofs_samples

reacoma.utils.cmdline(cmd)
slices = {}
table.insert(slices, reacoma.utils.readfile(tmp))
slice_points = reacoma.utils.commasplit(slices[1])

-- Scaling Mode Stuff
scaling_mode = reaper.GetEnvelopeScalingMode(tenv)

br_env = reaper.BR_EnvAlloc(tenv, false)
active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type, faderScaling = reaper.BR_EnvGetProperties(br_env, true, true, true, true, 0, 0, 0, 0, 0, 0, true)
for i=1, #slice_points do
    wincentre = reacoma.utils.sampstos(
        ((i-1) * hopsize) + (windowsize / 2) - windowsize,
        sr
    )
    -- some scaling
    foo = normalise(slice_points[i], -157, 0, minValue * 1, maxValue)
    reaper.InsertEnvelopePoint(tenv, wincentre, foo, 1, 1, true)
    
end