class_name FaceWindowView
extends Control






const MARGIN: = 8.0
const PAD: = 3.0

var cfg: Dictionary = {}
var top: = MARGIN
var character_id: = ""
var expression: = ""

var _inner: Control
var _base: TextureRect
var _face: TextureRect


func _init() -> void :
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	anchor_left = 0.0
	anchor_right = 0.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	var frame: = Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", CrossSectionView._frame_style())
	add_child(frame)
	_inner = Control.new()
	_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_inner.offset_left = PAD
	_inner.offset_top = PAD
	_inner.offset_right = - PAD
	_inner.offset_bottom = - PAD
	_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner.clip_contents = true
	add_child(_inner)
	_base = _layer()
	_face = _layer()
	hide()


func _layer() -> TextureRect:
	var t: = TextureRect.new()
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	_inner.add_child(t)
	return t


func applies(id: String, p_cg: String) -> bool:

	return p_cg in cfg.get("cgs", []) and cfg.get("rects", {}).has(id) and CgView.has_cg(id, str(cfg.get("from", "")))


func show_for(id: String, p_cg: String, p_expression: String, on: bool) -> void :

	if not on or p_expression == "__no_face__" or not applies(id, p_cg):
		hide()
		return
	character_id = id
	expression = p_expression
	var src: = str(cfg["from"])
	_base.texture = CgView._load(CgView.base_path(id, src))
	_face.texture = CgView._load(CgView.face_path(id, src, p_expression))
	_face.visible = _face.texture != null
	_layout(cfg["rects"][id])
	show()


func _layout(rect: Array) -> void :

	var ts: = _base.texture.get_size()
	var r: = Rect2(Vector2(float(rect[0]), float(rect[1])) * ts, Vector2(float(rect[2]) - float(rect[0]), float(rect[3]) - float(rect[1])) * ts)
	var w: = float(cfg.get("width", 180.0))
	var cw: = w - PAD * 2
	var k: = cw / maxf(1.0, r.size.x)
	var h: = r.size.y * k + PAD * 2
	offset_left = MARGIN
	offset_right = MARGIN + w
	offset_top = top
	offset_bottom = top + h
	for t in [_base, _face]:
		t.position = - r.position * k
		t.size = ts * k
