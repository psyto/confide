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
# The file that is actually published. It moved on 2026-09-20 and the check kept passing against
# the old one, because it verifies that a claim matches A file rather than THE file.
PUB="${PUB:-video/Confide_Stocklana_20260923.mp4}"
# The caption file for the CURRENT video, not whichever one was published first. This guarded
# video/captions.srt — the 09-15 cut's track — and went on passing after the upload changed.
CAPS="${CAPS:-video/captions-20260923.srt}"

fail=0
ok()  { printf '  \033[32m✓\033[0m %s\n' "$1"; }
bad() { printf '  \033[31m✗\033[0m %s\n' "$1"; fail=$((fail+1)); }

echo
echo "  THE VIDEO — measured from the file"
if [ -f "$PUB" ]; then
  mmss=$("$FFPROBE" -v error -show_entries format=duration -of default=nw=1:nk=1 "$PUB" \
         | python3 -c "import sys;d=float(sys.stdin.read());print('%d:%02d'%(d//60,d%60))")
  # "delivered" rather than "published": the founder cuts the file and uploads it afterwards, so
  # between those two moments the README would have had to claim something untrue to pass.
  grep -qE "(published|delivered) cut is \*\*$mmss\*\*" video/README.md \
    && ok "the delivered cut is $mmss and video/README.md says so" \
    || bad "the delivered cut is $mmss; video/README.md claims another length"

  "$FFMPEG" -nostdin -v error -i "$PUB" -map 0:s:0 -f srt - 2>/dev/null > /tmp/.dc.srt || true
  cues=$(grep -c '\-\->' /tmp/.dc.srt 2>/dev/null || echo 0)
  [ "$cues" -gt 0 ] && ok "the file carries $cues caption cues" || bad "no caption track in the file"

  # Flatten before matching: cue text is double-spaced and a phrase can straddle two cues, so a
  # literal grep reports the line missing when it is there. The bug this script exists to catch.
  # THE SCRIPT'S OWN WORDS, not a list of them typed again. This was six phrases written for the
  # 09-20 cut -- "Nobody has built the block", "builds the proofs", "nobody in the middle" -- and
  # the 09-23 narration says none of them, so it failed the moment the check stopped looking at the
  # superseded file. spoken-check.sh already compares the delivered track against
  # CWF-PRESENTATION.md scene by scene and needs nothing typed, so it does this job instead.
  # Note what this does and does not prove. It reads the CORRECTED track -- the one that gets
  # uploaded -- so it verifies that track against the script. It cannot verify the VOICE for a
  # scene caption-gap authored: that text came from the script, so it matches it by construction.
  # Checking what was actually said needs the embedded track: ./scripts/spoken-check.sh "$PUB".
  SRT="$CAPS" ./scripts/spoken-check.sh "$PUB" >/tmp/.dc.spoken 2>&1 \
    && ok "the caption track that gets uploaded reads the current script, scene by scene" \
    || { sed -n '3,40p' /tmp/.dc.spoken | sed 's/^/     /'
         bad "the delivered captions do not read the current script — ./scripts/spoken-check.sh $PUB"; }

  # Silence is a property of the audio. Reading caption gaps is how this was got wrong.
  # A DROPPED LINE, not a breath. This was d=1 and the 09-22 delivery has a 1.4s beat between two
  # scenes, which is film-making and not a fault -- the check said "a line may not have been laid in"
  # about a pause between two lines that are both there. The shortest scripted line runs about five
  # seconds, so anything over three is the shape of a missing one; shorter pauses are printed and
  # not counted, because a person should still see them move.
  "$FFMPEG" -nostdin -hide_banner -i "$PUB" -af silencedetect=noise=-40dB:d=1 -f null - 2>&1 \
    | grep -aoE 'silence_start: [0-9.]+|silence_duration: [0-9.]+' | paste - - > /tmp/.dc.sil || true
  sil=$(awk '{d=$4+0; if (d>3) n++} END{print n+0}' /tmp/.dc.sil)
  if [ "$sil" -eq 0 ]; then
    ok "no stretch long enough to be a missing line$(awk '{d=$4+0; if (d>1) printf "  (longest pause %.1fs at %.0fs)", d, $2}' /tmp/.dc.sil)"
  else
    bad "$sil stretches over 3s — a line may not have been laid in"
  fi
else
  bad "$PUB is missing"
fi

if [ -f "$CAPS" ]; then
  for w in Salana Nvidia "stable coin" "Everyone leaves"; do
    grep -q "$w" "$CAPS" && bad "$CAPS still says $w"
  done
  ./scripts/fix-captions.sh "$PUB" 2>/dev/null \
    | python3 scripts/caption-gap.py "$PUB" video/CWF-PRESENTATION.md 2>/dev/null \
    | diff -q - "$CAPS" >/dev/null \
    && ok "$CAPS is what fix-captions.sh produces from the published file" \
    || bad "$CAPS has drifted from its generator"
fi

# The check-in's own track. A separate upload with a separate deadline, and the file that caught
# the ASR writing the chain's name as "salon a".
CK=video/checkin-1-20260921.srt
CKV=video/Confide_CWF_Check-in-1_20260921.mp4
if [ -f "$CK" ] && [ -f "$CKV" ]; then
  ./scripts/fix-captions.sh "$CKV" 2>/dev/null | diff -q - "$CK" >/dev/null \
    && ok "$CK is what fix-captions.sh produces from the delivered check-in" \
    || bad "$CK has drifted from its generator"
else
  bad "the check-in cut or its caption track is missing"
fi

echo
echo "  THE CUT — the manifest against the clips on disk"
# Every cut, not just the first one. This checked video/segments alone while two more cuts were
# added next to it, so the check-in and the presentation were cut, split and committed with nothing
# measuring them at all. video/segments itself went on 2026-09-24 with the rest of the 09-15 cut.
for seg in video/segments-checkin video/segments-presentation; do
  SEG="$seg" python3 - <<'PY' && ok "${seg#video/}: manifest, clips and LINES.md name the same set" \
                              || bad "${seg#video/}: manifest, clips and LINES.md disagree"
import json, os, sys
seg = os.environ["SEG"]
man = [e["file"] for e in json.load(open(f"{seg}/manifest.json"))]
disk = sorted(f for f in os.listdir(seg) if f.endswith(".mp4"))
lines = open(f"{seg}/LINES.md", encoding="utf-8").read()
sys.exit(0 if sorted(man) == disk and all(n in lines for n in man) else 1)
PY
done

# The set of filenames matching is not the same as the LINES.md content being current. The founder
# records FROM this file, so a script edited without re-running lines.py hands them last week's
# words under this week's clip names, and the check above would still pass.
for cut in checkin presentation; do
  python3 video/lines.py "$cut" --stdout 2>/dev/null | diff -q - "video/segments-$cut/LINES.md" >/dev/null \
    && ok "segments-$cut/LINES.md is what lines.py produces from the script" \
    || bad "segments-$cut/LINES.md has drifted — python3 video/lines.py $cut"
done

echo
echo "  THE WIRE — the client against the program"
if bash scripts/wire-check.sh >/dev/null 2>&1; then
  ok "every instruction's account count matches between client and program"
else
  bad "the client and the program disagree on an instruction's accounts — ./scripts/wire-check.sh"
fi
echo
echo "  THE COUNTS — measured, not remembered"
python3 video/pace.py >/dev/null 2>&1 \
  && ok "the presentation's timing table matches its own script" \
  || bad "video/CWF-PRESENTATION.md's table disagrees with its script — python3 video/pace.py --write"
t=$(cargo test 2>/dev/null | grep -E '^test result' | awk -F'[ ;]' '{s+=$4} END {print s+0}')
grep -q "cargo test  *# $t tests" README.md && ok "README says $t tests, and $t run" \
                                            || bad "$t tests run; README says something else"
z=$(cd programs/confide-seizure && cargo test 2>/dev/null | grep -E '^test result' | awk -F'[ ;]' '{s+=$4} END {print s+0}')
grep -q "# $z more, over the seizure program" README.md \
  && ok "README says $z over the seizure program, and $z run" \
  || bad "$z run over the seizure program; README says something else"
# _submission/full.md IS FROZEN and this check used to demand that it equal today's count.
#
# It was right while the form was editable -- the submission had drifted to "69 tests, 19 over the
# seizure program" because only README was being watched. Stocklana's edit window shut on
# 2026-09-25 16:00 ET, and from that moment the check could only be satisfied by never writing
# another test. It went red on 2026-09-30 for ten tests that turned a printed number into a
# comparison, and nothing could have cleared it: healthcheck.sh:239 already says a red no action
# can clear is a red that teaches everyone to skip.
#
# So it asks the question that still means something. A frozen submission may UNDERSTATE, which is
# the safe direction and the same ruling pasted.json records for the posted x-post ("the post
# understates ... and it stays as posted"). It may never OVERSTATE. Its integrity as a document is
# pinned by its sha256 in _submission/pasted.json, not by this line.
read -r fm fz < <(python3 - <<'PYF'
import re
m = re.search(r"^(\d+) tests, (\d+) over the seizure program\.", open("_submission/full.md").read(), re.M)
print(*(m.groups() if m else ("", "")))
PYF
)
if [ -z "$fm" ]; then
  bad "_submission/full.md no longer states a test count at all"
elif [ "$fm" -gt $((t + z)) ] || [ "$fz" -gt "$z" ]; then
  bad "_submission/full.md claims $fm tests / $fz over the program; only $((t + z)) / $z run — it OVERSTATES"
elif [ "$fm" -eq $((t + z)) ] && [ "$fz" -eq "$z" ]; then
  ok "_submission/full.md says $fm tests, $fz over the seizure program, and that is what runs"
else
  ok "_submission/full.md says $fm / $fz and $((t + z)) / $z run — frozen and understating, which is the safe direction"
fi
n=$(python3 -c "print(len(open('_submission/full.md',encoding='utf-8').read()))")
[ "$n" -le 5000 ] && ok "_submission/full.md is $n characters, inside 5,000" \
                  || bad "_submission/full.md is $n characters, over 5,000"
# Both YouTube copies, not just the first. The check-in file was written with hand-typed heading
# figures that were wrong by 7 and 22 the moment it was saved.
for yt in _submission/youtube.md _submission/youtube-checkin1.md; do
  read -r have claimed tl tclaimed < <(YT="$yt" python3 -c "
import os, re; s=open(os.environ['YT'],encoding='utf-8').read()
b=re.findall(r'\`\`\`\n(.*?)\n\`\`\`',s,re.S)
print(len(max(b,key=len).strip()), re.search(r'## Description — (\d+)',s).group(1),
      len(min(b,key=len).strip()), re.search(r'## Title — (\d+)',s).group(1))")
  [ "$have" = "$claimed" ] && [ "$have" -le 5000 ] && [ "$tl" = "$tclaimed" ] && [ "$tl" -le 100 ] \
    && ok "${yt#_submission/}: title $tl and description $have, both inside and both as claimed" \
    || bad "${yt#_submission/}: title $tl/$tclaimed, description $have/$claimed — a heading disagrees or a limit is passed"
done
for cut in "" checkin1; do
  out=_submission/youtube${cut:+-$cut}-paste.txt
  [ -z "$cut" ] && out=_submission/youtube-paste.txt
  ./scripts/youtube-paste.sh $cut 2>/dev/null | diff -q - "$out" >/dev/null \
    && ok "${out#_submission/} is what its generator produces" \
    || bad "${out#_submission/} has drifted — ./scripts/youtube-paste.sh $cut > $out"
done
# And the chapters against the file they describe. The published Stocklana cut carried chapter
# times from a different edit — a 2:07 runtime quoted for a 1:52 file — because they were copied
# from the recorder's plan. This reads them off the delivery.
if [ -f video/Confide_Stocklana_20260923.mp4 ]; then
  # TITLES used to come from the FROZEN delivered narration: CWF-PRESENTATION.md was restructured
  # on 2026-09-22 while the cut stayed as recorded, so the script's scene titles no longer matched
  # the voice on the delivery. The 09-23 cut WAS re-recorded from that script, so the two agree
  # again and the check reads the script — which is the arrangement this was always supposed to be.
  # SRT is the corrected track, because it is the one that gets uploaded.
  SRT=video/captions-20260923.srt TITLES=video/CWF-PRESENTATION.md \
  ./scripts/video-chapters.sh video/Confide_Stocklana_20260923.mp4 2>/dev/null \
  | diff -q - <(python3 -c "
import re
s = open('_submission/youtube.md', encoding='utf-8').read()
d = max(re.findall(r'\`\`\`\n(.*?)\n\`\`\`', s, re.S), key=len)
print('\n'.join(re.findall(r'(?m)^\d+:\d\d .*\$', d)))") >/dev/null \
    && ok "the YouTube chapters are the ones in the delivered file" \
    || bad "the YouTube chapters do not match the file — ./scripts/video-chapters.sh"
fi

# Every prose restatement of the market totals, against the file that computes them. On 2026-09-19
# the chain moved from $21.1m to $22.0m and six documents plus the packet GENERATOR still said the
# old number — the generator being the bad one, because regenerating the fourteen packets did not
# fix them. Anything that quotes a figure in millions has to match capacity.json or say why.
# The mint count, which was restated in forty files and went stale in all of them at once when a
# third issuer appeared on 2026-09-19. Same rule as the market totals: prose that speaks in the
# present tense has to match the file. Dated records — the reviews, the published cut's script and
# its YouTube description — describe a moment and are deliberately not listed.
# The loan record layout lives in Rust and is copied into web/loans.json so a browser can decode
# an account without a program. Two places holding one layout is the drift this repository keeps
# having, so the copy is checked against the original rather than trusted.
echo
echo "  THE LOAN LAYOUT — web/loans.json against the program"
python3 - <<'PY' && ok "loans.json and lender-check use the program's own loan offsets" || bad "a copy of the loan layout has drifted from the program"
import json, re, sys, pathlib
rs = pathlib.Path("programs/confide-seizure/src/lib.rs").read_text(encoding="utf-8")
def const(name):
    m = re.search(r"const %s: usize = (\d+);" % name, rs)
    return int(m.group(1)) if m else None
want = {"floor_mode": const("OFF_FLOOR_MODE"),
        "escrow": const("OFF_ESCROW"), "destination": const("OFF_DESTINATION"),
        "mint": const("OFF_MINT"), "oracle": const("OFF_ORACLE"),
        "q_min": const("OFF_Q_MIN"), "principal": const("OFF_PRINCIPAL"),
        "ratio_bps": const("OFF_RATIO_BPS"), "seized": const("OFF_SEIZED"),
        "release_destination": const("OFF_RELEASE_DESTINATION"), "released": const("OFF_RELEASED")}
lens = {"len_v1": int(re.search(r"LOAN_LEN_V1: usize = (\d+)", rs).group(1)),
        "len_v2": int(re.search(r"LOAN_LEN_V2: usize = (\d+)", rs).group(1)),
        "len_current": int(re.search(r"pub const LOAN_LEN: usize = (\d+);", rs).group(1))}
try:
    got = json.load(open("web/loans.json"))
except FileNotFoundError:
    print("      web/loans.json is missing"); sys.exit(1)
bad = [f"{k}: program {v}, loans.json {got['offsets'].get(k)}"
       for k, v in want.items() if got["offsets"].get(k) != v]
bad += [f"{k}: program {v}, loans.json {got.get(k)}" for k, v in lens.items() if got.get(k) != v]

# The lender's verifier keeps the same copy, because the offsets are private to the program.
lc = pathlib.Path("crates/confide-ct/src/lender_check.rs").read_text(encoding="utf-8")
names = {"escrow": "OFF_ESCROW", "destination": "OFF_DESTINATION", "mint": "OFF_MINT",
         "oracle": "OFF_ORACLE", "q_min": "OFF_Q_MIN", "principal": "OFF_PRINCIPAL",
         "ratio_bps": "OFF_RATIO_BPS", "seized": "OFF_SEIZED", "released": "OFF_RELEASED"}
for key, cname in names.items():
    m = re.search(r"const %s: usize = (\d+);" % cname, lc)
    if m is None or int(m.group(1)) != want[key]:
        bad.append(f"{cname}: program {want[key]}, lender_check.rs {m.group(1) if m else 'missing'}")
for b in bad[:8]: print("      " + b)
sys.exit(1 if bad else 0)
PY

echo
# A post cannot be edited after it goes out, so its figures are generated and this checks the
# generated file is current. The template is the source; x-post.txt is derived.
if [ -f docs/cwf-2026/x-post.txt ]; then
  # Skipped once posted. A post cannot be edited, so x-post.txt is frozen at what went out and
# Skipped once posted. A post cannot be edited, so x-post.txt is frozen at what went out and
# regenerating it would destroy the only record of what was actually said. pasted.json carries the
# flag and the sha; THE SUBMITTED FIELDS check below still verifies the file against it.
#
# Written as if/else, not as `A && ok || B && ok2 || bad`. That chain evaluates left to right, so a
# successful first branch fell through to the second `&&` and printed BOTH ticks.
if python3 -c "import json,sys; sys.exit(0 if json.load(open('_submission/pasted.json')).get('x-post',{}).get('immutable') else 1)" 2>/dev/null; then
  ok "x-post.txt is frozen at what was posted — not regenerated"
elif ./scripts/x-post.sh 2>/dev/null | diff -q - docs/cwf-2026/x-post.txt >/dev/null; then
  ok "docs/cwf-2026/x-post.txt is what its generator produces"
else
  bad "x-post.txt has drifted — ./scripts/x-post.sh > docs/cwf-2026/x-post.txt"
fi
fi

# The short description is a SUBMITTED field, and the one it replaced carried a mint count from
# before a third issuer existed. Prose checks elsewhere skip it because it is not markdown.
python3 - <<'PY' && ok "_submission/short.txt matches the mint count and names the wedge" || bad "_submission/short.txt has drifted — it is a submitted field"
import json, re, sys, pathlib
t = open("_submission/short.txt", encoding="utf-8").read()
want = str(len(json.load(open("web/mints.json"))))
bad = []
for m in re.finditer(r"\b([1-9][\d,]{3,})\b", t):
    if m.group(1).replace(",", "") not in (want, str(json.load(open("web/usage.json"))["total_accounts"])):
        bad.append("%s is neither the mint count nor the account count" % m.group(1))
if not re.search(r"stock-to-stablecoin|stablecoin swap", t, re.I):
    bad.append("it does not name the wedge")
# PASTED TWICE. On 2026-09-21 `bca61dc` -- a commit about YouTube caption tracks, whose message
# says nothing about this file -- appended a second verbatim copy of the sentence. It rode along
# in every repaste after that: `pasted.json` records 315 characters for a field whose text is 156.
# The checks here read the numbers and the wedge, and a paragraph repeated word for word passes
# both. What is checked is the shape: no block of this file is another block again.
blocks = [b.strip() for b in t.split("\n\n") if b.strip()]
if len(blocks) != len(set(blocks)):
    bad.append("a paragraph appears twice — this file is the paste source for one field")
# THE RECORD OF WHICH LINE WAS CHOSEN DRIFTED FROM THE LINE. short-alternatives.txt heads its
# first block "Chosen (short.txt)" and then quotes it; on 2026-09-22 `f61b53d` replaced the
# sentence here and left that block quoting the retired one, so the file that exists to say WHY
# this wording won was describing a wording that had lost. It is the copy-in-two-places failure,
# and the second place is the one nobody re-reads.
alt = pathlib.Path("_submission/short-alternatives.txt").read_text(encoding="utf-8")
chosen = [l.strip() for l in alt.split("\n")]
try:
    i = next(n for n, l in enumerate(chosen) if l.startswith("# Chosen (short.txt)"))
    quoted = next(l for l in chosen[i + 1:] if l and not l.startswith("#"))
    if quoted != blocks[0]:
        bad.append("short-alternatives.txt's \"Chosen\" block is not the line in short.txt")
except StopIteration:
    bad.append("short-alternatives.txt no longer records which line was chosen")
# ONE LINE, TWO SURFACES. full.md opens on the same sentence the short field carries, so a judge
# who reads the list entry and then the submission meets the same words -- which is the defect the
# founder caught in the film on 2026-09-23, where the description and the opening told different
# stories. They were aligned by hand on 2026-09-22 and drifted apart by 2026-09-24 without anything
# noticing. The lede is the first bold run of full.md, unwrapped, and it has to BE short.txt's line.
full = pathlib.Path("_submission/full.md").read_text(encoding="utf-8")
m = re.search(r"\*\*(.+?)\*\*", full, re.S)
if not m:
    bad.append("full.md has no bold lede to compare with short.txt")
elif " ".join(m.group(1).split()) != blocks[0]:
    bad.append("full.md's lede is not the line in short.txt")
if bad:
    print("      " + "; ".join(bad)); sys.exit(1)
PY

echo "  THE SLOT SCAN — the per-issuer table against web/slots.json"
python3 - <<'PY' && ok "every issuer's mint count matches web/slots.json" || bad "an issuer's mint count has drifted — RPC=<endpoint> ./scripts/slot-scan.sh, then fix the prose"
import json, re, sys, pathlib
d = json.load(open("web/slots.json"))
want = {r["issuer"]: r["mints"] for r in d["by_issuer"]}
files = ["README.md", "STATUS.md", "docs/cwf-2026/THE-PINCER.md", "docs/cwf-2026/GTM.md",
         "_submission/full.md", "docs/ONCHAIN.md", "DESIGN.md"]
bad = []
for f in files:
    t = pathlib.Path(f).read_text(encoding="utf-8")
    # `Backed 828`, `Backed     EMPTY   828`, `Backed 828,` — the issuer's name and the next number
    # on the same line. This existed because README carried `Backed EMPTY 732` and `Backpack EMPTY
    # 1137` for weeks: the two did not add up to the 1,992 in the sentence above them, a whole
    # third issuer was missing, and nothing failed.
    for line in t.splitlines():
        for iss, n in want.items():
            m = re.search(re.escape(iss) + r"\D{0,24}?(\d[\d,]*)", line)
            if m and int(m.group(1).replace(",", "")) != n:
                got = m.group(1)
                # A year, a dollar figure, an LTV, or a line from the ACCOUNT scan — which names
                # the same issuers beside a count of token accounts and is checked against
                # web/usage.json instead. Narrowing this was needed: without it the account table
                # in README read as four drifted mint counts.
                if re.search(r"(20\d\d|\$|LTV|\baccounts\b)", line):
                    continue
                bad.append("%s: %s %s, web/slots.json says %d" % (f, iss, got, n))
if bad:
    print("\n".join("      " + b for b in sorted(set(bad)))); sys.exit(1)
PY

echo "  THE ACCOUNT SCAN — prose against web/usage.json"
python3 - <<'PY' && ok "the account-scan figures match web/usage.json" || bad "an account-scan figure has drifted — ./scripts/usage-scan.sh, then fix the prose"
import json, re, sys, pathlib
u = json.load(open("web/usage.json"))
total = u["total_accounts"]
conf = u["total_confidential_accounts"]
appr = u["total_approved_accounts"]
want = {"{:,}".format(total), str(total)}
# Per-mint counts are legitimate figures in an account-count context, and README prints all six.
# They are checked line-for-line against the scan by THE PASTED SCAN below, which is stricter
# than this one; without them here, that check's own subject failed this one.
for _m in u["mints"]:
    want |= {"{:,}".format(_m["accounts"]), str(_m["accounts"])}
# This list held three files while the figure was live on ten. README's headline table, the
# page's hero panel and og:description, the submission and the YouTube description all carried it
# and none was read — so a scan that moved the count by 730 failed on STORY.md alone and looked
# like one stale sentence. The video, its script and its captions are deliberately absent: they
# are a dated recording, the narration rounds, and re-rendering a delivered file to chase a number
# that moves weekly is not a thing this repository can do.
files = ["STATUS.md", "README.md", "web/index.html", "_submission/full.md",
         "_submission/short-alternatives.txt", "_submission/youtube.md",
         "_submission/youtube-paste.txt", "docs/cwf-2026/POST.md", "docs/cwf-2026/STORY.md",
         "docs/cwf-2026/COMPOSITION.md", "scripts/testbed-join.sh"]
# A PASTED FILE IS A RECORD, NOT A SURFACE. `_submission/full.md` holds what went into Stocklana's
# form, whose edit window shut 2026-09-25. Editing it to match a later scan would destroy the thing
# THE SUBMITTED FIELDS compares against, so these two checks would disagree by construction and one
# of them would have to be wrong. Skipped here and guarded there -- and the skip is PRINTED, on the
# rule that the dangerous exemption is the silent one. The list above stays wide: a file leaves this
# check only by being pasted, and says so when it does.
frozen = {}
try:
    frozen = {v["file"]: v["pasted_utc"][:16]
              for v in json.load(open("_submission/pasted.json")).values()}
except Exception:
    pass
bad = []
for f in files:
    if f in frozen:
        print("      %s: a record of what was pasted %s — checked by THE SUBMITTED FIELDS instead"
              % (f, frozen[f]))
        continue
    t = pathlib.Path(f).read_text(encoding="utf-8")
    # Only figures in an account-count context: a bare six-digit number elsewhere is a balance or
    # a compute figure, and flagging those would teach the check to cry wolf the way the mint
    # count already had to learn not to.
    # THE SUBMITTED FIELD WROTE IT ANOTHER WAY. This matched only "N accounts" and "N token
    # accounts", so on 2026-09-24 it stayed green while `_submission/full.md` said "469,477
    # across the six mints" and the YouTube description said "469,477 live token accounts" --
    # both named in this very list, both a scan out of date, neither seen. The number is now
    # followed to whatever noun phrase ends in "account(s)", and to the submission's own
    # "across the ... mints". `accounts?(?![-\w])` keeps `100000 account-keys.json`, a command
    # line further down README, from reading as a count.
    for pat in (r"([1-9][\d,]{4,})(?:[ -][a-z]+){0,4}[ -]accounts?(?![-\w])",
                r"([1-9][\d,]{4,}) across the [a-z]+ mints"):
        for m in re.finditer(pat, t):
            if m.group(1) not in want:
                bad.append(f"{f}: {m.group(1)} accounts, web/usage.json says {total}")
    # And the headline: the whole claim is that the number of confidential accounts is this one.
    for m in re.finditer(r"(\d+) (?:of them )?configured for confidential", t):
        if int(m.group(1)) != conf:
            bad.append(f"{f}: says {m.group(1)} configured, web/usage.json says {conf}")
    # CONFIGURED IS NO LONGER THE HEADLINE. On 2026-09-22 two NVDAx accounts configured one and
    # neither was approved, so "zero" moved from the first number to the second. Both are checked.
    for m in re.finditer(r"(\d+) approved by an issuer", t):
        if int(m.group(1)) != appr:
            bad.append(f"{f}: says {m.group(1)} approved, web/usage.json says {appr}")
    # "Of 330,266 live accounts" — the page's og:description, which no fetch can reach because a
    # crawler reads the source. The hero panel beside it is filled from usage.json; this is not.
    for m in re.finditer(r"Of ([1-9][\d,]{4,}) live accounts", t):
        if m.group(1) not in want:
            bad.append(f"{f}: og:description says {m.group(1)}, web/usage.json says {total}")
if bad:
    print("\n".join("      " + b for b in bad)); sys.exit(1)
PY

echo "  THE PASTED SCAN — README's transcript against what the scan would print"
python3 - <<'PYB' && ok "README's usage-scan block is what usage-scan.sh prints" || bad "README's pasted scan output is not what the scan prints — rebuild it from web/usage.json"
import json, pathlib, re, sys
u = json.load(open("web/usage.json"))
want = ["$ ./scripts/usage-scan.sh"]
for m in u["mints"]:
    want.append("  %-10s %-10s %7d accounts   %3d over 400 bytes   %d configured   %d approved"
                % (m["symbol"], m["issuer"], m["accounts"], m["over_400_bytes"],
                   m["confidential_accounts"], m["approved_accounts"]))
want += ["", "  %d token accounts across %d mints, %d configured for confidential transfers, "
             "%d approved by an issuer"
         % (u["total_accounts"], len(u["mints"]), u["total_confidential_accounts"],
            u["total_approved_accounts"])]
t = pathlib.Path("README.md").read_text(encoding="utf-8")
m = re.search(r"```\n(\$ \./scripts/usage-scan\.sh\n.*?)\n```", t, re.S)
if not m:
    print("      README no longer holds a usage-scan transcript"); sys.exit(1)
got = m.group(1).splitlines()
if got != want:
    # Why this exists: the block held four rows and claimed six mints, because the two Backpack
    # mints with no holders had been dropped from a paste. A reader running the command would
    # have got a different screen, which is the one thing a transcript must not do.
    for i in range(max(len(got), len(want))):
        g = got[i] if i < len(got) else "(missing)"
        w = want[i] if i < len(want) else "(not printed)"
        if g != w:
            print("      line %d: README %r" % (i + 1, g))
            print("               scan   %r" % (w,))
    sys.exit(1)
PYB

echo "  THE MINT COUNT — prose against web/mints.json"
python3 - <<'PY' && ok "every quoted mint count matches web/mints.json" || bad "a quoted mint count has drifted — ./scripts/refresh-mints.sh, then fix the prose"
import json, re, sys, pathlib
mints = json.load(open("web/mints.json"))
want = {"{:,}".format(len(mints)), str(len(mints))}
files = ["README.md", "STATUS.md", "DESIGN.md", "docs/ONCHAIN.md", "docs/27-DAYS.md",
         "docs/cwf-2026/THE-PINCER.md", "docs/cwf-2026/FOUNDER-MARKET-FIT.md", "docs/cwf-2026/GTM.md",
         "docs/cwf-2026/POST.md", "_submission/full.md", "web/index.html", "web/kamino.html"]
bad = []
for f in files:
    t = pathlib.Path(f).read_text(encoding="utf-8")
    # Only figures in a mint-count context. A bare four-digit number is as likely to be a
    # character limit or one issuer's share, and flagging those taught the check to cry wolf.
    pats = [r"([1-9],\d{3}) of \1", r"([1-9],\d{3}) (?:tokenized|mints|tokenized-equity)",
            r"(?:all|any of the|the other) ([1-9],\d{3})\b", r"\bof the ([1-9],\d{3})\b"]
    # A figure inside quotation marks is being QUOTED, not claimed -- STATUS.md and
    # short-alternatives.txt both have to name "1,869" to record that it rotted in a submitted
    # field, and a check that forbids naming the bad number forbids writing down the lesson.
    # Only straight and curly double quotes count. The span may cross a line break -- these files
    # wrap at 100 columns and the first attempt at this rule missed the quote it was written for,
    # because it sat across two lines -- but it is bounded at 300 characters so an unpaired quote
    # cannot swallow a whole section and silence the check.
    unquoted = re.sub(r'["\u201c\u201d][^"\u201c\u201d]{0,300}?["\u201c\u201d]', " ", t, flags=re.S)
    found = {m if isinstance(m, str) else m[0] for p2 in pats for m in re.findall(p2, unquoted)}
    for n in found:
        if n not in want:
            bad.append("%s says %s; web/mints.json holds %s" % (f, n, "{:,}".format(len(mints))))
for b in sorted(set(bad))[:8]:
    print("      " + b)
sys.exit(1 if bad else 0)
PY

echo
echo "  THE POPULATION — 1,992 is a catalogue, not a census"
python3 - <<'PY' && ok "no live surface claims a census of Solana" || bad "the population claim is wrong somewhere — docs/cwf-2026/THE-POPULATION.md"
import re, subprocess, sys, pathlib

# web/mints.json comes from three issuers' own asset APIs, so a census claim over the whole chain
# was never true. Codex said so on 2026-09-15 and the correction went into ONE file while the
# sentence stayed in thirty-three others -- including the script header the others were quoting.
# Nothing compared the headline to the caveat sitting underneath it. This does.
# docs/cwf-2026/THE-POPULATION.md carries the wording and the reasons.
#
# The comment above deliberately does not spell the phrase out: the first run of this check matched
# its own explanation of itself, which is the bug this file exists to catch, found in this file.
#
# Files come from git rather than a typed list -- the last typed list of surfaces carrying this
# claim was short by twenty -- and untracked-but-not-ignored files count, so a new document cannot
# arrive with the claim in it and be invisible until someone commits it.
# Three shapes, because the first version of this check only knew the first one and Codex found
# four live surfaces it walked straight past -- including the published site and the script that
# GENERATES fourteen tracked packets. A quantifier does not have to be a word.
pats = [
    # "every|all ... tokenized stock ... on Solana"
    re.compile(r"(?:every|all|the whole)[^.\n]{0,70}?tokenized[- ](?:equity|stock)s?"
               r"[^.\n]{0,50}?on Solana", re.I),
    # "1,992 tokenized stocks on Solana" -- a count IS a quantifier. Anchored on the number sitting
    # next to the noun so that a date earlier in the line does not stand in for one.
    re.compile(r"\b\d[\d,]*\s+tokenized[- ](?:equity|stock)s?[^.\n]{0,50}?on Solana", re.I),
    # the packet generator's phrasing, which names no population at all
    re.compile(r"whole asset class", re.I),
]

# Each of these still says it, on purpose. The reason is the entry -- a bare path would let the
# allowlist absorb a new mistake, which is the shape of the failure it exists to prevent.
allowed = {
    "docs/cwf-2026/THE-POPULATION.md":        "the correction, which has to quote what it corrects",
    "_submission/full.md":                    "Stocklana's submitted text; the edit window shut 2026-09-25",
    "docs/cwf-2026/x-post.txt":               "posted and uneditable; the .tmpl it came from is corrected",
    "_submission/short-alternatives.txt":      "keeps every retired and rejected draft line verbatim",
    "video/CWF-PRESENTATION.md":              "the narration that was recorded and published",
    "video/captions-20260923.srt":            "the caption track uploaded with that narration",
    "video/segments-presentation/LINES.md":   "the narration that was recorded and published",
    "video/segments-presentation/manifest.json": "the narration that was recorded and published",
}
skip = re.compile(r"^docs/reviews/")   # what a reviewer said, and what they were sent

# Backticks count as quotation: STATUS.md documents this check's own patterns as markdown code
# spans, which is the right way to cite a literal and is not a claim about anything. Pairs are
# consumed left to right and non-greedily, so a real claim sitting between two unrelated spans is
# still read.
QUOTED = re.compile(
    r'&ldquo;.{0,300}?&rdquo;'
    r'|`[^`]{0,300}?`'
    r'|["\u201c\u201d\u300c\u300d][^"\u201c\u201d\u300c\u300d]{0,300}?'
    r'["\u201c\u201d\u300c\u300d]', re.S)


def unquote(s, prose=True):
    # NOT in JSON. There a double quote is syntax, not citation, so stripping quoted spans hides
    # every string value in the file -- which silently excused video/segments-presentation/
    # manifest.json, where the quoted string IS the published narration.
    return QUOTED.sub(" ", s) if prose else s

files = subprocess.run(["git", "ls-files", "--cached", "--others", "--exclude-standard"],
                       capture_output=True, text=True).stdout.split()
found, bad = set(), []
for f in files:
    if skip.match(f):
        continue
    p = pathlib.Path(f)
    # NOT .srt: the caption track that gets uploaded is a published surface, and the first
    # version of this check skipped it by suffix -- which hid one.
    if p.suffix in (".png", ".jpg", ".jpeg", ".mp4", ".ico") or not p.exists():
        continue
    try:
        t = p.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        continue
    for i, line in enumerate(t.splitlines(), 1):
        # A QUOTED occurrence is a citation, not a claim. The correction has to be able to print the
        # sentence it is correcting -- README's note above the video link, THE-POPULATION.md, the
        # check-in card -- and a check that forbids naming the bad sentence forbids retracting it.
        # Same rule THE MINT COUNT uses for figures, same 300-character bound so an unpaired quote
        # cannot swallow a section and silence the check. Japanese corner brackets count: STATUS.md
        # records the defect in Japanese. HTML entities count: the site quotes it as markup.
        if any(x.search(unquote(line, p.suffix != ".json")) for x in pats):
            found.add(f)
            if f not in allowed:
                bad.append("%s:%d claims a census: %s" % (f, i, line.strip()[:90]))

# THE SECOND HALF, and it is the finding that made this check worth having. The first pass replaced
# one false sentence with THREE different true ones -- "the three issuer catalogues publish", "these
# three issuers list", "in web/mints.json" -- and Codex called that the same drift starting again.
# docs/cwf-2026/THE-POPULATION.md fixes exactly two forms. Anything else is a third.
drift = re.compile(r"catalogues? publish|issuers? list\b|issuers publish", re.I)
for f in files:
    if skip.match(f) or f in ("scripts/docs-consistency.sh", "docs/cwf-2026/THE-POPULATION.md"):
        continue
    p = pathlib.Path(f)
    if p.suffix in (".png", ".jpg", ".jpeg", ".mp4", ".ico") or not p.exists():
        continue
    try:
        t = p.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        continue
    for i, line in enumerate(t.splitlines(), 1):
        # Same rule: naming a banned phrasing in order to ban it is not using it.
        if drift.search(unquote(line, p.suffix != ".json")):
            bad.append("%s:%d a third phrasing: %s" % (f, i, line.strip()[:80]))

# An entry that no longer carries the claim means the file was re-cut or re-pasted and the reason
# has expired. Leaving it is how the allowlist stops describing anything.
for f, why in sorted(allowed.items()):
    if f not in found:
        bad.append("%s no longer says it — drop the allowlist entry (%s)" % (f, why))

for b in bad[:10]:
    print("      " + b)
sys.exit(1 if bad else 0)
PY

echo
echo "  THE MOTIVE — what the issuers configured, never why"
python3 - <<'PY' && ok "no live surface says why the auditor slot is empty" || bad "a surface claims a motive — docs/cwf-2026/THE-PINCER.md, 2026-09-27"
import hashlib, re, subprocess, sys, pathlib

# The empty auditor slot and the shut gate are also the ZERO VALUE of the mint's confidential-transfer
# struct, so a shared template produces them with nobody deciding (THE-PINCER.md, 2026-09-27). The
# 2026-09-29 sweep fixed nine surfaces by hand and added no check. On 09-30 the reading was still in
# the published site, README, DESIGN, STORY, two crates' doc comments, the YouTube description, and
# slot-scan.sh's own OUTPUT.
#
# The first version of this check listed phrasings, and Codex walked eleven live claims past it the
# same day -- "each arrived there independently", "that is why the live mints leave it null",
# "makes the abstention deliberate". A list of phrasings catches the phrasings its author thought
# of. So the rules below are SHAPES of a claim, judged per paragraph:
#
#   CAUSE        the slot/key/field is empty or null, and the same paragraph gives a reason for it
#   INDEPENDENCE "independent" said of the issuers, the mints, or a witness to the configuration
#   INTENT       the configuration called deliberate, meant, or hard to explain away
#   SECONDARY    the empty slot said to block the secondary market -- an issuer need nobody asked about
#
# The shapes are described rather than spelled where possible; THE POPULATION's first run matched
# its own comment.
#
# WHAT THIS IS NOT: a proof that no surface implies a motive. It is a regression guard for the shapes
# that have actually appeared, plus the ones they generalise to. Codex constructed paraphrases in
# round 2 that a regular expression will always be able to miss -- "the pattern is purposeful",
# "peer-to-peer confidential settlement remains unavailable". Reading is still the check; this makes
# sure what was already read and fixed does not come back.
SLOT = re.compile(r"auditor|slot|\bkey\b|\bfield\b|auditorElgamalPubkey|auditor_elgamal_pubkey", re.I)
EMPTY = r"(?:empty|null|None|unset|inert)"
# A reason attached to the emptiness, in the grammatical shapes it has actually taken here.
# "... empty — because ...": needs the slot, the feature or Token-2022 named in the sentence, since
# plenty of true sentences say an ACCOUNT is empty because of something.
CAUSE_BECAUSE = re.compile(EMPTY + r"\b[^.]{0,80}?\bbecause\b", re.I)
NAMES_IT = re.compile(SLOT.pattern + r"|feature|extension|Token-2022", re.I)
# "that is why they leave it null", "so it sits empty": the shape alone is the claim, whatever "it" is.
CAUSE_SHAPE = re.compile(
    r"\b(?:that is why|which is why|the reason)\b[^.]{0,80}?\b(?:leave|leaves|left|stays?|sits?|keeps?)\b[^.]{0,30}?" + EMPTY +
    r"|\bso\b(?![^.]{0,20}\bnothing\b)[^.]{0,40}?\b(?:sits?|left|leaves?|stays?|keeps?)\b[^.]{0,20}?" + EMPTY, re.I)
# Verdicts. The strong ones are claims on their own; "not an oversight" only next to an empty slot.
VERDICT_STRONG = re.compile(r"what the substrate (?:forces|does)|nobody chose|only available choice"
                            r"|property of the substrate|not a choice any"
                            r"|\bnot (?:somebody|anybody|anyone|someone)'?s? (?:choice|decision)", re.I)
ISSUER_NAMED = re.compile(r"\bissuers?\b|Backed|Backpack|PreStocks|Paxos|PayPal|Kraken", re.I)
# Reason FIRST: "Because one auditor sees every transfer, issuers keep the field unset." (Codex r2)
CAUSE_FIRST = re.compile(  # needs the slot/feature named too, or "retried, because an RPC came back empty" trips it
    r"\b(?:because|since)\b[^.]{0,120}?\b(?:keeps?|leaves?|left|stays?|sits?)\b[^.]{0,30}?" + EMPTY, re.I)
SEPARATELY = re.compile(r"\bseparately\b|\bon their own\b|nothing to do with each other|\bunrelated\b", re.I)
CHOICE = re.compile(r"\b(?:chose|chosen|choose|decided|choice|purposeful)\b", re.I)
VERDICT = re.compile(r"not an oversight", re.I)
INDEPENDENCE = re.compile(r"\bindependent(?:ly)?\b(?!\s+(?:verifiab|verifi|checkab|of\b))", re.I)
ABOUT_ISSUERS = re.compile(r"\bissuers?\b|\bparties\b|\bwitness|\barriv", re.I)
INTENT = re.compile(
    r"\bdeliberate(?:ly)?\b[^.]{0,60}\b(?:abstention|empty|null|configur|left|slot)"
    r"|\b(?:abstention|configuration|slot)\b[^.]{0,60}\bdeliberate"
    r"|picked null|declin\w* exactly one|looking like neglect|explain away|means to enable"
    r"|did not miss it|thought about it carefully|have not noticed Token-2022|\bmean to enable\b", re.I)
SECONDARY = re.compile(r"blocks? the \W*secondary", re.I)
# Exempt per SENTENCE, never per paragraph, and never a sentence that names an issuer. Two narrow
# cases: Kamino's code, where the decision is written in the source; and OUR OWN mints (the mirror,
# the testbed), where the reason is ours to state. Round 2 showed a bare keyword was a hiding place:
# "Kamino shows issuers deliberately chose null" and "... not ours; their issuer deliberately left
# the slot empty" both passed (Codex, 2026-09-30).
EXEMPT_WHAT = re.compile(r"Kamino'?s?\b[^.]{0,40}\b(?:refus|code|program|deposit|source|reserve|rule)"
                         r"|underwrit|constraints\.rs|klend|\blender\b|\bmirror\b|\btestbed\b|we control|our own"
                         r"|Confide's own", re.I)


def exempt(x):
    return bool(EXEMPT_WHAT.search(x)) and not ISSUER_NAMED.search(x)


def sentences(t):
    # A sentence can end inside bold or a quote: "... like NVDAx.** `x` deliberately ..." -- the
    # first split missed that and read two sentences as one.
    return [x for x in re.split(r"(?<=[.!?])(?:\*{1,2}|[\"')\]])*\s+", t) if x]


def claims(t):
    out = []
    ss = [x for x in sentences(t) if not exempt(x)]
    for x in ss:
        if NAMES_IT.search(x) and CAUSE_BECAUSE.search(x):
            out.append("CAUSE")
        if CAUSE_SHAPE.search(x) or VERDICT_STRONG.search(x) or (CAUSE_FIRST.search(x) and NAMES_IT.search(x)):
            out.append("CAUSE")
        # Near each other, not merely in one sentence: a table or a block of page code joins into one
        # "sentence" and an issuer name 300 characters from "chosen" is not a claim.
        for m in ISSUER_NAMED.finditer(x):
            w = x[max(0, m.start() - 60):m.end() + 60]
            if SEPARATELY.search(w) or CHOICE.search(w):
                out.append("INTENT")
                break
        if SLOT.search(x) and re.search(EMPTY, x) and VERDICT.search(x):
            out.append("CAUSE")
        if INDEPENDENCE.search(x) and ABOUT_ISSUERS.search(x):
            out.append("INDEPENDENCE")
        if INTENT.search(x):
            out.append("INTENT")
        if SECONDARY.search(x):
            out.append("SECONDARY")
    # A verdict in the sentence after the one naming the empty slot: "... left the slot empty. That
    # is not an oversight." Also "So it sits null." after a sentence about the key.
    for x, y in zip(ss, ss[1:]):
        if SLOT.search(x) and re.search(EMPTY, x + " " + y) and VERDICT.search(y):
            out.append("CAUSE")
        # "Shipped, configured, inert. Not because it is immature: because ..."
        if re.search(EMPTY, x) and NAMES_IT.search(x + " " + y) and re.match(r"(?:not\s+)?because\b", y, re.I):
            out.append("CAUSE")
    return out


# THE CHECK'S OWN REGRESSION FIXTURES. Every MUST_FLAG line is a sentence that was live in this
# repository on 2026-09-30, most of them after the first version of this check called the tree clean.
# Every MUST_PASS line is a true sentence a looser rule would have silenced. A rule change that lets
# one through fails the run here, before it can fail silently on the tree.
MUST_FLAG = [
    "Every one of them leaves the auditor key empty — because the only key on offer reads everyone's everything.",
    "That is why the live mints leave it null, and why filling it is only useful if something decides.",
    "One field then separates the two mints, and the reason that field stays null everywhere else is that the key cannot be scoped.",
    "Backed, Backpack and PreStocks each arrived there independently — and the auditor slot is empty.",
    "A regulated issuer arrives at this configuration, now with a third and fourth independent witness.",
    "And the same scan shows what they do adopt, which makes the abstention deliberate rather than inattentive.",
    "The only model has no correct setting, so the slot sits empty and the feature goes unused.",
    "Leave it null and no holder can prove anything. So it sits null, on every mint, at every issuer.",
    "No setting shows one balance to one regulator — so every issuer left it empty.",
    "The issuer left the auditor slot empty. That is not an oversight.",
    "Four issuers, two asset classes, one dead end. Nobody chose this — it is what the substrate does.",
    "Three independent issuers, one configuration.",
    "The empty slot blocks the secondary market, not this one.",
    "Shipped, configured, inert. Not because it is immature: because Token-2022 offers one model.",
    "The issuer left the auditor slot empty. That is not an oversight. It is the only available choice.",
    "Four issuers, two asset classes, one configuration. It is what the substrate forces.",
    "Leaving the auditor key null was the only available choice.",
    # round 2 -- live in the tree after round 1
    "Backed and Backpack left the key null — companies that mean to enable this.",
    "Four issuers, two asset classes, one dead end — a property of the substrate, not a choice any of them made.",
    "All 1,992 of them, across three issuers that have nothing to do with each other.",
    # round 2 -- constructed by Codex to evade round 1; covered because the shape generalises
    "Because one auditor sees every transfer, issuers keep the field unset.",
    "Backed, Backpack, and PreStocks made the same choice separately.",
    "Backed's mints are not ours; their issuer deliberately left the slot empty.",
    "Kamino shows issuers deliberately chose null.",
    "Kamino's code refuses it, and the issuers deliberately left the slot empty.",
    "On the testbed we control it is set; the issuer deliberately left theirs empty.",
    "Four issuers, two asset classes, one dead end — the substrate, not somebody's choice.",
    "Across five mints from three unrelated issuers, most accounts hold less than one share.",
]
MUST_PASS = [
    "Kamino's refusal is correct underwriting, not an oversight.",
    "It is null on every mint in the list — why is not measured, since null is also the default.",
    "Fills the auditor slot on a mint we control. The xStock mints are not ours to configure, and their slot is empty.",
    "It works today only while every mint in the list has the slot null.",
    "Whether an issuer would accept that is not known; nobody has been asked.",
    "The issuer decides who may hold a confidential balance.",
    "Retried, because the public devnet RPC fails in ways that do not stay local: a lookup that came back empty.",
    "| of those, holding a real balance rather than a seed | **13**, all Backed's xStocks | | available liquidity across them | **≈89,192 tokens**, plus ≈230 borrowed | | LTVs, chosen by whoever owns those markets |",
    "The issuer has to approve each account, because the mirror mint is configured like NVDAx.**   leaves   false on purpose, so a freshly configured account is inert.",
    "| independently verifiable | unknown |",
    "BOTH auditor slots empty, matching all 1,992 live mints.",
    "Token-2022 offers exactly one disclosure model, a single mint-wide auditor key.",
    "The offsets decode to values already known independently — the liquidity mint at 128.",
    "Token-2022 with no confidential-transfer extension at all, so there is nothing to leave empty.",
    "Money already committed, under a rule in Kamino's own code.",
]
fx = [("should flag", l) for l in MUST_FLAG if not claims(l)] + \
     [("should pass", l) for l in MUST_PASS if claims(l)]
if fx:
    for why, l in fx:
        print("      the check itself is broken — %s: %s" % (why, l[:80]))
    sys.exit(1)


# FROZEN: published or submitted, so the claim stays and the file must not move. Pinned by content,
# not by "still matches a pattern" -- a re-cut that changed the text would otherwise keep its
# exemption (Codex, 2026-09-30). If one of these moves, re-read it and re-pin.
frozen = {
    "docs/cwf-2026/x-post.txt":                  ("52303ff47ccc00e4", "posted; the .tmpl it came from is corrected"),
    "video/DELIVERED-20260922.md":               ("144770c310b02dae", "the record of a delivered cut"),
    "video/captions-20260922.srt":               ("06f5db0a7a32a7af", "the caption track of that cut"),
    "video/CWF-PRESENTATION.md":                 ("3629f0a2190a69a7", "recorded, published narration; re-recording is the founder's call"),
    "video/captions-20260923.srt":               ("b5a4a3c6ea0d626d", "the caption track uploaded with that narration"),
    "video/segments-presentation/LINES.md":      ("8417644637e94849", "recorded, published narration"),
    "video/segments-presentation/manifest.json": ("76afa0a5da4f6138", "recorded, published narration"),
    "video/voiceover.md":                        ("687f4e4e55aa7604", "narration of the published Stocklana cut"),
    "video/captions.srt":                        ("fbe229c6d5a88c5f", "the caption track of that cut"),
    "video/captions-20260920.srt":               ("6bed57707091ab55", "the caption track of the 09-20 cut"),
    "_submission/full.md":                       ("209a546f3d04c2dd", "Stocklana's submitted text; the edit window shut 2026-09-25"),
}
# The retraction itself has to name what it retracts, and it is a live document, so it is not pinned.
retraction = "docs/cwf-2026/THE-PINCER.md"
skip = re.compile(r"^docs/reviews/|^STATUS\.md$|^scripts/docs-consistency\.sh$")

# Same citation rule as THE POPULATION: a quoted span is a citation, not a claim, so a correction can
# print what it corrects. Not in JSON, where quotes are syntax. Codex noted a claim can hide in quotes;
# that is the price of letting corrections quote, and the pinned files above are where it matters.
QUOTED = re.compile(
    r'&ldquo;.{0,300}?&rdquo;'
    r'|`[^`]{0,300}?`'
    r'|["\u201c\u201d\u300c\u300d][^"\u201c\u201d\u300c\u300d]{0,300}?'
    r'["\u201c\u201d\u300c\u300d]', re.S)

files = subprocess.run(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
                       capture_output=True, text=True).stdout.split("\0")
bad = []
# Deleting a pinned file, or the retraction, must not pass as "nothing found" (Codex r2).
for f in list(frozen) + [retraction]:
    if not pathlib.Path(f).exists():
        bad.append("%s is gone — a pinned or retraction file cannot silently disappear" % f)
for f in filter(None, files):
    if skip.match(f):
        continue
    p = pathlib.Path(f)
    if p.suffix in (".png", ".jpg", ".jpeg", ".mp4", ".ico", ".pdf") or not p.exists():
        continue
    if f in frozen:
        h = hashlib.sha256(p.read_bytes()).hexdigest()[:16]
        if h != frozen[f][0]:
            bad.append("%s is pinned as frozen (%s) and has changed — re-read it, then re-pin" % (f, frozen[f][1]))
        continue
    try:
        lines = p.read_text(encoding="utf-8").splitlines()
    except (UnicodeDecodeError, OSError):
        continue
    # PARAGRAPHS, not lines: narration wraps a clause across two lines. A caption track splits one
    # sentence across cues, so its text is read as one stream with cue numbers and timecodes dropped.
    if p.suffix == ".srt":
        lines = [" ".join(l for l in lines if l.strip() and not re.match(r"^\d+$|^\d\d:\d\d", l.strip()))]
    paras, cur, start = [], [], 1
    for i, l in enumerate(lines + [""], 1):
        if l.strip() in ("", ">"):
            if cur:
                paras.append((start, " ".join(cur)))
            cur = []
            continue
        if not cur:
            start = i
        cur.append(re.sub(r"^\s*(?:>\s*|#+\s*|//+!?\s*|///?\s*|\*\s+|-\s+)", "", l).strip())
    hits = []
    for n, text in paras:
        t = QUOTED.sub(" ", text) if p.suffix != ".json" else text
        c = claims(t)
        if c:
            hits.append((n, c[0], t))
    if f == retraction:
        if not hits:
            bad.append("%s no longer names what it retracts — was the retraction removed?" % f)
        continue
    for n, kind, t in hits:
        bad.append("%s:%d %s: %s" % (f, n, kind, t[:80]))
for b in bad[:15]:
    print("      " + b)
if len(bad) > 15:
    print("      ... and %d more" % (len(bad) - 15))
sys.exit(1 if bad else 0)
PY

echo
echo "  THE MARKET TOTALS — prose against the file that computes them"
python3 - <<'PY' && ok "every quoted \$m figure matches web/capacity.json" || bad "a quoted \$m figure has drifted from web/capacity.json — ./scripts/capacity.sh, then fix the prose"
import json, re, sys, pathlib
cap = json.load(open("web/capacity.json"))
want = {"%.1f" % (cap["held_usd"] / 1e6), "%.1f" % (cap["authorised_capacity_usd"] / 1e6)}
# Files that speak in the present tense about the market. CHECKIN-1.md and the reviews describe a
# dated recording and a dated review, so they are allowed to hold the number that was true then.
# POST.md, STORY.md and TESTBED.md were outside this list while all three quoted the pair. The
# account scan had the same hole on the same day, found the same way: grep the repository for the
# figure, then compare that against what the check reads. A file list is a claim about coverage
# and nothing was checking it.
files = ["README.md", "docs/27-DAYS.md", "docs/cwf-2026/THE-PINCER.md",
         "docs/cwf-2026/FOUNDER-MARKET-FIT.md", "docs/cwf-2026/GTM.md", "_submission/full.md",
         "docs/cwf-2026/POST.md", "docs/cwf-2026/STORY.md", "docs/TESTBED.md",
         "_submission/cwf-form.md"]
files += [str(p) for p in pathlib.Path("docs/packets").glob("*.md")]
bad = []
for f in files:
    for line in pathlib.Path(f).read_text(encoding="utf-8").splitlines():
      # A line recording a MOVEMENT between two readings is history, not a current claim, and its
      # earlier figure is supposed to disagree. A blanket substitution rewrote one of these into a
      # sentence that was simply false — "$21.1 m → $23.2 m in three days" — so the exemption is
      # narrow: the arrow has to be there, which a current claim never has.
      if "\u2192" in line:
          continue
      # A figure written without its decimal -- "$22 m" -- was invisible to this check and sat
      # stale in POST.md for days. Both forms are read now; the decimal-less one is reported
      # whatever its value, because there is no reading of capacity.json it can be right about.
      for n in re.findall(r"\$(\d{2})\s?m\b", line):
          bad.append("%s says $%s m without a decimal; write it as %s so it can be checked"
                     % (f, n, " or ".join(sorted(want))))
      for n in re.findall(r"\$(\d{2}\.\d)\s?m\b", line):
        if n not in want:
            bad.append("%s says $%sm; capacity.json says %s" % (f, n, " / ".join(sorted(want))))
for b in bad[:8]:
    print("      " + b)
sys.exit(1 if bad else 0)
PY

echo
echo "  THE BASELINE — REACH.md against the traffic snapshot it describes"
python3 - <<'PY2' && ok "REACH.md's two unique-visitor figures match web/reach.json" || bad "REACH.md quotes a visitor figure web/reach.json does not hold — ./scripts/reach.sh, then fix the prose"
import json, pathlib, re, sys
try:
    d = json.load(open("web/reach.json"))
except FileNotFoundError:
    print("      web/reach.json missing — run ./scripts/reach.sh"); sys.exit(1)
txt = pathlib.Path("docs/cwf-2026/REACH.md").read_text(encoding="utf-8")
m = re.search(r"it gives (\d+) where GitHub's own figure for the same fourteen days is (\d+)", txt)
if not m:
    print("      REACH.md no longer states the pair this check reads"); sys.exit(1)
summed = sum(v.get("uniques", 0) for v in d.get("days", {}).values())
windows = d.get("windows") or []
if not windows:
    print("      web/reach.json has no `windows` entry to compare against"); sys.exit(1)
dedup = windows[0]["view_uniques"]
bad = []
if int(m.group(1)) != summed:
    bad.append("REACH.md says summed uniques %s; reach.json sums to %d" % (m.group(1), summed))
if int(m.group(2)) != dedup:
    bad.append("REACH.md says deduplicated %s; the baseline window holds %d" % (m.group(2), dedup))
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PY2

echo
echo "  THE SUBMITTED FIELDS — the files against what the founder said they pasted"
# The one artifact nothing here can read is a form. "1,869 tokenized stocks" sat in the Stocklana
# short description for days because it had been typed once and no check could see it. This does
# not check the form either. It checks whether the FILE moved after the founder said they pasted
# it, which is the same question asked from the side this repository can answer.
python3 - <<'PYP' && ok "no submitted field has drifted since it was pasted" || bad "a file has changed since it was pasted — repaste it, then ./scripts/pasted.sh <field>"
import hashlib, json, os, sys
try:
    d = json.load(open("_submission/pasted.json"))
except FileNotFoundError:
    print("      _submission/pasted.json is missing — ./scripts/pasted.sh <field>"); sys.exit(1)
bad = []
for k in sorted(d):
    f = d[k]["file"]
    if not os.path.exists(f):
        bad.append("%s: %s is gone" % (k, f)); continue
    now = hashlib.sha256(open(f, "rb").read()).hexdigest()
    if now != d[k]["sha256"]:
        bad.append("%s: %s changed since it was pasted %s" % (k, f, d[k]["pasted_utc"][:16]))
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PYP

echo
echo "  THE SCRIPTED CUTS — each rendered file against the script it was cut from"
python3 - <<'PYK' && ok "every scripted cut matches its script, and the check-in fits its minute" || bad "a cut is out of date or over its limit — re-render it"
import os, re, subprocess, sys, pathlib
# Both scripted cuts, not just the one that had a deadline this morning. The check-in got this
# check the day it was submitted; the presentation had none, and its script was edited hours after
# the file was last rendered without anything noticing.
# DERIVED. This was a list of two, so CHECKIN-2.md would have been written and rendered with
# nothing comparing them. A check-in script is `video/CHECKIN-<n>.md` and its cut is
# `video/checkin-<n>.mp4`; that pairing is the rule, and the glob applies it to whatever exists.
import glob
ins = sorted(glob.glob("video/CHECKIN-*.md"),
             key=lambda s: int(re.search(r"(\d+)", s).group(1)))
CUTS = [(d, "video/checkin-%s.mp4" % re.search(r"(\d+)", d).group(1), 60) for d in ins]
CUTS.append(("video/CWF-PRESENTATION.md", "video/presentation.mp4", None))
# The NEWEST check-in may legitimately have no cut yet -- the script is written days before the
# recording window opens. Any earlier one missing its cut is a real failure: it means a file that
# was submitted has been deleted. So the tolerance is for exactly one doc, and it is named.
pending = ins[-1] if ins else None
bad = []
for doc, mp4, cap in CUTS:
    if not os.path.exists(mp4):
        if doc == pending:
            print("      %s has no cut yet — record it before the window closes" % doc)
        else:
            bad.append("%s is missing" % mp4)
        continue
    md = pathlib.Path(doc).read_text(encoding="utf-8")
    m = re.search(r"\| \| \| \*\*(\d+) s\*\* \| \*\*(\d+)\*\* \|", md)
    if not m:
        bad.append("%s has no totals row — python3 video/pace.py --write" % doc); continue
    want = int(m.group(1))
    # ffprobe the FILE. A recorder prints its own figure and one of them ran a second short of the
    # encoded result; trusting the report over the artifact is the mistake this repository is
    # written against.
    try:
        got = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                    "-of", "csv=p=0", mp4], capture_output=True, text=True,
                                   check=True).stdout.strip())
    except Exception as e:
        bad.append("could not probe %s: %s" % (mp4, e)); continue
    if abs(got - want) > 2:
        bad.append("%s is %.1f s; %s says %d s — re-render after editing the script" % (mp4, got, doc, want))
    if cap and got > cap:
        bad.append("%s is %.1f s, over the %d the form asks for" % (mp4, got, cap))
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PYK

echo
echo "  THE EXTENSION INVENTORY — the 7-of-8 argument against web/slots.json"
# WHY-THE-SLOT-IS-EMPTY.md turns on a count: four control extensions on 1,992 of 1,992, and the one
# privacy extension inert beside them. That is the strongest thing this repository knows about why
# the slot is empty, and it was about to be a table somebody typed. slot-roles.sh prints it from the
# scan; this checks the document still carries exactly what it prints.
./scripts/slot-roles.sh --check docs/cwf-2026/WHY-THE-SLOT-IS-EMPTY.md \
  && ok "the extension table is what ./scripts/slot-roles.sh prints from web/slots.json" \
  || bad "the extension table has drifted from the scan — ./scripts/slot-roles.sh"

echo
echo "  CONFIGURED IS NOT APPROVED — the headline moved on 2026-09-22"
# For a day the number that mattered was "0 configured". Two NVDAx accounts then configured one and
# neither was approved, so the claim moved to the next column. The danger is a surface that took the
# NEW account count from a sweep and kept the OLD zero -- it reads as current and is false, and
# POST.md and STORY.md were both in exactly that state. Dated records are exempt by name: they say
# what was true when they were written, which is what a record is for.
python3 - <<'PYC' && ok "no surface still says zero accounts are CONFIGURED" || bad "a surface says zero configured; web/usage.json says otherwise"
import json, re, sys, pathlib, glob
u = json.load(open("web/usage.json"))
conf, appr = u["total_confidential_accounts"], u["total_approved_accounts"]
FROZEN = ("docs/reviews/", "x-post.txt", "WHERE-THE-POSITIONS-ARE", "WHAT-THE-WEEK-CHANGED",
          "DELIVERED-", "CHECKIN-1.md", "segments-checkin/")
# ONE PHRASING IS NOT THE CLAIM. This asked for the literal words "configured for confidential"
# near a zero, and on 2026-09-23 README.md said the same thing as "**0** | of them are confidential.
# **Nobody has ever opened one.**" -- in a headline table, twelve lines above a pasted scan reading
# "2 configured", in the file a judge opens first. The check reported a tick. web/index.html said
# it twice more, POST.md once, short-alternatives.txt once. Five surfaces, four wordings, one
# pattern that matched none of them.
#
# So the shape is caught instead of the words: a sentence that puts a nothing-word beside a
# confidential account and does NOT mention approval is making the old claim, whatever it calls it.
# "Two asked and none was approved" is the true one and always says approv-.
# The first broadening went the other way and matched any sentence with a zero and the word
# confidential in it -- six false hits, including "$0 is reachable" about Kamino. So: the claim
# shapes, named, each one testable.
PATS = [re.compile(p, re.I) for p in (
    r"\b(?:zero|0|none)\b[^.\n]{0,40}\b(?:are|is)\s+confidential",
    r"\b(?:zero|0|none)\b[^.\n]{0,30}configured for confidential",
    r"\b(?:zero|0|none)\b[^.\n]{0,30}confidential accounts?\b",
    r"\b(?:nobody|no one|not one|no account)\b[^.\n]{0,40}\b(?:ever\s+)?(?:opened|configured)\b",
)]
# AND THE CHECK IS CHECKED. These are the five wordings that were live in this repository on
# 2026-09-23, when the pattern of the day matched exactly one of them. Any edit to PATS that stops
# catching one of these fails here rather than in six months, silently, on a surface a judge reads.
SPECIMENS = [
    "| **0** | of them are confidential. **Nobody has ever opened one.**",
    "Of 469,477 live accounts, zero are confidential.",
    "of them are confidential. <b>Nobody has ever opened one.</b>",
    "0 are confidential.** Nobody has ever opened one",
    "469,477 token accounts, 0 configured for confidential transfers",
]
missed = [s for s in SPECIMENS if not any(p.search(s) for p in PATS)]
if missed:
    print("      the pattern no longer catches a claim it was written for:")
    for s in missed:
        print("        " + s)
    sys.exit(1)
bad = []
# Text only: _submission/*.* also matches graphic.jpg, and reading it as UTF-8 is a crash rather
# than a finding.
for f in sorted(set(glob.glob("_submission/*.md") + glob.glob("_submission/*.txt")
                    + glob.glob("docs/**/*.md", recursive=True)
                    + glob.glob("web/*.html") + ["README.md", "STATUS.md"])):
    if any(k in f for k in FROZEN):
        continue
    text = pathlib.Path(f).read_text(encoding="utf-8")
    for pat in PATS:
        for m in pat.finditer(text):
            s = m.group(0)
            if conf == 0 or re.search(r"approv", s, re.I):
                continue
            # A line recording its own correction is not making the claim. STATUS.md keeps the old
            # wording beside the new one -- 'zero are confidential' -> 'two have configured one' --
            # which is what a record is for, and the arrow is how this repository writes them.
            line = text[text.rfind("\n", 0, m.start()) + 1:text.find("\n", m.end())]
            if "\u2192" in line:
                continue
            bad.append("%s: %r — %d have configured one, so say what is 0"
                       % (f, " ".join(s.split())[:72], conf))
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PYC

echo
echo "  THE GITHUB ABOUT — the one surface that is not a file in here"
# It is the most-read sentence about this project and it lived outside every check, because no
# check reads GitHub. On 2026-09-23 it still said "Of 329,536 live accounts, zero are confidential":
# an account count from 17 September, two measurements stale, beside a claim false since the 22nd.
# Skipped rather than failed when gh is missing or the network is not there -- this file has to
# pass on a plane.
if command -v gh >/dev/null 2>&1 && LIVE=$(gh repo view "${REPO:-psyto/confide}" --json description -q .description 2>/dev/null); then
  WANT=$(./scripts/github-about.sh)
  if [ "$LIVE" = "$WANT" ]; then
    ok "the repository's About line is what the measurements say"
  else
    echo "      live: $LIVE"
    echo "      want: $WANT"
    bad "the GitHub About has drifted — ./scripts/github-about.sh --apply"
  fi
else
  echo "      ${dim}gh is unavailable or offline — not checked${off}"
fi

echo
echo "  THE UNASKED QUESTION — a measurement is not a prediction"
# 2026-09-22, and it came from outside this repository: a reader replied to the post that "no issuer
# will approve one is a bit early if you haven't asked any issuers yet." They were right. What is
# measured is that autoApproveNewAccounts is false on 1,992 of 1,992 and that none of 465,520 live
# accounts is confidential -- that nobody HAS been through the door. Whether an issuer WOULD refuse
# is unknown, because nobody has asked, and saying otherwise hands a judge a claim with no command
# under it. full.md already said "a conversation nobody has had"; four other surfaces did not.
python3 - <<'PYU' && ok "no submission predicts what an issuer would do" || bad "a submission claims an issuer would refuse — nobody has asked one"
import re, sys, pathlib
BAD = [r"no issuer will approve", r"issuers? will (?:never )?refuse",
       r"no issuer would approve", r"issuers? would (?:never )?approve"]
bad = []
for f in ["_submission/full.md", "_submission/short.txt", "_submission/cwf-form.md",
          "_submission/youtube.md", "_submission/youtube-checkin1.md", "README.md",
          "video/CWF-PRESENTATION.md", "video/CHECKIN-2.md", "web/index.html"]:
    q = pathlib.Path(f)
    if not q.exists():
        continue
    body = q.read_text(encoding="utf-8")
    for pat in BAD:
        for m in re.finditer(pat, body, re.I):
            # QUOTING THE MISTAKE IS NOT MAKING IT. CHECKIN-2.md names the phrase in order to say it
            # was a prediction and not a measurement, which is the point of the scene. A line that
            # wraps it in quotes or italics is explaining it; a bare one is claiming it.
            a = body.rfind("\n", 0, m.start()) + 1
            b = body.find("\n", m.end())
            line = body[a : b if b != -1 else len(body)]
            q2 = m.group(0)
            quoted = any(mark + v in line
                         for mark in ('"', "\u201c", "*", "_")
                         for v in (q2, q2.capitalize(), q2[0].upper() + q2[1:]))
            if quoted:
                continue
            bad.append("%s says \"%s\"" % (f, q2))
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PYU

echo
echo "  THE SEC ORDER — the pitch's spine against the pinned primary source"
# full.md now OPENS on this order, so every figure in it has to come from the file that was pinned
# from the SEC's own release — docs/SEC-EXEMPTION.md, which has already been corrected three times.
# A pitch whose first paragraph is wrong about a published rule is disposed of in one line.
python3 - <<'PYS' && ok "every SEC figure in the submissions matches docs/SEC-EXEMPTION.md" || bad "a submission quotes the SEC order in a way the pinned source does not support"
import re, sys, pathlib
src = pathlib.Path("docs/SEC-EXEMPTION.md").read_text(encoding="utf-8")
# Each fact, and the phrase in the pinned file that has to still carry it.
FACTS = [
    ("2026-09-17",  "the date the order issued"),
    ("10 minutes",  "the publication deadline"),
    ("0.25%",       "the Tier 1 volume cap"),
    ("2031-09-17",  "the expiry, which is the term"),
]
missing = [w for f, w in FACTS if f not in src for w in [f]]
bad = [("docs/SEC-EXEMPTION.md no longer states %s — the pinned source moved under the pitch" % m)
       for m in missing]

# And nothing may claim the exemption covers Confide, or that it is beyond regulation. The pinned
# file rules on this explicitly: say "not a venue", never "outside the SEC's purview".
FORBIDDEN = ["outside the SEC's purview", "outside the SEC's jurisdiction",
             "outside SEC jurisdiction", "not regulated by the SEC"]
for f in ["_submission/full.md", "_submission/short.txt", "_submission/cwf-form.md",
          "docs/cwf-2026/x-post.txt", "README.md", "video/CWF-PRESENTATION.md"]:
    q = pathlib.Path(f)
    if not q.exists():
        continue
    body = q.read_text(encoding="utf-8")
    for phrase in FORBIDDEN:
        if phrase.lower() in body.lower():
            bad.append("%s says \"%s\" — docs/SEC-EXEMPTION.md rules that out" % (f, phrase))
    # A quoted cap or deadline must be the one the order sets.
    for m in re.finditer(r"(\d+(?:\.\d+)?)%\s*of\s*average daily", body):
        if m.group(1) != "0.25":
            bad.append("%s caps Tier 1 at %s%% of ADV; the order says 0.25%%" % (f, m.group(1)))
    for m in re.finditer(r"within\s+(\w+)\s+minutes", body):
        if m.group(1).lower() not in ("ten", "10"):
            bad.append("%s says fills publish within %s minutes; the order says ten" % (f, m.group(1)))
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PYS

echo
echo "  THE DEVNET TRADES — prose against web/swaps.json"
# full.md said "three devnet trades" and the site's og:description said "Three real devnet trades"
# after a fourth was pinned. Two hand-maintained copies of a number the file next to them computes,
# and the page itself was right the whole time because it renders from swaps.json and counts nothing.
python3 - <<'PYT' && ok "every quoted devnet-trade count matches web/swaps.json" || bad "a quoted trade count disagrees with web/swaps.json"
import json, re, sys, pathlib
n = len(json.load(open("web/swaps.json"))["swaps"])
WORDS = {"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10}
pat = re.compile(r"(\d+|one|two|three|four|five|six|seven|eight|nine|ten)\s+(?:real\s+)?devnet trades", re.I)
bad = []
for f in ["_submission/full.md", "_submission/short.txt", "web/index.html", "README.md",
          "docs/cwf-2026/x-post.txt", "_submission/cwf-form.md"]:
    q = pathlib.Path(f)
    if not q.exists():
        continue
    for m in pat.finditer(q.read_text(encoding="utf-8")):
        g = m.group(1).lower()
        got = int(g) if g.isdigit() else WORDS[g]
        if got != n:
            bad.append("%s says %s devnet trades; web/swaps.json pins %d" % (f, m.group(1), n))
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PYT

echo
echo "  THE SPOKEN LENGTH — STATUS.md's script figures against the scripts"
# STATUS.md said CHECKIN-1.md was "64秒・138語" for a day after the script was cut to 58 s and 125
# words. Nothing looked: pace.py checks the table inside each script, and no check read the prose
# that quotes it elsewhere. Exactly the shape this repository keeps repeating -- a number typed
# once into a second place.
python3 - <<'PYL' && ok "every spoken length quoted in prose matches the script it describes" || bad "a quoted script length is stale — the figure is in the script's own totals row"
import re, sys, pathlib, glob

# Every totals row, derived: `| | | **58 s** | **125** | | |`
want = {}
for doc in glob.glob("video/CHECKIN-*.md") + ["video/CWF-PRESENTATION.md"]:
    m = re.search(r"\| \| \| \*\*(\d+) s\*\* \| \*\*(\d+)\*\* \|", pathlib.Path(doc).read_text(encoding="utf-8"))
    if m:
        want[doc] = (int(m.group(1)), int(m.group(2)))

bad = []
for f in ["STATUS.md", "video/README.md", "docs/27-DAYS.md"]:
    p = pathlib.Path(f)
    if not p.exists():
        continue
    for line in p.read_text(encoding="utf-8").splitlines():
        for doc, (s, w) in want.items():
            if doc not in line:
                continue
            # Both the Japanese form (58秒・125語) and the English one (58 s, 125 words).
            for gs, gw in re.findall(r"(\d+)\s*(?:秒|s)\s*[・,]\s*(\d+)\s*(?:語|words)", line):
                if (int(gs), int(gw)) != (s, w):
                    bad.append("%s quotes %s as %s s / %s words; the script is %d s / %d words"
                               % (f, doc, gs, gw, s, w))
for b in bad:
    print("      " + b)
sys.exit(1 if bad else 0)
PYL

echo
echo "  THE CWF FORM — every field against the limit the form states"
./scripts/cwf-form.sh >/dev/null 2>&1 \
  && ok "every CWF form field fits and quotes the counts the chain reports" \
  || bad "a CWF form field is over its limit or quotes a stale count — ./scripts/cwf-form.sh"

echo
echo "  THE DEMO SCRIPT'S TIMES — each scene's range against the cut it narrates"
# video/DEMO.md names where each scene sits in demo-ops.mp4. Those ranges were typed once and went
# stale at the first re-recording; video/demo-times.py derives them from the cut's own manifest.
python3 video/demo-times.py --check >/dev/null 2>&1 \
  && ok "every scene's time range in video/DEMO.md matches demo-ops.manifest.json" \
  || bad "video/DEMO.md scene times differ from the cut — python3 video/demo-times.py"

echo
echo "  THE PRIVATE ENDPOINT — it may exist as an environment variable and nowhere else"
# web/slots.json recorded the founder's Alchemy URL on this script's first run, key and all, into a
# file that is committed AND published to the site. It was caught by reading the file. Nothing was
# stopping the next one, and the endpoint is pasted into a terminal every time the chain is
# rescanned — so the next one was a matter of time rather than of care.
leak=$(grep -rIl -E 'g\.alchemy\.com|helius-rpc\.com/\?api-key|quiknode\.pro/[0-9a-f]{8}' . 2>/dev/null \
       | grep -v '^\./\.git/' | grep -v '^\./scripts/docs-consistency\.sh$' || true)
[ -z "$leak" ] && ok "no keyed RPC endpoint appears in any file" \
               || bad "a keyed RPC endpoint is in the tree: $(printf '%s ' $leak)"

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
