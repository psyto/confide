"""Is this scene in that transcript? One answer, used by everything that asks.

`spoken-check.sh` asks it to report on a delivered film. `caption-gap.py` asks it to decide which
scene's words belong in a hole the transcriber left. They asked it separately and got different
answers on the same file, which is how this module came to exist:

    caption-gap.py   "3 scenes are missing from the transcript, not 1 —
                      Confide, why the door is shut, the gate, both ways"
    spoken-check.sh  scenes 3 and 8 present at 88.6% and 100%

`caption-gap.py` was matching each scene's first five words as a literal substring. The transcriber
hears *Confide* as **confined** and writes *twenty thousand* as **20,000**, so two scenes that are
plainly there looked gone — and the tool refused to fill the one hole it could see, because it
believed there were three.

**A transcript is not the audio.** Everything here is tolerant on purpose: it mishears, it splits
compounds, it writes digits for words, and it drops whole stretches. What it does not do is delete
a word from a 370-word film and leave the rest intact, which is why an absent distinctive word
still means something.
"""
import re, difflib

# The voice says numbers as words; the transcript writes digits. Neither is wrong, so both are
# reduced to the same vocabulary before anything is compared.
NUM = {
    "a hundred and seventy-three thousand": "173000",
    "twenty thousand": "20000",
    "1,992": "1992", "173,000": "173000", "20,000": "20000",
    "ten minutes": "10 minutes", "five years": "5 years",
}


def norm(s):
    """Lowercase words, numbers spelled one way, punctuation gone.

    The apostrophe goes with the punctuation: the script writes *the other's amount* and the
    transcriber writes *the others amount*, and that one character was once reported as a line
    never spoken.
    """
    s = s.lower()
    for a, b in NUM.items():
        s = s.replace(a, b)
    s = s.replace("’", "").replace("'", "").replace("—", " ").replace("–", " ")
    s = re.sub(r"[^a-z0-9\- ]", " ", s)
    return [w for w in re.split(r"\s+", s) if w]


def vocabulary(heard_words):
    """Every form of every word the transcript might be said to contain.

    Hyphenated compounds arrive split as often as not, and a compound arrives as two words —
    *stablecoins* came back as *stable coins*, and the script's own word was called unspoken. So
    the parts of hyphenated words and every adjacent pair joined together are all in here.
    """
    v = set(heard_words)
    for w in list(v):
        v.update(w.split("-"))
    v.update(a + b for a, b in zip(heard_words, heard_words[1:]))
    return v


def distinctive(w):
    """Long enough to carry meaning, and not a number the voice may phrase differently.

    Short words drift through transcription constantly and mean nothing on their own.
    """
    return len(w) >= 7 and not w.isdigit()


def presence(scene_words, heard_words, vocab=None):
    """How much of one scene the transcript contains: (ratio, missing distinctive words).

    The ratio is against the stretch of transcript where this scene's words actually matched, not
    against the whole film — otherwise every scene is diluted by the nine it is not.
    """
    vocab = vocabulary(heard_words) if vocab is None else vocab
    sm = difflib.SequenceMatcher(None, heard_words, scene_words, autojunk=False)
    blocks = [b for b in sm.get_matching_blocks() if b.size]
    if blocks:
        lo = min(b.a for b in blocks)
        hi = max(b.a + b.size for b in blocks)
        window = heard_words[lo:hi]
    else:
        window = []
    ratio = difflib.SequenceMatcher(None, window, scene_words, autojunk=False).ratio()
    missing = [w for w in scene_words
               if distinctive(w) and w not in vocab and not any(p in vocab for p in w.split("-"))]
    return ratio, missing


# Below this, a scene is not in the transcript at all — as opposed to being in it and misheard.
# Scene 5 of the 09-23 cut, whose whole stretch the transcriber dropped, scores 0.108; the worst
# scene that IS present in that same file scores 0.886.
ABSENT = 0.5


def scenes_of(markdown):
    """Every scripted scene of CWF-PRESENTATION.md as (number, title, spoken words)."""
    found = re.findall(r"^### (\d+) — ([^·\n]+?)\s*(?:·[^\n]*)?$\n\n((?:^>.*\n)+)", markdown, re.M)
    return [(n, t.strip(), " ".join(re.sub(r"^> ?", "", b, flags=re.M).split()))
            for n, t, b in found]
