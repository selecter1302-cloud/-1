extends RefCounted
const FILE = "user://mod_expression_filters.cfg"
const IDS = ["reimu", "sakuya", "marisa", "sanae"]
const VIEWS = {"standing": "평상시 · 스탠딩", "scene_portrait": "H씬 · 초상화", "missionary": "H씬 · 정상위", "doggy": "H씬 · 후배위 · 얼굴층 없음", "cowgirl": "H씬 · 기승위", "fellatio": "H씬 · 구강", "paizuri": "H씬 · 가슴", "harem_front": "다함께 · 앞쪽", "harem_peek": "다함께 · 뒤쪽"}
const RELATIONS = {"*": "공통 · 모든 관계", "stranger": "타인", "friend": "친구", "crush": "짝사랑", "lover": "연인", "quarrel": "싸우는 중", "wavering": "마음이 변함", "ex": "옛 연인", "hate": "싫어함", "submit": "굴복", "coerced": "협박 중"}
static var _loaded = false
static var _rows: Array = []
static var _by_path: Dictionary = {}
static var _by_key: Dictionary = {}
static var _disabled: Dictionary = {}
static var _deleted: Dictionary = {}
static var _entries: Dictionary = {}
const STORE = preload("res://scripts/scenarios/expression_store.gd")
static var _links: Dictionary = {}
static var _profiles: Dictionary = {}
static var _thumbs: Dictionary = {}
static var _thumb_order: Array = []
static var _disk_thumb_order: Array = []
static var _disk_thumbs_loaded = false
const THUMB_DIR = "user://expression_thumbnails_v2"
static var revision = 0
static var preview_depth = 0
static func ensure() -> void :
	if _loaded: return
	_loaded = true
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/expression_catalog.json"))
	_rows = data.get("entries", []) if data is Dictionary else []
	for row in _rows:
		if not bool(row.get("baked", false)): _by_path[str(row.path)] = row
		_by_key[identity(str(row.id), str(row.view), str(row.key))] = row
	var cfg = ConfigFile.new()
	if cfg.load(FILE) == OK:
		var links = cfg.get_value("expressions", "links", {})
		if links is Dictionary: _links = links.duplicate(true)
		var profiles = cfg.get_value("expressions", "profiles", {})
		if profiles is Dictionary: _profiles = profiles.duplicate(true)
		for bucket in _profiles.keys():
			if not _profiles[bucket] is Dictionary: _profiles.erase(bucket)
		var saved = cfg.get_value("expressions", "excluded", [])
		if saved is Array or saved is PackedStringArray:
			for key in saved: _disabled[str(key)] = true
		var deleted = cfg.get_value("expressions", "deleted", {})
		if deleted is Dictionary: _deleted = deleted.duplicate(true)
		if int(cfg.get_value("expressions", "schema", 1)) < 3:
			# Preserve every old setting before folding relationship scopes.
			if STORE.backup(FILE) != OK: push_warning("Expression preference backup failed; migration remains in memory.")
			cfg.set_value("migration", "legacy_profiles", _profiles.duplicate(true))
			for bucket in _profiles:
				var merged: Dictionary = {}
				for address_key in _profiles[bucket]:
					var parts = str(address_key).split("|")
					if parts.size() < 3: continue
					parts[2] = normalize_relation(parts[2]);var new_key = "|".join(parts);var value = _profiles[bucket][address_key]
					if merged.has(new_key) and merged[new_key] is Array and value is Array:
						for item in value:
							if not merged[new_key].has(item): merged[new_key].append(item)
					elif bucket == "excluded": merged[new_key] = bool(merged.get(new_key, false)) or bool(value)
					elif not merged.has(new_key): merged[new_key] = value
				_profiles[bucket] = merged
			for address_key in _disabled: _deleted[str(address_key)] = true
			for address_key in _profiles.get("excluded", {}):
				var parts = str(address_key).split("|")
				if parts.size() == 4 and _profiles.excluded[address_key] == true: _deleted[identity(parts[0], parts[1], parts[3])] = true
			cfg.set_value("expressions", "profiles", _profiles)
			cfg.set_value("expressions", "deleted", _deleted)
			cfg.set_value("expressions", "schema", 3)
			if STORE.backup(FILE) == OK: STORE.save(cfg, FILE)
static func normalize_relation(rel: String) -> String:
	return "lover" if rel in ["lover_public", "lover_secret"] else rel
static func deleted(id: String, view: String, key: String) -> bool:
	ensure();return _deleted.has(identity(id, view, key)) or _deleted.has(identity(id, "*", key))
static func deleted_rows(id: String = "") -> Array:
	ensure();var result: Array = []
	for address_key in _deleted:
		var parts = str(address_key).split("|")
		if parts.size() == 3 and (id.is_empty() or parts[0] == id): result.append({"id": parts[0], "view": parts[1], "key": parts[2]})
	return result
static func set_deleted(row: Dictionary, value: bool, all_views: bool = false) -> Error:
	ensure();var id = str(row.get("id", ""));var view = str(row.get("view", ""));var key = str(row.get("key", ""))
	if not IDS.has(id) or not VIEWS.has(view) or key.is_empty(): return ERR_INVALID_PARAMETER
	var old = _deleted.duplicate();var address_key = identity(id, "*" if all_views else view, key)
	if value: _deleted[address_key] = true
	else:
		_deleted.erase(address_key);_deleted.erase(identity(id, "*", key));_disabled.erase(identity(id, view, key));_disabled.erase(identity(id, "*", key))
		if all_views:
			for context_view in VIEWS: _deleted.erase(identity(id, str(context_view), key));_disabled.erase(identity(id, str(context_view), key))
		var excluded: Dictionary = _profiles.get("excluded", {})
		for address_old in excluded.keys():
			var parts = str(address_old).split("|")
			if parts.size() == 4 and parts[0] == id and parts[3] == key and (all_views or parts[1] in [view, "*"]): excluded.erase(address_old)
	var err = _save()
	if err == OK:
		_thumbs.clear();_thumb_order.clear();_changed()
		if value: load("res://scripts/scenarios/expression_surgery.gd").purge_deleted()
	else: _deleted = old;reload_preferences()
	return err
static func visible_entries(id: String, view: String) -> Array:
	return entries(id, view).filter(func(row): return not deleted(id, view, str(row.key)))
static func identity(id: String, view: String, key: String) -> String: return id + "|" + view + "|" + key
static func address(id: String, view: String, rel: String, key: String = "") -> String: return id + "|" + view + "|" + normalize_relation(rel) + ("|" + key if key != "" else "")
static func entries(id: String, view: String) -> Array:
	ensure()
	if view == "doggy": return [{"id": id, "view": view, "key": "default", "source": "native", "path": "res://art/%s/doggy/base.png" % id, "baked": true}]
	var cache_key = id + "|" + view
	if _entries.has(cache_key): return _entries[cache_key]
	var source_view = "standing" if view == "scene_portrait" else view
	var rows = _rows.filter( func(row): return str(row.id) == id and str(row.view) == source_view)
	if view == "scene_portrait":
		rows = rows.duplicate(true)
		for row in rows: row["view"] = view
	_entries[cache_key] = rows
	return rows
static func entry(id: String, view: String, key: String) -> Dictionary:
	ensure()
	if view == "doggy" and key == "default": return entries(id, view)[0]
	var row: Dictionary = _by_key.get(identity(id, "standing" if view == "scene_portrait" else view, key), {})
	if view == "scene_portrait" and not row.is_empty(): row = row.duplicate(true);row["view"] = view
	return row
static func default_entry(id: String, key: String) -> Dictionary:
	for view in VIEWS:
		var row = entry(id, str(view), key)
		if not row.is_empty(): return row
	return {}
static func current_state():
	var tree = Engine.get_main_loop(); var gs = tree.root.get_node_or_null("GameState") if tree is SceneTree else null
	return gs.state if gs != null else null
static func context(id: String, view: String) -> String:
	var st = current_state()
	if view == "standing" and st != null and SceneSex.active(st) and str(st.scene.get("id", "")) == id: return "scene_portrait"
	return view
static func relation(st, id: String, view: String) -> String:
	if st == null or not st.heroines.has(id): return "*"
	var actor = str(st.scene.get("actor", "pc")) if view != "standing" and SceneSex.active(st) else "pc"
	if actor not in ["pc", "rival"]: actor = "pc"
	var rel = str(st.relation(id, actor))
	rel = normalize_relation(rel)
	return rel if RELATIONS.has(rel) else "*"
static func scopes(rel: String) -> Array:
	rel = normalize_relation(rel)
	return ["*"] if rel == "*" else [rel, "*"]
static func _profile_value(bucket: String, id: String, view: String, rel: String, key: String = ""):
	ensure(); var table = _profiles.get(bucket, {})
	if not table is Dictionary: return null
	for scope in scopes(rel):
		var addr = address(id, view, str(scope), key)
		if table.has(addr): return table[addr]
	return null
static func _changed() -> void :
	revision += 1
	load("res://scripts/ui/face_icon.gd")._cache.clear()
	var tree = Engine.get_main_loop(); var gs = tree.root.get_node_or_null("GameState") if tree is SceneTree else null
	if gs != null: gs.notify_expression_preferences()
static func _save() -> Error:
	var cfg = ConfigFile.new();var read_error = cfg.load(FILE)
	if read_error not in [OK, ERR_FILE_NOT_FOUND]: return read_error
	cfg.set_value("expressions", "schema", 3);cfg.set_value("expressions", "deleted", _deleted)
	cfg.set_value("expressions", "links", _links);cfg.set_value("expressions", "excluded", _disabled.keys());cfg.set_value("expressions", "profiles", _profiles)
	return STORE.save(cfg, FILE)
static func _write_profile(bucket: String, id: String, view: String, rel: String, value, key: String = "") -> Error:
	ensure()
	if not IDS.has(id) or not RELATIONS.has(rel): return ERR_INVALID_PARAMETER
	var old = _profiles.duplicate(true)
	if not _profiles.get(bucket, {}) is Dictionary: _profiles[bucket] = {}
	if not _profiles.has(bucket): _profiles[bucket] = {}
	_profiles[bucket][address(id, view, rel, key)] = value
	var err = _save()
	if err == OK: _changed()
	else: _profiles = old
	return err
static func master_on(st) -> bool:
	if st == null: return true
	if load("res://scripts/scenarios/vanilla_cfg.gd").on(st): return false
	var base = bool(st.flags.get("mod_scenarios", {}).get("faces", true))
	if not bool(preload("res://scripts/scenarios/appearance_preferences.gd").read("feature_faces", base, true)): return false
	var config = st.flags.get("cheat_xface", {})
	return not (config is Dictionary and bool(config.get("off", false)))
static func extra_master(id: String, family: String) -> bool:
	var value = _profile_value("master", id, family, "*")
	return bool(value) if value is bool else true
static func set_extra_master(id: String, family: String, on: bool) -> Error:
	if family not in ["standing", "scene"]: return ERR_INVALID_PARAMETER
	return _write_profile("master", id, family, "*", on)
static func extra_setting(id: String, view: String, rel: String = "*") -> bool:
	var value = _profile_value("extra", id, view, rel)
	return bool(value) if value is bool else true
static func set_extra_view(id: String, view: String, rel: String, on: bool) -> Error:
	if not VIEWS.has(view): return ERR_INVALID_PARAMETER
	return _write_profile("extra", id, view, rel, on)
static func extra_enabled(st, id: String, view: String, rel: String = "") -> bool:
	if not master_on(st): return false
	if rel.is_empty(): rel = relation(st, id, view)
	return extra_master(id, "standing" if view == "standing" else "scene") and extra_setting(id, view, rel)
static func additional(id: String, view: String, key: String) -> bool:
	var row = entry(id, view, key)
	return str(row.get("source", "")) == "additional" or key.begins_with("kx_")
static func allowed(id: String, view: String, key: String, rel: String = "") -> bool:
	ensure(); var st = current_state()
	if deleted(id, view, key): return false
	if rel.is_empty(): rel = relation(st, id, view)
	if additional(id, view, key) and not extra_enabled(st, id, view, rel): return false
	var table: Dictionary = _profiles.get("excluded", {})
	for scope in scopes(rel):
		for context in [view, "*"]:
			var addr = address(id, str(context), str(scope), key)
			if table.get(addr) is bool: return not bool(table[addr])
	return not _disabled.has(identity(id, view, key)) and not _disabled.has(identity(id, "*", key))
static func set_excluded(row: Dictionary, exclude: bool, all_views: bool = false) -> int:
	# Excluding is now a permanent, cross-relationship block for this character/view.
	return set_deleted(row, exclude, all_views)
static func linked(id: String, view: String, key: String, rel: String = "*") -> Array:
	var value = _profile_value("links", id, view, rel, key)
	if value == null: value = _links.get(identity(id, view, key), [])
	return value.duplicate() if value is Array else []
static func set_links(id: String, view: String, key: String, extras: Array, rel: String = "*") -> Error:
	ensure(); var base = entry(id, view, key)
	if base.is_empty() or str(base.source) == "additional": return ERR_INVALID_PARAMETER
	var clean: Array = []
	for extra in extras:
		var row = entry(id, view, str(extra))
		if not row.is_empty() and str(row.source) == "additional" and not clean.has(str(extra)): clean.append(str(extra))
	if rel != "*": return _write_profile("links", id, view, rel, clean, key)
	var old = _links.duplicate(true); var address = identity(id, view, key)
	if clean.is_empty(): _links.erase(address)
	else: _links[address] = clean
	var err = _save()
	if err == OK: _changed()
	else: _links = old
	return err
static func pool_keys(id: String, view: String, rel: String = "*") -> Array:
	var value = _profile_value("pool", id, view, rel)
	return value.duplicate() if value is Array else []
static func set_pool(id: String, view: String, rel: String, keys: Array) -> Error:
	var clean: Array = []
	for key in keys:
		var row = entry(id, view, str(key))
		if row.is_empty() or str(row.source) == "additional": return ERR_INVALID_PARAMETER
		if not clean.has(str(key)): clean.append(str(key))
	if clean.size() > 10: return ERR_INVALID_PARAMETER
	return _write_profile("pool", id, view, rel, clean)
static func has_links(id: String, view: String) -> bool:
	ensure()
	if _links.is_empty() and _profiles.get("links", {}).is_empty() and _profiles.get("pool", {}).is_empty(): return false
	var st = current_state()
	if not master_on(st): return false
	var rel = relation(st, id, view)
	if not pool_keys(id, view, rel).is_empty(): return true
	if not extra_enabled(st, id, view, rel): return false
	if _links.is_empty() and _profiles.get("links", {}).is_empty(): return false
	for row in entries(id, view):
		if str(row.source) != "additional" and not linked(id, view, str(row.key), rel).is_empty(): return true
	return false
static func replacement(id: String, view: String, key: String, rel: String = "*") -> String:
	var value = _profile_value("replacement", id, view, rel, key)
	return str(value) if value is String else ""
static func set_replacement(row: Dictionary, target: String) -> Error:
	var id = str(row.get("id", "")); var view = str(row.get("view", "")); var key = str(row.get("key", "")); var rel = str(row.get("relation", "*"))
	if target == key or ( not target.is_empty() and entry(id, view, target).is_empty()): return ERR_INVALID_PARAMETER
	return _write_profile("replacement", id, view, rel, target, key)
static func reset_profile(id: String, view: String, rel: String) -> Error:
	ensure(); var old = _profiles.duplicate(true); var old_links = _links.duplicate(true); var old_disabled = _disabled.duplicate(true); var prefix = address(id, view, rel)
	for bucket in ["pool", "extra", "links", "excluded", "replacement"]:
		var table: Dictionary = _profiles.get(bucket, {})
		for key in table.keys():
			if str(key) == prefix or str(key).begins_with(prefix + "|"): table.erase(key)
	if rel == "*":
		for key in _disabled.keys():
			if str(key).begins_with(id + "|" + view + "|"): _disabled.erase(key)
		for key in _links.keys():
			if str(key).begins_with(id + "|" + view + "|"): _links.erase(key)
	var err = _save()
	if err == OK: _changed()
	else: _profiles = old;_links = old_links;_disabled = old_disabled
	return err
static func note_event(st) -> void :
	if st != null: st.flags["mod_expression_event"] = int(st.flags.get("mod_expression_event", 0)) + 1
static func _stamp(st) -> String: return "%d/%s/%d/%d/%d" % [int(st.day), str(st.slot), int(st.tick), int(st.flags.get("mod_expression_event", 0)), int(st.scene.get("actions", 0))]
static func _rotate(st, bucket: String, addr: String, keys: Array, alternate_base: String = "") -> String:
	if not st.flags.get(bucket, {}) is Dictionary: st.flags[bucket] = {}
	if not st.flags.has(bucket): st.flags[bucket] = {}
	var book: Dictionary = st.flags[bucket]; var old: Dictionary = book.get(addr, {})
	var signature = JSON.stringify(keys) + alternate_base; var stamp = _stamp(st)
	if str(old.get("stamp", "")) == stamp and str(old.get("signature", "")) == signature: return str(old.selected)
	var count = int(old.get("count", 0)) if str(old.get("signature", "")) == signature else 0
	var selected = str(keys[count % keys.size()]) if alternate_base.is_empty() else (alternate_base if count % 2 == 0 else str(keys[int(count / 2) % keys.size()]))
	if book.size() >= 128 and not book.has(addr): book.erase(book.keys()[0])
	book[addr] = {"stamp": stamp, "signature": signature, "count": count + 1, "selected": selected}
	return selected
static func choose_pool(st, id: String, view: String, key: String) -> String:
	if preview_depth > 0 or st == null or not master_on(st) or not preload("res://scripts/mod_controls.gd").forced_face(id).is_empty(): return key
	if additional(id, view, key): return key
	var rel = relation(st, id, view); var pool = pool_keys(id, view, rel).filter( func(value): return not entry(id, view, str(value)).is_empty() and not additional(id, view, str(value)))
	return _rotate(st, "mod_base_face_rotation", address(id, view, rel), pool) if not pool.is_empty() else key
static func choose_linked(st, id: String, view: String, key: String) -> String:
	if preview_depth > 0 or st == null or not extra_enabled(st, id, view) or not preload("res://scripts/mod_controls.gd").forced_face(id).is_empty(): return key
	var rel = relation(st, id, view); var extras = linked(id, view, key, rel).filter( func(extra): return allowed(id, view, str(extra), rel))
	if extras.is_empty() or not allowed(id, view, key, rel): return key
	return _rotate(st, "mod_face_rotation", address(id, view, rel, key), extras, key)
static func safe_key(st, id: String, view: String, key: String, rel: String = "") -> String:
	if rel.is_empty(): rel = relation(st, id, view)
	if key.is_empty() or key == "__no_face__": return key
	var check = key
	if entry(id, view, key).is_empty() and key in ["blush", "neutral", "base"] and not entry(id, view, "default").is_empty(): check = "default"
	if allowed(id, view, check, rel): return key
	var target = replacement(id, view, check, rel); var visited: Array = [check]
	while not target.is_empty() and not visited.has(target):
		visited.append(target)
		if not entry(id, view, target).is_empty() and allowed(id, view, target, rel): return target
		target = replacement(id, view, target, rel)
	for candidate in ["neutral", "base", "blush", "lover", "friendly", "dazed", "default"]:
		if not entry(id, view, str(candidate)).is_empty() and allowed(id, view, str(candidate), rel): return str(candidate)
	for row in entries(id, view):
		if str(row.source) != "additional" and allowed(id, view, str(row.key), rel): return str(row.key)
	return "__no_face__"
static func resolve_expression(id: String, view: String, key: String) -> String:
	if preview_depth > 0: return "__no_face__" if deleted(id, view, key) else key
	var st = current_state(); var original = key;key = choose_pool(st, id, view, key);key = choose_linked(st, id, view, key)
	return safe_key(st, id, view, load("res://scripts/scenarios/expression_surgery.gd").resolve(st, id, view, original, safe_key(st, id, view, key)))
static func resolve_path(path: String) -> String:
	if path.is_empty(): return path
	ensure(); var row: Dictionary = _by_path.get(path, {})
	if row.is_empty(): return path
	var id = str(row.id); var view = context(id, str(row.view)); var original = str(row.key); var st = current_state()
	var key = choose_pool(st, id, view, original);key = choose_linked(st, id, view, key)
	key = load("res://scripts/scenarios/expression_surgery.gd").apply(st, id, view, original, key);key = safe_key(st, id, view, key)
	if key == original: return path
	var replacement = entry(id, view, key)
	if key == "__no_face__": return ""
	if replacement.is_empty() and view.begins_with("harem_") and allowed(id, view, "base"): replacement = entry(id, view, "base")
	if replacement.is_empty() or bool(replacement.get("baked", false)): return ""
	return str(replacement.path)
static func reload_preferences() -> void :
	_loaded = false;_entries.clear();_deleted.clear();_thumbs.clear();_thumb_order.clear();_disabled.clear();_links.clear();_profiles.clear();_by_path.clear();_by_key.clear();ensure();revision += 1
	load("res://scripts/ui/face_icon.gd")._cache.clear()

static func raw_texture(path: String) -> Texture2D:
	ensure()
	var row: Dictionary = _by_path.get(path, {})
	if not row.is_empty() and deleted(str(row.id), context(str(row.id), str(row.view)), str(row.key)): return null
	if path.begins_with("res://scripts/scenarios/art/"):
		var access = load("res://scripts/scenarios/art_access.gd")
		return access.raw_texture(path)
	return ResourceLoader.load(path, "Texture2D") if ResourceLoader.exists(path, "Texture2D") else null
static func _image(path: String) -> Image:
	var texture = load("res://scripts/scenarios/art_access.gd").raw_texture(path) if path.begins_with("res://scripts/scenarios/art/") else (ResourceLoader.load(path, "Texture2D") if ResourceLoader.exists(path, "Texture2D") else null)
	if texture == null: return null
	var image = texture.get_image()
	if image.is_compressed(): image.decompress()
	if image.get_format() != Image.FORMAT_RGBA8: image.convert(Image.FORMAT_RGBA8)
	return image
static func thumbnail(row: Dictionary, px: int = 112) -> Texture2D:
	if row.is_empty() or deleted(str(row.id), str(row.view), str(row.key)): return null
	px = 192 # One shared face-centered thumbnail size throughout all editors.
	var cache = str(row.path)
	if _thumbs.has(cache):
		_thumb_order.erase(cache);_thumb_order.append(cache);return _thumbs[cache]
	var disk = THUMB_DIR + "/" + cache.sha256_text() + ".png"
	var texture: Texture2D = null
	if FileAccess.file_exists(disk):
		var image = Image.load_from_file(disk)
		if image != null and image.get_width() <= 192 and image.get_height() <= 192: texture = ImageTexture.create_from_image(image)
	if texture == null:
		texture = preview_texture(row, px)
		if texture == null: return null
		DirAccess.make_dir_recursive_absolute(THUMB_DIR)
		texture.get_image().save_png(disk)
		if not _disk_thumbs_loaded:
			_disk_thumbs_loaded = true
			for file_name in DirAccess.get_files_at(THUMB_DIR):
				if str(file_name).ends_with(".png"): _disk_thumb_order.append(THUMB_DIR + "/" + str(file_name))
		_disk_thumb_order.erase(disk);_disk_thumb_order.append(disk)
		while _disk_thumb_order.size() > 256: DirAccess.remove_absolute(str(_disk_thumb_order.pop_front()))
	_thumbs[cache] = texture;_thumb_order.append(cache)
	while _thumb_order.size() > 96: _thumbs.erase(_thumb_order.pop_front())
	return texture
static func preview_texture(row: Dictionary, px: int = 640) -> Texture2D:
	if row.is_empty() or deleted(str(row.id), str(row.view), str(row.key)): return null
	var overlay = _image(str(row.path))
	if overlay == null: return null
	var id = str(row.id); var view = str(row.view)
	var base_path = "res://art/%s/%s.png" % [id, id + "_body_normal"]
	if view in ["standing", "scene_portrait"]: base_path = "res://art/%s/%s_body_normal.png" % [id, id]
	elif view.begins_with("harem_"): base_path = ""
	elif view == "fellatio": base_path = "res://art/%s/fellatio/head.png" % id
	else: base_path = "res://art/%s/%s/base.png" % [id, view]
	var base = _image(base_path) if base_path != "" else null
	var image = overlay.duplicate()
	if base != null:
		image = base.duplicate();image.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), Vector2i.ZERO)

	var bounds = overlay.get_used_rect()
	if view.begins_with("harem_"):
		# Native base/face difference bounds locate the actual face, not the full figure.
		var regions = {"reimu": {"harem_front": Rect2i(222,151,195,232), "harem_peek": Rect2i(456,482,129,122)}, "sakuya": {"harem_front": Rect2i(219,168,206,215), "harem_peek": Rect2i(470,477,130,115)}, "marisa": {"harem_front": Rect2i(221,165,204,210), "harem_peek": Rect2i(476,483,124,103)}, "sanae": {"harem_front": Rect2i(161,162,266,222), "harem_peek": Rect2i(473,480,111,93)}}
		bounds = regions.get(id, {}).get(view, bounds)
		var side = roundi(maxi(bounds.size.x, bounds.size.y) * 1.25)
		var crop = Rect2i(bounds.get_center() - Vector2i(side / 2, side / 2), Vector2i(side, side)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		image = image.get_region(crop)
	elif bounds.size.x > 0 and bounds.size.y > 0 and not view.begins_with("harem_"):
		var side = maxi(bounds.size.x, bounds.size.y)
		var rect = Rect2i(bounds.position - Vector2i((side - bounds.size.x) / 2, (side - bounds.size.y) / 2), Vector2i(side, side)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		image = image.get_region(rect)
	var ratio = float(px) / maxf(image.get_width(), image.get_height())
	image.resize(maxi(1, roundi(image.get_width() * ratio)), maxi(1, roundi(image.get_height() * ratio)), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)
