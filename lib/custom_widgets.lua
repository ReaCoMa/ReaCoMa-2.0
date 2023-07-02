function generate_odds(start, finish)
	local odd_tbl = {}
	
	-- Ensure the startNumber is odd
	if start % 2 == 0 then
	  start = start + 1
	end
	
	for i = start, finish, 2 do
	  table.insert(odd_tbl, math.floor(i))
	end
	
	return odd_tbl
end

function generate_powers_of_two(start_number, end_number)
	local powers_table = {}
	
	for power = 0, end_number do
	  local value = 2 ^ power
	  if value >= start_number and value <= end_number then
		table.insert(powers_table, math.floor(value))
	  end
	end
	
	return powers_table
end

local widgets = {}

-- For FFT parameters
widgets.FFTSlider = {
	opts = generate_powers_of_two(2, 65536)
}

-- For parameters which snap to odds like filters or kernel sizes
widgets.FilterSlider = {
	opts = generate_odds(1, 101)
}

widgets.KernelSlider = {
	opts = generate_odds(3, 71)
}

return widgets