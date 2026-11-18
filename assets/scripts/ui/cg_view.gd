class_name CgView
extends Control





















const ART_DIR: = "res://art"
const DEFAULT_CG: = "missionary"


const BG_SHADER: = "\nshader_type canvas_item;\nuniform sampler2D light_tex : filter_linear, repeat_disable;\nuniform sampler2D steam_tex : filter_linear, repeat_disable;\nuniform vec2 view = vec2(1.0);\nuniform float bg_aspect = 1.0;\nuniform vec3 steam_color : source_color = vec3(0.92, 0.87, 0.80);\nuniform float steam_amount = 1.0;\nuniform float steam_on_body = 0.6;\nvec2 bg_uv(vec2 uv) {\n\tfloat a = view.x / max(view.y, 1.0);\n\tif (a >= bg_aspect) return vec2(uv.x, 0.5 + (uv.y - 0.5) * bg_aspect / a);\n\treturn vec2(0.5 + (uv.x - 0.5) * a / bg_aspect, uv.y);\n}\nvoid fragment() {\n\tvec2 bu = bg_uv(UV);\n\tvec3 col = texture(TEXTURE, bu).rgb * texture(light_tex, bu).rgb * 2.0;\n\tfloat s = clamp(texture(steam_tex, bu).r * steam_amount, 0.0, 0.95);\n\tfloat k = steam_on_body;\n\t// 一番上の湯気（k × s）と重ねて s になる濃さ\n\tfloat s0 = s * (1.0 - k) / max(1.0 - k * s, 1e-4);\n\tCOLOR = vec4(mix(col, steam_color, s0), 1.0);\n}\n"

























const BODY_SHADER: = "\nshader_type canvas_item;\nuniform sampler2D light_tex : filter_linear, repeat_disable;\nuniform vec2 inv_x = vec2(1.0, 0.0);   // 世界の座標 → 枠（CgView）のローカル座標（get_global_transform の逆）\nuniform vec2 inv_y = vec2(0.0, 1.0);\nuniform vec2 inv_o = vec2(0.0);\nuniform vec2 view = vec2(1.0);\nuniform float bg_aspect = 1.0;\nuniform float char_light = 0.5;\nvarying vec2 fuv;\nvec2 bg_uv(vec2 uv) {\n\tfloat a = view.x / max(view.y, 1.0);\n\tif (a >= bg_aspect) return vec2(uv.x, 0.5 + (uv.y - 0.5) * bg_aspect / a);\n\treturn vec2(0.5 + (uv.x - 0.5) * a / bg_aspect, uv.y);\n}\nvoid vertex() {\n\tvec2 w = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;\n\tfuv = (inv_x * w.x + inv_y * w.y + inv_o) / view;\n}\nvoid fragment() {\n\tvec3 lt = texture(light_tex, bg_uv(fuv)).rgb * 2.0;\n\tCOLOR.rgb *= mix(vec3(1.0), lt, char_light);\n}\n"

























const STEAM_SHADER: = "\nshader_type canvas_item;\nuniform vec2 view = vec2(1.0);\nuniform float bg_aspect = 1.0;\nuniform vec3 steam_color : source_color = vec3(0.92, 0.87, 0.80);\nuniform float steam_amount = 1.0;\nuniform float steam_on_body = 0.6;\nvec2 bg_uv(vec2 uv) {\n\tfloat a = view.x / max(view.y, 1.0);\n\tif (a >= bg_aspect) return vec2(uv.x, 0.5 + (uv.y - 0.5) * bg_aspect / a);\n\treturn vec2(0.5 + (uv.x - 0.5) * a / bg_aspect, uv.y);\n}\nvoid fragment() {\n\tfloat s = clamp(texture(TEXTURE, bg_uv(UV)).r * steam_amount, 0.0, 0.95);\n\tCOLOR = vec4(steam_color, s * steam_on_body);\n}\n"

















var bg: TextureRect
var _group: Control
var cut: TextureRect
var steam: TextureRect
var shown_bg: = ""
var _place: Dictionary = {}
var _place_room: = ""
var _bg_mat: = ShaderMaterial.new()
var _body_mat: = ShaderMaterial.new()
var _steam_mat: = ShaderMaterial.new()
var base: TextureRect
var face: TextureRect
var crotch: TextureRect
var hole: TextureRect
var shaft_clip: Control
var shaft: TextureRect
var ring: TextureRect
var _waiting: = false
var cum: TextureRect
var body: TextureRect
var cum_level: = 0
var body_level: = 0
var cum_in: = false
var creampie: = false
var _shown_cum: = 0
var _shown_body: = 0
var _shaft_images: Array = [null, null]

var character_id: = ""
var cg: = ""
var expression: = ""
var cross_section: CrossSectionView
var face_window: FaceWindowView
var _shaft_spec: Dictionary = {}
var shaft_x_scale: = 1.0
var debug_shaft: Dictionary = {}
var _shaft_stroke_px: = 0.0
var _shaft_tip_y: = 0.0
var _shaft_pull_max_y: = INF
var bag: CondomFx.Bag
var _condom_cfg: Dictionary = {}
var _cg_tip_out_y: = 0.0


static var _cache: Dictionary = {}

static var only_ids: Array = []


func _init() -> void :
	bg = _full_rect(self)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	var sh: = Shader.new()
	sh.code = BG_SHADER
	_bg_mat.shader = sh
	bg.material = _bg_mat
	bg.hide()
	_group = Control.new()
	_group.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_group)
	sh = Shader.new()
	sh.code = BODY_SHADER
	_body_mat.shader = sh
	cut = TextureRect.new()
	cut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cut.stretch_mode = TextureRect.STRETCH_SCALE
	cut.use_parent_material = true
	cut.hide()
	_group.add_child(cut)
	base = _layer()
	body = _layer()
	face = _layer()
	crotch = _layer()
	hole = _layer()
	shaft_clip = Control.new()
	shaft_clip.clip_contents = true
	shaft_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shaft_clip.use_parent_material = true
	shaft_clip.hide()
	_group.add_child(shaft_clip)
	shaft = TextureRect.new()
	shaft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shaft.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shaft.stretch_mode = TextureRect.STRETCH_SCALE
	shaft.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	shaft_clip.add_child(shaft)
	bag = CondomFx.Bag.new()
	shaft_clip.add_child(bag)
	ring = _layer()
	cum = _layer()
	steam = _full_rect(self)
	steam.stretch_mode = TextureRect.STRETCH_SCALE
	sh = Shader.new()
	sh.code = STEAM_SHADER
	_steam_mat.shader = sh
	steam.material = _steam_mat
	steam.hide()
	resized.connect(_layout_shaft)
	resized.connect(_layout_place)
	set_notify_transform(true)
	visibility_changed.connect(_sync_face_window)
	set_process(false)


func _notification(what: int) -> void :
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		_update_body_xform()


func _layer() -> TextureRect:

	var t: = _full_rect(_group)
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.use_parent_material = true
	return t


func _full_rect(parent: Control) -> TextureRect:
	var t: = TextureRect.new()
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parent.add_child(t)
	return t




func show_cg(id: String, p_cg: String, p_expression: String, inserted: bool, p_cum_level: int = 0, shaft_cfg: Dictionary = {}, waiting: bool = false, p_body_level: int = 0, p_creampie: bool = false) -> void :




	character_id = id
	cg = p_cg
	p_expression = load("res://scripts/scenarios/expression_filter.gd").resolve_expression(id, p_cg, p_expression)
	_group.visible = p_expression != "__no_face__"
	expression = p_expression
	base.texture = _load(base_path(id, p_cg))
	face.texture = _face_texture(id, p_cg, p_expression)
	crotch.texture = _load(crotch_path(id, p_cg)) if inserted else null
	cum_level = p_cum_level
	body_level = p_body_level
	creampie = p_creampie
	cum_in = false
	face.visible = face.texture != null
	crotch.visible = crotch.texture != null
	_waiting = waiting and not inserted
	_shaft_spec = shaft_cfg.get("cgs", {}).get("%s/%s" % [id, p_cg], {}).duplicate(true) if inserted or _waiting else {}
	if not _shaft_spec.is_empty():
		for key in debug_shaft:
			if key == "clip_top":
				_shaft_spec["clip"][1] = debug_shaft[key]
			else:
				_shaft_spec[key] = debug_shaft[key]
	_shaft_images = [_load(str(shaft_cfg.get("image", ""))), _load(str(shaft_cfg.get("image_cum", "")))] if not _shaft_spec.is_empty() else [null, null]
	_apply_shaft_texture()
	if shaft.texture == null:
		_shaft_spec = {}
	_apply_cum(cum_level, body_level)
	var has_shaft: = not _shaft_spec.is_empty()
	hole.texture = _load(hole_path(id, p_cg)) if has_shaft else null
	ring.texture = _load(ring_path(id, p_cg)) if has_shaft else null
	shaft_clip.visible = has_shaft
	hole.visible = hole.texture != null
	ring.visible = ring.texture != null
	set_process(has_shaft)
	_layout_shaft()
	_process(0.0)
	_sync_face_window()
	_apply_place()


func set_place(cfg: Dictionary, room: String) -> void :


	var r = cfg.get("rooms", {}).get(room)
	_place = r if typeof(r) == TYPE_DICTIONARY else {}
	_place_room = room if not _place.is_empty() else ""


func _apply_place() -> void :

	var c = _place.get("cgs", {}).get(cg) if not _place.is_empty() else null
	var cut_tex: Texture2D = _load(cut_path(character_id, cg)) if typeof(c) == TYPE_DICTIONARY else null
	var floor_tex: Texture2D = _load(str(c["image"])) if cut_tex != null else null
	var on: = floor_tex != null and base.texture != null
	shown_bg = _place_room if on else ""
	bg.visible = on
	cut.visible = on
	steam.visible = on
	base.visible = not on
	_group.material = _body_mat if on else null
	if not on:
		cut.texture = null
		return
	var light: Texture2D = _load(str(_place["light"]))
	var steam_tex: Texture2D = _load(str(_place["steam"]))
	var aspect: = float(floor_tex.get_width()) / float(floor_tex.get_height())
	var amount: = float(c.get("steam_amount", 1.0))
	var color: = Color.html(str(_place["steam_color"]))
	var k: = float(_place["steam_on_body"])
	bg.texture = floor_tex
	cut.texture = cut_tex
	steam.texture = steam_tex
	for m in [_bg_mat, _steam_mat]:
		m.set_shader_parameter("bg_aspect", aspect)
		m.set_shader_parameter("steam_color", color)
		m.set_shader_parameter("steam_amount", amount)
		m.set_shader_parameter("steam_on_body", k)
	_bg_mat.set_shader_parameter("light_tex", light)
	_bg_mat.set_shader_parameter("steam_tex", steam_tex)
	_body_mat.set_shader_parameter("light_tex", light)
	_body_mat.set_shader_parameter("bg_aspect", aspect)
	_body_mat.set_shader_parameter("char_light", float(_place["char_light"]))
	_layout_place()


func _layout_place() -> void :

	for m in [_bg_mat, _steam_mat, _body_mat]:
		m.set_shader_parameter("view", size)
	_update_body_xform()
	if cut.texture == null or base.texture == null:
		return
	var r: = display_rect()
	var k: = r.size.y / float(base.texture.get_height())
	var cs: = cut.texture.get_size() * k
	cut.position = Vector2(r.position.x - (cs.x - r.size.x) / 2.0, r.position.y)
	cut.size = cs


func _update_body_xform() -> void :

	if not is_inside_tree():
		return
	var inv: = get_global_transform().affine_inverse()
	_body_mat.set_shader_parameter("inv_x", inv.x)
	_body_mat.set_shader_parameter("inv_y", inv.y)
	_body_mat.set_shader_parameter("inv_o", inv.origin)


func display_rect() -> Rect2:

	if base.texture == null:
		return Rect2(Vector2.ZERO, size)
	var ts: = base.texture.get_size()
	var scale: = minf(size.x / ts.x, size.y / ts.y)
	var disp: = ts * scale
	return Rect2((size - disp) / 2.0, disp)


func shaft_spec() -> Dictionary:

	return _shaft_spec


func _layout_shaft() -> void :

	if _shaft_spec.is_empty() or shaft.texture == null:
		return
	var r: = display_rect()
	var clip: Array = _shaft_spec["clip"]
	var top_left: = r.position + Vector2(float(clip[0]), float(clip[1])) * r.size
	shaft_clip.position = top_left
	shaft_clip.size = Vector2(float(clip[2]) - float(clip[0]), float(clip[3]) - float(clip[1])) * r.size
	var ts: = shaft.texture.get_size()
	var w0: = float(_shaft_spec["width"]) * r.size.x
	var w: = w0 * float(_shaft_spec.get("x_scale", shaft_x_scale))
	shaft.size = Vector2(w, ts.y * w0 / maxf(1.0, ts.x))
	shaft.position.x = r.position.x + float(_shaft_spec["x"]) * r.size.x - w / 2.0 - top_left.x
	_shaft_tip_y = r.position.y + float(_shaft_spec["tip"]) * r.size.y - top_left.y
	_shaft_stroke_px = float(_shaft_spec["stroke"]) * r.size.y
	_shaft_pull_max_y = r.position.y + float(_shaft_spec["pull_max"]) * r.size.y - top_left.y if _shaft_spec.has("pull_max") else INF
	_cg_tip_out_y = float(_condom_cfg.get("cg_tip_out", 0.05)) * r.size.y


func _process(_delta: float) -> void :





	var tip: = CondomFx.shaft_tip(shaft.texture) if shaft.texture != null else {}
	if not tip.is_empty():
		bag.tip_width = float(tip["w"]) * shaft.size.x
	var d: = cross_section.depth if cross_section != null else 0.0
	var out_condom: = cross_section != null and cross_section.pull_condom and cross_section.pull_progress >= 0.0
	var inside: = d <= 1.0 or out_condom or _waiting

	var y: = _shaft_tip_y + d * _shaft_stroke_px
	if _waiting:
		y = _cg_tip_out_y
	elif out_condom:
		y = lerpf(minf(y, _shaft_pull_max_y), _cg_tip_out_y + bag.extent(), cross_section.pull_progress)
	elif not (cross_section != null and cross_section.unclamped):
		y = minf(y, _shaft_pull_max_y)
	shaft.position.y = y
	var exited: = y > 0.0 or _waiting
	shaft_clip.visible = inside and not _shaft_spec.is_empty()
	hole.visible = inside and not exited and hole.texture != null
	ring.visible = inside and not exited and ring.texture != null
	var now_in: = shaft_clip.visible and not exited
	if now_in != cum_in:
		cum_in = now_in
		_apply_cum(_shown_cum, _shown_body)
	_place_bag()


func _place_bag() -> void :

	var tip: = CondomFx.shaft_tip(shaft.texture) if shaft.texture != null else {}
	var on: = shaft_clip.visible and not tip.is_empty() and bag.amount > 0.001
	bag.visible = on
	if on:
		bag.position = shaft.position + Vector2(float(tip["x"]) * shaft.size.x, float(tip["y"]) * shaft.size.y)
		bag.tip_width = float(tip["w"]) * shaft.size.x


func set_bag(amount: float, cfg: Dictionary) -> void :

	_condom_cfg = cfg
	bag.cfg = cfg.get("bag", {})
	if cfg.has("color"):
		bag.film = Color.html(str(cfg["color"]))
	bag.set_amount(amount)
	_layout_shaft()
	_place_bag()


func hold_cum(p_cum_level: int, p_body_level: int) -> void :


	_apply_cum(mini(p_cum_level, cum_level), mini(p_body_level, body_level))


func release_cum() -> void :

	_apply_cum(cum_level, body_level)


func _apply_cum(p_cum: int, p_body: int) -> void :
	_shown_cum = p_cum
	_shown_body = p_body
	cum.texture = _load_level(cum_in_path(character_id, cg), p_cum) if cum_in else null
	if cum.texture == null and creampie and not cum_in and not _shaft_spec.is_empty():
		cum.texture = _load_level(out_path(character_id, cg), p_cum)
	if cum.texture == null:
		cum.texture = _load_level(cum_path(character_id, cg), p_cum)
	body.texture = _load_level(body_path(character_id, cg), p_body)
	cum.visible = cum.texture != null
	body.visible = body.texture != null
	_apply_shaft_texture()


func _apply_shaft_texture() -> void :

	var tex = _shaft_images[1] if _shown_cum >= 1 and _shaft_images[1] != null else _shaft_images[0]
	if shaft.texture != tex:
		shaft.texture = tex


static func _face_texture(id: String, pose: String, key: String) -> Texture2D:
	if key == "__no_face__" or not load("res://scripts/scenarios/expression_filter.gd").allowed(id, pose, key): return null
	var additions = load("res://scripts/scenarios/facel_cfg.gd")
	if key in additions.NEW_KEYS or key.begins_with(additions.FP_PREFIX):
		var extra: Texture2D = additions.hs_tex(id, pose, key)
		if extra != null: return extra
	return load("res://scripts/scenarios/expression_filter.gd").raw_texture(face_path(id, pose, key))

func set_face(p_expression: String) -> void :
	p_expression = load("res://scripts/scenarios/expression_filter.gd").resolve_expression(character_id, cg, p_expression)
	_group.visible = p_expression != "__no_face__"

	expression = p_expression
	face.texture = _face_texture(character_id, cg, p_expression)
	face.visible = face.texture != null
	_sync_face_window()


func _sync_face_window() -> void :

	if face_window != null:
		face_window.show_for(character_id, cg, expression, visible)


static func cg_for(id: String, position: String) -> String:

	for candidate in [position, DEFAULT_CG]:
		if not candidate.is_empty() and has_cg(id, candidate):
			return candidate
	return ""


static func has_cg(id: String, p_cg: String) -> bool:
	return not locked(id) and ResourceLoader.exists(base_path(id, p_cg), "Texture2D")


static func locked(id: String) -> bool:

	return not only_ids.is_empty() and not only_ids.has(id)




static func base_path(id: String, p_cg: String) -> String:
	return "%s/%s/%s/base.png" % [ART_DIR, id, p_cg]


static func cut_path(id: String, p_cg: String) -> String:

	return "%s/%s/%s/cut.png" % [ART_DIR, id, p_cg]


static func face_path(id: String, p_cg: String, p_expression: String) -> String:
	if p_expression.begins_with("kx_"):
		return "res://scripts/scenarios/art/face_hs/%s/%s_%s.png" % [id, p_cg, p_expression]
	return "%s/%s/%s/face_%s.png" % [ART_DIR, id, p_cg, p_expression]


static func crotch_path(id: String, p_cg: String) -> String:
	return "%s/%s/%s/crotch_open.png" % [ART_DIR, id, p_cg]


static func cum_path(id: String, p_cg: String) -> String:
	return "%s/%s/%s/crotch_cum.png" % [ART_DIR, id, p_cg]


static func cum_in_path(id: String, p_cg: String) -> String:

	return "%s/%s/%s/crotch_cum_in.png" % [ART_DIR, id, p_cg]


static func out_path(id: String, p_cg: String) -> String:

	return "%s/%s/%s/crotch_out.png" % [ART_DIR, id, p_cg]


static func body_path(id: String, p_cg: String) -> String:
	return "%s/%s/%s/body_cum.png" % [ART_DIR, id, p_cg]


static func hole_path(id: String, p_cg: String) -> String:
	return "%s/%s/%s/crotch_hole.png" % [ART_DIR, id, p_cg]


static func ring_path(id: String, p_cg: String) -> String:
	return "%s/%s/%s/crotch_inserted.png" % [ART_DIR, id, p_cg]




static func _load_level(path: String, level: int) -> Texture2D:

	if level <= 0:
		return null
	if level >= 2:
		var heavy: = _load(path.get_basename() + "_heavy.png")
		if heavy != null:
			return heavy
	return _load(path)


static func _load(path: String) -> Texture2D:
	path = load("res://scripts/scenarios/expression_filter.gd").resolve_path(path)
	if path.is_empty(): return null
	if path.begins_with("res://scripts/scenarios/art/"):
		return load("res://scripts/scenarios/art_access.gd").texture(path)
	if not _cache.has(path):
		if _cache.size() >= 48: _cache.erase(_cache.keys()[0])
		_cache[path] = load(path) if ResourceLoader.exists(path, "Texture2D") else null
	return _cache[path]
