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

-- https://sashamaps.net/docs/resources/20-colors/
colors.scheme = {
	[1] = { r=230, g=25, b=75 },
	[2] = { r=60, g=180, b=75 },
	[3] = { r=255, g=225, b=25 },
	[4] = { r=0, g=130, b=200 },
	[5] = { r=245, g=130, b=48 }, 
	[6] = { r=70, g=240, b=240 },
	[7] = { r=240, g=50, b=230 },
	[8] = { r=250, g=190, b=212 },
	[9] = { r=0, g=128, b=128 },
	[10] = { r=220, g=190, b=255 },
	[11] = { r=170, g=110, b=40 },
	[12] = { r=255, g=250, b=200 },
	[13] = { r=128, g=0, b=0 },
	[14] = { r=127, g=255, 195 },
	[15] = { r=0, g=0, b=128 },
	[16] = { r=128, g=128, b=128 },
	[17] = { r=255, g=120, b=120 },
	[18] = { r=0, g=0, b=0}
}

return colors