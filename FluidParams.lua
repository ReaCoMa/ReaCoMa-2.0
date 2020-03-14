-- Store a bunch of archetypes as tables
-- These mostly act as a way of storing an idenfitier (name)...
-- ... and the parameters
-- As a bonus, some defaults are defined in order to initialise the objects at some point
fluid_archetype = {

    nmf = {
        name = "FluidParamNMF",
        fftsettings = "1024 -1 -1",
        components = "2",
        iterations = "100",
    },

    transients = {
        name = "FluidParamTransients",
        blocksize = "256",
        clumplength = "25",
        order = "20",
        padsize = "128",
        skew = "0.0",
        threshback = "1.1",
        threshfwd = "2.0",
        windowsize = "14"
    },

    hpss = {
        name = "FluidParamHPSS",
        fftsettings = "1024 -1 -1",
        harmfiltersize = "17",
        harmthresh = "0.0 1.0 1.0 1.0",
        percfiltersize = "31",
        percthresh = "0.0 1.0 1.0 1.0",
        maskingmode = "0"
    },

    sines = {
        name = "FluidParamSines",
        bandwidth = "76",
        fftsettings = "1024 -1 -1",
        freqweight = "0.5",
        magweight = "0.01",
        mintracklen = "15",
        threshold = "0.7"
    },

    transientslice = {
        name = "FluidParamTransientSlice",
        blocksize = "256",
        clumplength = "25",
        minslicelength = "1000",
        order = "20",
        padsize = "128",
        skew = "0.0",
        threshback = "1.1",
        threshfwd = "2.0",
        windowsize = "14"
    },

    onsetslice = {
        name = "FluidParamOnsetSlice",
        fftsettings = "1024 -1 -1",
        filtersize = "5",
        framedelta = "0",
        metric = "0",
        minslicelength = "2",
        threshold = "0.5"
    },

    noveltyslice = {
        name = "FluidParamNoveltySlice",
        feature = "0",
        fftsettings = "1024 -1 -1",
        filtersize = "1",
        kernelsize = "3",
        threshold = "0.5"
    },

    loudness = {
        name = "FluidParamLoudness",
        hopsize = "4410",
        windowsize = "17640",
        kweighting = "1",
        truepeak = "1",
    },
}

fluid_multitype = {
    loudness_filter = {
        name = "FluidMultiTypeLoudnessFilter",
        operator = ">",
        threshold = "-24",
        hopsize = "4410",
        windowsize = "17640",
        kweighting = "1",
        truepeak = "1",
    },
}

function check_params(param_table)
    -- This should only really run once per REAPER install
    -- But we do have to do it everytime to ensure each 'type' has defaults ..
    -- .. and a named place to get/set them from
    local name = param_table.name
    for parameter, value in pairs(param_table) do
        if not reaper.HasExtState(name, parameter) then
            reaper.SetExtState(name, parameter, value, true)
        end
    end
end

function parse_params(parameter_names, processor)
    -- Provide captions in,
    -- turn this into a string of parameter values to be provided to the user
    -- We do this because iterating tables is not deterministic
    local split_params = commasplit(parameter_names)
    local param_values = {}
    for i=1, #split_params do
        param_values[#param_values+1] = reaper.GetExtState(processor.name, split_params[i])
        -- param_values[#param_values+1] = processor_table[split_params[i]]
    end
    return table.concat(param_values, ",")
end

function store_params(processor, parameter_names, parameter_values)
    -- Taking two strings that are CSV of params and values
    -- This lets you re-use non, hardcoded values to store
    -- Store the numbers in the external state of reaper
    -- Processor tells you what the name of the object is and where to store
    local n = commasplit(parameter_names)
    local v = commasplit(parameter_values)

    for i=1, #n do
        reaper.SetExtState(processor.name, n[i], v[i], true)
    end

end