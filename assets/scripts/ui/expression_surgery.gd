extends CanvasLayer
const C = preload("res://scripts/scenarios/expression_conditions.gd")
const S = preload("res://scripts/scenarios/expression_surgery.gd")
const F = preload("res://scripts/scenarios/expression_filter.gd")
const WHO = {"reimu": "레이무", "sakuya": "사쿠야", "marisa": "마리사", "sanae": "사나에"}
var _main
var _button: Button
var _root: Control
var _panel: PanelContainer
var _zoom: PanelContainer
var _contexts: Array = []
var _context: Dictionary = {}
var _cards: Array = []
var _scroll: ScrollContainer
var _status: Label
var _edit_token = ""
var _state_id = 0
var _set_mode = true
var _set_choices: Array = []
var _set_summary: Label
var _set_grid: GridContainer
var _set_source: OptionButton
var _set_order: OptionButton
var _preset_popup: PanelContainer
var _preset_hold = 0
var _preset_press_position = Vector2.ZERO
var _capture_session = false
func _ready() -> void:
	name = "ExpressionSurgery";layer = 130;process_mode = Node.PROCESS_MODE_ALWAYS;_main = get_parent()
	_button = Button.new();_button.name = "SurgeryFloatingButton";_button.text = "표정 고르기♡";_button.custom_minimum_size = Vector2(122, 42)
	_button.set_meta("hold_repeat_disabled", true);_button.pressed.connect(open_current);add_child(_button);_button.hide()
	_root = Control.new();_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_root.mouse_filter = Control.MOUSE_FILTER_STOP;add_child(_root)
	var shade = ColorRect.new();shade.color = Color(0, 0, 0, 0.85);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_root.add_child(shade);_root.hide()
func is_open() -> bool: return is_instance_valid(_root) and _root.visible
func _label(parent: Control, text: String) -> Label:
	var label = Label.new();label.text = text;label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label);return label
func _action(parent: Control, text: String, fn: Callable, node_name: String = "") -> Button:
	var b = Button.new();b.text = text;b.custom_minimum_size.y = 44;b.set_meta("hold_repeat_disabled", true)
	if not node_name.is_empty(): b.name = node_name
	b.pressed.connect(fn);parent.add_child(b);return b
func _make_panel() -> PanelContainer:
	var p = PanelContainer.new();p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.offset_left = -548;p.offset_right = 548;p.offset_top = -330;p.offset_bottom = 330
	var style = StyleBoxFlat.new();style.bg_color = Color("#171b28");style.border_color = Color("#7983ac");style.set_border_width_all(1);style.set_corner_radius_all(12)
	p.add_theme_stylebox_override("panel", style);_root.add_child(p);return p
func _box(p: Control) -> VBoxContainer:
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	p.add_child(margin);var box = VBoxContainer.new();box.add_theme_constant_override("separation", 8);margin.add_child(box);return box
func _clear_zoom() -> void:
	if is_instance_valid(_zoom): _zoom.hide();_zoom.queue_free();_zoom = null
func _begin() -> VBoxContainer:
	_close_presets();_clear_zoom();_cards.clear();_scroll = null
	if is_instance_valid(_panel): _panel.hide();_panel.queue_free()
	_panel = _make_panel();_root.show();return _box(_panel)
func _game_visible() -> bool:
	if GameState.state == null: return false
	for key in ["title_screen", "new_game_screen", "intro", "gallery", "ending", "take_home"]:
		var node = _main.get(key)
		if node != null and node.is_visible_in_tree(): return false
	return true
func visible_contexts() -> Array:
	var st = GameState.state;var result: Array = []
	if st == null: return result
	if SceneSex.active(st) and _main.sex_scene.is_visible_in_tree():
		var sx = _main.sex_scene;var id = str(st.scene.get("id", ""));var view = "";var fallback = ""
		if sx._cg.visible: view = str(sx._cg.cg);fallback = str(sx._cg.expression)
		elif sx._fellatio.visible: view = "fellatio";fallback = str(sx._fellatio.shown_face)
		elif sx._paizuri.visible: view = "paizuri";fallback = str(sx._paizuri.shown_face)
		elif sx._portrait.visible: view = "scene_portrait";fallback = str(sx._portrait.expression)
		if view == "doggy" and sx._face_window.visible:
			view = str(sx._face_window.cfg.get("from", "missionary"));fallback = str(sx._face_window.expression)
		if WHO.has(id) and F.VIEWS.has(view): result.append(S.observed(st, id, view, fallback))
		if SceneSexHarem.active(st) and sx._harem.visible:
			var slots = SceneSexHarem.slots(st)
			for slot in ["left", "back", "back2"]:
				var who = str(slots.get(slot, ""));var kind = "front" if slot == "left" else "peek"
				if WHO.has(who): result.append(S.observed(st, who, "harem_" + kind, str(SceneSexHarem.waiting_face(st, who))))
	else:
		for id in WHO:
			var portrait = _main.stage._portraits.get(id)
			if portrait != null and portrait.is_visible_in_tree(): result.append(S.observed(st, id, "standing", str(portrait.expression)))
	return result
func _condition(ctx: Dictionary) -> String:
	return "%s · %s · 관계: %s\n%s" % [WHO.get(str(ctx.id), str(ctx.id)), F.VIEWS.get(str(ctx.view), str(ctx.view)), F.RELATIONS.get(F.normalize_relation(str(ctx.relation)), str(ctx.relation)), C.describe(ctx.get("filters", {}))] + (" · 원본 " + str(ctx.source) if str(ctx.source) != "*" else "")
func open_current() -> void:
	_capture_session = true;_main.get_node("F3ModWindow").close_window();_contexts = []
	for raw in visible_contexts(): _contexts.append(load("res://scripts/scenarios/expression_branch.gd").context(GameState.state, raw))
	if _contexts.is_empty():
		var box = _begin();_label(box, "표정 고르기 · 인물이 보이는 화면에서 열어 주세요.");_action(box, "닫기", close);return
	var index = 0
	for i in _contexts.size():
		if str(_contexts[i].id) == str(_main.target): index = i;break
	_open_captured(index)
func _open_captured(index: int) -> void:
	var ctx: Dictionary = _contexts[index].duplicate(true);var saved: Dictionary = {}
	for row in S.rules():
		if S.identity(row) == S.identity(ctx): saved = row;break
	open_set(ctx, S.targets(saved) if not saved.is_empty() else [], S.identity(saved) if not saved.is_empty() else "")
func open_legacy_current() -> void: open_current()
func edit_rule(row: Dictionary) -> void:
	_capture_session = false;open_set(row, S.targets(row), S.identity(row))
func _context_valid(ctx: Dictionary) -> bool:
	var st = GameState.state
	if st == null or st.get_instance_id() != _state_id: return false
	for current in visible_contexts():
		if str(current.id) == str(ctx.id) and str(current.view) == str(ctx.view) and str(current.relation) == str(ctx.relation): return true
	return false
func open_set(ctx: Dictionary, choices: Array, old_token: String = "") -> void:
	_main.get_node("F3ModWindow").close_window();_set_mode = true;_context = ctx.duplicate(true);_context.erase("actor")
	_context.relation = F.normalize_relation(str(_context.relation));_set_choices = choices.filter(func(k): return str(k) == S.ORIGINAL or not F.deleted(str(ctx.id), str(ctx.view), str(k)));_edit_token = old_token
	_state_id = GameState.state.get_instance_id() if GameState.state != null else 0
	var box = _begin()
	var header = HBoxContainer.new();box.add_child(header)
	var title = _label(header, "표정 집합 · 직접 고른 표정만 사용");title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action(header, "저장된 프리셋 ▾", _toggle_presets, "SavedExpressionPresetsButton")
	if _contexts.size() > 1 and _capture_session:
		var select = OptionButton.new();select.name = "CapturedCharacter";select.custom_minimum_size.y = 44;box.add_child(select)
		for candidate in _contexts: select.add_item(str(WHO[candidate.id]) + " · " + str(F.VIEWS[candidate.view]))
		for i in _contexts.size():
			if _contexts[i].id == _context.id and _contexts[i].view == _context.view: select.select(i);break
		select.item_selected.connect(_open_captured)
	var heading = _label(box, _condition(_context));heading.name = "CurrentExpressionRelationship";heading.max_lines_visible = 3
	var controls = HBoxContainer.new();box.add_child(controls)
	_action(controls, "세부 조건", open_conditions, "SetConditions")
	_set_order = OptionButton.new();_set_order.name = "SetOrder";_set_order.custom_minimum_size = Vector2(240, 44);_set_order.add_item("무작위 · 연속 중복 방지");_set_order.add_item("선택한 순서대로")
	_set_order.select(0 if str(_context.get("order", "cycle")) == "random" else 1);controls.add_child(_set_order)
	_set_order.item_selected.connect(func(i): _context["order"] = "random" if i == 0 else "cycle";_sync_set_summary())
	_set_source = OptionButton.new();_set_source.name = "SetSource";_set_source.add_item("모든 표정");_set_source.add_item("기본 표정만");_set_source.add_item("추가 표정만");_set_source.custom_minimum_size = Vector2(220, 44);controls.add_child(_set_source);_set_source.item_selected.connect(func(_i): _populate_set())
	_action(controls, "삭제한 표정 복원", func(): _main.get_node("ExpressionInspector").open_restore(str(_context.id), _refresh_deleted), "RestoreDeletedExpressions")
	_set_summary = _label(box, "");_set_summary.custom_minimum_size.y = 42;_set_summary.max_lines_visible = 2
	_scroll = ScrollContainer.new();_scroll.name = "ExpressionSetPickerScroll";_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL;_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;box.add_child(_scroll)
	_set_grid = GridContainer.new();_set_grid.name = "ExpressionSetPickerGrid";_set_grid.columns = 3;_set_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL;_set_grid.add_theme_constant_override("h_separation", 12);_set_grid.add_theme_constant_override("v_separation", 12);_scroll.add_child(_set_grid)
	var actions = HBoxContainer.new();box.add_child(actions)
	_action(actions, "집합 저장", _save_set, "SaveExpressionSet")
	_action(actions, "원래 표정 사용", func(): _set_choices = [S.ORIGINAL];_save_set(), "PassthroughExpressionSet")
	_action(actions, "선택 비우기", func(): _set_choices.clear();_sync_checks())
	_action(actions, "취소", close);_populate_set()
func _refresh_deleted() -> void:
	if is_open() and is_instance_valid(_set_grid): _populate_set()
func _sync_set_summary() -> void:
	_set_summary.text = "선택 %d/%d · %s" % [_set_choices.size(), S.MAX_CHOICES, " → ".join(_set_choices.map(func(k): return "원래 표정" if str(k) == S.ORIGINAL else str(k))) if not _set_choices.is_empty() else "선택 없음 · 저장할 표정을 골라 주세요"]
func _sync_checks() -> void:
	for card in _cards: _sync_pick(card.check, card.row)
	_sync_set_summary()
func _toggle_set(key: String, on: bool) -> bool:
	if on and not _set_choices.has(key):
		if _set_choices.size() >= S.MAX_CHOICES: _set_summary.text = "최대 %d개까지 선택할 수 있습니다." % S.MAX_CHOICES;return false
		_set_choices.append(key)
	elif not on: _set_choices.erase(key)
	_sync_set_summary();return true
func _original_entry() -> Dictionary:
	var key = str(_context.get("original_key", _context.source))
	if key == "*": key = str(S.observed(GameState.state, str(_context.id), str(_context.view), "neutral").source)
	var row = F.entry(str(_context.id), str(_context.view), key)
	return {} if not row.is_empty() and F.deleted(str(row.id), str(row.view), str(row.key)) else row
func _populate_set() -> void:
	_cards.clear()
	for node in _set_grid.get_children(): _set_grid.remove_child(node);node.queue_free()
	var catalog = F.visible_entries(str(_context.id), str(_context.view))
	for raw in catalog:
		if bool(raw.get("baked", false)): continue
		var extra = str(raw.source) == "additional"
		if (_set_source.selected == 1 and extra) or (_set_source.selected == 2 and not extra): continue
		var row: Dictionary = raw.duplicate(true);var column = VBoxContainer.new();column.custom_minimum_size.x = 336;column.size_flags_horizontal = Control.SIZE_EXPAND_FILL;_set_grid.add_child(column)
		var preview = _action(column, "", func(): _set_preview(row), "SetPreview_" + str(row.key));preview.custom_minimum_size.y = 168
		var image = TextureRect.new();image.mouse_filter = Control.MOUSE_FILTER_IGNORE;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;preview.add_child(image)
		var controls = HBoxContainer.new();column.add_child(controls)
		var check = Button.new();check.toggle_mode = true;check.name = "SetPick_" + str(row.key);check.custom_minimum_size = Vector2(210, 60);check.size_flags_horizontal = Control.SIZE_EXPAND_FILL;check.set_meta("hold_repeat_disabled", true);check.clip_text = true;check.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_style_pick(check);_sync_pick(check, row)
		check.disabled = not F.allowed(str(row.id), str(row.view), str(row.key), str(_context.relation));check.toggled.connect(func(on):
			if not _toggle_set(str(row.key), on): check.set_pressed_no_signal(not on)
			_sync_checks())
		controls.add_child(check)
		var remove = _action(controls, "완전 삭제", func():
			if F.set_deleted(row, true) == OK:
				_set_choices.erase(str(row.key));_cards = _cards.filter(func(card): return str(card.row.key) != str(row.key));column.hide();column.queue_free();_sync_set_summary()
			else: _set_summary.text = "삭제 설정 저장 실패", "DeleteExpression_" + str(row.key))
		remove.add_theme_font_size_override("font_size", 14)
		remove.custom_minimum_size = Vector2(88, 44)
		remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		remove.tooltip_text = "이 캐릭터·화면의 모든 관계에서 차단합니다. 복원 메뉴에서만 되돌릴 수 있습니다."
		_cards.append({"preview": image, "row": row, "loaded": false, "check": check})
	if _cards.is_empty(): _label(_set_grid, "선택 가능한 표정이 없습니다. 삭제한 표정 복원 메뉴를 확인해 주세요.")
	_scroll.scroll_vertical = 0;_sync_set_summary()
func _set_preview(row: Dictionary) -> void:
	if F.deleted(str(row.id), str(row.view), str(row.key)): return
	_clear_zoom();_zoom = _make_panel();var box = _box(_zoom);_label(box, _condition(_context));_label(box, "후보: " + str(row.key))
	var area = preload("res://scripts/ui/expression_camera.gd").new();area.custom_minimum_size = Vector2(960, 350);area.size_flags_vertical = Control.SIZE_EXPAND_FILL;box.add_child(area)
	_main.get_node("ExpressionInspector")._draw_pose(area, row)
	var actions = HBoxContainer.new();box.add_child(actions);var selected = _set_choices.has(str(row.key))
	_action(actions, "집합에서 제거" if selected else "집합에 추가", func():
		if not selected and not F.allowed(str(row.id), str(row.view), str(row.key), str(_context.relation)): return
		if _toggle_set(str(row.key), not selected): _sync_checks();_clear_zoom(), "SetPreviewApply")
	_action(actions, "돌아가기", _clear_zoom)
func open_conditions() -> void:
	_clear_zoom();_zoom = _make_panel();var box = _box(_zoom);_label(box, "적용 조건 · 체크하지 않은 항목은 구분하지 않습니다")
	var editor = preload("res://scripts/ui/expression_condition_editor.gd").new();editor.size_flags_vertical = Control.SIZE_EXPAND_FILL;box.add_child(editor);editor.setup(_context)
	var actions = HBoxContainer.new();box.add_child(actions)
	_action(actions, "조건 적용", func():
		var result = editor.result()
		if result == null: return
		_context["filters"] = result;_clear_zoom();_sync_set_summary(), "ExpressionConditionsApply")
	_action(actions, "취소", _clear_zoom)
func _save_set() -> void:
	if _capture_session and not _context_valid(_context): _set_summary.text = "인물·화면·관계가 바뀌었습니다. 다시 열어 주세요.";return
	var err = S.save_set(_context, _set_choices, _edit_token)
	if err == OK: close()
	else: _set_summary.text = "저장 실패: 표정을 하나 이상 선택하고 제외/OFF 설정을 확인해 주세요."
func confirm_delete(row: Dictionary) -> void:
	_capture_session = false;_main.get_node("F3ModWindow").close_window();var box = _begin();_label(box, "이 표정 집합을 삭제할까요?");_label(box, _condition(row))
	_action(box, "삭제", func():
		if S.remove_rule(S.identity(row)) == OK: close(), "SurgeryDeleteConfirm")
	_action(box, "취소", close)
func confirm_reset_all() -> void:
	_capture_session = false;_main.get_node("F3ModWindow").close_window();var box = _begin()
	_label(box, "표정 모두 초기화 · 최종 확인")
	_label(box, "모든 캐릭터·관계·화면의 표정 집합, 삭제 차단, 대체, 연결, 고정을 초기화합니다. 삭제한 표정도 다시 표시됩니다.")
	_label(box, "게임 세이브·해금·라이벌·의상 설정은 유지합니다. 초기화 전 표정 설정은 기기 안에 백업합니다.")
	var status = _label(box, "");var actions = HBoxContainer.new();box.add_child(actions)
	_action(actions, "취소", close, "ResetExpressionsCancel")
	_action(actions, "모든 표정 설정 초기화", func():
		var result = load("res://scripts/scenarios/expression_reset.gd").reset_defaults()
		if not result.ok: status.text = str(result.error);return
		close();GameState.notify_expression_preferences(), "ResetExpressionsConfirm")
func _process(_delta: float) -> void:
	if _main == null: return
	var clear = _game_visible() and not is_open() and not _main.get_node("F3ModWindow").is_open()
	for key in ["options_menu", "save_menu", "status_overview", "hypno_menu", "map_guide", "bug_report_menu", "skip_confirm", "prompt_box"]:
		var node = _main.get(key)
		if node != null and node.is_visible_in_tree(): clear = false
	var inspector = _main.get_node_or_null("ExpressionInspector")
	if inspector != null and inspector._root.visible: clear = false
	var dialogs = get_tree().root.get_node_or_null("SelectedScenarioDialogs")
	if dialogs != null and dialogs.is_open(): clear = false
	if _main._fade != null and _main._fade.fading(): clear = false
	_button.visible = clear and S.button_visible()
	if _button.visible:
		var rect = _main.sex_scene._slot.get_global_rect() if SceneSex.active(GameState.state) else _main.stage.get_global_rect()
		_button.position = Vector2(rect.position.x + 10, rect.end.y - 52);_button.size = Vector2(122, 42)
	if not is_open() or is_instance_valid(_zoom) or not is_instance_valid(_scroll): return
	var count = 0
	for card in _cards:
		if card.loaded or not _scroll.get_global_rect().intersects(card.preview.get_global_rect()): continue
		card.preview.texture = F.thumbnail(card.row);card.loaded = true;count += 1
		if count >= 2: break
func close() -> void:
	_close_presets()
	_capture_session = false;_clear_zoom();_cards.clear();_scroll = null
	if is_instance_valid(_panel): _panel.hide();_panel.queue_free();_panel = null
	_root.hide()
func _input(event: InputEvent) -> void:
	if is_open() and event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE, KEY_F3]:
		if is_instance_valid(_zoom): _clear_zoom()
		elif is_instance_valid(_preset_popup): _close_presets()
		else: close()
		get_viewport().set_input_as_handled()
func _unhandled_key_input(_event: InputEvent) -> void:
	if is_open(): get_viewport().set_input_as_handled()
func _unhandled_input(_event: InputEvent) -> void:
	if is_open(): get_viewport().set_input_as_handled()

func _close_presets() -> void:
	_preset_hold += 1
	if is_instance_valid(_preset_popup):
		_preset_popup.hide();_preset_popup.queue_free();_preset_popup = null
func _toggle_presets() -> void:
	if is_instance_valid(_preset_popup): _close_presets();return
	_preset_popup = _make_panel();_preset_popup.name = "SavedExpressionPresets"
	_preset_popup.offset_left = 80;_preset_popup.offset_right = 536
	_preset_popup.offset_top = -264;_preset_popup.offset_bottom = 230
	var box = _box(_preset_popup)
	_label(box, "저장된 집합 · 길게 눌러 미리보기")
	var tree = Tree.new();tree.name = "ExpressionPresetTree";tree.hide_root = true
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL;tree.custom_minimum_size = Vector2(420, 320)
	tree.add_theme_constant_override("item_margin", 12);box.add_child(tree)
	var root = tree.create_item();var groups: Dictionary = {}
	for row in S.rules():
		var parent = root;var path = ""
		for title in [str(WHO.get(str(row.id), row.id)), str(F.RELATIONS.get(str(row.relation), row.relation)), str(F.VIEWS.get(str(row.view), row.view))]:
			path += "|" + title
			if not groups.has(path):
				var group = tree.create_item(parent);group.set_text(0, title);group.collapsed = true;group.set_selectable(0, false);groups[path] = group
			parent = groups[path]
		var leaf = tree.create_item(parent)
		leaf.set_text(0, C.describe(row.get("filters", {})) + (" · 원본 " + str(row.source) if str(row.source) != "*" else "") + (" · OFF" if not row.get("on", true) else ""))
		leaf.set_metadata(0, row.duplicate(true));leaf.set_tooltip_text(0, _condition(row))
	if groups.is_empty(): _label(box, "아직 저장된 집합이 없습니다.")
	tree.gui_input.connect(func(event): _preset_input(event, tree))
	tree.item_activated.connect(func(): _preview_selected_preset(tree))
	tree.item_collapsed.connect(func(_item): _preset_hold += 1)
	var actions = HBoxContainer.new();box.add_child(actions)
	_action(actions, "선택 집합 미리보기", func(): _preview_selected_preset(tree))
	_action(actions, "접기", _close_presets)
func _preview_selected_preset(tree: Tree) -> void:
	var item = tree.get_selected()
	if item != null and item.get_metadata(0) is Dictionary: _preview_preset(item.get_metadata(0))
func _preset_input(event: InputEvent, tree: Tree) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch:
		_preset_hold += 1
		if not event.pressed: return
		_preset_press_position = event.position
		var item = tree.get_item_at_position(event.position)
		if item == null or not item.get_metadata(0) is Dictionary: return
		var row: Dictionary = item.get_metadata(0).duplicate(true);var token = _preset_hold
		get_tree().create_timer(0.55).timeout.connect(func():
			if token == _preset_hold and is_instance_valid(_preset_popup) and is_open(): _preview_preset(row))
	elif event is InputEventMouseMotion and event.position.distance_to(_preset_press_position) > 12:
		_preset_hold += 1
	elif event is InputEventScreenDrag or (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]):
		_preset_hold += 1
func _preset_choices(row: Dictionary) -> Array:
	var choices: Array = []
	for key in S.targets(row):
		if str(key) == S.ORIGINAL:
			choices.append(S.ORIGINAL);continue
		if F.deleted(str(row.id), str(row.view), str(key)): continue
		var entry = F.entry(str(_context.id), str(_context.view), str(key))
		if entry.is_empty() or bool(entry.get("baked", false)): continue
		if not F.allowed(str(_context.id), str(_context.view), str(key), str(_context.relation)): continue
		if not choices.has(str(key)): choices.append(str(key))
	return choices.slice(0, S.MAX_CHOICES)
func _preview_preset(row: Dictionary) -> void:
	_close_presets();_clear_zoom();_zoom = _make_panel();_zoom.name = "ExpressionPresetPreview"
	var box = _box(_zoom);_label(box, "가져올 집합 · " + _condition(row))
	_label(box, "적용할 현재 분기 · " + _condition(_context))
	var compatible = str(row.id) == str(_context.id) and str(row.view) == str(_context.view)
	var chosen = _preset_choices(row) if compatible else []
	_label(box, "현재 분기에 복사 가능: %d개 · 삭제·제외된 표정은 가져오지 않습니다." % chosen.size() if compatible else "이 집합은 다른 캐릭터·화면용입니다. 미리보기만 가능합니다.")
	var scroll = ScrollContainer.new();scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;box.add_child(scroll)
	var grid = GridContainer.new();grid.columns = 4;grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL;scroll.add_child(grid)
	for key in S.targets(row):
		var cell = VBoxContainer.new();cell.custom_minimum_size.x = 252;grid.add_child(cell)
		if str(key) == S.ORIGINAL: _label(cell, "원래 표정 사용 (현재 분기의 원래 표정)");continue
		if F.deleted(str(row.id), str(row.view), str(key)): _label(cell, str(key) + " · 삭제됨");continue
		var entry = F.entry(str(row.id), str(row.view), str(key))
		if entry.is_empty(): _label(cell, str(key) + " · 찾을 수 없음");continue
		var image = TextureRect.new();image.custom_minimum_size = Vector2(252, 180);image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture = F.thumbnail(entry);cell.add_child(image);_label(cell, str(key))
	var actions = HBoxContainer.new();box.add_child(actions)
	var apply = _action(actions, "현재 분기·상황에 적용", func(): _apply_preset(row), "ApplyExpressionPreset")
	apply.disabled = not compatible or chosen.is_empty()
	_action(actions, "돌아가기", func(): _clear_zoom();_toggle_presets())
func _apply_preset(row: Dictionary) -> void:
	if str(row.id) != str(_context.id) or str(row.view) != str(_context.view): return
	if _capture_session and not _context_valid(_context): return
	var chosen = _preset_choices(row)
	if chosen.is_empty(): return
	_set_choices = chosen.duplicate();_clear_zoom();_sync_checks()
	_set_summary.text += " · 복사됨: 집합 저장을 누르면 반영됩니다."

func _style_pick(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#26334b")
		style.border_color = Color("#667a9b")
		style.set_border_width_all(1);style.set_corner_radius_all(8)
		style.content_margin_left = 12;style.content_margin_right = 12
		if state in ["pressed", "hover_pressed"]:
			style.bg_color = Color("#175956");style.border_color = Color("#6ce5cf");style.set_border_width_all(2)
		elif state == "hover": style.bg_color = Color("#354766")
		elif state == "disabled": style.bg_color = Color("#242630");style.border_color = Color("#3c4150")
		elif state == "focus": style.bg_color = Color.TRANSPARENT;style.border_color = Color("#d9e6ff");style.set_border_width_all(2)
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color("#f4f8ff"))
func _sync_pick(button: Button, row: Dictionary) -> void:
	var selected = _set_choices.has(str(row.key))
	button.set_pressed_no_signal(selected)
	button.text = ("✓ " if selected else "") + str(row.key) + (" · 추가" if str(row.source) == "additional" else "")
	button.tooltip_text = str(row.key) + (" · 선택됨 · 눌러서 해제" if selected else " · 눌러서 선택")
