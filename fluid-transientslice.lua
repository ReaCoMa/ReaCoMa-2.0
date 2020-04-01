local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "/FluidPlumbing/FluidParams.lua")
dofile(script_path .. "/FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "/FluidPlumbing/FluidSlicing.lua")

if FluidPaths.sanity_check() == false then goto exit; end
local exe = FluidUtils.doublequote(FluidPaths.get_fluid_path() .. "/fluid-transientslice")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    -- Parameter Get/Set/Prep
    local processor = fluid_archetype.transientslice
    FluidParams.check_params(processor)
    local param_names = "order,blocksize,padsize,skew,threshfwd,threshback,windowsize,clumplength,minslicelength"
    local param_values = FluidParams.parse_params(param_names, processor)

    local confirm, user_inputs = reaper.GetUserInputs("Transient Slice Parameters", 9, param_names, param_values)
    if confirm then
        FluidParams.store_params(processor, param_names, user_inputs)
        
        reaper.Undo_BeginBlock()
        -- Algorithm Parameters
        local params = FluidUtils.commasplit(user_inputs)
        local order = params[1]
        local blocksize = params[2]
        local padsize = params[3]
        local skew = params[4]
        local threshfwd = params[5]
        local threshback = params[6]
        local windowsize = params[7]
        local clumplength = params[8]
        local minslicelength = params[9]

        local data = FluidSlicing.container

        for i=1, num_selected_items do
            FluidSlicing.get_data(i, data)

            local cmd = exe .. 
            " -source " .. FluidUtils.doublequote(data.full_path[i]) .. 
            " -indices " .. FluidUtils.doublequote(data.tmp[i]) .. 
            " -order " .. order .. 
            " -blocksize " .. blocksize .. 
            " -padsize " .. padsize .. 
            " -skew " .. skew .. 
            " -threshfwd " .. threshfwd .. 
            " -threshback " .. threshback ..
            " -windowsize " .. windowsize .. 
            " -clumplength " .. clumplength .. 
            " -minslicelength " .. minslicelength ..
            " -numframes " .. data.item_len_samples[i] .. 
            " -startframe " .. data.take_ofs_samples[i]
            table.insert(data.cmd, cmd)
        end
        
        for i=1, num_selected_items do
            FluidUtils.cmdline(data.cmd[i])
            table.insert(data.slice_points_string, FluidUtils.readfile(data.tmp[i]))
            FluidSlicing.perform_splitting(i, data)
        end

        reaper.UpdateArrange()
        reaper.Undo_EndBlock("transientslice", 0)
        FluidUtils.cleanup(data.tmp)
    end
end
::exit::
