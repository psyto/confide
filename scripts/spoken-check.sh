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
SRT=$(mktemp -t spoken-check)
trap 'rm -f "$SRT"' EXIT
"$FFMPEG" -nostdin -v error -i "$SRC" -map 0:s:0 -f srt "$SRT" -y 2>/dev/null || true
python3 - "$SRC" "$SRT" <<'PY'
import sys, re, io, difflib

srt = io.open(sys.argv[2], encoding="utf-8").read() if len(sys.argv) > 2 else ""
if not srt.strip():
    print(f"  {sys.argv[1]} carries no caption track — nothing to check against", file=sys.stderr)
    print("  YouTube writes one after processing; pull the file back down once it has.", file=sys.stderr)
    sys.exit(2)

bold = "\033[1m"; red = "\033[31m"; grn = "\033[32m"; dim = "\033[2m"; off = "\033[0m"

heard = " ".join(
    re.sub(r"\s+", " ", m).strip()
    for m in re.findall(r"\d\d:\d\d:\d\d,\d+ --> \d\d:\d\d:\d\d,\d+\n(.*?)(?=\n\n|\Z)", srt, re.S)
)

script = io.open("video/CWF-PRESENTATION.md", encoding="utf-8").read()
scenes = re.findall(r"^### (\d+) — ([^·\n]+?)\s*(?:·[^\n]*)?$\n\n((?:^>.*\n)+)", script, re.M)
if not scenes:
    raise SystemExit("video/CWF-PRESENTATION.md: no scripted scenes found")

# The voice says numbers as words and the transcript writes digits, and neither is wrong. Both
# sides are reduced to the same vocabulary before anything is compared.
NUM = {"a hundred and seventy-three thousand": "173000", "twenty thousand": "20000",
       "ten minutes": "10 minutes", "five years": "5 years",
       "1,992": "1992", "173,000": "173000", "20,000": "20000", "half a million": "half a million"}
def norm(s):
    s = s.lower()
    for a, b in NUM.items():
        s = s.replace(a, b)
    s = s.replace("’", "'").replace("—", " ").replace("–", " ")
    s = re.sub(r"[^a-z0-9'\- ]", " ", s)
    return [w for w in re.split(r"\s+", s) if w]

heard_w = norm(heard)
heard_set = set(heard_w)
# Hyphenated compounds reach the transcript as separate words as often as not.
for w in list(heard_set):
    heard_set.update(w.split("-"))

# A word worth failing over: long enough to be distinctive, and not a number the voice may phrase
# differently. Short words drift through ASR constantly and mean nothing on their own.
def distinctive(w):
    return len(w) >= 7 and not w.isdigit()

print()
print(f"  {bold}WHAT THE FILM SAYS, AGAINST THE SCRIPT{off}  {dim}{sys.argv[1]}{off}")
print()
bad = 0
for n, title, body in scenes:
    said = re.sub(r"\s+", " ", re.sub(r"^> ?", "", body, flags=re.M)).strip()
    want = norm(said)
    # Where this scene's words sit in the transcript: the best-matching run, so a scene is
    # compared with its own stretch of the film rather than with all of it.
    sm = difflib.SequenceMatcher(None, heard_w, want, autojunk=False)
    blocks = [b for b in sm.get_matching_blocks() if b.size]
    if blocks:
        lo = min(b.a for b in blocks); hi = max(b.a + b.size for b in blocks)
        window = heard_w[lo:hi]
    else:
        window = []
    ratio = difflib.SequenceMatcher(None, window, want, autojunk=False).ratio()
    missing = [w for w in want if distinctive(w) and w not in heard_set
               and not any(p in heard_set for p in w.split("-"))]
    ok = ratio >= 0.80 and not missing
    mark = f"{grn}✓{off}" if ok else f"{red}✗{off}"
    print(f"  {mark} {n:>2}. {title:<42} {ratio*100:5.1f}% of the scripted words")
    if missing:
        bad += 1
        print(f"       {red}never spoken anywhere in the film:{off} " + ", ".join(dict.fromkeys(missing)))
    elif not ok:
        bad += 1
        d = [w for w in want if w not in window]
        print(f"       {red}the scene has drifted{off} — missing: " + " ".join(d[:14]))
print()
if bad:
    print(f"  {red}{bad} scene(s) are not reading the current script.{off}")
    print(f"  {dim}The audio is generated outside this repository, so this is the only thing that")
    print(f"  compares the two. Regenerate those scenes from video/segments-presentation/LINES.md.{off}")
    print()
    sys.exit(1)
print(f"  {grn}every scene says what the script says{off}")
print(f"  {dim}Pronunciation is not checked and cannot be — listen once for the project's own name.{off}")
print()
PY
