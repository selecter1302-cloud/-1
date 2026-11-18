#!/usr/bin/env python3
"""Apply scoped v58 fixes to scripts extracted from the verified v57 APK."""
from pathlib import Path
import sys
root=Path(sys.argv[1])
def change(rel,old,new):
    path=root/rel
    text=path.read_text(encoding="utf-8")
    n=text.count(old)
    if n!=1:
        raise ValueError(f"{rel}: expected one match, got {n}: {old[:60]!r}")
    path.write_text(text.replace(old,new),encoding="utf-8")

change("scenarios/expression_filter.gd", '"doggy": "H씬 · 후배위 · 얼굴층 없음",', '"doggy": "H씬 · 후배위 · 얼굴층 없음", "doggy_monitor": "H씬 · 후배위 · 작은 표정 화면",')
change("scenarios/expression_filter.gd", 'var source_view = "standing" if view == "scene_portrait" else view\n', 'var source_view = "standing" if view == "scene_portrait" else ("missionary" if view == "doggy_monitor" else view)\n')
change("scenarios/expression_filter.gd", 'if view == "scene_portrait":\n\t\trows = rows.duplicate(true)\n', 'if view in ["scene_portrait", "doggy_monitor"]:\n\t\trows = rows.duplicate(true)\n')
change("scenarios/expression_filter.gd", 'var row: Dictionary = _by_key.get(identity(id, "standing" if view == "scene_portrait" else view, key), {})\n\tif view == "scene_portrait" and not row.is_empty(): row = row.duplicate(true);row["view"] = view', 'var source_view = "standing" if view == "scene_portrait" else ("missionary" if view == "doggy_monitor" else view)\n\tvar row: Dictionary = _by_key.get(identity(id, source_view, key), {})\n\tif view in ["scene_portrait", "doggy_monitor"] and not row.is_empty(): row = row.duplicate(true);row["view"] = view')
change("ui/expression_surgery.gd", 'if view == "doggy" and sx._face_window.visible:\n\t\t\tview = str(sx._face_window.cfg.get("from", "missionary"));fallback = str(sx._face_window.expression)', 'if view == "doggy" and sx._face_window.visible and str(sx._face_window.character_id) == id:\n\t\t\t# The monitor reuses front-view art, not its expression storage branch.\n\t\t\tview = "doggy_monitor";fallback = str(sx._face_window.expression)')
change("ui/cg_view.gd", 'var expression: = ""', 'var expression: = ""\nvar _face_window_raw_expression: = ""')
change("ui/cg_view.gd", '\tcharacter_id = id\n\tcg = p_cg\n\tp_expression = load("res://scripts/scenarios/expression_filter.gd").resolve_expression(id, p_cg, p_expression)', '\tcharacter_id = id\n\tcg = p_cg\n\t_face_window_raw_expression = p_expression\n\tp_expression = load("res://scripts/scenarios/expression_filter.gd").resolve_expression(id, p_cg, p_expression)')
change("ui/cg_view.gd", 'func set_face(p_expression: String) -> void :\n\tp_expression = load', 'func set_face(p_expression: String) -> void :\n\t_face_window_raw_expression = p_expression\n\tp_expression = load')
change("ui/cg_view.gd", '\t\tface_window.show_for(character_id, cg, expression, visible)', '\t\tface_window.show_for(character_id, cg, _face_window_raw_expression if cg == "doggy" else expression, visible)')
change("ui/face_window_view.gd", '''\tif not on or p_expression == "__no_face__" or not applies(id, p_cg):
\t\thide()
\t\treturn
\tcharacter_id = id
\texpression = p_expression
\tvar src: = str(cfg["from"])
\t_base.texture = CgView._load(CgView.base_path(id, src))
\t_face.texture = CgView._load(CgView.face_path(id, src, p_expression))
\t_face.visible = _face.texture != null
\t_layout(cfg["rects"][id])
\tshow()''', '''\tif not on or p_expression == "__no_face__" or not applies(id, p_cg):
\t\thide()
\t\treturn
\tcharacter_id = id
\tvar src: = str(cfg["from"])
\t_base.texture = CgView._load(CgView.base_path(id, src))
\tif p_cg == "doggy":
\t\t# The visible monitor uses 'from' art; its rules must not share that view's saves.
\t\tvar filter = load("res://scripts/scenarios/expression_filter.gd")
\t\texpression = filter.resolve_expression(id, "doggy_monitor", p_expression)
\t\tif expression == "__no_face__":
\t\t\thide()
\t\t\treturn
\t\tvar row: Dictionary = filter.entry(id, "doggy_monitor", expression)
\t\tvar path: String = str(row.get("path", CgView.face_path(id, src, expression)))
\t\t# Loading art directly avoids applying the front-view preferences a second time.
\t\tif path.begins_with("res://scripts/scenarios/art/"):
\t\t\t_face.texture = load("res://scripts/scenarios/art_access.gd").raw_texture(path)
\t\telse:
\t\t\t_face.texture = ResourceLoader.load(path, "Texture2D") if ResourceLoader.exists(path, "Texture2D") else null
\telse:
\t\texpression = p_expression
\t\t_face.texture = CgView._load(CgView.face_path(id, src, expression))
\t_face.visible = _face.texture != null
\t_layout(cfg["rects"][id])
\tshow()''')
change("behavior_night.gd", '\t\t\t\tif NewGame.mod_enabled(state, "multi_visit_sleep"):\n\t\t\t\t\tstate.pending["clash_receipt"] = clash_receipt', '\t\t\t\tstate.pending["clash_receipt"] = clash_receipt')
change("behavior_night.gd", 'if not NewGame.mod_enabled(state, "multi_visit_sleep") or p.get("kind", "") != "visit" or not p.get("clash_receipt", {}) is Dictionary:', 'if p.get("kind", "") != "visit" or not p.get("clash_receipt", {}) is Dictionary:')
change("behavior_night.gd", '\tif both_visit_reason(state, p).is_empty():\n\t\topts.append({"id": "accept_both", "label": I18n.t("둘 다 맞이하기")})', '\tvar reason: = both_visit_reason(state, p)\n\topts.append({"id": "accept_both", "label": I18n.t("모두 받아들이기"), "disabled": not reason.is_empty(), "reason": reason})')
print("PATCH_APPLIED")
