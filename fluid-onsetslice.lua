local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "/FluidPlumbing/FluidSlicing.lua")

if fluidPaths.sanity_check() == false then goto exit; end
local exe = fluidUtils.doublequote(fluidPaths.get_fluid_path() .. "/fluid-onsetslice")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = fluid_archetype.onsetslice
    fluidParams.check_params(processor)
    local param_names = "metric,threshold,minslicelength,filtersize,framedelta,fftsettings"
    local param_values = fluidParams.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Onset Slice Parameters", 6, param_names, param_values)
    if confirm then
        fluidParams.store_params(processor, param_names, param_values)

        reaper.Undo_BeginBlock()
        local params = fluidUtils.commasplit(user_inputs)
        local metric = params[1]
        local threshold = params[2]
        local minslicelength = params[3]
        local filtersize = params[4]
        local framedelta = params[5]
        local fftsettings = params[6]

        local data = fluidSlicing.container

        for i=1, num_selected_items do
            fluidSlicing.get_data(i, data)

            local cmd = exe .. 
            " -source " .. fluidUtils.doublequote(data.full_path[i]) .. 
            " -indices " .. fluidUtils.doublequote(data.tmp[i]) ..
            " -maxfftsize " .. fluidUtils.getmaxfftsize(fftsettings) .. 
            " -metric " .. metric .. 
            " -minslicelength " .. minslicelength ..
            " -threshold " .. threshold .. 
            " -filtersize " .. filtersize .. 
            " -framedelta " .. framedelta ..
            " -fftsettings " .. fftsettings .. 
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]

            table.insert(data.cmd, cmd)
        end

        for i=1, num_selected_items do
            fluidUtils.cmdline(data.cmd[i])
            table.insert(data.slice_points_string, fluidUtils.readfile(data.tmp[i]))
            fluidSlicing.perform_splitting(i, data)
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("onsetslice", 0)
        fluidUtils.cleanup(data.tmp)
    end
end
::exit::
