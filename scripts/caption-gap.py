#!/usr/bin/env python3
"""Fill a stretch the ASR dropped, using the script the voice was given.

    ./scripts/fix-captions.sh <file.mp4> | python3 scripts/caption-gap.py <file.mp4> <script.md>

`fix-captions.sh` corrects words and never touches a cue's timing, which is the right contract and
the reason this is a separate step: filling a gap AUTHORS timings, and that is a different promise.

It exists because the 2026-09-22 delivery has no cues at all between 83.4s and 99.8s. The audio is
there -- mean -24.4 dB across that window, with the short breaths of speech in it -- and the picture
is the stablecoin table, so the narration was spoken and the transcriber lost it. A caption track
with sixteen silent seconds in it fails exactly the viewer captions are for.

Three things are checked before a single cue is written, and any of them failing is an error rather
than a guess:

  1. the gap really is longer than a scene boundary (> 6 s),
  2. the audio inside it is NOT silent -- otherwise there is nothing to caption and the gap is real,
  3. exactly one scene of the script is missing from the transcript, so there is no question which
     words belong in the hole.
"""
import re, subprocess, sys, io, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "lib"))
import spoken

FFMPEG = "/opt/homebrew/bin/ffmpeg"
GAP = 6.0

def sec(t):
    h, m, r = t.split(":"); s, ms = r.split(",")
    return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000

def stamp(x):
    ms = int(round(x * 1000))
    return "%02d:%02d:%02d,%03d" % (ms // 3600000, ms // 60000 % 60, ms // 1000 % 60, ms % 1000)

src, doc = sys.argv[1], sys.argv[2]
srt = sys.stdin.read()
cues = [(sec(a), sec(b), " ".join(t.split()))
        for a, b, t in re.findall(r"(\d\d:\d\d:\d\d,\d+) --> (\d\d:\d\d:\d\d,\d+)\n(.*?)(?=\n\n|\Z)", srt, re.S)]
if not cues:
    sys.exit("  no cues in the track")

gaps = [(cues[i][1], cues[i + 1][0]) for i in range(len(cues) - 1) if cues[i + 1][0] - cues[i][1] > GAP]
if not gaps:
    sys.stdout.write(srt)
    sys.exit(0)
if len(gaps) > 1:
    sys.exit("  %d gaps over %gs — this fills one, and more than one needs a person" % (len(gaps), GAP))
g0, g1 = gaps[0]

# 2. The audio has to be there. A genuinely silent stretch is a gap the film meant, and captioning
#    it would put words on screen that nobody says.
out = subprocess.run([FFMPEG, "-nostdin", "-ss", str(g0), "-t", str(g1 - g0), "-i", src,
                      "-af", "volumedetect", "-f", "null", "-"],
                     capture_output=True, text=True).stderr
m = re.search(r"mean_volume: (-?[\d.]+) dB", out)
if not m:
    sys.exit("  could not measure the audio in %.1f-%.1fs" % (g0, g1))
if float(m.group(1)) < -45:
    sys.exit("  %.1f-%.1fs is silent (%s dB) — that gap is the film's, not the transcriber's" % (g0, g1, m.group(1)))

# 3. Exactly one scene must be missing, so the words are not a choice.
#
# This used to ask whether a scene's first five words appeared in the transcript as a literal
# substring, and on 2026-09-23 that made it refuse a file it could have fixed: the transcriber
# hears Confide as "confined" and writes "twenty thousand" as 20,000, so two scenes that were
# plainly there looked gone and the tool reported three holes where there was one. The comparison
# now lives in scripts/lib/spoken.py, which spoken-check.sh asks the same question of -- they gave
# different answers about the same file while each had its own copy of the idea.
md = io.open(doc, encoding="utf-8").read()
scenes = [(t, b) for _, t, b in spoken.scenes_of(md)]
heard_w = spoken.norm(" ".join(c[2] for c in cues))
vocab = spoken.vocabulary(heard_w)
missing = [(t, b) for t, b in scenes
           if spoken.presence(spoken.norm(b), heard_w, vocab)[0] < spoken.ABSENT]
if len(missing) != 1:
    sys.exit("  %d scenes are missing from the transcript, not 1 — %s"
             % (len(missing), ", ".join(t for t, _ in missing) or "none"))
title, body = missing[0]

# Spread the line over the gap at the track's own rhythm, so the inserted cues read like the rest.
per = sum(len(c[2].split()) for c in cues) / len(cues)
words = body.split()
n = max(1, min(len(words), round(len(words) / per)))
size = -(-len(words) // n)
chunks = [" ".join(words[i:i + size]) for i in range(0, len(words), size)]
span = (g1 - g0) / len(chunks)

new = []
for i, c in enumerate(chunks):
    a = g0 + i * span
    new.append((a, a + span * 0.92, c))
sys.stderr.write("  filled %.1f-%.1fs from scene \"%s\" — %d cues, %d words\n"
                 % (g0, g1, title, len(new), len(words)))

allc = sorted(cues + new)
sys.stdout.write("\n".join("%d\n%s --> %s\n%s\n" % (i + 1, stamp(a), stamp(b), t)
                           for i, (a, b, t) in enumerate(allc)))
