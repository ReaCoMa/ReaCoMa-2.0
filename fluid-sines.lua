local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/" .. "FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/" .. "FluidLayers.lua")

------------------------------------------------------------------------------------
--   Each user MUST point this to their folder containing FluCoMa CLI executables --
if sanity_check() == false then goto exit; end
local cli_path = get_fluid_path()
--   Then we form some calls to the tools that will live in that folder --
local suf = cli_path .. "/fluid-sines"
local exe = doublequote(suf)
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

        data = LayersContainer

        data.outputs = {
            sines = {},
            residual = {}
        }

        for i=1, num_selected_items do
            get_layers_data(i, data)

            table.insert(
                data.outputs.sines,
                basename(data.full_path[i]) .. "_sines-s_" .. uuid(i) .. ".wav"
            )

            table.insert(
                data.outputs.residual,
                basename(data.full_path[i]) .. "_sines-r_" .. uuid(i) .. ".wav"
            )
            
            table.insert(
                data.cmd, 
                exe .. 
                " -source " .. doublequote(data.full_path[i]) .. 
                " -sines " .. doublequote(data.outputs.sines[i]) .. 
                " -residual " .. doublequote(data.outputs.residual[i]) .. 
                " -bandwidth " .. bandwidth .. 
                " -threshold " .. threshold ..
                " -mintracklen " .. mintracklen .. 
                " -magweight " .. magweight .. 
                " -freqweight " .. freqweight ..
                " -fftsettings " .. fftsettings .. 
                " -numframes " .. data.item_len_samples[i] .. 
                " -startframe " .. data.take_ofs_samples[i]
            )
        end

        -- Execute NMF Process
        for i=1, num_selected_items do
            cmdline(data.cmd[i])
        end

        reaper.SelectAllMediaItems(0, 0)
        for i=1, num_selected_items do
            perform_layers(i, data)
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("FluidSines", 0)
    end
end
::exit::
