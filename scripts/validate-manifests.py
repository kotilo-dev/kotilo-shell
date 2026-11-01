#!/usr/bin/env python3
"""Validate every plugins/**/manifest.json against plugins/schema/manifest.schema.json.
Pure-stdlib validator covering the subset of JSON Schema we use (required, enum, pattern, type,
additionalProperties, array items/uniqueItems, allOf if/then). Exit 1 on any failure."""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = json.loads((ROOT / "plugins/schema/manifest.schema.json").read_text())

def check(value, schema, path, errors):
    t = schema.get("type")
    if t:
        ok = {"object": dict, "array": list, "string": str, "boolean": bool, "integer": int, "number": (int, float)}[t]
        if not isinstance(value, ok) or (t == "integer" and isinstance(value, bool)):
            errors.append(f"{path}: expected {t}"); return
    if "const" in schema and value != schema["const"]:
        errors.append(f"{path}: expected {schema['const']!r}")
    if "enum" in schema and value not in schema["enum"]:
        errors.append(f"{path}: {value!r} not in {schema['enum']}")
    if "pattern" in schema and isinstance(value, str) and not re.fullmatch(schema["pattern"], value):
        errors.append(f"{path}: {value!r} does not match {schema['pattern']}")
    if isinstance(value, str):
        if "minLength" in schema and len(value) < schema["minLength"]: errors.append(f"{path}: too short")
        if "maxLength" in schema and len(value) > schema["maxLength"]: errors.append(f"{path}: too long")
    if isinstance(value, dict):
        for r in schema.get("required", []):
            if r not in value: errors.append(f"{path}: missing required '{r}'")
        props = schema.get("properties", {})
        for k, v in value.items():
            if k in props: check(v, props[k], f"{path}.{k}", errors)
            elif schema.get("additionalProperties") is False: errors.append(f"{path}: unknown property '{k}'")
    if isinstance(value, list):
        if "minItems" in schema and len(value) < schema["minItems"]: errors.append(f"{path}: needs ≥{schema['minItems']} items")
        if schema.get("uniqueItems") and len(set(map(json.dumps, value))) != len(value): errors.append(f"{path}: duplicate items")
        if "items" in schema:
            for i, item in enumerate(value): check(item, schema["items"], f"{path}[{i}]", errors)
    for sub in schema.get("allOf", []):
        cond = sub.get("if")
        if cond and not _matches(value, cond): continue
        if "then" in sub: check(value, sub["then"], path, errors)

def _matches(value, cond):
    e = []; check(value, cond, "", e); return not e

def main(argv):
    base = ROOT / (argv[1] if len(argv) > 1 else "plugins")
    files = sorted(base.rglob("manifest.json"))
    if not files: print(f"no manifests under {base}"); return 1
    bad = 0; ids = {}
    for f in files:
        try: m = json.loads(f.read_text())
        except Exception as e: print(f"  {f}: invalid JSON ({e})"); bad += 1; continue
        errors = []; check(m, SCHEMA, "manifest", errors)
        if m.get("kind") == "qml" and not (f.parent / "Main.qml").exists(): errors.append("kind qml but no Main.qml")
        if m.get("kind") == "script" and not (f.parent / "widget.json").exists(): errors.append("kind script but no widget.json")
        if m.get("settingsSchema") and not (f.parent / m["settingsSchema"]).exists(): errors.append(f"settingsSchema {m['settingsSchema']} missing")
        if m.get("id") in ids: errors.append(f"duplicate id (also in {ids[m['id']]})")
        ids[m.get("id")] = f.parent.name
        if errors: bad += 1; print(f"  FAIL {f.relative_to(ROOT)}"); [print("    -", e) for e in errors]
        else: print(f"  ok   {f.relative_to(ROOT)}")
    print(f"{len(files) - bad}/{len(files)} manifests valid")
    return 1 if bad else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
