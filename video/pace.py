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
    """Each scene heading is `### N — title`, optionally followed by `· +P s silence`.

    Seconds and words are NOT in the heading: they are derived from the words below it. A heading
    that carried them would be one more number maintained by hand, which is the thing this file
    exists to stop.

    Silence is declared rather than inferred. A scene whose whole point is the gap before its last
    line -- "the chain says it holds nothing" ... "it holds a hundred and seventy-three thousand"
    -- is not a pace problem, and a formula that only divides words by time will always price that
    scene as too short. The pause is part of the picture, so it is part of the duration and not
    part of the pace.
    """
    out = []
    for m in re.finditer(r"^### (\d+) — ([^·\n]+?)\s*(?:·[^\n]*)?$\n\n((?:^> ?.*\n)+)", text, re.M):
        head = m.group(0).split("\n")[0]
        pause = re.search(r"\+\s*([\d.]+)\s*s silence", head)
        body = re.sub(r"^> ?", "", m.group(3), flags=re.M)
        out.append((int(m.group(1)), m.group(2), len(body.split()), float(pause.group(1)) if pause else 0.0))
    return out

def build(sc):
    rows, total_s, total_w = [], 0.0, 0
    for n, title, words, pause in sc:
        secs = round(words / WPM * 60 + TAIL + pause)
        pace = round(words / (secs - TAIL - pause) * 60)
        held = ("%d + %g" % (secs - pause, pause)) if pause else str(secs)
        rows.append("| %d | %s | %s | %d | %d | %s |" % (n, title, held, words, pace, SHOWS[n]))
        total_s += secs; total_w += words
    rows.append("| | | **%d s** | **%d** | | |" % (total_s, total_w))
    return rows, total_s, total_w

SHOWS = {
 1: "a position climbing across a quarter, watched",
 2: "`spl-token balance` says 0; the confidential balance says 173,000",
 3: "the mint scan finishing, the auditor slot empty",
 4: "the 19 Kamino reserves, live",
 5: "`constraints.rs` on screen",
 6: "the proofs accepted by Solana's ZK program; the seizure on devnet",
 7: "the three missing pieces, as text",
 8: "`./scripts/packet.sh SPCX.US`, then the page URL",
}

text = io.open(DOC, encoding="utf-8").read()
sc = scenes(text)
if len(sc) != len(SHOWS):
    print("  found %d scenes, expected %d — the heading format changed" % (len(sc), len(SHOWS)))
    raise SystemExit(1)
rows, total_s, total_w = build(sc)

head = "| | scene | seconds (+ silence) | words | pace | what it shows |\n|---|---|---|---|---|---|\n"
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
