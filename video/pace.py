#!/usr/bin/env python3
"""Rewrite the presentation's timing table from the script it sits above.

The table drifted from the words within minutes of both being written, which is the failure this
repository keeps having: a number typed once and then maintained by hand. Run this after editing
any narration block.

    python3 video/pace.py                       # check every scripted file
    python3 video/pace.py --write               # rewrite their tables from the words
    python3 video/pace.py video/CHECKIN-1.md    # just one
"""
import io, re, sys

WPM = 137          # the pace the earlier recording actually held
TAIL = 0.6         # a line should finish before the picture does
DOCS = ["video/CWF-PRESENTATION.md", "video/CHECKIN-1.md"]

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

SHOWS_BY_DOC = {
 "video/CWF-PRESENTATION.md": {
 1: "the title card — Confide, and what it does",
 2: "the exchange as a diagram: two parties, two arrows, an empty middle",
 3: "a position climbing across a quarter, watched",
 4: "`spl-token balance` says 0; the confidential balance says 173,000",
 5: "the mint scan finishing, the auditor slot empty",
 6: "`./scripts/usage-scan.sh` running to its total: 329,536 accounts, 0",
 7: "PYUSD and USDG beside a tokenized stock, the matching fields lit",
 8: "the escrow in the diagram, then gone",
 9: "both instruction names in one transaction; the record account",
 10: "the conditions table, then a command and the page URL",
 },
 "video/CHECKIN-1.md": {
 1: "the page being used — a mint typed in, the verdict appearing",
 2: "the reserve table live, then $21.1m / $81.6m / $0",
 3: "the three missing pieces, as text",
 },
}

import sys as _s
targets = [a for a in _s.argv[1:] if not a.startswith("--")] or DOCS
write = "--write" in _s.argv
bad = 0

for DOC in targets:
    SHOWS = SHOWS_BY_DOC[DOC]
    text = io.open(DOC, encoding="utf-8").read()
    sc = scenes(text)
    if len(sc) != len(SHOWS):
        print("  %s: found %d scenes, expected %d — the heading format changed" % (DOC, len(sc), len(SHOWS)))
        bad += 1
        continue
    rows, total_s, total_w = build(sc)

    head = "| | scene | seconds (+ silence) | words | pace | what it shows |\n|---|---|---|---|---|---|\n"
    table = head + "\n".join(rows)
    old = re.search(r"\| \| scene \| seconds.*?\n\| \| \| \*\*\d+ s\*\* \| \*\*\d+\*\* \| \| \|", text, re.S)
    if not old:
        print("  %s: the table is not where this expects it" % DOC)
        bad += 1
        continue

    if write:
        io.open(DOC, "w", encoding="utf-8").write(text[:old.start()] + table + text[old.end():])
        print("  %s rewritten — %d s, %d words, %d scenes" % (DOC, total_s, total_w, len(sc)))
    elif old.group(0).strip() != table.strip():
        print("  %s: the table disagrees with the script. Run: python3 video/pace.py --write" % DOC)
        bad += 1
    else:
        print("  %s matches its script — %d s, %d words" % (DOC, total_s, total_w))

raise SystemExit(1 if bad else 0)
