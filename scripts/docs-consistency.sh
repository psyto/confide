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
PUB="${PUB:-video/Confide_Stocklana_20260920.mp4}"

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
t = re.sub(r'\\s+', ' ', t)
# The lines a sound-off viewer cannot lose. Written for the 09-20 cut: the one that was here
# guarded a seizure line, and that scene does not exist in this film — it kept passing on the old
# file and failed the moment the check was pointed at the one that is published.
missing = [n for n, p in [
    ('the moment', r'173,000\\s+shares'),
    ('what Confide is', r'That\\s+is\\s+the\\s+product'),
    ('the count', r'accounts\\s+across\\s+Apple'),
    ('the empty middle', r'stands\\s+between\\s+nobody'),
] if not re.search(p, t, re.I)]
print(', '.join(missing))
sys.exit(1 if missing else 0)
" > /tmp/.dc.missing \
    && ok "every line a sound-off viewer needs is in the captions" \
    || bad "missing from the captions: $(cat /tmp/.dc.missing) — sound-off viewers lose it"

  # Silence is a property of the audio. Reading caption gaps is how this was got wrong.
  sil=$("$FFMPEG" -nostdin -hide_banner -i "$PUB" -af silencedetect=noise=-40dB:d=1 -f null - 2>&1 \
        | grep -c silence_start || true)
  [ "$sil" -eq 0 ] && ok "no silent second anywhere in the audio" \
                   || bad "$sil silent stretches — a line may not have been laid in"
else
  bad "$PUB is missing"
fi

# The caption file for the CURRENT video, not whichever one was published first. This guarded
# video/captions.srt — the 09-15 cut's track — and went on passing after the upload changed.
CAPS="${CAPS:-video/captions-20260920.srt}"
if [ -f "$CAPS" ]; then
  for w in Salana Nvidia "stable coin" "Everyone leaves"; do
    grep -q "$w" "$CAPS" && bad "$CAPS still says $w"
  done
  ./scripts/fix-captions.sh "$PUB" 2>/dev/null | diff -q - "$CAPS" >/dev/null \
    && ok "$CAPS is what fix-captions.sh produces from the published file" \
    || bad "captions.srt has drifted from its generator"
fi

echo
echo "  THE CUT — the manifest against the clips on disk"
# Every cut, not just the first one. This checked video/segments alone while two more cuts were
# added next to it, so the check-in and the presentation were cut, split and committed with nothing
# measuring them at all.
for seg in video/segments video/segments-checkin video/segments-presentation; do
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
# The submission drifted to "69 tests, 19 over the seizure program" while it was live, because
# only README was being checked. It is a separate surface and gets its own line.
grep -q "^$((t + z)) tests, $z over the seizure program\." _submission/full.md \
  && ok "_submission/full.md says $((t + z)) tests, $z over the seizure program, and that is what runs" \
  || bad "$((t + z)) tests run, $z of them over the seizure program; _submission/full.md says something else"
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
# And the chapters against the file they describe. The published Stocklana cut carried chapter
# times from a different edit — a 2:07 runtime quoted for a 1:52 file — because they were copied
# from the recorder's plan. This reads them off the delivery.
if [ -f video/Confide_Stocklana_20260920.mp4 ]; then
  ./scripts/video-chapters.sh video/Confide_Stocklana_20260920.mp4 2>/dev/null \
  | diff -q - <(python3 -c "
import re
s = open('_submission/youtube.md', encoding='utf-8').read()
d = max(re.findall(r'\`\`\`\n(.*?)\n\`\`\`', s, re.S), key=len)
print('\n'.join(re.findall(r'(?m)^\d+:\d\d .*\$', d)))") >/dev/null \
    && ok "the YouTube chapters are the ones in the delivered file" \
    || bad "the YouTube chapters do not match the file — ./scripts/video-chapters.sh"
fi

./scripts/youtube-paste.sh 2>/dev/null | diff -q - _submission/youtube-paste.txt >/dev/null \
  && ok "youtube-paste.txt is what its generator produces" \
  || bad "youtube-paste.txt has drifted from youtube.md"

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
# The short description is a SUBMITTED field, and the one it replaced carried a mint count from
# before a third issuer existed. Prose checks elsewhere skip it because it is not markdown.
python3 - <<'PY' && ok "_submission/short.txt matches the mint count and names the wedge" || bad "_submission/short.txt has drifted — it is a submitted field"
import json, re, sys
t = open("_submission/short.txt", encoding="utf-8").read()
want = str(len(json.load(open("web/mints.json"))))
bad = []
for m in re.finditer(r"\b([1-9][\d,]{3,})\b", t):
    if m.group(1).replace(",", "") not in (want, str(json.load(open("web/usage.json"))["total_accounts"])):
        bad.append("%s is neither the mint count nor the account count" % m.group(1))
if not re.search(r"stock-to-stablecoin|stablecoin swap", t, re.I):
    bad.append("it does not name the wedge")
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
want = {"{:,}".format(total), str(total)}
files = ["STATUS.md", "docs/cwf-2026/STORY.md", "docs/cwf-2026/COMPOSITION.md"]
bad = []
for f in files:
    t = pathlib.Path(f).read_text(encoding="utf-8")
    # Only figures in an account-count context: a bare six-digit number elsewhere is a balance or
    # a compute figure, and flagging those would teach the check to cry wolf the way the mint
    # count already had to learn not to.
    for m in re.finditer(r"([1-9][\d,]{4,}) (?:token )?accounts", t):
        if m.group(1) not in want:
            bad.append(f"{f}: {m.group(1)} accounts, web/usage.json says {total}")
    # And the headline: the whole claim is that the number of confidential accounts is this one.
    for m in re.finditer(r"(\d+) (?:of them )?configured for confidential", t):
        if int(m.group(1)) != conf:
            bad.append(f"{f}: says {m.group(1)} confidential, web/usage.json says {conf}")
if bad:
    print("\n".join("      " + b for b in bad)); sys.exit(1)
PY

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
    found = {m if isinstance(m, str) else m[0] for p2 in pats for m in re.findall(p2, t)}
    for n in found:
        if n not in want:
            bad.append("%s says %s; web/mints.json holds %s" % (f, n, "{:,}".format(len(mints))))
for b in sorted(set(bad))[:8]:
    print("      " + b)
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
files = ["README.md", "docs/27-DAYS.md", "docs/cwf-2026/THE-PINCER.md",
         "docs/cwf-2026/FOUNDER-MARKET-FIT.md", "docs/cwf-2026/GTM.md", "_submission/full.md"]
files += [str(p) for p in pathlib.Path("docs/packets").glob("*.md")]
bad = []
for f in files:
    for n in re.findall(r"\$(\d{2}\.\d)\s?m\b", pathlib.Path(f).read_text(encoding="utf-8")):
        if n not in want:
            bad.append("%s says $%sm; capacity.json says %s" % (f, n, " / ".join(sorted(want))))
for b in bad[:8]:
    print("      " + b)
sys.exit(1 if bad else 0)
PY

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
