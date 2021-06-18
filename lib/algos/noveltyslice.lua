noveltyslice = {
    specification =  {
        {
            name = 'threshold',
            widget = reaper.ImGui_SliderDouble,
            min = 0.0,
            max = 1.0,
            value = 0.5
        },
        {
            name = 'kernelsize',
            widget = reaper.ImGui_SliderInt,
            min = 3,
            max = 51,
            value = 3
        },
        {
            name = 'minslicelength',
            widget = reaper.ImGui_SliderInt,
            min = 0,
            max = 20,
            value = 2
        }
    }
}

return noveltyslice