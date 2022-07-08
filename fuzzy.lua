local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end
r = reaper

ctx, viewport = imgui_helpers.create_context('reacoma.fuzzy')

local open = true
local search = ''
local prev_search = ''
local scripts = {
	'ampgate',
	'ampslice',
	'hpss',
	'nmf',
	'noveltyslice',
	'onsetslice',
	'sines',
	'transients',
	'transientslice'
}

local scores = {}

function score_sort(a, b)
	return a > b
end

function get_scores()
	for k, v in pairs(scripts) do
		local score = fzy.score(search, tostring(v))
		scores[v] = score
	end
	table.sort(scores, function(l, r) return l[2] > r[2] end)
end

function paint()
	if prev_search ~= search then get_scores() end
    local pos = { r.ImGui_Viewport_GetWorkPos(viewport) }
    r.ImGui_SetNextWindowPos(ctx, pos[1] + 100, pos[2] + 100, r.ImGui_Cond_FirstUseEver())
	r.ImGui_SetNextWindowSize(ctx, 300, 300, r.ImGui_Cond_FirstUseEver())
	visible, open = r.ImGui_Begin(ctx, 'reacoma.fuzzy', true, r.ImGui_WindowFlags_NoCollapse())
	
	rv, search = r.ImGui_InputText(ctx, 'search')
	r.ImGui_Text(ctx, search)
	
	for k, v in pairs(scores) do
		r.ImGui_Text(ctx, k)
		r.ImGui_Text(ctx, v)
	end
	
	
	r.ImGui_End(ctx)
	if open then
		r.defer(paint)
	else
        r.ImGui_DestroyContext(ctx)
        return
	end
end

r.defer(paint)


