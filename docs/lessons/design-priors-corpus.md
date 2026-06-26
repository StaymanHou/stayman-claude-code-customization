# Design Priors — Scenario Corpus (durable oracle)

> **Status:** curated. This is the reasoning record behind the `design-priors` feature
> (shipped 2026-06-26) — the labeled examples from which the **capture discriminant**
> (PRIOR vs FACT vs NOTHING) and the **consult weighting** (CONSULT-CHANGES vs
> CONSULT-NOCHANGE) were derived, and from which the behavioral scenarios
> `tests/scenarios/product.yaml::DP-*` are seeded. The Q1 (arch-boundary) and Q2
> (preserve inferred-vs-corrected-why gap) rulings in "Open questions" below were
> resolved by the operator during the feature's design. Keep in sync if the
> discriminant or weighting rules change.
>
> Original purpose (preserved): derive the capture discriminant and consult weighting
> from labeled examples rather than an ambiguous prose rule.
>
> Vocabulary:
> - **PRIOR** — a design prior; propose to write to `design-priors.md`.
> - **FACT** — a concrete one-off; belongs to session-reflect / WIP, NOT a prior.
> - **NOTHING** — no durable signal; capture nothing.
> - **ARCH** — a technical/architecture lean → belongs in `arch.md`, not design-priors (boundary case).
> - **CONSULT-CHANGES** — a recorded prior should alter the gap-fill decision.
> - **CONSULT-NOCHANGE** — common sense stands; prior doesn't fire.

---

## PART A — CAPTURE side (is this a design prior?)

| # | Checkpoint | Operator input (the moment) | Inferred-why (what CC can infer alone) | Corrected/true-why (what's really in your head) | **Verdict** | Discriminating signal |
|---|---|---|---|---|---|---|
| A1 | roadmap | "Cut the multi-tenant milestone — this is a single-operator tool." | Operator deprioritized multi-tenant. | The product is *intentionally* single-operator; breadth-of-users is a non-goal, not a "later." | **PRIOR** | A transferable *non-goal* stated as identity ("this IS X"), not a sequencing choice. Generalizes: future "should we support teams?" decisions inherit it. |
| A2 | feature-spec | "Use blue for the primary button, not green." | Operator prefers blue here. | (none deeper — just looks better) | **FACT** | A concrete one-off with no transferable why. Bare preference. session-reflect/WIP territory. |
| A3 | wbs | "Don't bother caching this — we'd rather ship and see if anyone even uses it." | Operator skipped caching. | Standing lean: **speed-to-validate > performance** until usage is proven. | **PRIOR** | A *recurring tradeoff axis* (perf vs ship) resolved with a why that will recur on the next perf decision. |
| A4 | arch | "Use SQLite, not Postgres — keep deploy to a single binary." | Operator chose SQLite. | Standing lean: operational simplicity / single-artifact deploy > scalability headroom. | **ARCH (boundary)** | It's a *tradeoff with a transferable why* — BUT the axis is technical-architecture, and arch.md is its home. **Open Q: does a tradeoff-with-why that's architectural go to design-priors or arch.md?** |
| A5 | vision | "The whole point is to feel instant — sub-100ms or it's not worth doing." | Operator values speed. | Perf is a *product identity bet*, not a tradeoff to be balanced — it OUTRANKS ship-speed for this product. | **PRIOR** | Notable: same axis as A3 (perf vs ship) but resolved the OPPOSITE way *because the project differs*. Confirms priors are per-project, and that the why is what carries the direction. |
| A6 | feature-spec | "Add an export button while you're in there." | Operator wants export. | (just wants the feature) | **NOTHING** | Pure scope addition, no tradeoff, no why. Not even a fact worth recording — it's just the work. |
| A7 | wbs | "No, keep it laser-focused on solo founders — don't generalize for agencies." | Operator rejected generalization. | Audience is *deliberately* narrow (solo founders); resist breadth-creep toward adjacent segments. | **PRIOR** | Audience-narrowing with a transferable why; directly governs future "should we serve segment Y too?" decisions. |
| A8 | verify-human | "This dialog has too many options — I want one obvious default and an 'advanced' hideaway." | Operator wants fewer visible options. | Standing lean: **opinionated-defaults > configurability**; novice-approachability > power-user surface area. | **PRIOR** | A UX-tradeoff lean stated generally ("I want ..." as a pattern), surfacing at verify-human — proves capture isn't planning-only. |
| A9 | verify-human | "This specific label is wrong, it should say 'Drafts' not 'Saved'." | Operator corrected a label. | (just the right word) | **FACT** | One-off correction, no transferable principle. The corpus's canonical "looks like capture but isn't." |
| A10 | feature-spec | "Let's not build the plugin system yet — but design the seam so we can." | Operator deferred + asked for a seam. | Lean: **YAGNI on the feature, but preserve extensibility at boundaries** — a nuanced standing stance. | **PRIOR** | A *compound* tradeoff stance (don't-build-now + keep-the-door-open). Tests whether the schema can hold a two-part prior. |
| A11 | roadmap | "Reorder these — auth before billing." | Operator sequenced milestones. | Auth is a dependency of billing. | **FACT / NOTHING** | Sequencing driven by a technical dependency, not a values-tradeoff. No transferable design lean. |
| A12 | arch | "Prefer boring tech — I don't want to debug a trendy framework at 2am." | Operator chose conservative stack. | Standing lean across the whole project: **maintainer-cognitive-load > novelty/capability**. | **PRIOR or ARCH? (boundary)** | Like A4 — transferable why, but is "boring tech" a *product* prior or an *arch* prior? It reads more philosophy-than-stack — **leaning PRIOR.** Needs your call vs A4. |
| A13 | vision | "I keep saying 'for people who hate spreadsheets' — that's the north star." | Audience framing. | The anti-persona (spreadsheet-lovers) is a *standing filter*: features that please power-users-who-love-grids are off-thesis. | **PRIOR** | An *anti-persona* stated as a recurring filter. Especially valuable: it tells CC what to steer AWAY from, not just toward. |
| A14 | feature-spec | "I changed my mind, do it the other way." (no reason given) | Operator reversed a decision. | (unstated) | **NOTHING (but probe once)** | Reversal with no why. Capture nothing — BUT this is the high-value moment to *ask once*: "is there a principle behind the reversal?" If yes → becomes a PRIOR via your review step. |
| A15 | wbs | "Ship the ugly version first, polish never blocks a release." | Operator deprioritized polish. | Standing lean: **coverage/velocity > craft/polish** as a release gate. | **PRIOR** | Clear tradeoff axis + transferable release-gating rule. |

---

## PART B — CONSULT side (does a recorded prior change a gap-fill?)

Assume `design-priors.md` already contains:
- **P-FOCUS:** audience is solo founders; resist breadth toward agencies/teams. (from A7)
- **P-SHIP:** speed-to-validate > performance until usage proven. (from A3)
- **P-DEFAULTS:** opinionated defaults > configurability; novice > power-user. (from A8)
- **P-ANTI:** anti-persona = spreadsheet-lovers; grid/power features off-thesis. (from A13)

| # | Checkpoint | Gap CC must fill (operator left it open) | Common-sense default (the 90%) | Recorded prior in play | **Verdict** | What CC does |
|---|---|---|---|---|---|---|
| B1 | feature-spec | "Add user settings" — how many options to expose? | Expose a reasonable set of toggles. | P-DEFAULTS | **CONSULT-CHANGES** | Ship one opinionated default + hidden advanced, not a toggle wall. Note the prior in the plan. |
| B2 | wbs | Should the import feature support CSV *and* Excel *and* Google Sheets? | Support the common formats. | P-FOCUS, P-ANTI | **CONSULT-CHANGES** | Spreadsheet-import is anti-thesis (P-ANTI) AND breadth (P-FOCUS) → **surface as a proposal, don't silently cut.** Borderline-strong → flag, don't decide. |
| B3 | feature-spec | What font size for body text? | 16px / system default. | (none relevant) | **CONSULT-NOCHANGE** | Take the default. No prior touches this. The 90% path, untouched. |
| B4 | arch | Cache layer for the dashboard query? | Add a cache; it's slow otherwise. | P-SHIP | **CONSULT-CHANGES (tie-break)** | Common sense says cache; P-SHIP says don't optimize pre-validation. Genuine tension → lean no-cache, **disclose**: "skipping per P-SHIP; flag if this page is hot." |
| B5 | roadmap | A teammate-collaboration milestone seems like an obvious next step. | Most tools add collaboration eventually. | P-FOCUS | **CONSULT-CHANGES (contradiction)** | Common sense says add it; P-FOCUS says solo-only is identity. **Clear-default-contradicts-strong-prior → the 10% case → propose, don't auto-add, don't auto-cut.** |
| B6 | feature-spec | Error message tone — terse or friendly? | Friendly, helpful copy. | P-DEFAULTS (weak link) | **CONSULT-NOCHANGE** | Prior is about option-count, not copy tone. **Don't stretch a prior to a decision it doesn't actually govern** — this is the canonical over-infer trap; verdict is NOCHANGE. |
| B7 | wbs | Build a public API now or later? | Depends; often defer. | P-FOCUS, P-SHIP | **CONSULT-CHANGES** | Both priors point defer (breadth + pre-validation). Priors *agree* with the cautious default → take it *with higher confidence*, brief note. |
| B8 | feature-spec | Onboarding: guided tour or just sensible defaults? | A short guided tour is common. | P-DEFAULTS | **CONSULT-CHANGES** | P-DEFAULTS (opinionated, novice-first, less surface) leans "sensible defaults, skip the tour." Tie-ish → lean + disclose. |

---

## Candidate patterns extracted (to validate against the corrected corpus)

**Capture discriminant (PRIOR vs FACT vs NOTHING):**
1. **Tradeoff + transferable why = PRIOR.** The input resolves a *recurring* tension (an axis that will recur) AND carries a *why that generalizes* beyond this instance.
2. **Identity/non-goal/anti-persona stated as "this IS / IS-NOT X" = PRIOR.** Even without an explicit axis — it's a standing filter.
3. **Concrete one-off with no transferable why = FACT.** (session-reflect/WIP.)
4. **Pure scope/sequence/dependency with no values-tradeoff = NOTHING.**
5. **Reversal/correction with no stated why = NOTHING, but PROBE ONCE** — the one-question moment that your review step converts to PRIOR if a why exists.

**Boundary rule (design-prior vs arch):** *open question A4/A12* — proposed resolution: if the why is about **product values / audience / what-the-product-is** → design-priors; if about **operational/technical stack mechanics** → arch.md. Philosophy-flavored tech leans ("boring tech because cognitive load") are the genuine gray zone.

**Consult weighting (the over-infer guard):**
6. **No prior governs the decision → NOCHANGE (90% path untouched).**
7. **Prior agrees with the default → take default, higher confidence.**
8. **Prior breaks a genuine tie → lean prior + disclose.**
9. **Clear default *contradicts* a strong prior → the 10% → PROPOSE, never silently steer.**
10. **Do NOT stretch a prior to a decision it doesn't actually govern (B6).** The over-infer failure mode lives here — a prior only fires on the axis it's about.

---

## Open questions for Stayman (annotate inline)

- **Q1 (A4/A12 boundary):** Tradeoff-with-why that's *architectural* — design-priors.md or arch.md? Where's the line? (My lean: product-values → priors; stack-mechanics → arch.)
- **Q2 (schema):** Preserve the *gap* between inferred-why and your-corrected-why as two fields, or collapse to the final why? (My lean: preserve — it's the signal of "what CC couldn't infer.")
- **Q3 (A14 probe):** Should "reversal with no why" trigger a one-time probe question, or stay silent? (My lean: probe once, gated.)
- **Q4:** Any verdict above you disagree with? Mark it.
