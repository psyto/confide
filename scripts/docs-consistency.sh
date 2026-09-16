#!/usr/bin/env bash
# Check what the documents claim against what the files actually are.
#
#   ./scripts/docs-consistency.sh
#
# healthcheck.sh asks the chain whether the on-chain claims are still true. This asks the same of
# the claims that are about files. Every check below measures the artifact rather than something
# derived from it, because on 2026-09-15 four separate mistakes had one shape: a transcript read
# instead of the audio, a manifest read instead of the render, a replace() return value read
# instead of the text. Exit code is the number of disagreements.
set -uo pipefail
cd "$(dirname "$0")/.."
FFPROBE="${FFPROBE_PATH:-/opt/homebrew/bin/ffprobe}"
FFMPEG="${FFMPEG_PATH:-/opt/homebrew/bin/ffmpeg}"
PUB="${PUB:-video/Confide_Stocklana_20260915.mp4}"

fail=0
ok()  { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad() { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail+1)); }

echo
echo "  THE VIDEO — measured from the file"
if [ -f "$PUB" ]; then
  mmss=$("$FFPROBE" -v error -show_entries format=duration -of default=nw=1:nk=1 "$PUB" \
         | python3 -c "import sys;d=float(sys.stdin.read());print('%d:%02d'%(d//60,d%60))")
  grep -q "published cut is \*\*$mmss\*\*" video/README.md \
    && ok "the published cut is $mmss and video/README.md says so" \
    || bad "the published cut is $mmss; video/README.md claims another length"

  "$FFMPEG" -nostdin -v error -i "$PUB" -map 0:s:0 -f srt - 2>/dev/null > /tmp/.dc.srt || true
  cues=$(grep -c '\-\->' /tmp/.dc.srt 2>/dev/null || echo 0)
  [ "$cues" -gt 0 ] && ok "the file carries $cues caption cues" || bad "no caption track in the file"

  # Flatten before matching: cue text is double-spaced and a phrase can straddle two cues, so a
  # literal grep reports the line missing when it is there. The bug this script exists to catch.
  python3 -c "
import re, sys
t = open('/tmp/.dc.srt', encoding='utf-8').read()
t = ' '.join(l.strip() for l in t.split(chr(10)) if l.strip() and '-->' not in l and not l.strip().isdigit())
sys.exit(0 if re.search(r'lender\\s+takes\\s+it', re.sub(r'\\s+', ' ', t)) else 1)
" \
    && ok "the seizure line is in the captions" \
    || bad "the seizure line is missing from the captions — sound-off viewers lose the strongest claim"

  # Silence is a property of the audio. Reading caption gaps is how this was got wrong.
  sil=$("$FFMPEG" -nostdin -hide_banner -i "$PUB" -af silencedetect=noise=-40dB:d=1 -f null - 2>&1 \
        | grep -c silence_start || true)
  [ "$sil" -eq 0 ] && ok "no silent second anywhere in the audio" \
                   || bad "$sil silent stretches — a line may not have been laid in"
else
  bad "$PUB is missing"
fi

if [ -f video/captions.srt ]; then
  for w in Salana Nvidia; do grep -q "$w" video/captions.srt && bad "captions.srt still says $w"; done
  ./scripts/fix-captions.sh 2>/dev/null | diff -q - video/captions.srt >/dev/null \
    && ok "captions.srt is what fix-captions.sh produces" \
    || bad "captions.srt has drifted from its generator"
fi

echo
echo "  THE CUT — the manifest against the clips on disk"
python3 - <<'PY' && ok "manifest, clip files and LINES.md name the same set" || bad "manifest, clips and LINES.md disagree"
import json, os, sys
man = [e["file"] for e in json.load(open("video/segments/manifest.json"))]
disk = sorted(f for f in os.listdir("video/segments") if f.endswith(".mp4"))
lines = open("video/segments/LINES.md", encoding="utf-8").read()
sys.exit(0 if sorted(man) == disk and all(n in lines for n in man) else 1)
PY

echo
echo "  THE COUNTS — measured, not remembered"
python3 video/pace.py >/dev/null 2>&1 \
  && ok "the presentation's timing table matches its own script" \
  || bad "video/CWF-PRESENTATION.md's table disagrees with its script — python3 video/pace.py --write"
t=$(cargo test 2>/dev/null | grep -E '^test result' | awk -F'[ ;]' '{s+=$4} END {print s+0}')
grep -q "cargo test  *# $t tests" README.md && ok "README says $t tests, and $t run" \
                                            || bad "$t tests run; README says something else"
n=$(python3 -c "print(len(open('_submission/full.md',encoding='utf-8').read()))")
[ "$n" -le 5000 ] && ok "_submission/full.md is $n characters, inside 5,000" \
                  || bad "_submission/full.md is $n characters, over 5,000"
read -r have claimed < <(python3 -c "
import re; s=open('_submission/youtube.md',encoding='utf-8').read()
b=re.findall(r'\`\`\`\n(.*?)\n\`\`\`',s,re.S)
print(len(max(b,key=len).strip()), re.search(r'## Description — (\d+)',s).group(1))")
[ "$have" = "$claimed" ] && [ "$have" -le 5000 ] \
  && ok "the YouTube description is $have characters and its heading agrees" \
  || bad "the YouTube description is $have characters; the heading claims $claimed"
./scripts/youtube-paste.sh 2>/dev/null | diff -q - _submission/youtube-paste.txt >/dev/null \
  && ok "youtube-paste.txt is what its generator produces" \
  || bad "youtube-paste.txt has drifted from youtube.md"

echo
echo "  THE LINKS — one video, one program, everywhere"
ids=$(grep -rhoE "youtu\.be/[A-Za-z0-9_-]{11}|embed/[A-Za-z0-9_-]{11}|VIDEO:-[A-Za-z0-9_-]{11}" \
      README.md web/index.html _submission/full.md docs/DURABILITY.md scripts/healthcheck.sh 2>/dev/null \
      | grep -oE "[A-Za-z0-9_-]{11}$" | sort -u)
[ "$(printf '%s\n' "$ids" | grep -c .)" -eq 1 ] \
  && ok "every surface points at $ids" \
  || bad "surfaces disagree about the video: $(printf '%s ' $ids)"

prog=$(grep -oE "Gn3rzw8[A-Za-z0-9]+" README.md docs/SEIZURE.md scripts/healthcheck.sh scripts/seizure-status.sh 2>/dev/null \
       | cut -d: -f2 | sort -u | grep -c . || echo 0)
[ "$prog" -le 1 ] && ok "the seizure program id is quoted consistently" \
                  || bad "more than one seizure program id is quoted"

echo
[ "$fail" -eq 0 ] && printf '  \033[32mconsistent\033[0m — every claim above was measured\n' \
                  || printf '  \033[31m%d disagreements\033[0m\n' "$fail"
exit "$fail"
