"""Check content/data against the schemas and the cross-file rules in content/README.md.

Usage: python -I tools/content/check_content.py <repo_root> [extra mission files relative to the hero folder...]
Reports observations; the apps' unit tests stay the real gate.
"""
import json
import sys
import unicodedata
from pathlib import Path

import jsonschema
from referencing import Registry, Resource

ROOT = Path(sys.argv[1]) / "content"
EXTRA = sys.argv[2:]
schemas = {}
reg = Registry()
for p in (ROOT / "schema").glob("*.json"):
    s = json.loads(p.read_text(encoding="utf-8"))
    schemas[p.name] = s
    res = Resource.from_contents(s)
    reg = reg.with_resource(s["$id"], res)


def load(p):
    return json.loads(Path(p).read_text(encoding="utf-8"))


errors, warns, notes = [], [], []


def validate(path, schema_name):
    data = load(path)
    v = jsonschema.Draft202012Validator(schemas[schema_name], registry=reg)
    errs = sorted(v.iter_errors(data), key=lambda e: list(e.path))
    for e in errs:
        errors.append(f"R1 {path.relative_to(ROOT)} at {list(e.path)}: {e.message[:160]}")
    return data


D = ROOT / "data"
rules = validate(D / "rules.json", "rules.schema.json")
markers = validate(D / "markers.json", "markers.schema.json")
sources = validate(D / "sources.json", "sources.schema.json")
assets = validate(D / "assets.json", "assets.schema.json")
index = validate(D / "index.json", "index.schema.json")
validate(D / "tuning.json", "tuning.schema.json")
validate(D / "strings.json", "strings.schema.json")
budget = rules["text_limits"]["en_budget"]
src_ids = {s["id"]: s for s in sources["sources"]}
asset_ids = {a["id"]: a for a in assets["assets"]}

all_text_ids = {}


def texts(obj, field, out):
    """Collect (field_type, Text) pairs."""
    out.append((field, obj))


for hero in index["heroes"]:
    H = D / "heroes" / hero
    claims = validate(H / "claims.json", "claims.schema.json")
    cmap = {c["id"]: c for c in claims["claims"]}
    files = [("mission.json", "mission.schema.json"), ("quiz.json", "quiz.schema.json")] + [(x, "mission.schema.json") for x in EXTRA]
    for c in claims["claims"]:
        for s in c["sources"]:
            if s not in src_ids:
                errors.append(f"R2 {hero} claim {c['id']}: source {s} missing")
        if c["label"] in ("fact", "fact_as_recorded") and c["signoff"]["status"] == "approved" and any(src_ids[s]["status"] == "to_confirm" for s in c["sources"]):
            errors.append(f"R5 {c['id']} approved with a to_confirm source")
        if not c["sources"] and c["label"] != "invented":
            errors.append(f"R5b {c['id']} has no sources")
    for fname, sname in files:
        data = validate(H / fname, sname)
        items = []
        pics = []
        if sname == "mission.schema.json":
            items += [("hero_name", data["hero"]["name"]), ("place", data["hero"]["place"])]
            items += [("intro", t) for t in data["intro"]]
            if "banner" in data:
                items.append(("banner", data["banner"]))
            for b in data["beats"]:
                items.append(("beat_title", b["title"]))
                items += [("scene", t) for t in b["scene"]]
                if "goal" in b: items.append(("goal", b["goal"]))
                # R13
                if b["type"] == "dialogue":
                    if b["buttons"]:
                        errors.append(f"R13d {fname} {b['id']}: dialogue buttons must be []")
                    lines_ = b["params"]["lines"]; ask = b["params"].get("ask")
                    if ask and ask["at_line"] + ask["taps"] > len(lines_):
                        errors.append(f"R13d {fname} {b['id']}: at_line + taps > lines")
                    first = lines_[0]
                    def marked(tx): return all(any(m in tx[l] for m in markers["legend"][l]) for l in ("vi","en"))
                    covered = set(first["text"]["claims"]) if first["speaker"] == "narrator" and marked(first["text"]) else set()
                    for ln in lines_:
                        fld = "dialogue_narrator" if ln["speaker"] == "narrator" else "dialogue_line"
                        items.append((fld, ln["text"], covered))
                        if ln["speaker"] != "narrator":
                            pid = f"pic.portrait_{data['hero']['id']}_{ln['speaker']}" + (f"_{ln['mood']}" if ln.get("mood") else "")
                            pics.append(pid)
                    if ask: items.append(("button", ask["button"], covered))
                    continue
                need = {"walk": {"move"}, "hold-meter": {"special"}, "fight": {"move", "attack"},
                        "training": {"move", "attack"}, "reach-the-flag": {"move"}}[b["type"]]
                p = b["params"]
                if b["type"] == "training":
                    if p.get("blocks", 0) > 0:
                        need.add("defend")
                    if p.get("finish_special"):
                        need.add("special")
                if b["type"] == "reach-the-flag" and p.get("encounters"):
                    need.add("attack")
                missing = need - set(b["buttons"])
                if missing:
                    errors.append(f"R13 {fname} {b['id']}: missing buttons {sorted(missing)}")
                if "special" in b["buttons"] and not (b["type"] in ("hold-meter",) or (b["type"] == "training" and p.get("finish_special"))):
                    errors.append(f"R13 {fname} {b['id']}: special not allowed on {b['type']}")
                if b["type"] == "reach-the-flag":
                    ats = [e["at_screen"] for e in p.get("encounters", [])]
                    if ats != sorted(set(ats)) or any(not (0 < a < p["length_screens"]) for a in ats):
                        errors.append(f"R13b {fname} {b['id']}: encounters {ats}")
            items += [("ending", t) for t in data["ending"]["lines"]]
            pics.append(data["ending"]["picture_id"])
        else:
            n = len(data["questions"])
            notes.append(f"{hero} quiz: {n} questions")
            for q in data["questions"]:
                items.append(("quiz_prompt", q["prompt"]))
                items.append(("quiz_why", q["why"]))
                for ch in q["choices"]:
                    items.append(("quiz_choice", ch["text"]))
                    pics.append(ch["picture_id"])
                if "picture_id" in q:
                    pics.append(q["picture_id"])
        for it in items:
            field, t = it[0], it[1]
            covered = it[2] if len(it) > 2 else set()
            tid = t["id"]
            if tid in all_text_ids and all_text_ids[tid] != fname and not (fname in EXTRA or all_text_ids[tid] in EXTRA):
                errors.append(f"R9 duplicate text id {tid}")
            all_text_ids.setdefault(tid, fname)
            for c in t["claims"]:
                if c not in cmap:
                    errors.append(f"R2 {fname} {tid}: claim {c} missing")
            labels = {cmap[c]["label"] for c in t["claims"] if c in cmap}
            for lang in ("vi", "en"):
                s = t[lang]
                if unicodedata.normalize("NFC", s) != s:
                    errors.append(f"R7 {fname} {tid}.{lang} not NFC")
                if len(s) > 120:
                    errors.append(f"R8 {fname} {tid}.{lang} {len(s)} chars")
            if len(t["en"]) > budget.get(field, 120) and field in budget:
                errors.append(f"R8 {fname} {tid}.en {len(t['en'])} > {field} budget {budget[field]}")
            if "legend" in labels:
                ok = all(any(m in t[l] for m in markers["legend"][l]) for l in ("vi", "en"))
                legend_claims = {c for c in t["claims"] if c in cmap and cmap[c]["label"] == "legend"}
                if not ok and legend_claims and legend_claims <= covered:
                    ok = True  # R4c
                if not ok:
                    (warns if field in ("banner", "quiz_choice", "beat_title", "goal", "hero_name", "place") else errors).append(f"R4 {fname} {tid} ({field}) cites a legend claim without a marker")
            if field.startswith("quiz") and "invented" in labels:
                errors.append(f"R6 {fname} {tid} quiz text cites an invented claim")
        for pid in pics:
            if pid not in asset_ids:
                errors.append(f"R10 {fname}: picture {pid} not in assets.json")
            elif not (D / asset_ids[pid]["file"]).exists():
                errors.append(f"R10 {fname}: file for {pid} missing")
        pending = sorted({c for it in items for c in it[1]["claims"] if c in cmap and cmap[c]["signoff"]["status"] == "pending"})
        notes.append(f"R12 {fname}: pending claims cited {pending} (release build refuses; debug shows UNSIGNED)")

for a in assets["assets"]:
    f = D / a["file"]
    if not f.exists():
        errors.append(f"R10 asset {a['id']}: file missing")
    elif f.stat().st_size != a["bytes"]:
        errors.append(f"R10 asset {a['id']}: bytes {f.stat().st_size} != {a['bytes']}")

print("ERRORS", len(errors)); [print("  ", e) for e in errors]
print("WARNINGS", len(warns)); [print("  ", w) for w in warns]
print("NOTES"); [print("  ", n) for n in notes]
