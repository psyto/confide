#!/usr/bin/env python3
"""Write each scene's time range in video/DEMO.md from video/demo-ops.manifest.json.

    python3 video/demo-times.py            # rewrite the "*Shows:* m:ss–m:ss" prefixes
    python3 video/demo-times.py --check    # exit 1 if any differs

The ranges were typed by hand on 2026-09-30 and went stale the moment the video was re-recorded.
They are derived from the cut's own timeline now: a scene starts where its first action landed.
"""
import json, re, sys

MANIFEST, DOC = "video/demo-ops.manifest.json", "video/DEMO.md"
# scene -> the mark that opens it: (mode, kind, step)
STARTS = {
    2: ("normal", "click", "Build both legs' proofs"),
    3: ("normal", "click", "Send the allocation (account not approved yet)"),
    4: ("normal", "click", "Approve exactly this account"),
    5: ("normal", "click", "Look from outside"),
    6: ("normal", "click", "Act 2 — approve a second holder"),
    7: ("normal", "ready", "done"),
    8: ("short", "ready", "done — the short leg was refused"),
}
m = json.load(open(MANIFEST))
tl = m["timeline"]
def at(mode, kind, step):
    for x in tl:
        if (x["mode"], x["kind"], x["step"]) == (mode, kind, step):
            return x["cut_seconds"]
    raise SystemExit(f"{MANIFEST} has no {mode} {kind} {step!r} -- re-cut with cut-app.js")
starts = {1: 0.0, **{k: at(*v) for k, v in STARTS.items()}}
ends = {k: starts.get(k + 1, m["cut_seconds"]) for k in starts}
fmt = lambda s: "%d:%02d" % divmod(int(round(s)), 60)
doc = open(DOC, encoding="utf-8").read()
out = doc
for k in sorted(starts):
    rng = f"{fmt(starts[k])}–{fmt(ends[k])}"
    pat = re.compile(r"(### %d — [^\n]*\n\n(?:> ?.*\n)+\n\*Shows:\* )\d+:\d\d–\d+:\d\d" % k)
    if not pat.search(out):
        raise SystemExit(f"scene {k}: no '*Shows:* m:ss–m:ss' line to rewrite")
    out = pat.sub(lambda mm: mm.group(1) + rng, out)
if "--check" in sys.argv:
    if out != doc:
        print("  video/DEMO.md scene times differ from the cut -- python3 video/demo-times.py")
        sys.exit(1)
    print("  video/DEMO.md scene times match the cut")
else:
    open(DOC, "w", encoding="utf-8").write(out)  # computed above, written last
    print("  video/DEMO.md scene times written from the cut:", ", ".join(f"{k} {fmt(starts[k])}" for k in sorted(starts)))
