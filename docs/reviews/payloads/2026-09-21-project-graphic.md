# Review request — the project graphic for a hackathon submission

You cannot see images. That is understood and is the point of the framing below: judge the source
and the reasoning, not the render. Where a question needs eyes, say so rather than guessing.

## What it is for

Colosseum's Crypto World's Fair submission form has a required, PUBLIC field:

> **Project logo or graphic** — "This image represents your project on its public page."

It appears as a card among many projects. Assume it is often shown at roughly **360px wide**.

## What it replaced, and why

The first version was a 1920x640 crop of a frame from the project's own narrated video: a diagram
with two account panels, six figures, and a caption. Downscaled to 360px every figure became
texture. It was rejected for that reason.

## The product, in one line

Two parties settle tokenized stock against a stablecoin in ONE Solana transaction, and neither
publishes what moved. Confidential delivery versus payment, with no venue, custodian or clearing
house. The demo trade is 50,000 shares against $8,750,000; all four token accounts still report a
public balance of 0.

## The current source — video/graphic.html, rendered headless at 1200x630, deviceScaleFactor 2

```html
<!doctype html>
<meta charset="utf-8" />
<title>Confide — project graphic</title>
<style>
/* Built for a project card, not for reading. Everything here is sized so it survives being shown
   at ~360px wide in a grid: the video-frame crop that used to serve this was 1920x640 of small
   terminal type and became texture at that size. One idea, four numbers, nothing else. */
:root{--bg:#07080c;--dim:#5b6678;--fg:#e8edf5;--grn:#63cf83;--yel:#f0c05a;--line:#1c2233}
*{margin:0;padding:0;box-sizing:border-box}
html,body{width:1200px;height:630px}
body{background:
  radial-gradient(900px 480px at 50% 22%, #0d1220 0%, var(--bg) 70%);
  color:var(--fg);font:400 20px/1.5 ui-sans-serif,-apple-system,"Segoe UI",Inter,system-ui,sans-serif;
  -webkit-font-smoothing:antialiased;display:flex;flex-direction:column;
  align-items:center;justify-content:center;gap:34px}
.mark{font-size:30px;letter-spacing:.38em;color:var(--dim);text-transform:uppercase;font-weight:600}
.deal{display:flex;align-items:center;gap:34px;font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
.amt{font-size:72px;font-weight:600;letter-spacing:-.02em;white-space:nowrap}
.amt.a{color:var(--fg)} .amt.b{color:var(--yel)}
/* Two arrows drawn as rules, not as a glyph. U+21C4 at this size next to 72px figures collapsed
   into something that reads as an EQUALS-WITH-SLASH when the card is shown at 360px wide -- so the
   headline said 50,000 shares is NOT $8,750,000, which is the opposite of the claim. */
.sw{display:flex;flex-direction:column;gap:11px;padding:0 6px}
.sw i{display:block;width:96px;height:5px;background:var(--dim);border-radius:3px;position:relative}
.sw i::after{content:"";position:absolute;top:-7px;width:19px;height:19px;border-top:5px solid var(--dim);
  border-right:5px solid var(--dim);border-radius:2px}
.sw i.r::after{right:0;transform:rotate(45deg)}
.sw i.l::after{left:0;transform:rotate(-135deg)}
.one{font-size:30px;color:var(--dim);letter-spacing:.02em}
.one b{color:var(--fg);font-weight:600}
.chain{display:flex;align-items:center;gap:22px;margin-top:10px}
.chain .k{font-size:25px;color:var(--dim)}
.z{width:96px;height:78px;border:1px solid var(--line);border-radius:14px;background:#0a0e17;
   display:flex;align-items:center;justify-content:center;
   font-family:ui-monospace,Menlo,monospace;font-size:46px;font-weight:600;color:var(--grn)}
</style>

<div class="mark">Confide</div>

<div class="deal">
  <div class="amt a">50,000 shares</div>
  <div class="sw"><i class="r"></i><i class="l"></i></div>
  <div class="amt b">$8,750,000</div>
</div>

<div class="one">settled in <b>one Solana transaction</b> — neither side published a thing</div>

<div class="chain">
  <div class="k">what the chain shows everyone else</div>
  <div class="z">0</div><div class="z">0</div><div class="z">0</div><div class="z">0</div>
</div>
```

## What already went wrong once, so you do not have to find it

The exchange symbol was the glyph U+21C4 at 44px, in the dim grey, between two 72px figures. At
360px it collapsed into something that reads as a not-equals sign — so the headline said *50,000
shares ≠ $8,750,000*, the opposite of the claim. It is now two arrows drawn as CSS rules with
pseudo-element heads. That class of failure — a mark that inverts the meaning when small — is what
this review should hunt for more of.

## Questions

1. **Does anything else in this markup invert, vanish or become ambiguous at 360px wide?** Be
   specific about which rule and which element.
2. **Is the hierarchy right for one second of attention?** A judge scanning a grid should learn
   what this is before deciding whether to click. Right now the first thing is the trade, the
   second is "one Solana transaction", the third is four zeros.
3. **Is the wordmark doing anything?** "CONFIDE" is 30px, letter-spaced, dim grey, above the
   headline. The card almost certainly prints the project name separately. Argue for keeping or
   dropping it.
4. **The four zero boxes.** They carry the strongest fact — the chain shows nothing — but they are
   the smallest element and sit bottom-right. Should they be the headline instead of the trade?
5. **1200x630.** The form states no dimensions, only "up to 20 MB before compression, optimized to
   0.5 MB". Is that ratio a defensible default for an unknown card layout, or is square or 16:9
   safer? Say what you are assuming.
6. **Anything dishonest.** Every figure is from a real devnet transaction. Flag anything that
   reads as a claim the project has not earned — this repository's whole argument is that its
   numbers are checkable, and an image that overstates would cost more than it wins.

Answer concretely. "Looks good" is not useful; a named element and a named failure is.
