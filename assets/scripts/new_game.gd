class_name NewGame
extends RefCounted




static var custom_path: = "user://presets.json"
static var last_path: = "user://last_settings.json"
const DROPPED_ABILITIES: = {"pc": ["charm", "courage", "strength"], "rival": ["charm", "skill", "courage", "strength"]}


const PORT_FEATURES = ["serious_takumi", "morning_cg", "multi_visit_sleep", "affection_bonds", "rivalry_conflict"]
const MODS: = {
	"morning_cg": {"label": "아침 기상 CG", "note": "원본 아침 기상 CG를 표시합니다."},
	"rivalry_conflict": {"label": "히로인 감정·연적 확장", "note": "경쟁·중재·협력과 전언·관심 돌리기를 추가한다. 끄면 대기 중인 행동은 취소되고, 이미 발생한 결과는 남는다."}, 
	"affection_bonds": {"label": "순애·하렘 확장", "note": "자발적인 교류와 교류 권유, 하렘 관계를 받아들인 히로인과 함께 쉬기가 추가된다. 발동 조건은 관계와 성격에 따라 달라진다."}, 
	"cheat_editor": {"label": "게임 중 치트 편집기", "note": "게임 중 수치와 관계를 변경합니다. 켠 회차에서는 새 업적을 달성할 수 없으며 다시 꺼도 자격이 복구되지 않습니다."}, 
	"serious_takumi": {"label": "진심의 그녀", "note": "교류와 관계 유지를 판단해 주인공 행동 후 시간대당 최대 4회 행동합니다. 켜져 있는 동안 성격을 자동 설정하고 끄면 원래 성격으로 돌아갑니다. 신체·능력·수단 설정은 유지합니다."}, 
	"hard_mode": {"label": "하드 모드", "note": "현재 위치를 기준으로 보이는 정보를 제한합니다. 이동과 문 확인에 행동력을 사용합니다."}, 
	"ironman_mode": {"label": "철인 모드", "note": "이번 회차에서는 수동·빠른·자동 저장과 게임 중 불러오기를 사용할 수 없습니다. 종료하면 이어서 할 수 없습니다."}, 
	"night_visit_response": {"label": "라이벌의 심야 방문에 대응", "note": "잠들 때 행동력이 남아 있고 라이벌이 심야에 방문하면 결과가 정해지기 전에 남은 행동력으로 대응할 수 있습니다."}, 
	"auto_overflow": {"label": "한계 초과 시 자동 처리", "note": "한계 초과 결과를 현재 행동에 맞춰 자동 처리합니다. 직접 선택하는 명령과 발생 시점은 바뀌지 않습니다."}, 
	"multi_visit_sleep": {"label": "다인 방문·함께 자기", "note": "밤에 최대 네 명이 방문하며 조건이 맞으면 선택한 사람이나 모두를 맞이할 수 있습니다. 함께 자기는 최대 네 명입니다."}, 
	"morning_harem": {"label": "다인 장면 확장", "note": "서로 인정한 연인이 아침 이벤트나 둘의 장면을 목격하면 참여를 제안합니다. 아침에는 한 명만 합류할 수 있습니다."}, 
}
const SPACE_KEYS: = ["annex", "judge", "endless"]
const MEANS_KEYS: = ["night_raid", "ply_drink", "blackmail", "womanizer"]
const MEANS_LABELS: = {"night_raid": "夜這い", "ply_drink": "酔わせる", "blackmail": "脅迫", "womanizer": "女たらし"}
const LEND_KEYS: = ["lend_demand", "ntr_hobby"]
const LEND_LABELS: = {"lend_demand": "寝取り趣味", "ntr_hobby": "寝取らせ趣味"}
const ASSAULT_KEY: = "assault"
const FLAG_KEYS: = ["night_raid", "ply_drink", "blackmail", "womanizer", "lend_demand", "ntr_hobby", "assault"]
const SPACE_TAB_RIVAL_KEYS: = ["natural_ntr"]
const DROPPED_RIVAL_KEYS: = ["favorite_start", "master_key"]

const NAME_MAX: = 8
const NAME_BANNED: = ["[", "]"]
const START_RELATIONS: = ["stranger", "friend", "crush", "lover_public", "lover_secret", "ex"]
const START_RELATION_LABELS: = {"stranger": "他人", "friend": "友人", "crush": "片思い", "lover_public": "恋人（公認）", "lover_secret": "恋人（秘密）", "ex": "元恋人"}
const TYPE_DEFAULT: = "default"

const PERSONALITY_FROM_INITIATIVE: = {0: "absent", 1: "sickly", 2: "sickly", 3: "gentle", 4: "pushy", 5: "pushy"}
const PERSONALITY_ABSENT: = "absent"
const FERTILITY_LEVELS_FALLBACK: = ["off", "low", "normal", "high", "certain"]
const INTIMACY_LEVELS_FALLBACK: = ["bad", "cool", "normal", "close", "best"]
const FAVORITE_START_KEYS: = ["rival", "rival_experience", "pc"]



const SERIOUS_CHALLENGE_RULES: = 3
const SERIOUS_CHALLENGE_REASONS: = {
	"not_from_start": "새 회차 시작부터 ‘진심의 그녀’를 켜야 합니다.", 
	"legacy": "이전 세이브에는 설정 유지 기록이 없어 이번 회차는 대상에서 제외됩니다.", 
	"turned_off": "이번 회차에서 ‘진심의 그녀’를 껐습니다.", 
	"night_visit_response": "인정을 받으려면 라이벌 심야 방문 대응을 처음부터 끝까지 꺼야 합니다.", 
	"hypno_used": "이번 회차에서 최면을 사용한 기록이 있습니다.", 
	"power": "라이벌의 강도는 ‘중간’ 이상이어야 합니다.", 
	"initial_abilities": "시작 시 라이벌 능력 중 기본값보다 낮은 항목이 있습니다.", 
	"size": "라이벌의 신체 크기는 ‘큼’ 이상이어야 합니다.", 
	"cum_speed": "라이벌의 사정 속도는 ‘보통’ 또는 ‘지루’여야 합니다.", 
	"natural_ntr": "자연 발생 NTR을 켜야 합니다.", 
	"judge": "판정은 ‘보통’, ‘어려움’, ‘자동 실패’ 중 하나여야 합니다.", 
	"stat_lock_used": "이번 회차에서 수치 고정을 사용한 기록이 있습니다.", 
	"skip_used": "이번 회차에서 마지막 날로 건너뛴 기록이 있습니다.", 
}


static func serious_setting_reasons(data: Dictionary, settings: Dictionary) -> Array:
	var rv_raw = settings.get("rival", {})
	var rv: Dictionary = rv_raw if rv_raw is Dictionary else {}
	var sp_raw = settings.get("space", {})
	var sp: Dictionary = sp_raw if sp_raw is Dictionary else {}
	var defaults_rv: Dictionary = data["rival"]["abilities"]
	var reasons: Array = []
	if normalize_mods(settings.get("mods", {}))["night_visit_response"]:
		reasons.append("night_visit_response")
	if not str(rv.get("power", defaults_rv.get("power", "mid"))) in ["mid", "strong", "strongest"]:
		reasons.append("power")
	var minimum: int = int(data["rival"]["power_levels"][str(defaults_rv.get("power", "mid"))]["value"])
	for key in State.ABILITY_KEYS:
		if rv.has(key) and State.ability_points(rv[key]) < minimum:
			reasons.append("initial_abilities")
			break
	if not str(rv.get("size", defaults_rv["size"])) in ["large", "huge"]:
		reasons.append("size")
	if not str(rv.get("cum_speed", data["rival"]["cum_speed"]["default"])) in ["normal", "late"]:
		reasons.append("cum_speed")
	var ntr = rv.get("natural_ntr", defaults_rv["natural_ntr"])
	if not ntr is bool or not ntr:
		reasons.append("natural_ntr")
	if not str(sp.get("judge", State.JUDGE_DEFAULT)) in ["normal", "hard", "auto_fail"]:
		reasons.append("judge")
	return reasons


static func correct_retired_challenge_reason(state: State) -> void :

	if int(state.flags.get("serious_takumi_challenge_rules", 0)) != SERIOUS_CHALLENGE_RULES:
		return
	var stored = state.flags.get("serious_takumi_challenge_reasons", [])
	if not stored is Array or not stored.has("means"):
		return
	var kept: Array = stored.filter( func(reason): return reason != "means")
	state.flags["serious_takumi_challenge_reasons"] = kept
	if kept.is_empty():
		state.flags["serious_takumi_challenge_eligible"] = true


static func challenge_load_notice(_state: State) -> String:
	return ""


static func serious_challenge_reason_text(reason: String) -> String:
	if reason == "cheat_editor": return I18n.t("치트 편집기를 켠 회차에서는 새로운 업적을 달성할 수 없습니다.")
	return I18n.t(str(SERIOUS_CHALLENGE_REASONS.get(reason, SERIOUS_CHALLENGE_REASONS["not_from_start"])))


static func serious_challenge_reasons(state: State) -> Array:
	if load("res://scripts/cheat_editor.gd").blocked(state): return ["cheat_editor"]
	if int(state.flags.get("serious_takumi_challenge_rules", 0)) != SERIOUS_CHALLENGE_RULES:
		return ["legacy"] if state.flags.has("serious_takumi_challenge_eligible") else ["not_from_start"]
	var reasons: Array = []
	if state.flags.get("serious_takumi_challenge_eligible") != true:
		var stored = state.flags.get("serious_takumi_challenge_reasons", [])
		if stored is Array:
			for code in stored:
				if SERIOUS_CHALLENGE_REASONS.has(str(code)) and not reasons.has(str(code)):
					reasons.append(str(code))
		if reasons.is_empty():
			reasons.append("not_from_start")
	if not mod_enabled(state, "serious_takumi") and not reasons.has("turned_off"):
		reasons.append("turned_off")
	for reason in serious_setting_reasons(state.data, settings_from_state(state)):
		if not reasons.has(reason):
			reasons.append(reason)


	if bool(state.flags.get("hypno_cast", false)):
		reasons.append("hypno_used")
	if has_stat_locks(state) and not reasons.has("stat_lock_used"):
		reasons.append("stat_lock_used")
	return reasons


static func has_stat_locks(state: State) -> bool:
	for id in state.heroine_ids():
		for key in state.stat_lock_keys(id):
			if state.stat_locked(id, key):
				return true
	return state.rival_stat_locked("lust")


static func note_challenge_use(state: State, reason: String) -> void :

	if int(state.flags.get("serious_takumi_challenge_rules", 0)) != SERIOUS_CHALLENGE_RULES:
		return
	var reasons: Array = state.flags.get("serious_takumi_challenge_reasons", []).duplicate()
	if not reasons.has(reason):
		reasons.append(reason)
	state.flags["serious_takumi_challenge_eligible"] = false
	state.flags["serious_takumi_challenge_reasons"] = reasons


static func challenge_use_warning(reason: String) -> String:
	var action: String = {"hypno_used": "최면을 사용합니다.", "stat_lock_used": "수치를 고정합니다.", "skip_used": "마지막 날로 건너뜁니다."}.get(reason, "")
	return I18n.t(action) + "\n" + I18n.t("이번 회차에서는 MOD 업적을 달성할 수 없게 됩니다. 설정을 되돌려도 자격은 복구되지 않습니다. 실행할까요?")


static func serious_challenge_eligible(_state: State) -> bool:
	return false


static func hard_challenge_eligible(state: State) -> bool:
	return state.flags.get("hard_challenge_from_start", false) == true and mod_enabled(state, "hard_mode") and serious_challenge_eligible(state)


static func ironman_challenge_eligible(state: State) -> bool:
	return state.flags.get("ironman_challenge_from_start", false) == true and mod_enabled(state, "ironman_mode") and hard_challenge_eligible(state)


static func retain_night_response_history(state: State) -> void :
	if mod_enabled(state, "night_visit_response"):
		note_challenge_use(state, "night_visit_response")


static func _start_serious_challenge(state: State) -> void :
	if mod_enabled(state, "hard_mode") and mod_enabled(state, "serious_takumi"):
		state.flags["hard_challenge_from_start"] = true
		if mod_enabled(state, "ironman_mode"):
			state.flags["ironman_challenge_from_start"] = true
	if not mod_enabled(state, "serious_takumi"):
		state.flags["serious_takumi_challenge_rules"] = SERIOUS_CHALLENGE_RULES
		state.flags["serious_takumi_challenge_eligible"] = false
		state.flags["serious_takumi_challenge_reasons"] = ["not_from_start"]
		return
	var reasons: Array = serious_setting_reasons(state.data, settings_from_state(state))
	var power_default: String = str(state.data["rival"]["abilities"].get("power", "mid"))
	var minimum: int = int(state.data["rival"]["power_levels"][power_default]["value"])


	for key in State.ABILITY_KEYS:
		if int(state.rival.get(key, 0)) < minimum and not reasons.has("initial_abilities"):
			reasons.append("initial_abilities")
			break
	state.flags["serious_takumi_challenge_rules"] = SERIOUS_CHALLENGE_RULES
	state.flags["serious_takumi_challenge_eligible"] = reasons.is_empty()
	state.flags["serious_takumi_challenge_reasons"] = reasons


static func _forfeit_serious_challenge(state: State, reasons: Array) -> void :
	if state.flags.get("serious_takumi_challenge_eligible") != true or reasons.is_empty():
		return
	state.flags["serious_takumi_challenge_eligible"] = false
	state.flags["serious_takumi_challenge_reasons"] = reasons.duplicate()


static func presets(data: Dictionary) -> Array:
	return data["presets"]["presets"]


static func preset(data: Dictionary, id: String) -> Dictionary:
	for p in presets(data):
		if p["id"] == id:
			return p
	return {}




static func random_name(data: Dictionary, who: String, exclude: Array, rng: RandomNumberGenerator = null) -> String:


	var cands: Array = data["rival"].get("random_names", {}).get(who, []).map( func(n): return I18n.data(n, "rival.json")).filter( func(n): return not exclude.has(str(n)))
	if cands.is_empty():
		return ""
	var i: = rng.randi_range(0, cands.size() - 1) if rng != null else randi_range(0, cands.size() - 1)
	return str(cands[i])


static func strip_banned(name: String) -> String:

	for c in NAME_BANNED:
		name = name.replace(c, "")
	return name


static func default_pc_name(data: Dictionary) -> String:

	return I18n.data(str(data.get("rival", {}).get("pc_name", "主人公")), "rival.json")


static func clean_name(name: Variant, fallback: String) -> String:

	var n: = strip_banned(str(name if name != null else "")).strip_edges()
	return fallback if n.is_empty() else n




static func defaults(data: Dictionary, skill: int = State.PC_ABILITY_DEFAULT) -> Dictionary:


	var rv: Dictionary = data["rival"]["abilities"]
	var cs_def: = str(data["rival"]["cum_speed"]["default"])
	var d: = {
		"pc": {"name": default_pc_name(data), "skill": skill, "size": "large", "cum_speed": cs_def}, 
		"rival": {
			"name": I18n.data(data["rival"]["name"], "rival.json"), 
			"power": str(rv.get("power", "mid")), 
			"personality": str(rv.get("personality", "gentle")), 
			"size": str(rv["size"]), "favorite": str(rv["favorite"]), "natural_ntr": bool(rv["natural_ntr"]), 
			"night_raid": bool(rv.get("night_raid", false)), "ply_drink": bool(rv.get("ply_drink", false)), "blackmail": bool(rv.get("blackmail", false)), 
			"womanizer": bool(rv.get("womanizer", false)), 
			"lend_demand": bool(rv.get("lend_demand", false)), "ntr_hobby": bool(rv.get("ntr_hobby", false)), 
			"assault": bool(rv.get("assault", true)), 
			"cum_speed": cs_def, 
		}, 
		"space": {"annex": true, "judge": State.JUDGE_DEFAULT, "endless": false}, 
		"heroines": {}, 
		"mods": normalize_mods({}), 
	}
	for id in data["characters"]:
		d["heroines"][id] = {"traits": data["characters"][id]["traits"].duplicate(), 
			"relation": {"pc": "stranger", "rival": "stranger"}, "experience": {"pc": false, "rival": false}, 
			"fertility": State.FERTILITY_DEFAULT}

	d["intimacy"] = {}
	var hids: Array = data["characters"].keys()
	for i in hids.size():
		for j in range(i + 1, hids.size()):
			d["intimacy"][pair_key(hids[i], hids[j])] = intimacy_default(data, hids[i], hids[j])
	return d




static func normalize_mods(raw: Variant) -> Dictionary:


	var out: Dictionary = raw.duplicate(true) if raw is Dictionary else {}
	for key in MODS:
		if not out.get(key) is bool:
			out[key] = key == "morning_cg"
	for key in MODS:
		if not PORT_FEATURES.has(key): out[key] = false
	return out


static func mods_from_state(state: State) -> Dictionary:
	return normalize_mods(state.flags.get("custom_mods", {}))


static func mod_enabled(state: State, key: String) -> bool:
	var cfg = state.flags.get("custom_mods", {})
	return PORT_FEATURES.has(key) and MODS.has(key) and cfg is Dictionary and cfg.get(key) is bool and cfg[key]


static func refresh_mod_pending(state: State) -> void :
	if not mod_enabled(state, "night_visit_response"):
		if state.pending.get("kind", "") == "night_visit_response":
			state.pending = {}
		state.ongoing_sex.erase("night_response_entry")
	SceneSexHarem.refresh_expansion_offer(state)
	load("res://scripts/social_expansion.gd").refresh_pending(state)
	var p: Dictionary = state.pending
	if p.get("kind", "") == "harem_pick" and p.get("cands") is Array and p.get("checked") is Array:
		SceneSexHarem._pick_options(state)
	if p.get("kind", "") == "morning_bed" and p.has("group_guest") and not EventsNight.group_morning_offer_ok(state, p):
		state.pending = {}
		return
	if p.get("kind", "") == "visit" and p.has("visitors"):
		if mod_enabled(state, "multi_visit_sleep"):
			p["options"] = BehaviorNight.group_visit_options(state, p)
		else:
			BehaviorNight.cancel_group_visit(state, p)
			state.pending = {}
		return
	if p.get("kind", "") != "visit" or str(p.get("clash", "")).is_empty():
		return



	if p.has("clash_receipt") or p.get("options", []).any( func(o): return o is Dictionary and o.get("id", "") == "accept_both"):
		p["options"] = BehaviorNight.clash_options(state, p)


static func apply_mod_settings(state: State, raw: Variant) -> void :
	if not raw is Dictionary:
		return
	retain_night_response_history(state)
	var serious_was_on: bool = mod_enabled(state, "serious_takumi")
	var cfg: = mods_from_state(state)
	for key in raw:
		cfg[key] = raw[key]
	state.flags["custom_mods"] = normalize_mods(cfg)
	if raw.has("morning_cg"): state.flags["morning_cg_option_version"] = 1
	retain_night_response_history(state)
	if not mod_enabled(state, "ironman_mode"):
		state.flags.erase("ironman_challenge_from_start")
	if not mod_enabled(state, "hard_mode"):
		HardMode.clear_room_cues(state)
		state.flags.erase("hard_challenge_from_start")
		if state.pending.get("kind", "") == "hard_room":
			state.pending = {}
	if serious_was_on and not mod_enabled(state, "serious_takumi"):

		_forfeit_serious_challenge(state, ["turned_off"])
	load("res://scripts/cheat_editor.gd").mark(state)
	sync_serious_takumi(state)
	refresh_mod_pending(state)
	load("res://scripts/social_expansion.gd").on_settings(state)


static func sync_serious_takumi(state: State) -> void :
	var active: bool = mod_enabled(state, "serious_takumi")
	var m = state.flags.get("serious_takumi_state", {})
	if not m is Dictionary:
		m = {}
	if not active and (state.flags.has("serious_takumi_meal") or state.rival.has("meal_items")):
		load("res://scripts/rival_meal.gd").clear(state)
	if active:
		if not m.has("base_personality"):
			m["had_personality"] = state.rival.has("personality")
			m["had_initiative"] = state.rival.has("initiative")
			m["base_personality"] = str(state.rival.get("personality", personality_from_initiative(int(state.rival.get("initiative", 3)))))
			m["base_initiative"] = int(state.rival.get("initiative", 3))
		state.flags["serious_takumi_state"] = m
		state.rival["personality"] = "gentle"
		state.rival["initiative"] = 3
	elif m.has("base_personality"):
		if bool(m.get("had_personality", true)):
			state.rival["personality"] = str(m["base_personality"])
		else:
			state.rival.erase("personality")
		if bool(m.get("had_initiative", true)):
			state.rival["initiative"] = int(m.get("base_initiative", 3))
		else:
			state.rival.erase("initiative")
		for key in ["base_personality", "base_initiative", "had_personality", "had_initiative"]:
			m.erase(key)


static func rival_personality_label(state: State) -> String:
	return I18n.t("진심의 그녀") if mod_enabled(state, "serious_takumi") else personality_label(state.data, Rival.personality_id(state))


static func pair_key(a: String, b: String) -> String:

	return "%s.%s" % [a, b] if a < b else "%s.%s" % [b, a]


static func intimacy_levels(data: Dictionary) -> Array:

	return data["intimacy"].get("levels", [])


static func intimacy_default(data: Dictionary, a: String, b: String) -> String:

	var v: = int(data["intimacy"].get("pairs", {}).get(a, {}).get(b, data["intimacy"].get("default", 50)))
	return intimacy_level_of(data, v)


static func intimacy_level_of(data: Dictionary, value: int) -> String:
	var best: = ""
	var gap: = 1 << 30
	for lv in intimacy_levels(data):
		if absi(int(lv["value"]) - value) < gap:
			gap = absi(int(lv["value"]) - value)
			best = str(lv["id"])
	return best


static func intimacy_value(data: Dictionary, level: String) -> int:
	for lv in intimacy_levels(data):
		if str(lv["id"]) == level:
			return int(lv["value"])
	return int(data["intimacy"].get("default", 50))


static func intimacy_label(data: Dictionary, level: String) -> String:
	for lv in intimacy_levels(data):
		if str(lv["id"]) == level:
			return I18n.data(lv["label"], "intimacy.json")
	return level




static func types(data: Dictionary) -> Array:

	return data["traits"].get("types", [])


static func type_def(data: Dictionary, type_id: String) -> Dictionary:
	for t in types(data):
		if str(t["id"]) == type_id:
			return t
	return {}


static func type_traits(data: Dictionary, id: String, type_id: String) -> Dictionary:

	var tr: Dictionary = data["characters"][id]["traits"].duplicate()
	tr.erase("bust")
	var t: = type_def(data, type_id)
	for axis in t.get("traits", {}):
		tr[axis] = t["traits"][axis]
	return tr


static func type_of(data: Dictionary, id: String, h: Dictionary) -> String:

	var chosen: = str(h.get("type", ""))
	if not type_def(data, chosen).is_empty():
		return chosen
	var tr: Dictionary = h.get("traits", {})
	for t in types(data):
		if _same_traits(type_traits(data, id, str(t["id"])), tr):
			return str(t["id"])
	return TYPE_DEFAULT


static func type_adjusted(data: Dictionary, id: String, h: Dictionary) -> bool:

	return not _same_traits(type_traits(data, id, type_of(data, id, h)), h.get("traits", {}))


static func type_display(data: Dictionary, id: String, h: Dictionary) -> String:

	var label: = I18n.data(type_def(data, type_of(data, id, h)).get("label", ""), "traits.json")
	return I18n.t("%s＋調整") % label if type_adjusted(data, id, h) else label


static func _same_traits(a: Dictionary, b: Dictionary) -> bool:
	for axis in a:
		if str(a[axis]) != str(b.get(axis, a[axis])):
			return false
	return true


static func relation_of(value: String) -> Dictionary:

	match value:
		"lover_public": return {"relation": "lover", "is_public": true}
		"lover_secret": return {"relation": "lover", "is_public": false}
		"friend", "crush", "ex": return {"relation": value, "is_public": false}
	return {"relation": "stranger", "is_public": false}


static func apply_start(state: State, settings: Dictionary) -> void :






	state.flags["custom_mods"] = normalize_mods(settings.get("mods", {}))
	state.flags["morning_cg_option_version"] = 1
	var hs: Dictionary = settings.get("heroines", {})
	var start: = {}
	var b: = state.balance("relation")
	for id in state.heroine_ids():
		var h: Dictionary = hs.get(id, {})
		var rel: Dictionary = h.get("relation", {})
		var exp: Dictionary = h.get("experience", {})
		var rec: = {}
		for side in State.SIDES:
			var r: = relation_of(str(rel.get(side, "stranger")))
			if side == "rival" and r["relation"] == "lover" and state.relation(id, "pc") == "lover":
				r = relation_of("friend")
			var s: Dictionary = state.heroines[id][side]
			if r["relation"] != "stranger":
				s["relation"] = r["relation"]
				s["is_public"] = r["is_public"]
				s["ex_reason"] = str(b.get("start_ex_reason", "faded")) if r["relation"] == "ex" else ""
				s["since_day"] = state.day - int(b["ex_cooldown_days"]) if r["relation"] == "ex" else state.day
				state.set_param(id, side, "affection", int(b["affection_mid"].get(r["relation"], state.param(id, side, "affection"))))
			if bool(exp.get(side, false)) and s["relation"] != "stranger":
				s["sex_count"] = 1
				s["acts"] = {"missionary": 1}
				s["consensual_count"] = 1
				s["kissed"] = true
				state.set_param(id, side, "pleasure", int(b.get("start_experience_dev", 30)))
				if str(state.heroines[id]["self"]["first_partner"]).is_empty():
					state.heroines[id]["self"]["first_partner"] = side
			rec[side] = s["relation"]
		start[id] = rec

	for id in state.heroine_ids():
		for side in State.SIDES:
			var s: Dictionary = state.heroines[id][side]
			if s["relation"] == "lover" and s["is_public"]:
				for who in ["pc", "rival"] + state.heroine_ids():
					if who != id and who != side:
						state.add_knowledge(who, "lover", side, id, "public")
	state.flags["start_relations"] = start
	sync_serious_takumi(state)
	load("res://scripts/cheat_editor.gd").mark(state)
	_start_serious_challenge(state)





const IN_GAME_KEYS: = {"pc": ["name", "skill", "size", "cum_speed"], "rival": ["name", "power", "size", "cum_speed", "personality", "favorite", "natural_ntr", "night_raid", "ply_drink", "blackmail", "womanizer", "lend_demand", "ntr_hobby", "assault"], 
	"space": ["judge"], "heroine": ["traits", "fertility"]}


static func settings_from_state(state: State) -> Dictionary:

	var d: = {"pc": {}, "rival": {}, "space": {"judge": state.judge_mode()}, "heroines": {}, "mods": mods_from_state(state)}
	for k in IN_GAME_KEYS["pc"]:
		d["pc"][k] = state.pc[k]
	for k in IN_GAME_KEYS["rival"]:
		d["rival"][k] = state.rival.get(k, "")

	d["rival"]["personality"] = Rival.personality_id(state)
	d["rival"]["power"] = str(state.rival.get("power", state.data["rival"]["abilities"].get("power", "mid")))
	for k in FLAG_KEYS:
		d["rival"][k] = bool(state.rival.get(k, state.data["rival"]["abilities"].get(k, false)))
	for id in state.heroine_ids():
		var h: Dictionary = state.heroines[id]
		d["heroines"][id] = {"traits": h["traits"].duplicate(), "fertility": str(h["self"]["fertility"])}
	if mod_enabled(state, "serious_takumi"):
		d["rival"]["personality"] = str(state.flags.get("serious_takumi_state", {}).get("base_personality", "gentle"))
	return d


static func apply_in_game(state: State, settings: Dictionary, skill_cap: int) -> void :





	if settings.has("mods"):
		apply_mod_settings(state, settings["mods"])
	var data: = state.data
	var pc_s: Dictionary = settings.get("pc", {})
	if pc_s.has("name"):
		state.pc["name"] = clean_name(pc_s["name"], default_pc_name(data))
	if pc_s.has("skill"):
		state.pc["skill"] = clampi(int(pc_s["skill"]), 1, maxi(1, skill_cap))
	for who in ["pc", "rival"]:
		var a: Dictionary = settings.get(who, {})
		var actor: Dictionary = state.pc if who == "pc" else state.rival
		if data["rival"]["sizes"].has(str(a.get("size", ""))):
			actor["size"] = str(a["size"])
		if data["rival"]["cum_speed"]["levels"].has(str(a.get("cum_speed", ""))):
			actor["cum_speed"] = str(a["cum_speed"])
	var rv_s: Dictionary = settings.get("rival", {})
	var rv: = state.rival
	if rv_s.has("name"):
		rv["name"] = clean_name(rv_s["name"], I18n.data(data["rival"]["name"], "rival.json"))
		rv["short"] = rv["name"]
	var levels: Dictionary = data["rival"].get("power_levels", {})
	var power: = str(rv_s.get("power", ""))
	if levels.has(power) and power != str(rv.get("power", "")):
		var old_v: = int(levels.get(str(rv.get("power", "")), {}).get("value", rv["charm"]))
		var new_v: = int(levels[power]["value"])
		rv["power"] = power
		for k in ["charm", "courage", "strength"]:
			rv[k] = State.ability_points(new_v)
		rv["skill"] = clampi(int(rv["skill"]) - old_v + new_v, 1, State.ABILITY_MAX)
	var pers: Dictionary = data["rival"]["personalities"]["levels"]
	var personality: = str(rv_s.get("personality", ""))
	if pers.has(personality) and not mod_enabled(state, "serious_takumi"):
		rv["personality"] = personality
		rv["initiative"] = int(pers[personality]["initiative"])
	if state.heroines.has(str(rv_s.get("favorite", ""))):
		rv["favorite"] = str(rv_s["favorite"])
	if rv_s.has("natural_ntr"):
		rv["natural_ntr"] = bool(rv_s["natural_ntr"])
	for k in FLAG_KEYS:
		if rv_s.has(k):
			rv[k] = bool(rv_s[k])
	if State.JUDGE_MODES.has(str(settings.get("space", {}).get("judge", ""))):
		state.space["judge"] = str(settings["space"]["judge"])
	var axes: Dictionary = data["traits"]["axes"]
	for id in settings.get("heroines", {}):
		if not state.heroines.has(id):
			continue
		var hs: Dictionary = settings["heroines"][id]
		var h: Dictionary = state.heroines[id]
		for axis in hs.get("traits", {}):
			if axes.has(axis) and axes[axis]["values"].has(str(hs["traits"][axis])):
				h["traits"][axis] = str(hs["traits"][axis])
		if data["balance"]["fertility"]["levels"].has(str(hs.get("fertility", ""))):
			h["self"]["fertility"] = str(hs["fertility"])

	sync_serious_takumi(state)
	_forfeit_serious_challenge(state, serious_setting_reasons(state.data, settings_from_state(state)))


static func start_relation(state: State, id: String, side: String) -> String:

	return str(state.flags.get("start_relations", {}).get(id, {}).get(side, "stranger"))


static func personality_from_initiative(v: int) -> String:

	return str(PERSONALITY_FROM_INITIATIVE[clampi(v, 0, 5)])


static func personality_label(data: Dictionary, id: String) -> String:
	return I18n.data(data["rival"]["personalities"]["levels"].get(id, {}).get("label", id), "rival.json")


static func merge(base: Dictionary, over: Dictionary, top: bool = true) -> Dictionary:

	var out: = base.duplicate(true)
	for k in over:
		if out.has(k) and typeof(out[k]) == TYPE_DICTIONARY and typeof(over[k]) == TYPE_DICTIONARY:
			out[k] = merge(out[k], over[k], false)
		else:
			out[k] = over[k]
	if top:
		out["mods"] = normalize_mods(out.get("mods", {}))
		for who in ["pc", "rival"]:
			if out.has(who) and typeof(out[who]) == TYPE_DICTIONARY:
				for key in DROPPED_ABILITIES[who]:
					out[who].erase(key)
				if who == "pc" and out[who].has("skill"):
					out[who]["skill"] = State.ability_points(out[who]["skill"])
				if out[who].has("initiative"):

					var ov = over.get(who, {})
					if not (ov is Dictionary and ov.has("personality")):
						out[who]["personality"] = personality_from_initiative(int(out[who]["initiative"]))
					out[who].erase("initiative")
		if out.has("space") and typeof(out["space"]) == TYPE_DICTIONARY:
			for k in State.DROPPED_SPACE_KEYS:
				out["space"].erase(k)
			if out["space"].has("auto_success"):

				var osp = over.get("space", {})
				if not (osp is Dictionary and osp.has("judge")):
					out["space"]["judge"] = State.judge_of({"auto_success": out["space"]["auto_success"]})
				out["space"].erase("auto_success")
			if out["space"].has("judge") and not State.JUDGE_MODES.has(str(out["space"]["judge"])):
				out["space"]["judge"] = State.JUDGE_DEFAULT
		if out.has("rival") and typeof(out["rival"]) == TYPE_DICTIONARY:
			for k in DROPPED_RIVAL_KEYS:
				out["rival"].erase(k)
		for id in out.get("heroines", {}):
			if typeof(out["heroines"][id]) == TYPE_DICTIONARY and out["heroines"][id].has("traits"):
				out["heroines"][id]["traits"].erase("bust")
				SaveCompat.map_traits(out["heroines"][id]["traits"])
			if typeof(out["heroines"][id]) == TYPE_DICTIONARY and out["heroines"][id].has("fertility") and not FERTILITY_LEVELS_FALLBACK.has(str(out["heroines"][id]["fertility"])):
				out["heroines"][id]["fertility"] = State.FERTILITY_DEFAULT
		if typeof(out.get("intimacy")) == TYPE_DICTIONARY:
			for k in out["intimacy"].keys():
				if not INTIMACY_LEVELS_FALLBACK.has(str(out["intimacy"][k])):
					if base.get("intimacy", {}).has(k):
						out["intimacy"][k] = base["intimacy"][k]
					else:
						out["intimacy"].erase(k)
	return out


static func from_preset(data: Dictionary, id: String, rng: RandomNumberGenerator = null, skill: int = State.PC_ABILITY_DEFAULT) -> Dictionary:

	var d: = defaults(data, skill)
	if id == "random":
		return randomize_settings(data, d, rng if rng != null else RandomNumberGenerator.new())
	var p: = preset(data, id)
	if p.is_empty():
		p = custom_presets().get(id, {})
	var out: = merge(d, p.get("settings", {}))

	var ph: Dictionary = p.get("settings", {}).get("heroines", {})
	for hid in ph:
		if out["heroines"].has(hid) and ph[hid].has("type"):
			var tr: = type_traits(data, hid, str(ph[hid]["type"]))
			for axis in ph[hid].get("traits", {}):
				tr[axis] = ph[hid]["traits"][axis]
			out["heroines"][hid]["traits"] = tr

	var fs: Dictionary = p.get("favorite_start", {})
	if not fs.is_empty():
		var ids: Array = data["characters"].keys()
		var fav: = str(out["rival"].get("favorite", "random"))
		if fav == "random" or not out["heroines"].has(fav):
			if rng == null:
				rng = RandomNumberGenerator.new()
				rng.randomize()
			fav = ids[rng.randi_range(0, ids.size() - 1)]
		out["rival"]["favorite"] = fav
		var h: Dictionary = out["heroines"][fav]
		if str(fs.get("rival", "stranger")) != "stranger":
			h["relation"]["rival"] = str(fs["rival"])
		if str(fs.get("pc", "stranger")) != "stranger":
			h["relation"]["pc"] = str(fs["pc"])
		if bool(fs.get("rival_experience", false)):
			h["experience"]["rival"] = true
	return out


static func randomize_settings(data: Dictionary, d: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var sizes: Array = data["rival"]["sizes"].keys()
	for who in ["pc", "rival"]:
		d[who]["size"] = sizes[rng.randi() % sizes.size()]

	var powers: Array = data["rival"]["power_levels"].keys()
	d["rival"]["power"] = powers[rng.randi() % powers.size()]

	var pers: Array = data["rival"]["personalities"]["levels"].keys().filter( func(p): return p != PERSONALITY_ABSENT)
	d["rival"]["personality"] = pers[rng.randi() % pers.size()]
	var rr: Dictionary = data["presets"]["random"]
	d["rival"]["natural_ntr"] = rng.randf() < float(rr["natural_ntr_rate"])
	d["space"]["annex"] = rng.randf() < float(rr["annex_rate"])

	var axes: Dictionary = data["traits"]["axes"]
	for id in d["heroines"]:
		for axis in axes:
			var vals: Array = axes[axis]["values"].keys()
			d["heroines"][id]["traits"][axis] = vals[rng.randi() % vals.size()]
	return d





const LOCK_KEYS: = ["pc.size", "heroine.traits", "heroine.relation_pc", "heroine.intimacy", "rival.power", "rival.initiative", "rival.means", "space.annex", 
	"rival.size", "rival.favorite", "heroine.relation_rival", "heroine.fertility_high", "rival.initiative_zero", "space.auto_success"]
const FERTILITY_HIGH: = ["high", "certain"]

const RANDOM_PRESET_KEYS: = ["pc.size", "rival.size", "rival.power", "rival.initiative", "space.annex", "heroine.traits"]


static func locked_keys(data: Dictionary, settings: Dictionary, is_open: Callable) -> Array:

	var d: = defaults(data)
	var out: = []
	for key in LOCK_KEYS:
		if not is_open.call(key) and _differs(data, settings, d, key):
			out.append(key)
	return out


static func _differs(data: Dictionary, s: Dictionary, d: Dictionary, key: String) -> bool:

	var parts: = key.split(".")
	match key:
		"pc.size", "rival.power", "rival.size", "rival.favorite":
			return str(s.get(parts[0], {}).get(parts[1], d[parts[0]][parts[1]])) != str(d[parts[0]][parts[1]])
		"rival.initiative":

			var v: = str(s.get("rival", {}).get("personality", d["rival"]["personality"]))
			return v != str(d["rival"]["personality"]) and v != PERSONALITY_ABSENT
		"rival.means":

			for k in MEANS_KEYS + [ASSAULT_KEY]:
				if bool(s.get("rival", {}).get(k, d["rival"][k])) != bool(d["rival"][k]):
					return true
			return false
		"rival.initiative_zero":
			return str(s.get("rival", {}).get("personality", d["rival"]["personality"])) == PERSONALITY_ABSENT and str(d["rival"]["personality"]) != PERSONALITY_ABSENT
		"space.annex":
			return bool(s.get("space", {}).get(parts[1], d["space"][parts[1]])) != bool(d["space"][parts[1]])
		"space.auto_success":

			return str(s.get("space", {}).get("judge", d["space"]["judge"])) != str(d["space"]["judge"])
		"heroine.intimacy":
			var si: Dictionary = s.get("intimacy", {})
			for k in d["intimacy"]:
				if str(si.get(k, d["intimacy"][k])) != str(d["intimacy"][k]):
					return true
			return false
	for id in s.get("heroines", {}):
		if not d["heroines"].has(id):
			continue
		var h: Dictionary = s["heroines"][id]
		match key:
			"heroine.traits":
				var tr: Dictionary = h.get("traits", {})
				var dt: Dictionary = d["heroines"][id]["traits"]
				if not _same_traits(dt, tr) or not _same_traits(tr, dt):
					return true
			"heroine.relation_pc", "heroine.relation_rival":
				var side: = "pc" if key == "heroine.relation_pc" else "rival"
				if str(h.get("relation", {}).get(side, "stranger")) != "stranger" or bool(h.get("experience", {}).get(side, false)):
					return true
			"heroine.fertility_high":
				if FERTILITY_HIGH.has(str(h.get("fertility", State.FERTILITY_DEFAULT))):
					return true
	return false


static func reset_locked(data: Dictionary, settings: Dictionary, is_open: Callable) -> Array:

	var keys: = locked_keys(data, settings, is_open)
	var d: = defaults(data)
	for key in keys:
		var parts: PackedStringArray = key.split(".")
		match key:
			"rival.initiative", "rival.initiative_zero":
				settings["rival"]["personality"] = d["rival"]["personality"]
			"pc.size", "rival.power", "rival.size", "rival.favorite", "space.annex":
				settings[parts[0]][parts[1]] = d[parts[0]][parts[1]]
			"space.auto_success":
				settings["space"]["judge"] = d["space"]["judge"]
			"heroine.intimacy":
				settings["intimacy"] = d["intimacy"].duplicate()
			_:
				for id in settings.get("heroines", {}):
					if not d["heroines"].has(id):
						continue
					var h: Dictionary = settings["heroines"][id]
					match key:
						"heroine.traits":
							h["traits"] = d["heroines"][id]["traits"].duplicate()
							h.erase("type")
						"heroine.relation_pc", "heroine.relation_rival":
							var side: = "pc" if key == "heroine.relation_pc" else "rival"
							if not h.has("relation"):
								h["relation"] = {"pc": "stranger", "rival": "stranger"}
							if not h.has("experience"):
								h["experience"] = {"pc": false, "rival": false}
							h["relation"][side] = "stranger"
							h["experience"][side] = false
						"heroine.fertility_high":
							if FERTILITY_HIGH.has(str(h.get("fertility", State.FERTILITY_DEFAULT))):
								h["fertility"] = State.FERTILITY_DEFAULT
	return keys


static func preset_keys(data: Dictionary, id: String) -> Array:

	if id == "random":
		return RANDOM_PRESET_KEYS.duplicate()
	var rng: = RandomNumberGenerator.new()
	rng.seed = 1
	return locked_keys(data, from_preset(data, id, rng), func(_k): return false)

static func changes(data: Dictionary, settings: Dictionary, skill: int = State.PC_ABILITY_DEFAULT) -> Array:

	var out: = []
	for pair in changes_by_tab(data, settings, skill):
		if not out.has(pair[1]):
			out.append(pair[1])
	return out


static func changed_tabs(data: Dictionary, settings: Dictionary, skill: int = State.PC_ABILITY_DEFAULT) -> Array:

	var out: = []
	for pair in changes_by_tab(data, settings, skill):
		if not out.has(pair[0]):
			out.append(pair[0])
	return out


static func summary(data: Dictionary, settings: Dictionary) -> Array:


	var d: = defaults(data)
	var out: = []
	var rv: Dictionary = settings.get("rival", {})
	var power: = str(rv.get("power", d["rival"]["power"]))
	if power != str(d["rival"]["power"]):
		out.append(I18n.t("ライバルの強さ：%s") % power_label(data, power))
	var fav: = str(rv.get("favorite", d["rival"]["favorite"]))
	if fav != "random":
		out.append(I18n.t("本命：%s") % _who_label(data, fav))
	if str(rv.get("personality", d["rival"]["personality"])) == PERSONALITY_ABSENT:
		out.append(I18n.t("ライバルは自分から手を出さない（性格：静観）"))
	if not bool(rv.get("natural_ntr", d["rival"]["natural_ntr"])):
		out.append(I18n.t("自然発生NTR オフ"))
	var means: = MEANS_KEYS.filter( func(k): return bool(rv.get(k, d["rival"][k])))
	if not means.is_empty():
		out.append(I18n.t("ライバルの手段：%s") % I18n.t("・").join(means.map( func(k): return I18n.t(MEANS_LABELS[k]))))
	if not bool(rv.get(ASSAULT_KEY, d["rival"][ASSAULT_KEY])):
		out.append(I18n.t("ライバルは無理やり襲わない"))
	var lends: = LEND_KEYS.filter( func(k): return bool(rv.get(k, d["rival"][k])))
	if not lends.is_empty():
		out.append(I18n.t("ライバル：%s") % I18n.t("・").join(lends.map( func(k): return I18n.t(LEND_LABELS[k]))))
	var sp: Dictionary = settings.get("space", {})
	if not bool(sp.get("annex", true)):
		out.append(I18n.t("離れなし"))
	var judge: = State.judge_of(sp)
	if judge != State.JUDGE_DEFAULT:
		out.append(I18n.t("判定：%s") % I18n.t(State.JUDGE_LABELS[judge]))
	if bool(sp.get("endless", false)):
		out.append(I18n.t("エンドレス（30 日で終わらない）"))
	for id in settings.get("heroines", {}):
		var h: Dictionary = settings["heroines"][id]
		var rel: Dictionary = h.get("relation", {})
		var exp: Dictionary = h.get("experience", {})
		var bits: = []
		for side in ["pc", "rival"]:
			var r: = str(rel.get(side, "stranger"))
			var e: = bool(exp.get(side, false))
			if r != "stranger":
				bits.append(I18n.t("%sと%s") % [_who_label(data, side), _relation_text(r, e)])
			elif e:
				bits.append(I18n.t("%sと経験あり") % _who_label(data, side))
		var fert: = str(h.get("fertility", State.FERTILITY_DEFAULT))
		if fert != State.FERTILITY_DEFAULT:
			bits.append(I18n.data(data["balance"]["fertility"]["summary"].get(fert, fert), "balance.json"))
		if not bits.is_empty():
			out.append(I18n.t("%s：%s") % [_short(data, id), I18n.t("・").join(bits)])

	var si: Dictionary = settings.get("intimacy", {})
	for k in d["intimacy"]:
		if si.has(k) and str(si[k]) != str(d["intimacy"][k]):
			out.append(I18n.t("%sの仲：%s") % [_pair_label(data, k), intimacy_label(data, str(si[k]))])
	var mods: = normalize_mods(settings.get("mods", {}))
	for key in MODS:
		if mods[key]:
			out.append(I18n.t("MOD: %s 켜짐") % I18n.t(MODS[key]["label"]))
	return out


static func _pair_label(data: Dictionary, key: String) -> String:

	var ab: = key.split(".")
	if int(data["characters"][ab[0]].get("order", 99)) > int(data["characters"][ab[1]].get("order", 99)):
		ab = PackedStringArray([ab[1], ab[0]])
	return I18n.t("%sと%s") % [_short(data, ab[0]), _short(data, ab[1])]


static func _relation_text(relation: String, experience: bool) -> String:

	var label: = str(START_RELATION_LABELS.get(relation, relation))
	if not experience:
		return I18n.t(label)
	if label.ends_with("）"):
		var head: = label.trim_suffix("）").split("（")
		return I18n.t("%s（%s・経験あり）") % [I18n.t(head[0]), I18n.t(head[1])]
	return I18n.t("%s（経験あり）") % I18n.t(label)


static func changes_by_tab(data: Dictionary, settings: Dictionary, skill: int = State.PC_ABILITY_DEFAULT) -> Array:

	var d: = defaults(data, skill)
	var out: = []
	var labels: = {"name": "名前", "skill": "性技", "power": "強さ", "size": "陰茎のサイズ", "cum_speed": "射精の早さ", 
		"personality": "性格", "favorite": "本命", "natural_ntr": "自然発生NTR", "night_raid": "夜這い", "ply_drink": "酔わせる", "blackmail": "脅迫", "womanizer": "女たらし", "lend_demand": "寝取り趣味", "ntr_hobby": "寝取らせ趣味", "assault": "無理やり襲う", "annex": "離れ", "judge": "判定", "endless": "エンドレス"}
	for who in ["pc", "rival"]:
		for k in settings.get(who, {}):
			if who == "rival" and SPACE_TAB_RIVAL_KEYS.has(k):
				if bool(settings[who][k]) != bool(d[who].get(k, false)):
					out.append(["space", "%s → %s" % [I18n.t(labels.get(k, k)), I18n.t("オン") if bool(settings[who][k]) else I18n.t("オフ")]])
				continue
			if str(settings[who][k]) != str(d[who].get(k, "")):
				var before = d[who].get(k, "")
				var after = settings[who][k]
				if k == "power":
					before = power_label(data, str(before))
					after = power_label(data, str(after))
				elif k == "cum_speed":
					before = cum_speed_label(data, str(before))
					after = cum_speed_label(data, str(after))
				elif k == "personality":
					before = personality_label(data, str(before))
					after = personality_label(data, str(after))
				elif FLAG_KEYS.has(k):
					before = I18n.t("オン") if bool(before) else I18n.t("オフ")
					after = I18n.t("オン") if bool(after) else I18n.t("オフ")
				out.append([who, I18n.t("%s：%s %s → %s") % [I18n.t("主人公") if who == "pc" else I18n.t("ライバル"), I18n.t(labels.get(k, k)), before, after]])
	for k in settings.get("space", {}):
		if k == "judge":
			if str(settings["space"][k]) != str(d["space"][k]):
				out.append(["space", I18n.t("%s：%s → %s") % [I18n.t(labels[k]), I18n.t(State.JUDGE_LABELS.get(str(d["space"][k]), "")), I18n.t(State.JUDGE_LABELS.get(str(settings["space"][k]), str(settings["space"][k])))]])
			continue
		if SPACE_KEYS.has(k) and bool(settings["space"][k]) != bool(d["space"].get(k, false)):

			var on: = bool(settings["space"][k])
			out.append(["space", "%s → %s" % [I18n.t(labels.get(k, k)), (I18n.t("あり") if on else I18n.t("なし")) if k == "annex" else (I18n.t("オン") if on else I18n.t("オフ"))]])
	var axes: Dictionary = data["traits"]["axes"]
	for id in settings.get("heroines", {}):
		var short: = _short(data, id)
		var tr: Dictionary = settings["heroines"][id].get("traits", {})
		for axis in tr:
			if str(tr[axis]) != str(d["heroines"][id]["traits"].get(axis, "")):
				var vals: Dictionary = axes[axis]["values"]
				out.append([id, I18n.t("%s：%s %s → %s") % [short, I18n.data(axes[axis]["label"], "traits.json"), 
					I18n.data(vals.get(d["heroines"][id]["traits"][axis], {}).get("label", "?"), "traits.json"), I18n.data(vals.get(tr[axis], {}).get("label", tr[axis]), "traits.json")]])
		var rel: Dictionary = settings["heroines"][id].get("relation", {})
		for side in rel:
			if str(rel[side]) != "stranger":
				out.append([id, I18n.t("%s：%sとの関係 → %s") % [short, _who_label(data, side), I18n.t(str(START_RELATION_LABELS.get(str(rel[side]), rel[side])))]])
		var exp: Dictionary = settings["heroines"][id].get("experience", {})
		for side in exp:
			if bool(exp[side]):
				out.append([id, I18n.t("%s：%sとの経験 あり") % [short, _who_label(data, side)]])
		var fert: = str(settings["heroines"][id].get("fertility", State.FERTILITY_DEFAULT))
		if fert != State.FERTILITY_DEFAULT:
			out.append([id, I18n.t("%s：妊娠のしやすさ → %s") % [short, fertility_label(data, fert)]])

	var si: Dictionary = settings.get("intimacy", {})
	for k in d["intimacy"]:
		if si.has(k) and str(si[k]) != str(d["intimacy"][k]):
			var text: = I18n.t("%sの仲 %s → %s") % [_pair_label(data, k), intimacy_label(data, str(d["intimacy"][k])), intimacy_label(data, str(si[k]))]
			for hid in k.split("."):
				out.append([hid, text])
	var mods: = normalize_mods(settings.get("mods", {}))
	for key in MODS:
		if mods[key]:
			out.append(["mods", I18n.t("MOD: %s 켜짐") % I18n.t(MODS[key]["label"])])
	return out


static func fertility_label(data: Dictionary, level: String) -> String:

	return I18n.data(data["balance"]["fertility"]["labels"].get(level, level), "balance.json")


static func power_label(data: Dictionary, power: String) -> String:

	return I18n.data(data["rival"].get("power_levels", {}).get(power, {}).get("label", power), "rival.json")


static func cum_speed_label(data: Dictionary, lv: String) -> String:

	return I18n.data(data["rival"]["cum_speed"]["levels"].get(lv, {}).get("label", lv), "rival.json")


static func _who_label(data: Dictionary, who: String) -> String:
	match who:
		"pc": return I18n.t("主人公")
		"rival": return I18n.t("ライバル")
		"favorite": return I18n.t("本命")
	return _short(data, who)


static func _short(data: Dictionary, id: String) -> String:

	return I18n.t(str(data["characters"].get(id, {}).get("short", id)))




static func custom_presets() -> Dictionary:
	if not FileAccess.file_exists(custom_path):
		return {}
	return SaveCompat.unstamp(SaveCompat.upgrade("presets", SaveDir.read_json(custom_path)))


static func custom_desc(data: Dictionary, settings: Dictionary, skill: int = State.PC_ABILITY_DEFAULT) -> Dictionary:



	var cmp: Dictionary = _int_floats(settings.duplicate(true))
	if cmp.has("pc"):
		cmp["pc"]["name"] = defaults(data)["pc"]["name"]
	var all: = changes(data, cmp, skill)
	if all.is_empty():
		return {"short": I18n.t("標準のまま"), "full": I18n.t("標準のまま")}
	var sm: = summary(data, cmp)
	var rest: = _without_summary(data, cmp, skill)
	var n: = changes(data, rest, skill).size()
	var short: = ""
	if sm.is_empty():
		short = I18n.t("%sを変えた設定（%d 項目）") % [I18n.t("・").join(_change_kinds(data, rest, skill)), n]
	else:
		short = I18n.t("%s　ほか %d 項目") % [I18n.t("・").join(sm), n] if n > 0 else I18n.t("・").join(sm)
	return {"short": short, "full": "\n".join(all)}


static func _int_floats(v):

	if v is Dictionary:
		for k in v:
			v[k] = _int_floats(v[k])
	elif v is Array:
		for i in v.size():
			v[i] = _int_floats(v[i])
	elif v is float and is_equal_approx(v, roundf(v)):
		return int(v)
	return v


static func _without_summary(data: Dictionary, settings: Dictionary, skill: int) -> Dictionary:

	var d: = defaults(data, skill)
	var out: = settings.duplicate(true)
	var rv: Dictionary = out.get("rival", {})
	for k in ["power", "favorite", "natural_ntr"] + FLAG_KEYS:
		if rv.has(k):
			rv[k] = d["rival"][k]
	if str(rv.get("personality", d["rival"]["personality"])) == PERSONALITY_ABSENT:
		rv["personality"] = d["rival"]["personality"]
	var sp: Dictionary = out.get("space", {})
	for k in SPACE_KEYS:
		if sp.has(k):
			sp[k] = d["space"][k]
	for id in out.get("heroines", {}):
		var h: Dictionary = out["heroines"][id]
		h.erase("relation")
		h.erase("experience")
		h.erase("fertility")
	out.erase("intimacy")
	out.erase("mods")
	return out


static func _change_kinds(data: Dictionary, settings: Dictionary, skill: int) -> Array:

	var d: = defaults(data, skill)
	var labels: = {"skill": "性技", "size": "陰茎のサイズ", "cum_speed": "射精の早さ", "personality": "性格"}
	var out: = []
	for who in ["pc", "rival"]:
		for k in labels:
			if settings.get(who, {}).has(k) and str(settings[who][k]) != str(d[who].get(k, "")) and not out.has(I18n.t(labels[k])):
				out.append(I18n.t(labels[k]))
	for id in settings.get("heroines", {}):
		var tr: Dictionary = settings["heroines"][id].get("traits", {})
		if tr.keys().any( func(a): return str(tr[a]) != str(d["heroines"][id]["traits"].get(a, ""))):
			out.append(I18n.t("個性"))
			break
	if out.is_empty():
		out.append(I18n.t("ほかの項目"))
	return out


static func save_custom(name: String, settings: Dictionary, data: Dictionary = {}, skill: int = State.PC_ABILITY_DEFAULT) -> bool:


	var all: = custom_presets()
	var id: = "custom_" + name
	var desc: = I18n.t("自作")
	if not data.is_empty():
		desc = str(custom_desc(data, settings, skill)["short"])
	all[id] = {"id": id, "label": name, "desc": desc, "settings": settings}
	return _write(custom_path, SaveCompat.stamp("presets", all))


static func delete_custom(id: String) -> bool:
	var all: = custom_presets()
	all.erase(id)
	return _write(custom_path, SaveCompat.stamp("presets", all))


static func load_last() -> Dictionary:

	if not FileAccess.file_exists(last_path):
		return {}
	return SaveCompat.unstamp(SaveCompat.upgrade("last_settings", SaveDir.read_json(last_path)))


static func save_last(settings: Dictionary) -> bool:
	return _write(last_path, SaveCompat.stamp("last_settings", settings))


static func _write(path: String, d: Dictionary) -> bool:
	return SaveDir.write_json(path, d)

static func migrate_morning_cg(state: State) -> void:
	if int(state.flags.get("morning_cg_option_version", 0)) >= 1: return
	var mods = mods_from_state(state)
	mods["morning_cg"] = true
	state.flags["custom_mods"] = mods
	state.flags["morning_cg_option_version"] = 1
