extends SceneTree

var filter
var surgery_store
var layout
var scene_sex
var clock
var behavior_night
var new_game
var passed = 0
var failed = 0
var main
var game

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ", label)
	else:
		failed += 1
		printerr("FAIL ", label)

func finish() -> void:
	print("RESULT ", passed, " passed, ", failed, " failed")
	quit(int(failed > 0))

func frames() -> void:
	await process_frame
	await process_frame

func expression_setup() -> void:
	game.new_game()
	var state = game.state
	state.set_room("sakuya", state.pc["room"])
	state.heroines["sakuya"]["pc"]["relation"] = "lover"
	scene_sex.start(state, "sakuya", "pc")
	state.scene["phase"] = "cg"
	state.scene["position"] = "doggy"
	state.scene["face"] = "endure"
	state.flags["mod_expression_action"] = {"id": "insert", "target": "sakuya"}
	main.sex_scene.refresh()
	await frames()

func find_preset(item: TreeItem, condition: Dictionary) -> TreeItem:
	var data = item.get_metadata(0)
	if data is Dictionary and data.view == filter.DOGGY_WINDOW and data.get("filters", {}) == condition:
		return item
	for child in item.get_children():
		var found = find_preset(child, condition)
		if found != null:
			item.collapsed = false
			return found
	return null

func expression_tests(restart: bool) -> void:
	await expression_setup()
	var state = game.state
	var sex = main.sex_scene
	var surgery = main.get_node("ExpressionSurgery")
	var view = filter.DOGGY_WINDOW
	var standing = surgery_store.context(state, "sakuya", "standing", "*")
	var missionary = surgery_store.context(state, "sakuya", "missionary", "*")
	if not restart:
		check(surgery_store.save_set(standing, ["smile"]) == OK and surgery_store.save_set(missionary, ["cry"]) == OK, "seed existing standing and missionary presets")
		await frames()
	check(sex._cg.cg == "doggy" and sex._face_window.is_visible_in_tree(), "doggy CG with visible face window")
	check(sex._face_window.expression_view == view, "face window reports its own expression view")
	if restart:
		check(sex._face_window.expression == "cold" and sex._face_window._face.texture != null, "restarted process applies saved window expression")
		check(surgery_store.targets(surgery_store.current_rule(missionary, state)) == ["cry"] and surgery_store.targets(surgery_store.current_rule(standing, state)) == ["smile"], "restarted process preserves other preset branches")
		check(layout.transform_for(layout.read(), 3, "reimu", "partner").x == 42.0, "restarted process preserves layout preferences")
		return
	check(sex._face_window.expression == "endure", "window does not apply missionary-scoped rule")
	surgery._button.pressed.emit()
	var context = surgery._context.duplicate(true)
	check(surgery.is_open() and context.view == view and context.id == "sakuya" and context.filters.get("action") == "insert", "expression button captures window and previous action")
	check(surgery._set_grid.columns == 3 and surgery._set_grid.get_child_count() > 3, "real expression catalog renders in three columns")
	var row = filter.entry("sakuya", view, "cold")
	check(str(row.path) == "res://art/sakuya/missionary/face_cold.png" and filter.thumbnail(row) != null, "window catalog and preview use configured art")
	var picker = surgery._panel.find_child("SetPick_cold", true, false)
	check(picker != null and picker.custom_minimum_size.y >= 60, "large expression selection button")
	picker.button_pressed = true
	surgery._panel.find_child("SaveExpressionSet", true, false).pressed.emit()
	await frames()
	check(not surgery.is_open() and sex._face_window.expression == "cold", "Save set refreshes the displayed window")
	var expected = ResourceLoader.load(str(row.path), "Texture2D")
	check(expected != null and sex._face_window._face.texture == expected, "rendered overlay is the selected texture")
	check(surgery_store.targets(surgery_store.current_rule(missionary, state)) == ["cry"] and surgery_store.targets(surgery_store.current_rule(standing, state)) == ["smile"], "saved standing and missionary rules remain intact")

	var origin = context.duplicate(true)
	origin.filters = {"action": "slow"}
	check(surgery_store.save_set(origin, ["endure"]) == OK, "seed another window preset")
	surgery._button.pressed.emit()
	surgery._panel.find_child("SavedExpressionPresetsButton", true, false).pressed.emit()
	var tree = surgery._preset_popup.find_child("ExpressionPresetTree", true, false)
	check(tree.get_root().get_first_child().collapsed, "saved preset tree is collapsible")
	var item = find_preset(tree.get_root(), origin.filters)
	check(item != null, "find saved window preset in expanded tree")
	await frames()
	var hold = InputEventMouseButton.new()
	hold.button_index = MOUSE_BUTTON_LEFT
	hold.pressed = true
	hold.position = tree.get_item_area_rect(item, 0).get_center()
	tree.gui_input.emit(hold)
	await create_timer(0.65).timeout
	check(is_instance_valid(surgery._zoom) and surgery._zoom.find_child("ApplyExpressionPreset", true, false) != null, "long press opens the saved preset preview")
	if not is_instance_valid(surgery._zoom):
		surgery.close()
		return
	surgery._zoom.find_child("ApplyExpressionPreset", true, false).pressed.emit()
	check(surgery._set_choices == ["endure"] and surgery._context.filters == context.filters and surgery._context.relation == context.relation, "preset copy only replaces draft choices")
	check(surgery_store.targets(surgery_store.current_rule(context, state)) == ["cold"], "preset draft leaves saved current rule intact")
	check(surgery_store.rules().any(func(row): return surgery_store.identity(row) == surgery_store.identity(origin) and surgery_store.targets(row) == ["endure"]), "preset copy leaves original preset intact")
	surgery.close()
	sex._cg.set_face("endure")
	check(sex._face_window.expression == "cold", "CG expression update follows saved window branch")
	state.scene["position"] = "missionary"
	sex.refresh()
	check(not sex._face_window.visible and sex._cg.expression == "cry", "missionary keeps its own rendered preset")
	state.scene = {}
	sex.refresh()

func setup_visits(count: int):
	game.new_game()
	var state = game.state
	state.day = 6
	state.slot = "late"
	state.set_room("pc", clock.own_room("pc"))
	for id in state.heroine_ids():
		state.set_room(id, clock.own_room(id))
	var chosen = state.heroine_ids().slice(0, count)
	for id in chosen:
		state.heroines[id]["lent_tonight"] = state.day
	behavior_night.night_visits(state)
	return state

func visit_tests() -> void:
	for count in [2, 3, 4]:
		for action in ["all", "one", "none"]:
			var state = setup_visits(count)
			var p = state.pending
			var visitors = p.get("visitors", [p.get("id", ""), p.get("clash", "")])
			var label = "%d visitors / %s" % [count, action]
			check(p.get("kind") == "visit" and visitors.size() == count and not visitors.has(""), label + " via normal night event")
			if action == "all" and count == 2:
				# v57 saves with the group setting disabled can lack the receipt and button.
				p.erase("clash_receipt")
				p.options = p.options.filter(func(o): return o.id != "accept_all")
				new_game.refresh_mod_pending(state)
			main.prompt_box.refresh()
			var button = main.prompt_box._buttons.get_children().filter(func(b): return b.text == "모두 받아들이기" and not b.is_queued_for_deletion())
			check(button.size() == 1 and not button[0].disabled, label + " shows enabled accept-all control")
			if action == "all":
				button[0].pressed.emit()
			elif action == "none":
				game.choose("refuse")
			elif count == 2:
				game.choose("accept")
			else:
				game.choose("toggle:" + str(visitors[0]))
				check(state.pending.get("checked", []) == [visitors[0]], label + " selection keeps pending")
				game.choose("accept_selected")
			var expected = visitors if action == "all" else visitors.slice(0, 1) if action == "one" else []
			check(state.pending.is_empty(), label + " clears pending")
			var actual = visitors.filter(func(id): return state.room_of(id) == state.pc["room"] and state.heroines[id].get("night_welcomed", false))
			check(actual == expected, label + " admits exactly the selected visitors")
			var before = [state.day, state.slot]
			game.next_slot()
			check([state.day, state.slot] != before, label + " allows subsequent game progress")

func group_layout_tests() -> void:
	for count in [3, 4]:
		game.new_game()
		var state = game.state
		var ids = ["reimu", "marisa", "sakuya", "sanae"].slice(0, count)
		for id in ids:
			state.set_room(id, state.pc["room"])
			state.heroines[id]["pc"]["relation"] = "lover"
		var group = load("res://scripts/scene_sex_harem.gd")
		group.start(state, ids)
		var sex = main.sex_scene
		sex.refresh()
		var view = sex._harem
		check(view.visible and view._slot_rect("back2").visible == (count == 4), "%d-person game rendering" % count)
		var saved = layout.read()
		saved[layout.key(count, "marisa", "left")] = {"x": 80, "y": -30, "scale": 1.4}
		saved[layout.key(count, "marisa", "partner")] = {"x": -34, "y": 10, "scale": 0.9}
		saved[layout.key(count, "sakuya", "left")] = {"x": 24, "y": 31, "scale": 1.2}
		check(layout.save(saved) == OK, "%d-person layout is writable" % count)
		sex._harem_sel = "partner"
		sex._refresh_harem(state)
		await frames()
		var rect = view._slot_rect("left")
		var shadow = view._shadows["left"]
		var mark = view._mark_slots["left"]
		check(is_equal_approx(rect.scale.x, 1.4) and rect.scale == shadow.scale and rect.scale == mark.scale, "%d-person scale updates sprite, shadow and exchange marker" % count)
		var center = view.stage.position + view._mark_center("left") * view.stage.scale.x
		check(view.pick_at(center) == "left" and rect.position.distance_to(shadow.position) > 0, "%d-person touch targets track transformed art and marker" % count)
		sex._harem_sel = "left"
		sex._refresh_harem(state)
		check(rect.material != null, "%d-person visible selection outline" % count)
		group.move(state, "left", "back")
		sex.refresh()
		check(group.slots(state).left == "sakuya" and view._transforms.left.x == 24, "%d-person seat exchange selects new seat/character layout" % count)
		group.move(state, "back", "partner")
		sex.refresh()
		check(state.scene.id == "marisa" and view._transforms.partner.x == -34, "%d-person partner exchange applies incoming layout" % count)
		state.scene = {}
		sex.refresh()

func settings_tests(restart: bool) -> void:
	var vitals = load("res://scripts/mod_vitals.gd")
	var runtime = load("res://scripts/scenarios/runtime.gd")
	var preferences = load("res://scripts/scenarios/appearance_preferences.gd")
	if restart:
		check(not vitals.enabled() and runtime.on(game.state, "cut_in"), "restart preserves user-modified faint and cut-in switches")
		var cfg = ConfigFile.new()
		check(cfg.load(vitals.PATH) == OK and cfg.get_value("vitals", "default_on_v56") and not cfg.get_value("vitals", "enabled"), "v56 migration is not rerun")
	else:
		check(vitals.enabled() and not runtime.on(game.state, "cut_in"), "default faint ON and cut-in OFF")
		check(vitals.set_enabled(game.state, false) == OK and preferences.write_many({"feature_cut_in": true}) == OK, "save user-modified switches")

func layout_tests() -> void:
	game.new_game()
	var menu = main.options_menu
	var button = menu.find_child("HaremLayoutOpen", true, false)
	var title = menu.find_child("TitleAppearanceOpen", true, false)
	check(button.get_parent().get_parent() == title.get_parent().get_parent() and button.get_parent().get_index() == title.get_parent().get_index() + 1, "general layout button follows title appearance")
	button.pressed.emit()
	var editor = main.get_node("HaremLayoutEditor")
	check(editor.root.visible and editor.count == 3, "opens the existing 3-person preview")
	editor.x.value = 42
	editor.y.value = -16
	editor.zoom.value = 125
	editor.root.find_child("LayoutSave", true, false).pressed.emit()
	button.pressed.emit()
	var pose = layout.transform_for(editor.draft, 3, "reimu", "partner")
	check(pose.x == 42 and pose.y == -16 and pose.scale == 1.25, "numeric x/y/scale persist on save")
	editor.x.value = 72
	editor.root.find_child("LayoutCancel", true, false).pressed.emit()
	check(layout.transform_for(layout.read(), 3, "reimu", "partner").x == 42, "cancel preserves saved coordinates")
	button.pressed.emit()
	var mode = editor.root.find_child("LayoutCount", true, false)
	mode.item_selected.emit(1)
	check(editor.count == 4 and editor.x.value == 0 and editor.view._slot_rect("back2").visible, "4-person preview and separate coordinates")
	editor.x.value = 33
	var select = editor.root.find_child("LayoutSlot", true, false)
	select.item_selected.emit(3)
	var characters = editor.root.find_child("LayoutCharacter", true, false)
	characters.item_selected.emit(0)
	check(editor.selected == "back2" and editor.ids[3] == "reimu" and editor.x.value == 0, "seat and character preferences are independent")
	var drag = InputEventMouseMotion.new()
	drag.relative = Vector2(18, -10) * editor.view.stage.scale.x
	editor.dragging = true
	editor._input(drag)
	check(is_equal_approx(editor.x.value, 18) and is_equal_approx(editor.y.value, -10), "drag moves the selected preview member")
	editor.root.find_child("LayoutResetSelected", true, false).pressed.emit()
	check(editor.x.value == 0 and editor.draft.size() == 2, "selected reset preserves other positions")
	editor.root.find_child("LayoutResetAll", true, false).pressed.emit()
	check(editor.draft.is_empty(), "reset all clears draft")
	editor.root.find_child("LayoutCancel", true, false).pressed.emit()
	check(game.save_game(1), "create isolated game save")
	game.new_game()
	check(game.load_game(1) and layout.transform_for(layout.read(), 3, "reimu", "partner").x == 42, "load game preserves independent layout")
	check(surgery_store.rules().any(func(rule): return rule.view == filter.DOGGY_WINDOW and surgery_store.targets(rule) == ["cold"]), "load game preserves window expression presets")

func run() -> void:
	game = root.get_node("GameState")
	filter = load("res://scripts/scenarios/expression_filter.gd")
	surgery_store = load("res://scripts/scenarios/expression_surgery.gd")
	layout = load("res://scripts/scenarios/harem_layout.gd")
	scene_sex = load("res://scripts/scene_sex.gd")
	clock = load("res://scripts/clock.gd")
	behavior_night = load("res://scripts/behavior_night.gd")
	new_game = load("res://scripts/new_game.gd")
	var args = OS.get_cmdline_user_args()
	var restart = "restart" in args
	check(FileAccess.get_file_as_bytes("res://scripts/ui/face_window_view.gd").get_string_from_utf8().contains("F.DOGGY_WINDOW"), "patched source is loaded by the APK sparse pack")
	check(not FileAccess.file_exists("res://scripts/ui/face_window_view.gdc"), "superseded compiled window script is absent")
	var result = change_scene_to_file("res://scenes/main.tscn")
	check(result == OK, "main scene loads from APK sparse resources")
	if result != OK:
		finish()
		return
	await frames()
	main = current_scene
	await expression_tests(restart)
	if not restart:
		await visit_tests()
		await layout_tests()
		await group_layout_tests()
	settings_tests(restart)
	finish()
