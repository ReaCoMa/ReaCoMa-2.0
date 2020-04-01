local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "/FluidPlumbing/FluidSlicing.lua")

if sanity_check() == false then goto exit; end
local exe = doublequote(get_fluid_path() .. "/fluid-noveltyslice")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.noveltyslice
    check_params(processor)
    local param_names = "feature,threshold,kernelsize,filtersize,fftsettings,minslicelength"
    local param_values = parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Noveltyslice Parameters", 6, param_names, param_values)
    if confirm then
        store_params(processor, param_names, user_inputs)

        reaper.Undo_BeginBlock()
        local params = commasplit(user_inputs)
        local feature = params[1]
        local threshold = params[2]
        local kernelsize = params[3]
        local filtersize = params[4]
        local fftsettings = params[5]
        local minslicelength = params[6]
        
        local data = FluidSlicing.container

        for i=1, num_selected_items do
            FluidSlicing.get_data(i, data)
            
            local cmd = exe .. 
            " -source " .. doublequote(data.full_path[i]) .. 
            " -indices " .. doublequote(data.tmp[i]) .. 
            " -feature " .. feature .. 
            " -kernelsize " .. kernelsize .. 
            " -threshold " .. threshold .. 
            " -filtersize " .. filtersize .. 
            " -fftsettings " .. fftsettings .. 
            " -minslicelength " .. minslicelength ..
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
            table.insert(data.cmd, cmd)
        end

        for i=1, num_selected_items do
            cmdline(data.cmd[i])
            table.insert(data.slice_points_string, readfile(data.tmp[i]))
            FluidSlicing.perform_splitting(i, data)
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("noveltyslice", 0)
        cleanup(data.tmp)
    end
end
::exit::
