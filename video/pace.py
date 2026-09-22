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
# DERIVED, not listed. This was a hand-maintained list of two, and a third check-in script would
# have been written, paced by hand, and never checked again -- the exact shape of every drift in
# this repository. A check-in script IS `video/CHECKIN-<n>.md`, so the glob is the definition.
import glob as _g
DOCS = ["video/CWF-PRESENTATION.md"] + sorted(
    _g.glob("video/CHECKIN-*.md"), key=lambda s: int(re.search(r"(\d+)", s).group(1)))

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

def shows(text):
    """The `what it shows` column, taken from each scene's own `*Shows:*` line.

    This used to be a dict in this file, which made it a SECOND copy of something the script
    already said -- and it drifted exactly as this repository's copies always do: it was still
    holding "$21.1m / $81.6m / $0" and "329,536 accounts" long after both numbers had moved,
    where no check could see them because nothing reads a table's last column.

    The description runs from `*Shows:*` to where the bold commentary after it begins, not to the
    first full stop: several of these contain `./scripts/...` and would be cut at the dot.
    """
    out = []
    for m in re.finditer(r"^\*Shows:\*(.*?)(?=\n\n|\n### |\Z)", text, re.S | re.M):
        s = " ".join(m.group(1).split())
        s = s.split("**", 1)[0].strip().rstrip(".")
        out.append(s)
    return out


import sys as _s
targets = [a for a in _s.argv[1:] if not a.startswith("--")] or DOCS
write = "--write" in _s.argv
bad = 0

for DOC in targets:
    text = io.open(DOC, encoding="utf-8").read()
    SHOWS = {i + 1: s for i, s in enumerate(shows(text))}
    sc = scenes(text)
    if len(sc) != len(SHOWS):
        print("  %s: %d scenes but %d `*Shows:*` lines — every scene needs one"
              % (DOC, len(sc), len(SHOWS)))
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
