#!/usr/bin/env python3
"""Rewrite the presentation's timing table from the script it sits above.

The table drifted from the words within minutes of both being written, which is the failure this
repository keeps having: a number typed once and then maintained by hand. Run this after editing
any narration block.

    python3 video/pace.py           # check, exit 1 if the table disagrees
    python3 video/pace.py --write   # rewrite the table from the words
"""
import io, re, sys

WPM = 137          # the pace the earlier recording actually held
TAIL = 0.6         # a line should finish before the picture does
DOC = "video/CWF-PRESENTATION.md"

def scenes(text):
    out = []
    for m in re.finditer(r"^### (\d+) — (.+?) · .*?$\n\n((?:^> .*\n)+)", text, re.M):
        words = len(re.sub(r"^> ", "", m.group(3), flags=re.M).split())
        out.append((int(m.group(1)), m.group(2), words))
    return out

def build(sc):
    rows, total_s, total_w = [], 0.0, 0
    for n, title, words in sc:
        secs = round(words / WPM * 60 + TAIL)
        pace = round(words / (secs - TAIL) * 60)
        rows.append("| %d | %s | %d | %d | %d | %s |" % (n, title, secs, words, pace, SHOWS[n]))
        total_s += secs; total_w += words
    rows.append("| | | **%d s** | **%d** | | |" % (total_s, total_w))
    return rows, total_s, total_w

SHOWS = {
 1: "the 1,869 count, live from mainnet",
 2: "the 19 Kamino reserves, LTVs and balances",
 3: "`constraints.rs` on screen, the four conditions",
 4: "the floor proof accepted by Solana's ZK program; the seizure on devnet",
 5: "the three missing pieces, as text",
 6: "`./scripts/packet.sh SPCX.US` and its output",
 7: "traction, stated",
}

text = io.open(DOC, encoding="utf-8").read()
sc = scenes(text)
if len(sc) != len(SHOWS):
    print("  found %d scenes, expected %d — the heading format changed" % (len(sc), len(SHOWS)))
    raise SystemExit(1)
rows, total_s, total_w = build(sc)

head = "| | scene | seconds | words | pace | what it shows |\n|---|---|---|---|---|---|\n"
table = head + "\n".join(rows)
old = re.search(r"\| \| scene \| seconds.*?\n\| \| \| \*\*\d+ s\*\* \| \*\*\d+\*\* \| \| \|", text, re.S)
if not old:
    print("  the table is not where this expects it"); raise SystemExit(1)

if "--write" in sys.argv:
    io.open(DOC, "w", encoding="utf-8").write(text[:old.start()] + table + text[old.end():])
    print("  table rewritten — %d s, %d words, %d scenes" % (total_s, total_w, len(sc)))
elif old.group(0).strip() != table.strip():
    print("  the table disagrees with the script. Run: python3 video/pace.py --write")
    raise SystemExit(1)
else:
    print("  table matches the script — %d s, %d words" % (total_s, total_w))
