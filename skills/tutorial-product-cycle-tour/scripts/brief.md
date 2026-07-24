# Sample product brief — "Trailhead" (tour subject)

> **What this is.** The controlled subject the **full product-cycle tour**
> (`tutorial-product-cycle-tour`) drives `vision → roadmap → research → arch → wbs` against. It is a
> deliberately *fuzzy* idea — a paragraph a real person might scribble down — so the tour can show it
> being **decomposed** into a milestone-ordered, dependency-mapped, feature-ready plan. That
> transformation (shapeless want → structured plan) is the tour's headline aha.
>
> **It is tour CONTENT, not a real product and not a test fixture.** Nothing here runs. There is no
> code to maintain and nothing to rot — a written brief is the whole subject (design §2, Option A).
> The tour reasons *about* this brief; it never executes anything.

---

## The idea (as the fictional user pitched it)

> *"I want to build **Trailhead** — a little self-hosted web app for planning day hikes. I keep a
> messy list of trails I want to do in a notes app, and every weekend I waste an hour cross-checking
> weather, driving distance, and whether the trail's even open. I want one place where I dump a trail
> idea, and it pulls the current forecast and trail-status, sorts my list by 'good to go this
> weekend,' and lets me check one off when I've done it. Just for me and a couple of hiking friends —
> not a startup, just something that actually saves me that hour. I don't really know where to
> start."*

That's it. That's the fuzzy input. The rest is what the product workflow builds *from* it.

---

## Why this makes a good tour subject (notes for the driving agent — do NOT read these aloud)

The tour's job is to turn the paragraph above into a real plan. This subject was chosen because it
decomposes cleanly across every product stage without needing any external setup:

- **Vision has room to sharpen a fuzzy want** — "saves me an hour every weekend," a clear tiny
  audience (self + a few friends), an explicit non-goal ("not a startup"). Good raw material for
  `/product-vision` to turn a ramble into a crisp purpose + scope + anti-persona.
- **Roadmap has natural milestone ordering** — a walking skeleton (dump a trail, see the list) has to
  exist before the enrichment (weather + trail-status) is worth anything, which has to exist before
  the "good to go this weekend" ranking that depends on both. That dependency chain is exactly what
  `/product-roadmap` sequences — and what makes the decomposition *visible*.
- **Research has a real, bounded unknown** — the weather + trail-status data has to come from
  *somewhere* (a public forecast API; trail-status is genuinely harder and may have no clean source).
  `/product-research` scouts options here — and naming "trail-status might not have a real feed" is a
  perfect honest known-unknown, not a fake one.
- **Arch has genuine shape decisions grounded in the brief** — self-hosted + single-user-ish means a
  small stack: where trail ideas are stored, how external data is fetched/cached, how the ranking is
  computed. `/product-arch` can plan around *documented* real shapes (a public weather API's response
  shape) rather than inventing an API it hopes exists — which is the **grounding-NAMED** beat.
- **WBS decomposes to feature-ready work packages** — capture-a-trail, list view, weather-enrichment,
  trail-status-enrichment (with its unknown flagged), the ranking, the check-off. Each is a unit a
  `/feature-*` workflow could pick up. This is the **decomposition PAYOFF**: the fuzzy paragraph is
  now a dependency-mapped list of buildable things.

**Keep the brief fuzzy on purpose.** Do not pre-solve it in the framing. The user watches the
*workflow* do the sharpening — if the brief already read like a spec, the decomposition aha would be
gone. The whole point is that they hand it a ramble and watch a plan fall out.
