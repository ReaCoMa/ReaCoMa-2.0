local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "../FluidPlumbing/FluidUtils.lua")
dofile(script_path .. "../FluidPlumbing/FluidParams.lua")
dofile(script_path .. "../FluidPlumbing/FluidPaths.lua")
dofile(script_path .. "../FluidPlumbing/FluidSlicing.lua")

if fluidPaths.sanity_check() == false then return end
local cli_path = fluidPaths.get_fluid_path()
local exe = fluidUtils.doublequote(cli_path .. "/fluid-noveltyslice")

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = fluid_experimental.auto_novelty
    fluidParams.check_params(processor)
    local param_names = "feature,threshold,kernelsize,filtersize,fftsettings,minslicelength,target_slices,tolerance,max_iterations"
    local param_values = fluidParams.parse_params(param_names, processor)
    local confirm, user_inputs = reaper.GetUserInputs("Auto-threshold noveltyslice", 9, param_names, param_values)

    if confirm then

        reaper.Undo_BeginBlock()
        fluidParams.store_params(processor, param_names, user_inputs)

        local params = fluidUtils.commasplit(user_inputs)
        local feature = params[1]
        local threshold = params[2]
        local kernelsize = params[3]
        local filtersize = params[4]
        local fftsettings = params[5]
        local minslicelength = params[6]
        local target_slices = tonumber(params[7])
        local tolerance = tonumber(params[8])
        local max_iterations = tonumber(params[9])

        local data = fluidSlicing.container

        local function form_string(threshold, item_index)
            local temp_file = data.full_path[item_index] .. fluidUtils.uuid(item_index) .. "fs.csv"
            local cmd_string = exe ..
            " -source " .. fluidUtils.doublequote(data.full_path[item_index]) .. 
            " -indices " .. fluidUtils.doublequote(temp_file) .. 
            " -maxfftsize " .. fluidUtils.getmaxfftsize(fftsettings) ..
            " -maxkernelsize " .. kernelsize ..
            " -maxfiltersize " .. filtersize ..
            " -feature " .. feature .. 
            " -kernelsize " .. kernelsize .. 
            " -threshold " .. threshold ..
            " -filtersize " .. filtersize .. 
            " -fftsettings " .. fftsettings .. 
            " -minslicelength " .. minslicelength ..
            " -numframes " .. data.item_len_samples[item_index] .. 
            " -startframe " .. data.take_ofs_samples[item_index]
            return cmd_string, temp_file
        end

        for i=1, num_selected_items do
            fluidSlicing.get_data(i, data)
        end

        for i=1, num_selected_items do
            -- For each item that you have selected
            -- Initialise some values
            local iter = 0

            local curr_thresh = tonumber(threshold)
            local prev_thresh = curr_thresh

            num_slices = 0
            prev_slices = 0

            -- Do an initial pass
            local cmd, temp_file = form_string(curr_thresh, i)
            fluidUtils.cmdline(cmd)
            prev_slices = #fluidUtils.commasplit(fluidUtils.readfile(temp_file))
            os.remove(temp_file)
            
            -- start searching --
            while iter ~= tonumber(max_iterations) do
                if iter == 0 then -- on our first loop we have to initialise
                    if prev_slices < target_slices then
                        curr_thresh = prev_thresh * 0.5
                    else
                        curr_thresh = prev_thresh * 2
                    end
                end
                
                local cmd, temp_file = form_string(curr_thresh, i)
                fluidUtils.cmdline(cmd)
                num_slices = #fluidUtils.commasplit(fluidUtils.readfile(temp_file))
                

                if math.abs(target_slices - num_slices) <= tolerance then
                    --*************************************--
                    -- if finished within tolerance we win --
                    --*************************************--
                    table.insert(data.slice_points_string, fluidUtils.readfile(temp_file))
                    fluidSlicing.perform_splitting(i, data)
                    os.remove(temp_file)
                    reaper.UpdateArrange()
                else -- do some clever threshold manipulation and slicing
                    local n_thresh = 0.0
                    local d_slices = num_slices - prev_slices
                    local d_thresh = curr_thresh - prev_thresh

                    if d_slices ~= 0 then
                        n_thresh = math.max(0.000001, math.min(0.999999, ((d_thresh / d_slices) * (target_slices - num_slices)) + curr_thresh))
                    else
                        n_thresh = math.max(0.000001, math.min(0.999999, d_thresh + curr_thresh))
                    end

                    prev_thresh = curr_thresh
                    curr_thresh = n_thresh
                    prev_slices = num_slices
                    iter = iter + 1 -- move forward in our iterations
                    os.remove(temp_file)
                end
                
            end
        end
        reaper.Undo_EndBlock("auto_novelty", 0)
    end
end
