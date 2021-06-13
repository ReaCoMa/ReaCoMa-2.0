local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "../lib/reacoma.lua")()

if reacoma.settings.fatal then return end

local exe = reacoma.utils.wrap_quotes(
    reacoma.settings.path .. "/fluid-noveltyslice"
)

local num_selected_items = reaper.CountSelectedMediaItems(0)
if num_selected_items > 0 then

    local processor = reacoma.params.experimental.auto_novelty
    reacoma.params.check_params(processor)
    local param_names = "feature,threshold,kernelsize,filtersize,fftsettings,minslicelength,target_slices,tolerance,max_iterations"
    local param_values = reacoma.params.parse_params(param_names, processor)
    local confirm, user_inputs = reaper.GetUserInputs("Auto-threshold noveltyslice", 9, param_names, param_values)

    if confirm then

        reaper.Undo_BeginBlock()
        reacoma.params.store_params(processor, param_names, user_inputs)

        local params = reacoma.utils.split_comma(user_inputs)
        local feature = params[1]
        local threshold = params[2]
        local kernelsize = params[3]
        local filtersize = params[4]
        local fftsettings = params[5]
        local minslicelength = params[6]
        local target_slices = tonumber(params[7])
        local tolerance = tonumber(params[8])
        local max_iterations = tonumber(params[9])

        local data = reacoma.slicing.container

        local function form_string(kernelsize, item_index)
            local temp_file = data.full_path[item_index] .. reacoma.utils.uuid(item_index) .. "fs.csv"
            local cmd_string = exe ..
            " -source " .. reacoma.utils.wrap_quotes(data.full_path[item_index]) .. 
            " -indices " .. reacoma.utils.wrap_quotes(temp_file) .. 
            " -maxfftsize " .. reacoma.utils.get_max_fft_size(fftsettings) ..
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
            reacoma.slicing.get_data(i, data)
        end

        for i=1, num_selected_items do
            -- For each item that you have selected
            -- Initialise some values
            local solved = false
            local iter = 0

            local curr_thresh = tonumber(kernelsize)
            local prev_thresh = curr_thresh

            num_slices = 0
            prev_slices = 0
            
            -- Do an initial pass
            local cmd, temp_file = form_string(curr_thresh, i)
            reacoma.utils.cmdline(cmd)
            prev_slices = #reacoma.utils.split_comma(reacoma.utils.readfile(temp_file))
            os.remove(temp_file)
            
            -- start searching --
            while not solved do
                if iter ~= tonumber(max_iterations) then
                    if iter == 0 then -- on our first loop we have to initialise
                        if prev_slices < target_slices then
                            curr_thresh = prev_thresh * 0.5
                        else
                            curr_thresh = prev_thresh * 2
                        end
                    end
                    
                    local cmd, temp_file = form_string(curr_thresh, i)
                    reacoma.utils.cmdline(cmd)
                    num_slices = #reacoma.utils.split_comma(reacoma.utils.readfile(temp_file))
                    
                    if math.abs(target_slices - num_slices) <= tolerance then
                        --*************************************--
                        -- if finished within tolerance we win --
                        --*************************************--
                        table.insert(data.slice_points_string, reacoma.utils.readfile(temp_file))
                        reacoma.slicing.process(i, data)
                        os.remove(temp_file)
                        reacoma.utils.arrange("auto_kernel_novelty")
                        solved = true
                    else -- do some clever threshold manipulation and slicing
                        local n_thresh = 0.0
                        local d_slices = num_slices - prev_slices
                        local d_thresh = curr_thresh - prev_thresh

                        if d_slices ~= 0 then
                            n_thresh = math.floor(
                                math.max(2, math.min(2048, ((d_thresh / d_slices) * (target_slices - num_slices)) + curr_thresh)) + 0.5
                            )
                        else
                            n_thresh = math.floor(
                                math.max(2, math.min(2048, d_thresh + curr_thresh)) + 0.5
                            )
                        end

                        prev_thresh = curr_thresh
                        curr_thresh = n_thresh
                        prev_slices = num_slices
                        iter = iter + 1 -- move forward in our iterations
                        os.remove(temp_file)
                    end
                end
            end
        end
    end
end
