#!/usr/bin/env bash
# Does the delivered film SAY what the script says?
#
#   ./scripts/spoken-check.sh video/Confide_Stocklana_20260923.mp4
#
# The audio is generated outside this repository and dropped back in, so the one thing nothing
# checked was whether the voice is reading the current script. On 2026-09-23 it was not: the
# delivered file's scene 3 was missing ": confidential delivery-versus-payment for tokenized
# stocks" and scene 4 still said "for cash" rather than "for stablecoins" -- the two lines added
# hours earlier, and the only two that had changed. Everything else matched, which is exactly why
# nobody would have noticed by listening.
#
# It reads the file's own ASR caption track, which is what the voice actually said as heard by a
# machine, and compares it with video/CWF-PRESENTATION.md. ASR mishears -- "confined" for Confide,
# "token I stock" for tokenized stock, "bite for bite" for byte -- so two tests are applied and
# neither of them is exact-match:
#
#   ABSENT WORD    a distinctive word of the script that appears NOWHERE in the transcript. A
#                  mishearing moves a word; it does not delete it from a 370-word film.
#   SCENE DRIFT    per-scene sequence similarity, reported for every scene and failed under 0.80.
#
# It does not check pronunciation and it cannot: read the diff and listen to the scenes it names.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="${1:?usage: spoken-check.sh <delivered.mp4>}"
FFMPEG="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
# THE HEREDOC EATS THE PIPE. The first version was `ffmpeg ... | python3 - <<PY`, and `python3 -`
# reads its program from stdin -- which the heredoc had already taken. Python got the script and
# nothing else, so the check reported "this file carries no caption track" about a file that has
# one. The track goes to a file and the file is named as an argument.
SRTFILE=$(mktemp -t spoken-check)
trap 'rm -f "$SRTFILE"' EXIT
# SRT= reads a CORRECTED track instead of the file's own, the same override video-chapters.sh
# takes. The embedded track is raw ASR: it hears the project's name as "confined" and, on the
# 09-23 cut, dropped twenty-one seconds of scene 5 outright. The corrected track is the one that
# gets uploaded, so it is the one worth checking when there is one.
if [ -n "${SRT:-}" ] && [ -f "${SRT}" ]; then
  cp "$SRT" "$SRTFILE"
else
  "$FFMPEG" -nostdin -v error -i "$SRC" -map 0:s:0 -f srt "$SRTFILE" -y 2>/dev/null || true
fi

# WHERE THE TRANSCRIBER GAVE UP. The ASR drops whole stretches: sixteen seconds of the 09-22 cut,
# and the whole of scene 5 on 2026-09-23 -- in both cases the voice was there and the transcript
# was not. The first version of this check read the empty stretch as a missing scene and told the
# founder to re-record twenty seconds of perfectly good audio. So every gap over six seconds is
# measured in the ACTUAL AUDIO, and a scene that falls inside a gap carrying speech is reported as
# unreadable rather than as wrong.
python3 - "$SRC" "$SRTFILE" "$FFMPEG" <<'PY'
import sys, re, io, os, subprocess
sys.path.insert(0, os.path.join(os.getcwd(), "scripts", "lib"))
import spoken

srt = io.open(sys.argv[2], encoding="utf-8").read() if len(sys.argv) > 2 else ""
if not srt.strip():
    print(f"  {sys.argv[1]} carries no caption track — nothing to check against", file=sys.stderr)
    print("  YouTube writes one after processing; pull the file back down once it has.", file=sys.stderr)
    sys.exit(2)

bold = "\033[1m"; red = "\033[31m"; grn = "\033[32m"; dim = "\033[2m"; off = "\033[0m"

CUE = r"(\d\d:\d\d:\d\d,\d+) --> (\d\d:\d\d:\d\d,\d+)\n(.*?)(?=\n\n|\Z)"
cues = re.findall(CUE, srt, re.S)
heard = " ".join(re.sub(r"\s+", " ", c[2]).strip() for c in cues)

def secs(x):
    h, m, rest = x.split(":"); s, ms = rest.split(",")
    return int(h) * 3600 + int(m) * 60 + int(s) + int(ms) / 1000

# GAPS, AND WHETHER THE VOICE IS IN THEM. A stretch with no cues means the transcriber stopped, not
# that the film went quiet -- so the audio itself is measured. Speech in the gap means this check
# is blind there and must say so; near-silence means the line really is missing.
def mean_db(start, length):
    out = subprocess.run([sys.argv[3], "-nostdin", "-v", "info", "-ss", f"{start:.2f}",
                          "-t", f"{length:.2f}", "-i", sys.argv[1], "-map", "0:a:0",
                          "-af", "volumedetect", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    m = re.search(r"mean_volume:\s*(-?[\d.]+) dB", out)
    return float(m.group(1)) if m else None

gaps = []
if cues:
    for a, b in zip(cues, cues[1:]):
        lo, hi = secs(a[1]), secs(b[0])
        if hi - lo > 6:
            gaps.append((lo, hi, mean_db(lo, hi - lo)))

script = io.open("video/CWF-PRESENTATION.md", encoding="utf-8").read()
scenes = spoken.scenes_of(script)
if not scenes:
    raise SystemExit("video/CWF-PRESENTATION.md: no scripted scenes found")

heard_w = spoken.norm(heard)
vocab = spoken.vocabulary(heard_w)

print()
print(f"  {bold}WHAT THE FILM SAYS, AGAINST THE SCRIPT{off}  {dim}{sys.argv[1]}{off}")
print()
# Which scenes the transcript cannot speak for.
if gaps:
    print(f"  {dim}the transcript stops for a while in {len(gaps)} place(s):{off}")
    for lo, hi, db in gaps:
        what = ("SILENT — nothing was said here" if db is None or db < -45
                else f"the voice IS here, {db:.1f} dB mean — the transcriber lost it")
        print(f"  {dim}  {lo:6.1f}s to {hi:6.1f}s   {what}{off}")
    print()

bad = 0
unreadable = 0
for n, title, said in scenes:
    ratio, missing = spoken.presence(spoken.norm(said), heard_w, vocab)
    # A SCENE THE TRANSCRIPT NEVER SAW IS NOT A SCENE THAT IS WRONG. The first version of this
    # check scored scene 5 at 10.8% and listed nine of its words as "never spoken anywhere in the
    # film" — while the audio across that window measured -21.4 dB, the loudest stretch in the
    # file. It would have sent the founder to re-record twenty seconds that were already right.
    if ratio < spoken.ABSENT and any(g[2] is not None and g[2] > -45 for g in gaps):
        unreadable += 1
        print(f"  {dim}?{off} {n:>2}. {title:<42} {dim}not in the transcript{off}")
        print(f"       {dim}the transcriber dropped this stretch and the voice is in it. This check")
        print(f"       cannot see the scene — listen to it, or re-pull the file once YouTube has")
        print(f"       written its own captions.{off}")
        continue

    ok = ratio >= 0.80 and not missing
    mark = f"{grn}✓{off}" if ok else f"{red}✗{off}"
    print(f"  {mark} {n:>2}. {title:<42} {ratio*100:5.1f}% of the scripted words")
    if missing:
        bad += 1
        print(f"       {red}never spoken anywhere in the film:{off} " + ", ".join(dict.fromkeys(missing)))
    elif not ok:
        bad += 1
        print(f"       {red}the scene has drifted{off} — only {ratio*100:.0f}% of its words matched")
print()
if unreadable:
    print(f"  {dim}{unreadable} scene(s) could not be checked — see above.{off}")
if bad:
    print(f"  {red}{bad} scene(s) are not reading the current script.{off}")
    print(f"  {dim}The audio is generated outside this repository, so this is the only thing that")
    print(f"  compares the two. Regenerate those scenes from video/segments-presentation/LINES.md.{off}")
    print()
    sys.exit(1)
print(f"  {grn}every scene the transcript covers says what the script says{off}")
print(f"  {dim}Pronunciation is not checked and cannot be — listen once for the project's own name.{off}")
print()
PY
