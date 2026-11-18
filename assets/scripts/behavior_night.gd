class_name BehaviorNight
extends RefCounted






static func night_score(state: State, id: String, side: String) -> float:

	var sc: = Behavior.visit_score(state, id, side, false)
	if str(state.heroines[id]["night_invite"]) == side:
		sc += float(state.balance("night")["invite_bonus"])
	if Relations.is_fallen(state, id, side):
		sc += float(state.balance("behavior")["fallen_night_bonus"])
	return sc


static func _visit_first(a: Array, b: Array) -> bool:

	return a[0] > b[0] or (a[0] == b[0] and a[1] > b[1])


static func can_enter_at_night(state: State, id: String, side: String) -> bool:
	if load("res://scripts/scenarios/house_cfg.gd").has_rule(state, 5): return false



	if Behavior.obeys(state, id, side):
		return true
	return str(state.heroines[id]["night_invite"]) == side or Relations.is_loverish(state, id, side)


static func night_visits(state: State, escorted: String = "") -> Array:



	var msgs: = []
	var n: = state.balance("night")
	var threshold: = float(n["visit_threshold"])
	var to_pc: = []
	var to_rival: = []
	var no_show: = {}
	if escorted.is_empty():
		escorted = str(state.escort.get("id", ""))

	var rival_home: bool = state.room_of("rival") == Clock.own_room("rival") and state.present_in(Clock.own_room("rival"), "rival").is_empty()
	for id in state.heroine_ids():
		var h: Dictionary = state.heroines[id]

		h.erase("want_visit_now")
		h.erase("lent_visit")
		no_show[id] = "asleep"
		if h["self"]["drunk"] >= 2 or state.sleep_drugged(id) or id == escorted or state.room_of(id) != Clock.own_room(id):
			continue

		var want: Dictionary = h.get("want_visit", {})
		h.erase("want_visit")
		if Hypno.has_suggestion(state, id, "seek_pc"):
			to_pc.append([2, night_score(state, id, "pc"), id])
			continue
		if Hypno.has_suggestion(state, id, "seek_rival"):
			if rival_home:
				to_rival.append([2, night_score(state, id, "rival"), id])
			continue

		if not want.is_empty():
			if int(want.get("day", -1)) == state.day and Events.wants_too(state, id)\
			and Behavior.reception(state, id, "pc") == "ok" and not Behavior.keeps_distance_today(state, id, "pc"):
				h["want_visit_now"] = str(want.get("about", ""))
				to_pc.append([1, night_score(state, id, "pc"), id])
				continue

		if int(h.get("lent_tonight", -1)) == state.day:
			h.erase("lent_tonight")
			h["lent_visit"] = true
			to_pc.append([2, night_score(state, id, "pc"), id])
			continue

		if int(h.get("sent_tonight", -1)) == state.day:
			h.erase("sent_tonight")
			if rival_home:
				to_rival.append([2, night_score(state, id, "rival"), id])
				continue

		if state.rng.randf() >= float(Traits.coef(state, id, "initiative", "night_visit_rate", 0.3))\
		and str(h["night_invite"]).is_empty():
			continue
		if Behavior.reception(state, id, "pc") != "ok" or Behavior.keeps_distance_today(state, id, "pc"):
			no_show[id] = "mood"
		var best: = ""
		var best_score: = threshold
		for side in State.SIDES:
			if side == "rival" and ( not rival_home or Rival.inactive(state)):
				continue
			if not can_enter_at_night(state, id, side) or not BehaviorInvite.cheat_allowed(state, id, side):
				continue
			if Behavior.visit_override(state, id, side) < 0:
				continue
			if Behavior.reception(state, id, side) != "ok" or Behavior.keeps_distance_today(state, id, side):
				continue
			if side == "pc" and not str(BehaviorInvite.taken_detail(state, id)["reason"]).is_empty():
				continue
			var sc: = night_score(state, id, side)
			if sc >= best_score and (best.is_empty() or sc > best_score):
				best = side
				best_score = sc
		if best == "pc":
			to_pc.append([0, best_score, id])
		elif best == "rival":
			to_rival.append([0, best_score, id])
	if not to_rival.is_empty():
		to_rival.sort_custom(_visit_first)
		no_show[to_rival[0][2]] = "rival"
		msgs.append_array(Rival.receive_visit(state, to_rival[0][2]))

	if ( not NewGame.mod_enabled(state, "serious_takumi") or not load("res://scripts/rival_meal.gd").sleeping(state)) and state.pc["room"] == Clock.own_room("pc") and state.present_in(state.pc["room"], "pc").is_empty():
		var came: = ""
		var clashed: = ""
		if not to_pc.is_empty():
			msgs.append_array(Events.event_lines(state, "late_visit"))
			state.cue("noise", "footstep")
			to_pc.sort_custom(_visit_first)
			if to_pc.size() >= 3:
				msgs.append_array(_offer_group_visit(state, to_pc))
				for id in state.heroine_ids():
					var h: Dictionary = state.heroines[id]
					if not state.pending["visitors"].has(id) and str(h["night_invite"]) == "pc":
						msgs.append(Dialogue.pick(state, id, "night_no_show", Tags.derive(state, id) + ["no_show_" + str(no_show[id])]))
					h.erase("want_visit_now")
					h.erase("lent_visit")
				return msgs
			came = to_pc[0][2]
			clashed = to_pc[1][2] if to_pc.size() >= 2 else ""
			for w in [came, clashed]:
				if not w.is_empty():
					BehaviorInvite.mark_swayed(state, w)
				if not w.is_empty() and cuddle_visit(state, w):
					state.heroines[w]["cuddle_visit"] = true
			state.set_room(came, state.pc["room"])
			state.see(came)
			state.pending = {
				"kind": "visit", "id": came, 
				"options": [{"id": "accept", "label": I18n.t("受け入れる")}, {"id": "refuse", "label": I18n.t("断る"), "default": true}], 

				"lent": [came, clashed].filter( func(w): return not w.is_empty() and state.heroines[w].get("lent_visit", false)), 
			}
			if not clashed.is_empty():

				var clash_receipt: = {}
				msgs.append_array(EventsNight.night_clash(state, came, clashed, clash_receipt))
				state.set_room(clashed, state.pc["room"])
				state.see(clashed)
				state.pending["clash"] = clashed
				state.pending["clash_receipt"] = clash_receipt
				state.pending["options"] = clash_options(state, state.pending)
				if state.heroines[clashed].has("want_visit_now"):
					state.pending["saw_want_other"] = str(state.heroines[clashed]["want_visit_now"])

			var knock_tags: = Tags.derive(state, came)
			if state.heroines[came].has("want_visit_now"):

				state.pending["saw_want"] = str(state.heroines[came]["want_visit_now"])
				knock_tags.append("saw_want")
			if state.heroines[came].get("lent_visit", false):
				knock_tags.append("lent")
			if clashed.is_empty():
				msgs.append(Dialogue.pick(state, came, "night_knock", knock_tags, {"other": state.short_name(str(state.pending["saw_want"]))} if state.pending.has("saw_want") else {}))
				state.cue("noise", "knock")
			if state.heroines[came].get("lent_visit", false):
				msgs.append(I18n.t("（%sは、%sに言われて来たのだった）") % [state.short_name(came), state.short_name("rival")])
		else:
			msgs.append_array(blackout_visit(state, escorted))


		for id in state.heroine_ids():
			if id != came and id != clashed and str(state.heroines[id]["night_invite"]) == "pc":
				msgs.append(Dialogue.pick(state, id, "night_no_show", Tags.derive(state, id) + ["no_show_" + str(no_show[id])]))
	elif state.pc["room"] != Clock.own_room("pc"):



		for e in to_pc:
			var wid: String = e[2]
			if state.relation(wid, "pc") == "lover" and state.room_of(wid) != state.pc["room"] and str(state.heroines[wid]["pc"].get("remark", "")).is_empty():
				Events._set_remark(state, wid, "pc", "waited", "")
	for id in state.heroine_ids():
		state.heroines[id].erase("want_visit_now")
		state.heroines[id].erase("lent_visit")
	return msgs


static func cuddle_visit(state: State, id: String) -> bool:



	var h: Dictionary = state.heroines[id]
	if not Relations.is_lover_or_wavering(state, id, "pc"):
		return false
	if h.has("want_visit_now") or Hypno.has_suggestion(state, id, "seek_pc") or str(h["night_invite"]) == "pc":
		return false
	return state.param(id, "self", "lust") < int(state.balance("tick")["invite_lust"])


static func blackout_visit(state: State, escorted: String = "") -> Array:




	var msgs: = []
	if not Events.event_active(state, "blackout") or Events.has_pending(state):
		return msgs
	var cands: = []
	for id in state.heroine_ids():
		var h: Dictionary = state.heroines[id]
		if id == escorted or state.room_of(id) != Clock.own_room(id) or not state.present_in(Clock.own_room(id), id).is_empty():
			continue
		if int(h["self"]["drunk"]) >= 2 or state.sleep_drugged(id) or h["self"]["hypno"] or not str(h["night_invite"]).is_empty():
			continue
		if Behavior.reception(state, id, "pc") != "ok" or Behavior.keeps_distance_today(state, id, "pc"):
			continue
		cands.append(id)
	if cands.is_empty() or state.rng.randf() >= float(state.balance("random_events")["blackout_visit_rate"]):
		return msgs
	var came: String = cands[state.rng.randi() % cands.size()]
	msgs.append_array(Events.event_lines(state, "late_visit"))
	state.cue("noise", "footstep")
	state.set_room(came, state.pc["room"])
	state.see(came)
	state.pending = {
		"kind": "visit", "id": came, "scared": true, 
		"options": [{"id": "accept", "label": I18n.t("部屋に入れる")}, {"id": "refuse", "label": I18n.t("部屋に帰す"), "default": true}], 
	}
	msgs.append(Dialogue.line(state, came, "blackout_scared"))
	return msgs


static func resolve_visit(state: State, p: Dictionary, option: String) -> Array:

	var id: String = p["id"]
	var msgs: = []
	if p.has("visitors"):
		return _resolve_group_visit(state, p, option)
	if p.has("clash"):
		return _resolve_clash(state, p, option)
	if p.get("scared", false):

		if option == "accept":
			state.heroines[id]["night_welcomed"] = true
			msgs.append(Dialogue.line(state, id, "blackout_scared_ok"))
		else:
			msgs.append(Dialogue.line(state, id, "blackout_scared_refused"))
			state.set_room(id, Clock.own_room(id))
		return msgs
	if option == "accept":
		state.heroines[id]["night_welcomed"] = true
		state.heroines[id]["came_to_pc"] = true
		if p.get("lent", []).has(id):
			state.heroines[id]["lent_welcomed"] = true
		msgs.append(Dialogue.line(state, id, "visit_accepted"))
		msgs.append_array(EventsLeverage.underwear_notice(state))
	else:
		Traits.apply(state, id, "pc", "mood", float(state.balance("night")["refuse_visit_mood"]))
		var saw: = str(p.get("saw_want", ""))
		msgs.append(Dialogue.pick(state, id, "visit_refused", Tags.derive(state, id) + (["saw_want"] if not saw.is_empty() else []), {"other": state.short_name(saw)} if not saw.is_empty() else {}))
		if not saw.is_empty() and state.relation(id, "pc") == "crush":
			Events.saw_crush_drop(state, id, saw)
		state.set_room(id, Clock.own_room(id))
	return msgs


static func _resolve_clash(state: State, p: Dictionary, option: String) -> Array:




	var a: String = p["id"]
	var b: String = p["clash"]
	if option in ["accept_all", "accept_both"]:
		return _resolve_clash_both(state, p)
	var chosen: = a if option == "accept" else (b if option == "accept_other" else "")
	var msgs: = []
	if chosen.is_empty():
		for id in [a, b]:
			state.heroines[id]["cuddle_visit"] = false
			var sub: = {"kind": "visit", "id": id}
			var saw: = str(p.get("saw_want" if id == a else "saw_want_other", ""))
			if not saw.is_empty():
				sub["saw_want"] = saw
			msgs.append_array(resolve_visit(state, sub, "refuse"))
		return msgs
	var other: = b if chosen == a else a
	var other_saw: = str(p.get("saw_want_other" if chosen == a else "saw_want", ""))
	state.heroines[chosen]["night_welcomed"] = true
	state.heroines[chosen]["came_to_pc"] = true
	if p.get("lent", []).has(chosen):
		state.heroines[chosen]["lent_welcomed"] = true
	state.heroines[chosen]["pc"]["sulk"] = {}
	msgs.append(Dialogue.pick(state, chosen, "night_knock", Tags.derive(state, chosen) + ["clashed"], {"other": state.short_name(other)}))
	state.cue("noise", "knock")
	msgs.append(Dialogue.line(state, chosen, "visit_accepted"))
	Traits.apply(state, other, "pc", "mood", float(state.balance("night")["refuse_visit_mood"]))
	msgs.append(Dialogue.line(state, other, "clash_sent_back", {}, {"other": state.short_name(chosen)}))
	if not other_saw.is_empty() and state.relation(other, "pc") == "crush":
		Events.saw_crush_drop(state, other, other_saw)
	state.heroines[other]["cuddle_visit"] = false
	state.set_room(other, Clock.own_room(other))
	Events._set_remark(state, other, "pc", "clash", chosen)
	msgs.append_array(EventsLeverage.underwear_notice(state))
	return msgs


static func accepts_night_invite(state: State, id: String) -> bool:


	return night_invite_detail(state, id)["reason"].is_empty()


static func night_invite_detail(state: State, id: String) -> Dictionary:


	if Behavior.yields_to_pc(state, id):
		return {"reason": ""}
	var rc: = Behavior.reception_detail(state, id, "pc")
	if rc["result"] != "ok":
		return {"reason": rc["reason"], "other": rc.get("other", "")}
	if not Relations.is_loverish(state, id, "pc"):
		if Relations.in_ex_cooldown(state, id, "pc"):
			return {"reason": "just_broke_up"}
		if not BehaviorInvite.cheat_allowed(state, id, "pc"):
			return {"reason": "has_lover"}
	if night_close(state, id):
		return BehaviorInvite.taken_detail(state, id)
	return {"reason": "not_close"}


static func night_close(state: State, id: String) -> bool:


	var rel: = state.relation(id, "pc")
	return Relations.is_loverish(state, id, "pc") or rel == "crush" or Relations.is_sexfriend(state, id, "pc") or state.param(id, "pc", "affection") >= int(state.balance("night")["welcome_affection"])


static func night_stage(state: State, id: String) -> String:




	var h: Dictionary = state.heroines[id]
	if str(h["night_invite"]) == "pc" or Behavior.yields_to_pc(state, id):
		return "welcome"
	if Behavior.reception(state, id, "pc") == "refuse":
		return "refuse"
	var rel: = state.relation(id, "pc")
	if night_close(state, id):
		return "welcome" if str(BehaviorInvite.taken_detail(state, id)["reason"]).is_empty() else "taken"
	if rel == "friend" or rel == "ex":
		return "doorstep"
	return "turned_away"


static func can_stay_over(state: State, id: String) -> bool:



	var h: Dictionary = state.heroines[id]
	if int(h["pc"].get("push_down_refused_day", 0)) == state.day:
		return false
	if Relations.is_loverish(state, id, "pc") or state.relation(id, "pc") == "crush" or h.get("night_welcomed", false):
		return true
	return night_stage(state, id) == "welcome"


static func pc_must_leave_room(state: State) -> String:

	var owner: = state.owner_of(state.pc["room"])
	if state.heroines.has(owner) and not can_stay_over(state, owner):
		return owner
	return ""


static func night_door_locked(state: State, id: String) -> bool:
	if load("res://scripts/scenarios/house_cfg.gd").night_open(state, Clock.own_room(id)):
		return false


	var h: Dictionary = state.heroines[id]
	if h.get("night_welcomed", false):
		return false
	if str(h["night_invite"]) == "pc" or Relations.is_loverish(state, id, "pc") or Behavior.obeys(state, id, "pc"):
		return false
	return true


static func sneak_in(state: State, id: String) -> Array:



	var msgs: = []
	var n: = state.balance("night")
	var h: Dictionary = state.heroines[id]
	var room: = Clock.own_room(id)
	var welcomed: bool = h.get("night_welcomed", false)
	if not welcomed:
		msgs.append_array(Events.event_lines(state, "sneak"))
	if state.room_of(id) != room:
		state.set_room("pc", room)
		msgs.append(I18n.t("%sの部屋は空だった。") % state.short_name(id))
		return msgs
	var picked: = night_door_locked(state, id)
	if picked:
		if state.has_master_key("pc"):
			msgs.append(I18n.t("%sの部屋の鍵を、万能鍵でそっと開けた。") % state.short_name(id))
		else:
			var bonus: = float(state.balance("random_events")["blackout_sneak_bonus"]) if Events.event_active(state, "blackout") else 0.0
			var rl: = Events.roll(state, I18n.t("鍵を開ける（度胸）"), state.ability_tier("pc", "courage") * float(n["sneak_lock_rate_per_courage"]) + bonus)
			msgs.append(rl["note"])
			if not rl["ok"]:
				msgs.append(I18n.t("%sの部屋の鍵は開かなかった。") % state.short_name(id))
				return msgs
	if state.room_of("rival") == room:

		state.add_knowledge("pc", "entered", "rival", id, "seen")
		state.see(id, room)
		state.see("rival", room)
		msgs.append(I18n.t("%sの部屋には%sがいた。……見なかったことにして戻った。") % [state.short_name(id), state.name_of("rival")])
		return msgs
	if h["self"].get("asleep", false):

		state.set_room("pc", room)
		if picked:
			h["picked_in_slot"] = true
		state.see(id)
		msgs.append(Dialogue.line(state, id, "sleep_enter"))
		return msgs
	if picked and not welcomed:

		return msgs + sneak_found(state, id, true)
	if not welcomed:
		var stage: = night_stage(state, id)
		if stage != "welcome":
			return msgs + _night_not_welcome(state, id, stage)
	state.set_room("pc", room)
	state.see(id)
	if not welcomed:
		h["night_welcomed"] = true
		BehaviorInvite.mark_swayed(state, id)
		msgs.append(Dialogue.line(state, id, "night_welcome"))
		msgs.append_array(auto_lock(state, id))
	msgs.append_array(EventsLeverage.solo_walk_in(state, room))
	return msgs


static func _night_not_welcome(state: State, id: String, stage: String) -> Array:



	var msgs: = []
	var n: = state.balance("night")
	match stage:
		"refuse":
			msgs.append(Dialogue.line(state, id, "refused") + Behavior.refusal_line(state, id, "pc"))
			return msgs
		"doorstep":
			state.see(id)
			Traits.apply(state, id, "pc", "affection", float(n["doorstep_affection"]))
			state.mark_met(id, "pc")
			msgs.append(Dialogue.line(state, id, "night_doorstep") + Behavior.refusal_note(state, "not_close"))
		"turned_away":
			state.see(id)
			Traits.apply(state, id, "pc", "mood", float(n["turned_away_mood"]))
			msgs.append(Dialogue.line(state, id, "night_turned_away") + Behavior.refusal_note(state, "not_close"))
		"taken":
			state.see(id)
			var td: = BehaviorInvite.taken_detail(state, id)
			msgs.append(Dialogue.line(state, id, "refuse_pc_taken", {}, {"other": state.short_name(str(td["other"]))}) + Behavior.refusal_note(state, "pc_taken", str(td["other"])))
	state.set_room("pc", Clock.own_room("pc"))
	msgs.append(I18n.t("%sに戻った。") % pc_room_name(state))
	return msgs


static func pc_room_name(state: State) -> String:

	return str(state.room_name(Clock.own_room("pc")))


static func knock_detail(state: State, id: String) -> Dictionary:



	if Behavior.yields_to_pc(state, id):
		return {"reason": ""}
	var rc: = Behavior.reception_detail(state, id, "pc")
	if rc["result"] != "ok":
		return {"reason": rc["reason"], "other": rc.get("other", "")}
	if Behavior.keeps_distance_today(state, id, "pc"):
		return {"reason": "not_in_mood"}
	if not (Relations.is_loverish(state, id, "pc") or state.relation(id, "pc") == "crush" or Relations.is_sexfriend(state, id, "pc")\
	or state.param(id, "pc", "affection") >= int(state.balance("night")["welcome_affection"])):
		return {"reason": "not_close"}
	if not Relations.is_loverish(state, id, "pc"):
		var td: = BehaviorInvite.taken_detail(state, id)
		if not str(td["reason"]).is_empty():
			return td
	return {"reason": ""}


static func knock(state: State, id: String, room: String, late: bool) -> Array:



	var msgs: = []
	var h: Dictionary = state.heroines[id]
	state.cue("noise", "knock")
	if late and EventsLeverage.coerced(state, id):
		var tags: = Tags.derive(state, id)
		var dm: = 0
		if h["self"].get("asleep", false):
			h["self"]["asleep"] = false
			dm = Traits.apply(state, id, "pc", "mood", float(state.balance("night")["coerce_wake_mood"]))
			tags.append("woke")
		state.spend_ap(1, true)
		state.set_lock(room, false)
		state.set_room("pc", room)
		state.see(id)
		h["night_welcomed"] = true
		msgs.append(Dialogue.pick(state, id, "coerce_open", tags) + Events.delta_note(I18n.t("%sの機嫌") % state.short_name(id), dm, state, "mood"))
		msgs.append_array(EventsLeverage.solo_walk_in(state, room))
		return msgs
	if late:
		if h["self"].get("asleep", false):
			msgs.append(Dialogue.common_line(state, "knock_asleep", [], {"name": state.short_name(id)}))
			return msgs
		var stage: = night_stage(state, id)
		if stage != "welcome":
			return _night_not_welcome(state, id, stage)
		state.spend_ap(1, true)
		state.set_lock(room, false)
		state.set_room("pc", room)
		state.see(id)
		h["night_welcomed"] = true
		BehaviorInvite.mark_swayed(state, id)
		msgs.append(Dialogue.line(state, id, "night_welcome"))
		msgs.append_array(auto_lock(state, id))
		msgs.append_array(EventsLeverage.solo_walk_in(state, room))
		return msgs
	var kd: = knock_detail(state, id)
	if not str(kd["reason"]).is_empty():
		msgs.append(Dialogue.line(state, id, "knock_refused") + Behavior.refusal_note(state, str(kd["reason"]), str(kd.get("other", "")), id))
		return msgs
	BehaviorInvite.mark_swayed(state, id)
	msgs.append(Dialogue.line(state, id, "knock_ok"))
	state.set_lock(room, false)
	msgs.append_array(CommandsMove.move(state, room)["messages"])
	return msgs


static func sneak_found(state: State, id: String, late: bool) -> Array:



	var msgs: = []
	var h: Dictionary = state.heroines[id]
	state.see(id)
	var dm: = Traits.apply(state, id, "pc", "mood", float(state.balance("night")["sneak_found_mood"]))
	state.add_knowledge(id, "sneak", "pc", id, "seen")
	var tags: = Tags.derive(state, id)
	if not late:
		msgs.append(Dialogue.pick(state, id, "sneak_found", tags + ["daytime"]) + Events.delta_note(I18n.t("%sの機嫌") % state.short_name(id), dm, state, "mood"))
		return msgs
	if night_stage(state, id) == "welcome":
		state.set_room("pc", Clock.own_room(id))
		h["night_welcomed"] = true
		msgs.append(Dialogue.pick(state, id, "sneak_found", tags + ["let_in"]) + Events.delta_note(I18n.t("%sの機嫌") % state.short_name(id), dm, state, "mood"))
		msgs.append_array(EventsLeverage.solo_walk_in(state, Clock.own_room(id)))
		return msgs
	msgs.append(Dialogue.pick(state, id, "sneak_found", tags) + Events.delta_note(I18n.t("%sの機嫌") % state.short_name(id), dm, state, "mood"))
	state.set_room("pc", Clock.own_room("pc"))
	msgs.append(I18n.t("%sに戻った。") % pc_room_name(state))
	return msgs


static func auto_lock(state: State, id: String) -> Array:

	var room: = state.room_of(id)
	if not state.lockable(room) or state.is_locked(room):
		return []
	if state.rng.randf() >= float(state.balance("lock")["self_lock_rate"]):
		return []
	state.set_lock(room, true)
	if state.pc["room"] == room:
		return [lock_line(state, id)]
	return []


static func lock_line(state: State, id: String) -> String:

	return I18n.t("%sが戸に鍵をかけた。") % state.short_name(id)


static func _visitor_available(state: State, id: String, room: String) -> bool:
	return state.heroines.has(id) and state.room_of(id) == room and not state.is_asleep(id) and not state.in_sex(id) and not state.sleep_drugged(id)


static func both_visit_reason(state: State, p: Dictionary) -> String:
	var a: = str(p.get("id", ""))
	var b: = str(p.get("clash", ""))
	var room: String = state.pc["room"]
	if p.get("kind", "") != "visit" or a == b or room != Clock.own_room("pc") or not _visitor_available(state, a, room) or not _visitor_available(state, b, room):
		return I18n.t("상황이 달라져 둘 다 맞이할 수 없습니다. 다른 선택을 해 주세요.")
	return ""


static func clash_options(state: State, p: Dictionary) -> Array:
	var opts: = [
		{"id": "accept", "label": I18n.t("%sを入れる") % state.short_name(str(p["id"]))}, 
		{"id": "accept_other", "label": I18n.t("%sを入れる") % state.short_name(str(p["clash"]))}, 
	]
	var reason: = both_visit_reason(state, p)
	opts.append({"id": "accept_all", "label": I18n.t("모두 받아들이기"), "disabled": not reason.is_empty(), "reason": reason})
	opts.append({"id": "refuse", "label": I18n.t("二人とも帰す"), "default": true})
	return opts


static func _resolve_clash_both(state: State, p: Dictionary) -> Array:
	var receipt = p.get("clash_receipt", {})
	if receipt is Dictionary and receipt.get("used", false):
		return []
	var reason: = both_visit_reason(state, p)
	if not reason.is_empty():
		p["options"] = clash_options(state, p)
		state.pending = p
		return [reason]
	var a: = str(p["id"])
	var b: = str(p["clash"])
	# Old saves can lack a receipt. Refund the original clash only when its deltas are still valid.
	if receipt is Dictionary:
		EventsNight.refund_clash(state, receipt, a, b)
	var msgs: = [I18n.t("%s, 두 사람을 방에 맞이했다.") % state.short_names([a, b])]
	for id in [a, b]:
		state.heroines[id]["night_welcomed"] = true
		state.heroines[id]["came_to_pc"] = true
		if p.get("lent", []).has(id):
			state.heroines[id]["lent_welcomed"] = true
		state.heroines[id]["pc"]["sulk"] = {}
		msgs.append(Dialogue.line(state, id, "visit_both_accepted", {}, {"other": state.short_name(b if id == a else a)}))
	state.cue("noise", "knock")
	msgs.append_array(EventsLeverage.underwear_notice(state))
	return msgs



static func _offer_group_visit(state: State, ranked: Array) -> Array:
	var visitors: Array = ranked.slice(0, 4).map( func(row): return row[2])
	var p: = {"kind": "visit", "id": visitors[0], "visitors": visitors, "checked": [], "day": state.day, "slot": state.slot, "room": state.pc["room"], "saw": {}, "lent": []}
	for id in visitors:
		BehaviorInvite.mark_swayed(state, id)
		var h: Dictionary = state.heroines[id]
		if cuddle_visit(state, id): h["cuddle_visit"] = true
		if h.has("want_visit_now"): p["saw"][id] = str(h["want_visit_now"])
		if h.get("lent_visit", false): p["lent"].append(id)
		state.set_room(id, p["room"])
	state.pending = p
	p["options"] = group_visit_options(state, p)
	state.cue("noise", "knock")
	return [I18n.ui_text(I18n.t("%s의 방문이다.") % state.short_names(visitors))]


static func _group_visit_reason(state: State, p: Dictionary, chosen: Array) -> String:
	if chosen.is_empty(): return I18n.t("맞이할 사람 선택")
	if state.pc["room"] != p.get("room", "") or state.day != int(p.get("day", -1)) or state.slot != p.get("slot", ""):
		return I18n.t("상황이 달라졌다.")
	for id in chosen:
		if not p["visitors"].has(id) or not _visitor_available(state, id, p["room"]):
			return I18n.t("상황이 달라졌다.")
	# Joining a room does not start a group encounter. The later action still checks eligibility.
	return ""



static func group_visit_options(state: State, p: Dictionary) -> Array:
	var opts: Array = []
	for id in p["visitors"]:
		opts.append({"id": "toggle:" + str(id), "label": ("☑ " if p["checked"].has(id) else "☐ ") + state.short_name(id)})
	var all_reason: = _group_visit_reason(state, p, p["visitors"])
	var selected_reason: = _group_visit_reason(state, p, p["checked"])
	opts.append({"id": "accept_all", "label": I18n.t("모두 받아들이기"), "disabled": not all_reason.is_empty(), "reason": all_reason})
	opts.append({"id": "accept_selected", "label": I18n.t("선택한 사람 받아들이기"), "disabled": not selected_reason.is_empty(), "reason": selected_reason})
	opts.append({"id": "refuse", "label": I18n.t("모두 돌려보내기"), "default": true})
	return opts


static func cancel_group_visit(state: State, p: Dictionary) -> void :
	for id in p.get("visitors", []):
		if state.heroines.has(id) and state.room_of(id) == p.get("room", ""):
			state.set_room(id, Clock.own_room(id))
			state.heroines[id]["cuddle_visit"] = false


static func _resolve_group_visit(state: State, p: Dictionary, option: String) -> Array:
	if state.pc["room"] != p.get("room", "") or state.day != int(p.get("day", -1)) or state.slot != p.get("slot", ""):
		cancel_group_visit(state, p)
		return []
	var visitors: Array = p["visitors"]
	var selected: Array = p["checked"]
	if option.begins_with("toggle:"):
		var id: = option.trim_prefix("toggle:")
		if visitors.has(id):
			if selected.has(id): selected.erase(id)
			else: selected.append(id)
		state.pending = p
		p["options"] = group_visit_options(state, p)
		return []
	var chosen: Array = visitors if option == "accept_all" else selected if option == "accept_selected" else []
	if option != "refuse":
		var reason: = _group_visit_reason(state, p, chosen)
		if not option in ["accept_all", "accept_selected"] or not reason.is_empty():
			state.pending = p
			p["options"] = group_visit_options(state, p)
			return [] if reason.is_empty() else [reason]
	var msgs: Array = []
	for id in visitors:
		if not state.heroines.has(id) or state.room_of(id) != p["room"]: continue
		var h: Dictionary = state.heroines[id]
		if chosen.has(id):
			state.see(id)
			h["night_welcomed"] = true
			h["came_to_pc"] = true
			h["pc"]["sulk"] = {}
			if p["lent"].has(id): h["lent_welcomed"] = true
			msgs.append(Dialogue.line(state, id, "visit_accepted"))
		else:
			h["cuddle_visit"] = false
			var sub: = {"kind": "visit", "id": id, "saw_want": p["saw"].get(id, "")}
			msgs.append_array(resolve_visit(state, sub, "refuse"))
	if not chosen.is_empty():
		msgs.append(I18n.ui_text(I18n.t("%s 일행을 방에 맞이했다.") % state.short_names(chosen)))
		msgs.append_array(EventsLeverage.underwear_notice(state))
	return msgs
