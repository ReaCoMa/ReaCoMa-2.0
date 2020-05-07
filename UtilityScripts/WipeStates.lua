local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
-- loadfile(script_path .. "../lib/reacoma.lua")()

-- -- A script for getting rid of all FluCoMa related variables stored in the state table --
-- for k, v in pairs(reacoma.params.archetype) do
--     for i, j in pairs(v) do
--         reaper.DeleteExtState(v.name, i, true)
--     end
-- end

reaper.DeleteExtState("reacoma", "version_warned", true)