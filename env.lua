local info = debug.getinfo(1,'S');
local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
loadfile(script_path .. "lib/reacoma.lua")()
if reacoma.settings.fatal then return end

ctx, viewport = imgui_helpers.create_context('env')
selection = ''

function paint()
	if prev_search ~= search then get_scores() end
    local pos = { r.ImGui_Viewport_GetWorkPos(viewport) }
    r.ImGui_SetNextWindowPos(ctx, pos[1] + 100, pos[2] + 100, r.ImGui_Cond_FirstUseEver())
	r.ImGui_SetNextWindowSize(ctx, 300, 300, r.ImGui_Cond_FirstUseEver())
	visible, open = r.ImGui_Begin(ctx, 'reacoma.fuzzy', true, r.ImGui_WindowFlags_NoCollapse())

	r.ImGui_End(ctx)
	if open then
		local env = r.GetSelectedEnvelope(0)
		if env then
			local rv, env_name = reaper.GetEnvelopeName(env, "")
			local sm = r.GetEnvelopeScalingMode(env)
			local value = r.ScaleToEnvelopeMode(sm, 0.5)
			if r.ImGui_Button(ctx, 'process') then
				local take, _, _ = reaper.Envelope_GetParentTake(env)
				local info = envelope.get_take_info(take)

				local exe = reacoma.utils.wrap_quotes(
					reacoma.settings.path .. "/fluid-noveltyfeature"
				)
				local cmd = exe ..
				" -source " .. reacoma.utils.wrap_quotes(info.full_path) ..
				" -features " .. reacoma.utils.wrap_quotes(info.tmp) ..
				" -numframes " .. info.item_len_samples ..
				" -startframe " .. info.take_ofs_samples ..
				" -numchans 1" ..
				" -fftsettings 1024 512 1024 1024"
				-- " -startchan 0"
				-- " -kernelsize " ..
				-- " -filtersize " ..
				-- " -fftsettings " ..
				-- " -algorithm " ..
				reacoma.utils.cmdline(cmd)

				local feature = reacoma.utils.split_comma(
					reacoma.utils.readfile(info.tmp)
				)
				norm_feature = utils.normalise(feature)

				local scaling_mode = r.GetEnvelopeScalingMode(env)
				br_env = reaper.BR_EnvAlloc(env, false)
				active, visible, armed, inLane, laneHeight, defaultShape, min, max, centerValue, type, faderScaling = reaper.BR_EnvGetProperties(br_env, true, true, true, true, 0, 0, 0, 0, 0, 0, true)
				for i=1, #norm_feature do
					local pos = reacoma.utils.sampstos(i*512, info.sr)
					local value = reacoma.utils.scale(norm_feature[i], 0, 1, min, max)
					r.InsertEnvelopePoint(env, pos, value, 0, 0, false, true)
				end
				-- for i=1, #norm_feature do
				-- 	local value = r.ScaleToEnvelopeMode(scaling_mode, norm_feature[i])
				-- 	local pos = reacoma.utils.sampstos(i*512, info.sr)
				-- 	r.InsertEnvelopePoint(env, pos, value, 0, 0, false, true)
				-- end
			end
		end
		r.defer(paint)
	else
        r.ImGui_DestroyContext(ctx)
        return
	end
end


reaper.defer(paint)