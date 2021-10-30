-- @noindex
colors = {}

colors.red = reaper.ImGui_ColorConvertHSVtoRGB(0.0, 0.7, 1.0, 1.0)

colors.green = reaper.ImGui_ColorConvertHSVtoRGB(0.3, 1.0, 0.5, 1.0)
colors.dark_green = reaper.ImGui_ColorConvertHSVtoRGB(0.3, 1.0, 0.4, 1.0)
colors.mid_green = reaper.ImGui_ColorConvertHSVtoRGB(0.3, 1.0, 0.45, 1.0)


colors.grey = reaper.ImGui_ColorConvertHSVtoRGB(0.0, 0.0, 0.63, 1.0)
colors.dark_grey = reaper.ImGui_ColorConvertHSVtoRGB(0.0, 0.0, 0.47, 1.0)
colors.mid_grey = reaper.ImGui_ColorConvertHSVtoRGB(0.0, 0.0, 0.55, 1.0)

return colors