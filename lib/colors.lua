colors = {}

colors.convert = function(h, s, v, a)
	local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)
	return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

colors.red = colors.convert(0.0, 0.7, 1.0, 1.0)
colors.green = colors.convert(0.3, 1.0, 0.5, 1.0)
colors.dark_green = colors.convert(0.3, 1.0, 0.4, 1.0)
colors.mid_green = colors.convert(0.3, 1.0, 0.45, 1.0)
colors.grey = colors.convert(0.0, 0.0, 0.63, 1.0)
colors.dark_grey = colors.convert(0.0, 0.0, 0.47, 1.0)
colors.mid_grey = colors.convert(0.0, 0.0, 0.55, 1.0)

return colors