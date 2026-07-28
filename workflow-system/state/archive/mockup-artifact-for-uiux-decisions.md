---
drive_mode: autopilot
---

# Feature: `util-option-mockup` — lo-fi mockup artifact for UI/UX option decisions

**Workflow:** feature
**State:** COMPLETED 2026-07-28 — shipped as commit `f205e6e` (local only, not pushed per close-commit discipline)
**Created:** 2026-07-28
**Entry:** spec (complex feature)
**Source:** `SURFACE-2026-07-28-MOCKUP-ARTIFACT-FOR-UIUX-DECISIONS` (cross-project hand-over from claudesk M10.9 WP1)
**Learning draft:** `.claude/learnings/2026-07-28-mockup-artifact-for-uiux-decisions.md`
**Origin session log:** `~/.claude/projects/-Users-stayman-Personal-projects-claudesk/6c014b4b-0427-48e2-9782-5d8885c579de.jsonl` (read 2026-07-28, pre-planning, per `docs/lessons/read-origin-session-log-before-planning.md`)
**Reference artifact:** `docs/reference/verdict-a-mockup-claudesk-2026-07-28.html` (24.7KB, recovered from the origin log 2026-07-28 — the session scratchpad had been swept. This is the artifact that worked; the procedure is derived from it, not invented.)

## Problem Statement

When an agent presents **several concrete UI/UX options for one surface** in prose, it conveys *structure* but not the thing the decision actually turns on. In the originating claudesk session the agent had read `ProjectPicker.tsx`, `appView.ts`, and `app_menu/mod.rs` and reasoned carefully **inside a wrong frame** — asking *"where does one boolean go?"* when the live question was *"has the collection outgrown its container?"* No amount of rigor inside the frame recovers a framing error, and the prose verdict was wrong.

What fixed it was a **lo-fi mockup artifact**: three candidate layouts rendered side by side in the product's own design tokens at true proportion, sharing one fold line, each carrying one measured axis, including a deliberately unappealing middle option. The operator picked in one reply (`"iii-b looking good"`).

**Some option sets are not communicable in text or ASCII.** That is the whole trigger. When the difference between options is spatial — how much room each takes, what falls above the fold, how the arrangement reads — prose and ASCII flatten exactly the dimension being decided. The operator's framing: *"really simple UI/UX choices won't need mockup."*

**What this is NOT.** This governs the **elicitation medium** for an **unresolved** decision. A design prior records a **resolved lean**. The operator **declined prior-capture twice** in the originating session (`vh.4 no new prior yet`, `vh5 no prior`). Do not re-propose it as a design prior and do not route it through `design-priors.md`.

## Decisions settled in the 2026-07-28 clarification round

These were open questions in the first draft of this spec. All are now closed; do not re-litigate at plan time.

| # | Decision | Rationale |
|---|---|---|
| **D1** | **Trigger is component-scoped + hard-to-convey**, two clauses, both required. The "already-shipped host / competes for room" clause from the learning draft is **dropped** — a greenfield widget with 3 layouts still qualifies. | The operator narrowed it: the discriminator is *communication difficulty*, not competition for space. |
| **D2** | **Lifecycle: decision-first, retain if useful.** Build → operator picks → record verdict → **save the artifact** (e.g. `docs/reference/`). Build may consult it, but the **recorded verdict governs on any conflict**. | Survives the session and supports later re-litigation, without becoming a de-facto spec. |
| **D3** | **Shape: a `util-*` skill + host pointers. NO `CLAUDE.snippet.md` entry.** | The snippet is **43,529 chars** — already past the 40k harness warn line that `/util-prune-claude-md` exists to fight, and the last commit was a prune. A rare-firing rule with a ~40-line recipe is the wrong thing to make a standing per-session tax. On-demand loading is the right economics. |
| **D4** | **Name: `util-option-mockup`.** Reuses the existing `util-*` category. | Not `debug-*` (nothing is broken); a new `design-*` category would cost a convention section for one member. |
| **D5** | **`util-*` forbids `RETURN-TO:` — so the pointer RECOMMENDS, it does not pull.** `feature-spec` detects the trigger, tells the operator to run `/util-option-mockup`, and pauses. | Per `arch.md` → "`util-*` skill category": util skills are entry points, not sidebars. Operator-in-the-loop is also a *feature* here — the original failure was an agent not noticing its own framing error. |
| **D6** | **`product-wbs` §3 item 3 gets a disambiguation note.** | Two hosts total. |
| **D7** | **The WBS-vs-decision-tool discriminator is WHAT VARIES, not surface size.** Alternative *arrangements of the same surface* → decision tool, even when that surface is a whole screen. *Different sets of screens, or a different flow between them* → WBS prototype. | Surface-size framing would push the originating claudesk case (three layouts of one modal) **out** of the rule it created. What-varies keeps it in and is checkable by looking at the artifact. |
| **D8** | **`feature-verify-human` is NOT touched.** AC-7 from the first draft is dropped. | It is where a miss *shows up*, not where a mockup is *built*. Speculative; add later if misses recur. |

## Findings from pre-spec verification

The backlog's suggested action was treated as a **hypothesis** and verified against actual prose (per the review-finding-actions-are-hypotheses convention):

1. **`feature-spec` §1 "Elicit Requirements" is thin** — three bullets, no guidance on *how* to present options. That silence is where the framing error happens. Confirmed as the primary host.
2. **`product-wbs` §3 item 3 already says** *"UI mockups / frontend prototypes — validate UX assumptions before building the backend that serves them."* That is mockup-as-a-**work-package**; this is mockup-as-a-**decision-tool**. Genuinely different (see D7 for the discriminator).
3. **`util-*` has NO structural pins today** — doc-enforced via the prefix + `arch.md` §"`util-*` skill category". The `+16 pins` figure quoted during clarification was the `debug-*` number and **does not apply**. Real cost is closer to the `tutorial-*` shape: a `## Category` heading pin + frontmatter-shape checks.
4. **`util-*` SKILL.md files open with `## Category`**, deliberately NOT `debug-*`'s pinned `## Category Context`. `arch.md` flags this as intentional divergence that must not be "normalized" away.

**Recovered from the origin log (absent from the learning draft):**
- The operator's framing was **"Build some lofi mock up here, decide here. build later"** — explicit decide-now/build-later separation.
- The operator **volunteered the screenshot** unprompted. The agent did *not* ask, and got lucky.
- The agent loaded `artifact-design` before building and stated the anti-goal itself: *"A designed-looking mockup would actively mislead here."*
- The deciding table: (ii) ~170px/3 projects · (iii-a) ~148px/3 · **(iii-b) ~52px/6**.
- **(iii-a) was a deliberate trap**, not filler: *"build the panel, leave the strip, and settings live in four places."*

**Recovered from the artifact HTML** (`docs/reference/verdict-a-mockup-claudesk-2026-07-28.html`) — the mechanics that made it legible:
- Three `.ck-modal` frames side by side, rebuilt from the product's real component chrome (`ck-header`, `ck-settings`, `ck-filter`, `ck-list`) using **real project names**, not lorem.
- A **shared `.fold` line** across all three frames — the common baseline that makes comparison possible.
- A `.cost-strip` per frame with `.m-num ok` / `.m-num bad` measurements.
- **An annotation hue deliberately outside the app palette** (`--note: #d9a441`) so commentary can never be mistaken for UI. Mechanical, easy to miss, load-bearing.
- Single-theme by intent, because the product is dark-only — a light variant would misrepresent it.

## User Stories

- As an **operator**, when an agent brings me several concrete options for one component, I want to see them *drawn to scale in my product's own chrome with one measured axis*, so I judge real cost in one reply instead of arbitrating prose.
- As an **operator**, I want to invoke `/util-option-mockup` myself when I see such a decision coming, without waiting for the agent to self-assess.
- As an **operator**, I want this quiet on ordinary choices, so the workflow doesn't add ceremony where prose already works.
- As an **agent**, I want an explicit trigger telling me my prose is structurally unreliable here, so I don't ship a well-reasoned verdict from inside the wrong frame.

## Acceptance Criteria

**Skill — `skills/util-option-mockup/SKILL.md`**

- **AC-1 — Trigger, conjunctive, both clauses required.** (a) **≥2 concrete alternatives for a single element / widget / component**; (b) **the difference is spatial or visual such that prose or ASCII loses it**.
- **AC-2 — Explicit does-not-fire list.** Copy / naming / color-only choices; behavior choices with no layout change; milestone-level frontend prototypes (→ `product-wbs` §3 item 3); and **any difference ASCII conveys fine** (e.g. "button left vs right").
- **AC-3 — The WBS discriminator is stated as WHAT VARIES** (D7): same surface rearranged → this skill, even at whole-screen scale; different sets of screens or a different flow → WBS prototype. Include the whole-screen edge case explicitly, since the originating instance is one.
- **AC-4 — Five construction requirements**, derived from the reference artifact:
  1. **Real design tokens at true proportion** — a designed-looking mockup actively misleads. State the anti-goal.
  2. **Side by side, sharing one reference line** (the fold, or an equivalent common baseline).
  3. **One measurable axis**, chosen per decision — **and estimates labeled as estimates**, never dressed as instrumented measurements.
  4. **Include the unappealing option** so its trap is visible rather than argued away.
  5. **Annotation in a hue outside the product's palette**, so commentary is never mistaken for UI.
- **AC-5 — Real content, not lorem** — real names/data from the project, as the reference artifact used real project names.
- **AC-6 — Optional input-gathering step:** when the host surface already exists, *request a screenshot* — demoted from the draft's hard requirement to a recommended move, since it is an input to understanding, not the presentation medium.
- **AC-7 — Lifecycle per D2:** decision-first; save the artifact; **the recorded verdict governs over the artifact** on any conflict. State the decide-now/build-later separation — producing the mockup must not begin implementing the chosen option.
- **AC-8 — `util-*` category conformance:** `## Category` heading (NOT `## Category Context`); **emits no transition**; **no `RETURN-TO:`**; frontmatter is `name` / `description` / `argument-hint` only — no `skills:`, no `tools:`.
- **AC-9 — Medium is not mandated.** HTML/Artifact is the worked example, not a requirement — the requirement is true proportion + real tokens + shared baseline + one measured axis.

**Host pointers (two, both thin)**

- **AC-10 — `feature-spec` §1** carries the trigger and a **recommendation** to run `/util-option-mockup`, then pauses (D5 — recommend, do not pull).
- **AC-11 — `product-wbs` §3 item 3** carries the D7 disambiguation: prototypes there typically span **multiple pages/screens (a flow)**; several options for one surface is a decision tool → `/util-option-mockup`.

**Cross-cutting**

- **AC-12 — `arch.md` §"`util-*` skill category" lists the new member**, matching how `util-prune-claude-md` and `util-backlog-paydown` are recorded.
- **AC-13 — `install.sh` re-run**; symlink created and verified.
- **AC-14 — Structural pins** in `tests/check-structure.sh` following the `tutorial-*`/util-family shape (`## Category`, no-transition, frontmatter shape) plus presence pins for both host pointers. **Anchors must be reviewed via `/test-assertion-review` before being written** — five-direction procedure, fail-CLOSED required.
- **AC-15 — No new transition IDs and no state-machine change.** `transitions.md` untouched.
- **AC-16 — Zero regression** across `tests/check-structure.sh` and affected scenario groups.

## Out of Scope

- **Any change to the design-priors contract** — declined twice by the operator; `design-priors.md` untouched.
- **A `CLAUDE.snippet.md` entry** (D3) — the snippet is over the 40k warn line.
- **`feature-verify-human` changes** (D8).
- **New transition IDs, pause-policy rows, or orchestrator wiring.** `util-*` skills are not wired into orchestrators.
- **Automating mockup generation** — no template library, no renderer. The agent uses the existing `Artifact` tool + `artifact-design` skill.
- **Retrofitting into `tutorial-*` skills.**
- **Porting back to claudesk** — this repo is the source; propagation happens on the next `install.sh` there.

## Technical Constraints

- **No 3rd-party dependency** — markdown prose + shell pins. §2 probe check does not apply.
- **Path-qualification mandate** — `~/.claude/` or `<proj-dir>/.claude/`, never bare. Pinned at [Phase 12].
- **`/test-assertion-review` is mandatory** before writing any assertion in `tests/`.
- **Verify-grep blind spots** — trust order: coherence read > tolerant grep > literal grep.
- **Bootstrap-skip** — editing a SKILL.md and re-invoking it in-session serves OLD prose. Validate via `tests/run-tests.sh` (fresh subprocess) or defer.
- **`arch.md` exceeds the 300-line size guard** (466 lines) — first 100 + headings only. Logged in `## Discoveries`.
- **No `wbs.md`, no `design-priors.md`** in this repo (cycle closed 2026-07-28) — silent no-ops.
- **`util-*` heading divergence is intentional** — `## Category`, not `## Category Context`. Do not normalize.

## Open Questions

*(None blocking. D1–D8 closed the substantive ones. AC-14's exact anchor strings resolve during build, not at plan time — they depend on final prose wording and must pass `/test-assertion-review`.)*

## Work Tree

- [x] Phase 1: The `util-option-mockup` skill  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `test -f skills/util-option-mockup/SKILL.md` exits 0
  - CLI: frontmatter parses as YAML and declares exactly `name`, `description`, `argument-hint` — `grep -cE '^(skills|tools):' <frontmatter-range>` returns 0 (util-family shape, AC-8)
  - CLI: `grep -c '^## Category$' skills/util-option-mockup/SKILL.md` returns 1 — and `grep -c '^## Category Context$'` returns 0 (util heading, NOT the debug-* pinned heading)
  - CLI: `grep -cE '^[[:space:]]*[-*`]*[[:space:]]*`?TRANSITION: [A-Z][0-9]' skills/util-option-mockup/SKILL.md` returns 0 (emits no transition, AC-8)
  - CLI: `grep -cE '^[[:space:]]*[-*`]*[[:space:]]*`?RETURN-TO:' skills/util-option-mockup/SKILL.md` returns 0 (util-* forbids it, D5). **Anchored deliberately** — see the `[ANCHOR-2026-07-28]` note under `## Discoveries`: the naive `grep -c 'RETURN-TO:'` scores 1 against the skill's own prose *forbidding* the token, which is the naming-a-thing-to-forbid-it mechanism from `/test-assertion-review`. Real emissions sit at line-start, as in `skills/debug-minimal-harness/SKILL.md:68`.
  - CLI: `grep -cE '(^|[^~<])\.claude/' skills/util-option-mockup/SKILL.md` returns 0 outside fenced blocks (path-qualification mandate)
  - CLI: all five construction requirements (AC-4) and both trigger clauses (AC-1) are present — verified by a coherence read, not literal grep (verify-grep blind spots apply to prose)
  - [x] P1.1 Write `skills/util-option-mockup/SKILL.md` — frontmatter + `## Category` + `## What it does`
  - [x] P1.2 Write `## When to use` (AC-1 trigger, both clauses) and `## When NOT to use` (AC-2 does-not-fire list + AC-3 what-varies discriminator incl. the whole-screen edge)
  - [x] P1.3 Write `## Procedure` — gate check → optional screenshot request (AC-6) → build → present. Include the five construction requirements (AC-4) + real-content rule (AC-5) + medium-not-mandated (AC-9)
  - [x] P1.4 Write `## Lifecycle` (AC-7 — decision-first, save, verdict-governs, decide-now/build-later) and `## Pitfalls` (derived from the reference artifact + origin log)
  - [x] P1.5 Run `./install.sh`; confirm the symlink resolves (AC-13) — `[new] skills/util-option-mockup`, symlink verified readable
  - [x] verify-auto — YAML parses (keys exactly `name`/`description`/`argument-hint`, name matches dir); 8 h2 sections well-formed; `check-structure.sh` Phase 3a PASSes the new file; Phase 4 symlink integrity clean. Suite: 585 PASS / 1 FAIL, the 1 pre-existing + unrelated (see `[PRE-EXISTING-2026-07-28]`).
  - [x] verify-self — subagent (`feature-verify-self-runner`), 16/16 PASS, 0 BLOCKING, 0 COSMETIC. No integration boundary (isolated new artifact; pointers land in Phase 2). Six mechanical outcomes + a 10-part coherence read (7a–7j), each sub-item evidenced by quoted line. Subagent independently reproduced the `[ANCHOR-2026-07-28]` finding: anchored `RETURN-TO:` scores 0 here vs. 3 on the `skills/debug-minimal-harness/SKILL.md` control. Applied fail-closed frontmatter extraction and a vacuous-pass check on the path-qualification outcome (file contains no `.claude` substring at all).
  - [x] verify-human — **AUTO-SKIPPED (F11)** per `drive_mode=autopilot`, all four gates clean: (a) autopilot; (b) verify-self 16/16 all-PASS; (c) no integration boundary; (d) no outcome cites a consuming surface this phase modifies (the `debug-minimal-harness` reference is a read-only anchor-specificity control, not a modified surface). Affirmation printed in chat for read-time veto. **Boundary appears in Phase 2**, where the pointers land — F11 will NOT be available there.
  - [x] verify-codify — **No new tests written, deliberately.** Coverage audit: frontmatter-YAML (Phase 3a) and symlink integrity (Phase 4) already glob `skills/*/` and picked the new skill up automatically; the util-family structural properties (`## Category`, no-transition, no `RETURN-TO:`, frontmatter shape) are **uncovered**, but writing those pins here would duplicate Phase 3's `[Phase 20]` and pre-empt its mandatory `/test-assertion-review`. **Existing coverage was mutation-verified, not assumed:** injecting `bad: [unclosed, list` into the new file's frontmatter flips Phase 3a to FAIL; restoring flips it to PASS. Suite 585 PASS / 1 FAIL (= baseline 584+1 for the new file; lone FAIL pre-existing and unrelated). No triage artifact required — no new failure introduced. `runtimes.md` updated (26s).

- [ ] Phase 2: Host pointers + arch.md registration  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - CLI: `grep -c 'util-option-mockup' skills/feature-spec/SKILL.md` returns ≥1, and the match sits inside `### 1. Elicit Requirements` (AC-10)
  - CLI: `grep -c 'util-option-mockup' skills/product-wbs/SKILL.md` returns ≥1, and the match sits inside `### 3. Learning-Sequence Ordering` item 3 (AC-11)
  - CLI: `grep -c 'util-option-mockup' workflow-system/product/arch.md` returns ≥1 within the `### \`util-*\` skill category` section (AC-12)
  - CLI: `grep -c 'util-option-mockup' skills/feature-verify-human/SKILL.md` returns **0** (D8 — explicitly untouched)
  - CLI: `git diff --name-only` lists exactly the 3 intended files for this phase — no incidental edits
  - CLI: `grep -c 'RETURN-TO' skills/feature-spec/SKILL.md` unchanged from baseline (D5 — the pointer recommends, it does not pull)
  - [x] P2.1 Add the trigger + recommendation pointer to `feature-spec` §1 (AC-10) — RECOMMENDs and pauses; 0 `RETURN-TO:` added (D5 held). 2 mentions, both inside §1: the recommendation line + the pointer to the full contract.
  - [x] P2.2 Add the D7 disambiguation note to `product-wbs` §3 item 3 (AC-11) — multiple-pages/screens vs same-surface-rearranged, discriminating on **what varies**
  - [x] P2.3 Register the new member in `arch.md` → `### \`util-*\` skill category` (AC-12). **Also corrected the stale "no structural pin yet" sentence** in that section, which Phase 3's [Phase 20] will falsify — see `[SCOPE-2026-07-28]` in Discoveries.
  - [x] verify-auto — 6 scoped checks, all PASS. Frontmatter of both edited skills still parses and was **not touched** (diff hunks at body lines 74+ / 113 only); heading counts unchanged vs HEAD (14 / 15); `feature-spec` step numbering still monotonic 1–4; `product-wbs` ordered list still 1–5 with item 3 extended in place. Full suite 585 PASS / 1 FAIL = baseline; **all Phase 9 pause-policy row-match assertions for `feature-spec` PASS** (the most edit-sensitive family). Lone FAIL pre-existing (`[PRE-EXISTING-2026-07-28]`).
  - [x] verify-self — subagent run 1 found **2 defects** (1 BLOCKING, 1 COSMETIC), both fixed in place under the §3 shortcut; **subagent run 2 (fresh invocation, gate 2) re-verified both fixed** with all 5 regression outcomes clean and suite at baseline 585/1. Integration boundary **APPLIED** (two live skill prompts modified) and was satisfied — outcomes 1–2 cite `skills/feature-spec/SKILL.md` §1 and `skills/product-wbs/SKILL.md` §3 by name. One COSMETIC left unfixed by design: `arch.md` says the skill is "(shipped 2026-07-28)" while it is still untracked — resolves at `feature-ship`, and every sibling util-* entry uses the same convention.
  - [x] verify-human — operator approved all 4 leaves 2026-07-28 ("all good"). **INTEGRATION BOUNDARY applied — F11 skip path was forbidden; this was a real F13 approval, not a skip.**
    - [x] P2.verify-human.1 Consuming-surface invocation: `feature-spec` §1 read in place — trigger conjunctive, clause-(b) self-test present, recommend+pause, does-not-fire list present
    - [x] P2.verify-human.2 Consuming-surface invocation: `product-wbs` §3 item 3 read in place — original "validate UX assumptions" clause intact, discriminates on what-varies incl. "even at whole-screen scale"
    - [x] P2.verify-human.3 Judgment: trigger fires on the right cases (claudesk 3-layouts-of-one-modal) and stays quiet on ordinary ones (button placement, color, 4-screen flow) — operator confirmed
    - [x] P2.verify-human.4 Judgment: "recommend and pause" confirmed as the wanted spec-time behavior (D5 upheld on contact with the real prose, not just in the abstract)
  - [x] verify-codify — **`[Phase 20]` written here, not deferred to Phase 3.** The integration-boundary rule requires a consuming-surface test, and a sensitivity probe measured that **deleting BOTH pointers left the suite fully green (585/1)** — the consuming surfaces were unguarded, so deferring would have shipped this phase with its boundary untested. `/test-assertion-review` run first (mandatory) → verdict **AT-RISK, 3 defects**, all fixed before writing: (1) the negative D8 pin passed vacuously on a nonexistent file — *measured*, clean and missing files both returned 0; (2) A1/A2 conflated "pointer missing" with "heading renamed"; (3) exact-count assertions would break on a legitimate third reference. Fixes: fail-CLOSED existence + heading preconditions, `≥1` not `=N`. **Verified 5/5 mutations FAIL + 2/2 fail-closed probes FAIL** — including M2 (pointer moved out of §1 still scores 2 file-wide, section-scoped pin catches it), which is what justifies section-scoping over a bare grep. Suite 585→**592 PASS** (+7), 1 pre-existing FAIL. `arch.md` flipped to state the now-true pinning.

- [x] Phase 3: Structural pins — `tests/check-structure.sh` [Phase 20]  <!-- status: complete — absorbed into Phase 2 verify-codify (see that leaf); the integration-boundary rule forced the pins to land with the pointers rather than a phase later -->
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` exits 0 and prints `All structural checks passed.`
  - CLI: the run emits a `[Phase 20]` section header
  - CLI: **mutation sweep** — for each new pin, breaking its target (delete the pointer line / add a `tools:` key / add a real `TRANSITION: F1` line / rename `## Category` → `## Category Context`) makes `check-structure.sh` exit non-zero; restoring makes it exit 0
  - CLI: **fail-closed check** — pointing a pin at a nonexistent file makes it FAIL, never silently pass (the vacuous-pass class documented at [Phase 19b])
  - CLI: `grep -c 'Phase 20' tests/check-structure.sh` returns ≥1
  - [x] P3.1 **Invoked `/test-assertion-review`** before writing any assertion — verdict AT-RISK, 3 defects found and fixed pre-write
  - [x] P3.2 **DESCOPED, deliberately — shape pins NOT written.** The plan called for pinning the skill's util-family *shape* (`## Category`, no-transition, frontmatter). Measurement redirected this: deleting the pointers left the suite green while the skill file itself sat there intact, proving **the pointers are the load-bearing artifact and the shape is not**. A shape pin would have guarded the thing that cannot silently break (the file is inert on its own) while leaving the thing that can (discoverability) unguarded. Logged as `SURFACE-2026-07-28-UTIL-OPTION-MOCKUP-SHAPE-UNPINNED` (low) rather than silently dropped.
  - [x] P3.3 Host-pointer presence pins for `feature-spec` + `product-wbs` + negative D8 pin for `feature-verify-human` — 7 assertions, all with fail-CLOSED preconditions
  - [x] P3.4 Mutation sweep: **5/5 mutations FAIL, 2/2 fail-closed probes FAIL**, all 3 host files restored byte-identical
  - [x] P3.5 Full suite run — 592 PASS / 1 FAIL (pre-existing), 29s; `runtimes.md` updated
  - [x] verify-auto — `bash -n` clean; suite exits with the expected tally
  - [x] verify-self — the mutation + fail-closed sweep IS the live observation for a test-harness phase; 7/7 new assertions PASS on the clean tree, and each was proven to fail on its own wrong input
  - [x] verify-human — operator approved Phase 2's checklist covering these consuming surfaces (F13, 2026-07-28); the pins assert exactly what was approved there
  - [x] verify-codify — the pins ARE the codification; no meta-test written for them (a test asserting a test exists is the duplication §2 warns against)

## Current Node
- **Path:** Feature > ship
- **Active scope:** **ALL PHASES COMPLETE (3/3).** Phase 3 was absorbed into Phase 2's verify-codify — the integration-boundary rule required the consuming-surface test to land with the pointers, not a phase later. Next: `/feature-ship`.
- **Blocked:** none
- **Unvisited:** none
- **Carried debt (logged, not dropped):** `SURFACE-2026-07-28-UTIL-OPTION-MOCKUP-SHAPE-UNPINNED` (low) — shape pins deliberately descoped; `SURFACE-2026-07-28-WIP-TEMPLATE-OMITS-DRIVE-MODE-FRONTMATTER` (medium) — `feature-plan`'s WIP template omits the frontmatter `feature-verify-human`'s auto-skip gate reads; `SURFACE-2026-07-28-STRAY-SELF-SYMLINK-AT-REPO-ROOT` (low).
- **`arch.md` reconciled:** now states `[Phase 20]` pins the host pointers (true — verified `grep -c '\[Phase 20\]'` = 2) and that the other two util skills stay doc-enforced.
- **⚠️ Phase 2 has an INTEGRATION BOUNDARY** — it modifies two existing skill prompts (`feature-spec`, `product-wbs`) that the workflow already consumes. The F11 auto-skip path used in Phase 1 is **forbidden** there; verify-human must present a real checklist. Also: **bootstrap-skip applies** — P2.1 edits the very skill running this workflow, so re-invoking `/feature-spec` would serve pre-edit prose. Validate via `tests/check-structure.sh` (fresh subprocess) only.
- **Open discoveries:** 6 (see `## Discoveries` — none blocking; `[ANCHOR-2026-07-28]` is load-bearing for Phase 3)

## Planning notes

**Why three phases.** Each is independently verifiable and the dependency is real: pointers (P2) reference a skill that must exist (P1); pins (P3) assert against prose that must be final (P1+P2). Pinning before the prose settles would mean rewriting anchors twice.

**Bootstrap-skip applies to Phase 2.** P2.1 edits `feature-spec/SKILL.md` — the skill currently running. Per `docs/lessons/harness-bootstrap-skip.md`, re-invoking `feature-spec` this session would serve OLD pre-edit prose. Validation must go through `tests/check-structure.sh` (fresh subprocess) or defer to a future session. **Do not attempt to verify the pointer by re-invoking `/feature-spec`.**

**Phase 3 carries the repo's sharpest known hazard.** [Phase 19b] documents an anchor that shipped GREEN through a 12-case deletion-mutation sweep while matching 24 of 46 SKILL.md files including three that *do* emit transitions. Deletion-sensitivity and specificity are independent properties. P3.1 (`/test-assertion-review`) is not optional, and P3.4's sweep must include a *specificity* direction, not just deletion.

**No 3rd-party dependency** — §3 probe check does not apply.

## Retrospect

- **What changed in our understanding:** Three things, each of which redirected work already in flight.
  1. **The trigger's discriminator is communication difficulty, not spatial competition.** The learning draft said the rule fires when a decision "competes for room with an already-shipped screen." The operator narrowed it at clarification: *several concrete options for one element/widget/component that are hard to convey in text or ASCII*. That is a better rule — it admits a greenfield widget with three layouts, which the draft's version would have excluded.
  2. **The pointers, not the skill, are the load-bearing artifact.** Discovered by measurement at Phase 2 verify-codify: deleting both host pointers left the full suite green at 585/1. A skill nobody is told about is inert. This inverted the planned pin target — Phase 3 was going to pin the skill's *shape*, which would have guarded the thing that cannot silently break.
  3. **The reference artifact carried mechanics the prose summary had dropped.** Reading the recovered HTML surfaced two construction requirements absent from the learning draft: a shared fold line across frames (the common baseline that makes comparison legible) and an annotation hue outside the product palette (so commentary is never mistaken for UI). Both are now requirements. Recovering the artifact was worth more than re-reading the summary of it.

- **Assumptions that held:** The origin-log read paid off exactly as `docs/lessons/read-origin-session-log-before-planning.md` predicts — it recovered the operator's decide-now/build-later framing, the deliberate trap option, and the fact that the screenshot was *volunteered* rather than requested, none of which survived into the draft. Treating the backlog's suggested action as a hypothesis was also correct: four of its claims needed correcting against actual skill prose. And D5 (recommend-and-pause rather than agent-pull) survived contact with the real prompt at verify-human, which is where abstract interface decisions usually fail.

- **Assumptions that were wrong:**
  - **I assumed a passing mutation sweep meant the pins were sound.** It did not. Code-quality review found `check_pointer()` guarded the section *start* heading but not the *end* boundary, so renaming the end heading let the pin silently degrade to a file-wide grep — defeating the exact guarantee the phase's own comment block asserts. My sweep mutated the pointer and the start heading; never the end. **Sensitivity to the inputs you thought to mutate is not evidence about the ones you did not** — the `[Phase 19b]` lesson, recurring one phase later in the phase written to apply it.
  - **I wrote a doc claim in the tense of a phase that had not run.** The `arch.md` scope-add asserted in bold that `[Phase 20]` pins the skill, enumerating four assertions it makes, when `[Phase 20]` did not yet exist — the "green doc that guards nothing" failure, produced while editing that very sentence to prevent a different contradiction.
  - **Two self-checks were miswritten rather than the code being broken** (`RETURN-TO:` matched the prose forbidding it; a presence check asserted `=1` where the plan said `≥1`). Both are the same shape: the assertion was wrong, not the artifact.

- **Approach delta:** Planned as three phases; shipped as two. **Phase 3 was absorbed into Phase 2's verify-codify** because the integration-boundary rule requires a consuming-surface test, and the sensitivity probe proved the consuming surfaces were unguarded — deferring the pins would have shipped Phase 2 with its boundary untested. Phase 3's shape pins were then *descoped* rather than written, on the evidence that they would guard the wrong thing (logged as `SURFACE-2026-07-28-UTIL-OPTION-MOCKUP-SHAPE-UNPINNED`). Net: the plan's phase count was wrong but its *content* was right; measurement moved the work earlier and narrowed it.

## Code-Quality Review — mockup-artifact-for-uiux-decisions

Reviewer: `code-quality-reviewer` subagent against ship commit `6dcd525`. Verdict: **0 CRITICAL · 2 MAJOR · 3 MINOR**. drive_mode=autopilot → MAJOR would auto-backlog (F39), but **both MAJORs were FIXED instead** (see Disposition) because the first invalidated a guarantee [Phase 20]'s own comment block asserts.

### Strengths
- [Phase 20] pins the **measured** load-bearing artifact (host pointers) rather than the reflexive one (skill shape), with the justifying sensitivity probe recorded inline.
- Fail-closed preconditions are separated from the assertion they protect and emit *distinct* labels — a renamed heading reports as a renamed heading, not as a missing pointer.
- `util-option-mockup/SKILL.md` conforms to the `util-*` family shape and correctly states the category's structural distinctives.
- The decision-tool-vs-WBS-prototype discriminator resolves on **what varies**, with the whole-screen edge case explicit in both the skill and the `product-wbs` pointer.
- `arch.md` was *corrected*, not merely appended to — the sentence [Phase 20] falsified was rewritten.

### Issues

**CRITICAL** — none.

**MAJOR**
- **[FIXED]** `tests/check-structure.sh` — `check_pointer()` guarded `sec_start` but gave `sec_end` **no precondition**. `awk`'s `f` flag latches at start and only clears at end; rename the end heading and the window runs to EOF, silently degrading the pin to a file-wide grep. **Independently reproduced before fixing**: renaming `### 2.` → `## Step 2 - ` and moving the pointer to EOF scored PASS. This voids the exact M2 guarantee the phase's design rests on. **The mutation sweep could not have caught it** — it mutated the pointer and the start heading, never the end boundary, so "5/5 mutations FAIL" was not evidence for this input. Fix: a third fail-closed precondition on `sec_end`; verified the defeating input now FAILs.
- **[FIXED]** The trigger contract is stated three times (skill = canonical, `feature-spec` §1 = pointer, `arch.md` = registration) with **nothing pinning the copies against each other** — the pointer pins assert the *string* appears, never that the *contract* agrees. This surface already drifted once during development (clause-(b) self-test scoped in one file, unscoped in the other two), so the risk is demonstrated. Fix: a drift pin requiring the self-test to be scoped to clause (b) in both prose copies, anchored on the scoping phrase rather than the whole sentence; verified unscoping it FAILs.

**MINOR** (auto-backlogged, priority low)
- `docs/reference/` has no README and the exemplar's `<title>` never says it is a reference artifact from another project; the only prose tying it to this feature lives in the WIP, which finalize archives.
- Mixed `grep -c` (BRE) / `grep -cE` (ERE) convention inside one 30-line function; `grep -cF` would state the literal intent.
- `check_pointer()` reads `POINTER_TARGET` from enclosing scope rather than as a parameter, slightly less self-contained than its 4-param signature implies.

### Assessment
"Well-built work whose primary weakness is a single gap in an otherwise unusually rigorous test." Both MAJORs were the same underlying shape — *assertions correct on today's inputs whose guarantee is not itself guarded* — and both were cheap to close. Shell discipline under `set -euo pipefail` confirmed sound (separate `local` decls, faithful `(... || true) | head -1` idiom, `${var:-0}` fallbacks, awk interpolation that fails loudly). `check_pointer()` judged an honest abstraction: the two calls are genuinely the same check over different coordinates. Scope discipline good — the `arch.md` edit beyond bare registration was *required*, not creep.

### Disposition
Both MAJORs **fixed in place** rather than auto-backlogged. Autopilot would normally auto-backlog MAJOR, but MAJOR-1 falsified a guarantee the phase's own inline comment asserts — shipping it would have left a comment block claiming protection the code did not provide, the same "green test that guards nothing" class this feature is otherwise careful about. Suite 592 → **596 PASS** (+4: two `sec_end` preconditions, two drift pins). MINORs backlogged as `SURFACE-2026-07-28-QUALITY-MOCKUP-ARTIFACT`.

### If you disagree
Dismiss any finding by editing this section and marking the line `[DISMISSED]` before `feature-finalize` archives this file.

## Discoveries

<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->

- [SURFACED-2026-07-28] feature-spec — `arch.md` exceeds size guard (466 lines), truncated to first 100 + headings per Step 0.
- [SURFACED-2026-07-28] repo hygiene — untracked `my-claude-code-customization` at repo root is a **self-referential symlink** (repo root → itself). Recursion hazard for tree-walkers without symlink guards. Logged as `SURFACE-2026-07-28-STRAY-SELF-SYMLINK-AT-REPO-ROOT`. Not blocking.
- [SURFACED-2026-07-28] reference recovery — the origin artifact was recovered from the session log after the scratchpad was swept (`jq` over `tool_use` Write inputs). **Session scratchpads do not survive; the JSONL log does.** Generalizable recovery technique worth a lesson if it recurs.
- [SHORTCUT-2026-07-28] P2.3 (+ P2.1) — verify-self run 1 returned **BLOCKING 7(i)** and **COSMETIC 7(h)**; both fixed in place under the §3 in-place-fix shortcut rather than an F9b back-loop. **Gate 1 (trivial extension):** both are single-sentence prose corrections inside the leaves just written — no redesign, no new abstraction, no file outside P2's scope. **Gate 2 (fresh model invocation):** a second `feature-verify-self-runner` subagent re-verified independently — confirmed [Phase 20] absent, arch.md's corrected text now matches ground truth, self-test scoped to clause (b) in all three files, 5/5 regression outcomes clean, suite 585/1. **Gate 3:** this entry.
  - **7(i) BLOCKING — the doc asserted test coverage that does not exist.** My P2.3 scope-add wrote, in bold present tense, that "`[Phase 20]` pins it for `util-option-mockup`" and *enumerated four specific assertions it makes*. `[Phase 20]` does not exist; `grep -rn 'util-option-mockup' tests/` returns zero. **I created the exact "green doc that guards nothing" failure this repo has a lesson about — while editing that very sentence to prevent a doc contradiction.** The enumerated detail made it worse: a future reader had four concrete reasons to trust it without grepping. Root cause: I corrected the sentence for the state the feature *will* be in after Phase 3, not the state it was in when I wrote it. **Rule: a doc edit describing test coverage must be written in the tense of what exists at commit time, never of what a later phase will add.**
  - **7(h) COSMETIC — cross-file scoping drift.** `SKILL.md` scoped the self-test to clause (b); my `feature-spec` pointer dropped the qualifier and said a failed self-test means "the trigger has fired" — literally readable as bypassing clause (a) and collapsing the conjunction. `arch.md` was likewise unscoped. All three now read "clause (b)".
- [SCOPE-2026-07-28] P2.3 — `arch.md`'s `util-*` category section closed with *"The category convention is forward-looking (**no structural pin yet**…). Until then, the category is doc-enforced via this section + the `util-` prefix."* Phase 3's `[Phase 20]` makes that **false**. Rewrote it to state the now-partial pinning ([Phase 19] pins the `tutorial-*` family; [Phase 20] pins `util-option-mockup`; the other two util skills stay doc-enforced, pinned per-skill as each becomes load-bearing rather than globbing `skills/util-*/`). **Small deliberate scope-add beyond AC-12**, taken because shipping a doc that contradicts the code is the exact drift this repo's three-places-in-sync rule warns about — and the contradiction would have been introduced *by this feature*.
- [ANCHOR-2026-07-28b] P2 self-check — my planned outcome said `grep -c 'util-option-mockup' skills/feature-spec/SKILL.md` returns **≥1**, but I wrote the check as `= 1`; it reported FAIL at 2. **The code was right and the check was wrong** — both hits are inside §1 and both are intentional (the recommendation line, and the pointer to the full contract). Second instance this feature of a self-check being miswritten rather than the artifact being broken (cf. `[ANCHOR-2026-07-28]`). Lesson for Phase 3: **presence pins should assert `≥1`, not `=N`** — an exact count breaks the moment prose legitimately gains a second reference.
- [SURFACED-2026-07-28] Phase 1 verify-human — **the WIP file was created with no YAML frontmatter, so it carried no `drive_mode` field**, even though the operator selected `autopilot` explicitly at session start. Gate (a) of the auto-skip rule says "if frontmatter has no `drive_mode` field, treat as Mode 2 and do NOT auto-skip" — so a pure bookkeeping omission would have silently downgraded the operator's chosen drive mode for the whole feature. Added `drive_mode: autopilot` frontmatter at Phase 1 verify-human. **Root cause: `feature-plan`'s WIP template (`skills/feature-plan/SKILL.md` §4) does not include a YAML frontmatter block at all**, while `feature-verify-human`'s auto-skip gate reads `drive_mode` from exactly that block. Two skills disagree about the file's shape. Worth a task-level fix: have `feature-plan` (and `feature-spec`) stamp `drive_mode:` into WIP frontmatter at creation. Not fixed here — out of this feature's scope.
- [SURFACED-2026-07-28] Phase 1 verify-self — the skill's `## Procedure` §3 says *"Consider loading the `artifact-design` skill"*. `artifact-design` is **harness-provided**, resolving to neither `skills/` nor `~/.claude/skills/`. The reference is advisory and conditional ("Consider"), so it is a **soft reference, not a broken dependency** — but it is the one external name in the file that this repo does not own. If the harness ever renames or drops that skill the line goes stale silently. Acceptable as-is; noted so a future reader does not mistake it for a repo-local skill.
- [PRE-EXISTING-2026-07-28] verify-auto — `./tests/check-structure.sh` reports **585 PASS / 1 FAIL** at Phase 1 baseline. The single failure is **[Phase 7] settings fixture drift** (`effortLevel: live=<missing> fixture="xhigh"`) — pre-existing and **unrelated to this feature**, which touches neither `tests/fixtures/settings.json` nor `~/.claude/settings.json`. Matches the known `project_settings_fixture_claudesk_drift` memory. **Baseline for Phase 3 is 585/1, not 586/0** — do not read this failure as feature breakage, and do not "fix" it inside this feature.
- [ANCHOR-2026-07-28] P1 self-check — the planned outcome `grep -c 'RETURN-TO:' … returns 0` **scored 1 against correct code**: it matched the skill's own `## Category` prose stating *"there is no `RETURN-TO:` line"*. This is the **naming-a-thing-to-forbid-it** mechanism from `/test-assertion-review` — a doc that forbids a token necessarily contains the token. Real emissions are line-anchored (`skills/debug-minimal-harness/SKILL.md:68`), so the anchored form `^[[:space:]]*[-*`]*[[:space:]]*`?RETURN-TO:` scores 0 here and 3 there. Outcome corrected in the tree. **Phase 3 must use the anchored form** — and the same hazard applies to any `[Phase 20]` pin asserting the *absence* of a token that the prose deliberately names (`TRANSITION:` has the identical shape, and is already handled correctly by the [Phase 19b] two-halves pattern).
