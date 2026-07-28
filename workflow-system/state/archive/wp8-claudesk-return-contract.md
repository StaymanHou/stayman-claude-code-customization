---
workflow: task
state: act (complete)
created: 2026-07-28
docs-only: true
wbs_ref: "WP8 (Milestone 12)"
drive_mode: autopilot
---

# Task: WP8 — cross-repo return contract to Claudesk (Milestone 12)

**Workflow:** task
**State:** act (complete)
**Created:** 2026-07-28

## Problem Statement

Claudesk is waiting on three deliverables from this repo before it can build its M10.9 (opt-in gate +
evangelistic invite) and M11 (workflow-docs viewer). All three are now shipped here, but nothing has
been sent back — and one of them is **actively load-bearing**: Claudesk's own M11 spec still tells a
future implementer to glob doc paths that this cycle's M7 migration deleted.

## Context

### The contract is pre-existing — do NOT invent its shape

This is the **reciprocal half of an agreement already on disk**, not a note to design from scratch.
Both ends are already written:

- **Inbound:** [`HANDOFF-from-claudesk-2026-07-20.md`](../../../HANDOFF-from-claudesk-2026-07-20.md)
  §"What Claudesk needs back from you (the return contract)" (:59-66) names exactly three items and
  says a note "e.g. a reciprocal handoff or a backlog SURFACE there" closes the loop.
- **Outbound, already authored:** `workflow-system/product/onboarding-flow-spec.md`
  **§4 "Claudesk Surface Contract (AC-3 — the M12 return-contract form)"** (:423-480) was written
  *for this delivery*, with **§4d "Return-contract delivery note (for WP8)"** spelling out the bundle.
  WP8's job is to **deliver §4a–§4c**, not to re-derive them.

### The one genuinely load-bearing finding (verified this session)

Claudesk has **already physically migrated** to the new layout — `workflow-system/product/` +
`workflow-system/state/` exist; `docs/product/`, `workflow/wip/`, `workflow/backlog.md` are **gone**
(HEAD `aacc687` "chore: migrate doc layout to workflow-system/", `main`, clean tree).

**But** claudesk's `workflow-system/product/wbs.md:60` — M11 WP2 task 2.1, still `- [ ]` **UNBUILT** —
specifies `docs_list` discovery over the **OLD** paths:

> `docs/product/*.md` (vision, roadmap, research, arch, context) + glob `*wbs*.md`,
> `workflow/wip/*.md`, `workflow/backlog.md`, `workflow/.session.md`

**Concrete risk:** building WP2 as currently specified produces a `docs_list` that finds **nothing**,
because every path it globs was migrated away. The spec is stale relative to its own repo.

**This is a SPEC correction, not a code change.** `docs_list`/`docs_read` are **not implemented
anywhere** in claudesk `src/` or `src-tauri/` (grep returned zero hits). The WBS's framing of this as
"a required change, not an optional note" predates knowing WP2 was still unbuilt — it is required, but
it lands in prose, not in Rust. Claudesk's own `roadmap.md:245` already anticipates it: *"if the
companion repo unifies the `docs/product/` + `workflow/` folders (a companion-repo deliverable),
M11's `docs_list` discovery follows that layout."*

### Decision (a) — delivery vehicle: **a reciprocal handoff doc at claudesk's root**

Both source documents name two acceptable vehicles ("a reciprocal handoff or a backlog SURFACE").
Choosing the **handoff doc**, for three reasons:

1. **Symmetry with the inbound artifact.** Claudesk sent `HANDOFF-from-claudesk-2026-07-20.md` to
   *this* repo's root. The mirror-image `HANDOFF-from-mccc-2026-07-28.md` at *claudesk's* root is the
   obviously discoverable counterpart, and it makes the loop legible from either side.
2. **A backlog SURFACE is the wrong shape for three deliverables.** The backlog's own schema is
   one-item-per-entry with a single `Suggested action`. This delivery is a bundle of three, two of
   which are pure reference pointers with no action. Forcing it into one SURFACE would either bury the
   load-bearing `docs_list` correction among two non-actions, or require three entries that fragment
   one contract.
3. **It keeps the actionable item actionable.** The `docs_list` path correction *does* warrant a
   claudesk-side backlog entry, and the handoff doc is the natural thing for it to cite — same
   relationship the inbound handoff has to this repo's five inbound SURFACEs.

**Explicitly NOT chosen: directly editing claudesk's `wbs.md:60`.** Rejected because (i) that file is
another product's active WBS spec and editing it silently is a heavier act than filing a note against
it — the operator owns that repo's plan; (ii) the correction has a real design question attached
(does `docs_list` glob `workflow-system/product/*.md` flatly, or enumerate?) that claudesk's own
`/product-wbs` should settle, not this repo's task; (iii) it would be an uncommitted cross-repo edit
in a repo this task otherwise only reads. **T4 recommends the edit and stages nothing in claudesk's
git index beyond the two new/edited files it owns.**

### Decision (b) — path facts, verified not assumed

| Old path (claudesk wbs.md:60) | New path | Verified |
|---|---|---|
| `docs/product/*.md` | `workflow-system/product/*.md` | dir exists in claudesk; old dir gone |
| `workflow/wip/*.md` | `workflow-system/state/wip/*.md` | per this repo's CLAUDE.md + claudesk layout |
| `workflow/backlog.md` | `workflow-system/state/backlog.md` | same |
| `workflow/.session.md` | `workflow-system/state/.session.md` | confirmed at this repo's CLAUDE.md:94 |
| glob `*wbs*.md` | **still holds**, now under `workflow-system/product/` | `wbs.md` present; archived cycle copies also match |

Two notes the handoff must carry so claudesk does not rediscover them:
- **`.session.md` is gitignored** (per the artifact-tracking policy) but still present on disk — so
  `docs_list` must not assume git-tracked ⇒ discoverable.
- **The `*wbs*.md` glob is deliberate** and still correct: it catches the canonical `wbs.md` *and*
  temporary/scratch WBS files (e.g. `util-backlog-paydown`'s `shape: temporary-wbs` output), which is
  why it was a glob rather than a literal in the first place.

### Decision (c) — deliverables are POINTERS, never copied prose

Copied prose drifts the moment either repo edits it. Each deliverable is delivered as a **path in this
repo that claudesk reads**, plus only the minimum inline text needed to act:

| # | Deliverable | Citable source in THIS repo | Inline in the handoff |
|---|---|---|---|
| 1 | install/uninstall copy + commands | `README.md:45-49` (clone + `./install.sh`), `install.sh`, `uninstall.sh` | the literal commands only |
| 2 | settled doc-folder layout | `CLAUDE.md` → "State persistence is per-project"; `workflow-system/product/arch.md` AD-1 | the old→new path table above |
| 3 | onboarding flow spec | `workflow-system/product/onboarding-flow-spec.md` **§4a–§4c** | the one stable coupling: `/tutorial-getting-started` |

**The anti-brittleness clause (§4c) is the most valuable thing to transmit**, because it tells claudesk
what *not* to build: the **only** stable coupling it may depend on is the command name
`/tutorial-getting-started`. Not the flow, not the steps, not the copy, not the path fork, not the
permission-mode instruction. Proven in practice — the WP7g `acceptEdits`→`auto` change landed entirely
in this repo with zero claudesk changes.

Also from §4d, and easy to miss: **the tour is self-contained in the skill install.** The greenfield
sample + scaffolder live in `skills/tutorial-greenfield-workflow-tour/scripts/`, and `install.sh`
symlinks each skill's whole directory — so an invited user gets the sample automatically. **There is
no extra sample-fetch step for claudesk to document.**

## Work Tree

- [x] T1 Re-read the two source documents and extract the exact bundle  <!-- status: complete — read the inbound handoff in full (:59-66 names the 3 items + the two acceptable vehicles) and onboarding-flow-spec.md §4 (:423-480, incl. §4d written FOR WP8). Confirmed the contract is pre-existing: WP8 delivers §4a-§4c, it does not author them. -->
- [x] T2 Author `HANDOFF-from-mccc-2026-07-28.md` at claudesk's root  <!-- status: complete — mirrors the inbound doc's structure (why-you're-getting-this / status table / deliverables / where-to-look / what-we-need-back) so the pair reads as a matched set. Leads with the ONE required change rather than burying it under two reference deliverables. All 3 deliverables are pointers; only the literal commands + the old→new path table are inlined. Carries §4c in full, plus the two work-saving facts (self-contained skill install; honest-framing is structurally pinned so invite copy must not promise 5 minutes). -->
- [x] T3 File a claudesk backlog SURFACE for the actionable half  <!-- status: complete — `SURFACE-2026-07-28-M11-DOCS-LIST-PATHS-STALE` in claudesk's workflow-system/state/backlog.md, citing the handoff doc as Source. Records that this is a SPEC correction not a code change (docs_list/docs_read unimplemented, task 2.1 still `- [ ]`), and quotes that repo's own roadmap.md:245 which already anticipated the coupling. Priority medium: zero cost now, a non-functional feature if missed. -->
- [x] T4 Recommend (do NOT apply) the `wbs.md:60` spec edit  <!-- status: complete — `wbs.md` VERIFIED UNMODIFIED in claudesk (git diff empty for that path). The Suggested action gives the corrected path list AND surfaces the design question that is Claudesk's to settle: flat glob over `workflow-system/product/*.md` (which now also picks up transitions.md + design-priors.md) vs. a curated ordered set matching WP2's stated workflow-ordered intent. Plus the two must-preserve properties (.session.md gitignored-but-present; the *wbs*.md glob is deliberate) and the archived-cycles question. -->
- [x] T5 Close the loop on this side  <!-- status: complete — CHANGELOG written FIRST (Task closed + Backlog resolved + Milestone lines), then the ONBOARDING-DESIGN block deleted per delete-on-resolve, both staged together. The `## Inbound from Claudesk` heading now reads ALL FIVE ADDRESSED and its blockquote records the 2026-07-28 closure; the section is explicitly marked history with nothing open. -->
- [x] T6 Mark WP8 done in `wbs.md` + CLAUDE.md  <!-- status: complete — wbs.md frontmatter 6/8 (which was itself stale; WP7e had already made it 7/8) → **8/8 CYCLE COMPLETE**, plus a full WP8 AS-BUILT block recording the vehicle choice, the mis-scoped-framing correction, and why the spec edit was filed rather than applied. CLAUDE.md Current Phase → 8/8 with the /product-finalize pointer. -->

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete — T1-T6 `[x]`. Two files written in claudesk (handoff doc + backlog SURFACE), committed locally there at `6a633e7`, NOT pushed; claudesk's `wbs.md` verified untouched. This side: CHANGELOG + backlog + wbs.md + CLAUDE.md updated.
- **Blocked:** none
- **Open discoveries:** none — the `docs_list` design question is deliberately Claudesk's, filed as a SURFACE in their repo rather than carried here.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->

- [SURFACED-2026-07-28] **T2/T3 — claudesk is a SEPARATE repo; commit discipline applies there too.**
  This task writes two files into `/Users/stayman/Personal/projects/claudesk` (one new handoff doc, one
  backlog edit). Per the close-commit convention, commit locally in that repo and **do not push**.
  Never `git add -A` in either repo. Claudesk is on `main` with a clean tree at `aacc687`, so the two
  new/edited files are the only working-tree delta this task should produce there.
- [SURFACED-2026-07-28] **`docs-only: true` is correct here and is a deliberate declaration.** This
  task writes only markdown — a handoff doc, a backlog entry, and WBS/status prose. It touches no
  shell script, no skill prompt, no config, and no runtime surface, so `/task-verify` may auto-skip its
  gate. (Had it edited `install.sh` or a `SKILL.md`, this would be `false`.)
