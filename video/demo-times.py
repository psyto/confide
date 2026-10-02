#!/usr/bin/env python3
"""Write each scene's time range in video/DEMO.md from video/demo-ops.manifest.json.

    python3 video/demo-times.py            # rewrite the "*Shows:* m:ss–m:ss" prefixes
    python3 video/demo-times.py --check    # exit 1 if any differs

The ranges were typed by hand on 2026-09-30 and went stale the moment the video was re-recorded.
They are derived from the cut's own timeline now: a scene starts where its first action landed.
"""
import json, os, re, sys

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
# THE SAME BOUNDARIES, AS CLIPS. The voice is generated per scene outside this repository, so the
# cut has to exist one scene at a time -- and until 2026-10-02 it did not: split.sh knew the check-in
# and the presentation only. Written here, from the starts computed above, so the clip lengths and
# the script's ranges cannot come from two different calculations. `./video/split.sh demo` cuts them.
SEG = "video/segments-demo"
titles = dict((int(n), s.strip()) for n, s in re.findall(r"^### (\d+) — ([^·\n]+)", doc, re.M))
slug = lambda s: re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
seg = [{"file": "%02d-%s.mp4" % (k, slug(titles[k])), "start": round(starts[k], 2),
        "end": round(ends[k], 2), "seconds": round(ends[k] - starts[k], 2)} for k in sorted(starts)]
seg_json = json.dumps(seg, indent=1) + "\n"
seg_path = f"{SEG}/manifest.json"
if "--check" in sys.argv:
    stale = []
    if out != doc:
        stale.append("video/DEMO.md scene times differ from the cut")
    if not os.path.exists(seg_path) or open(seg_path).read() != seg_json:
        stale.append(f"{seg_path} differs from the cut")
    if stale:
        print("  " + "; ".join(stale) + " -- python3 video/demo-times.py")
        sys.exit(1)
    print("  video/DEMO.md scene times and segments-demo/manifest.json match the cut")
else:
    open(DOC, "w", encoding="utf-8").write(out)  # computed above, written last
    os.makedirs(SEG, exist_ok=True)
    open(seg_path, "w").write(seg_json)
    print("  video/DEMO.md scene times written from the cut:", ", ".join(f"{k} {fmt(starts[k])}" for k in sorted(starts)))
    print(f"  {seg_path}: {len(seg)} clips -- ./video/split.sh demo")
