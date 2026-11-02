---
drive_mode: autopilot
---

# Feature: verify-human is for alignment — route self-drivable checks upstream, present the evidence

**Workflow:** feature
**State:** Completed 2026-11-02
**Created:** 2026-09-29
**Entry:** spec (complex feature)
**Absorbs:** `SURFACE-2026-08-02-VERIFY-HUMAN-ASKS-HUMAN-TO-RUN-MECHANICAL-CHECKS` + `SURFACE-2026-09-27-VERIFY-HUMAN-ALIGNMENT-NOT-CORRECTNESS-RULE`

## Problem Statement

`feature-verify-human` hands the operator checks the agent could have driven itself — copy-paste commands, curls, exit codes, click-throughs verify-self already covered. The §3 pre-filter keys on *whether verify-self happened to cover an item*, not on *whether the item needs the human*, so anything verify-self skipped falls through to the human by default. The §2 integration-boundary rule goes further and **mandates** a human-run `curl`. Meanwhile the checks the human is genuinely needed for are the ones where the operator holds the expected answer (intent, reference output, real-world ground truth, taste) — and those are the same checks where verify-self most often passes something wrong.


Problem statement unchanged — the F9b back-loop found missed sync spots and two prose gaps in the new rule (environment gap mistaken for undrivable; decorated TRANSITION line), not a shift in the problem.

Problem statement unchanged (F12, second-pass amendments) — the evidence refined *how* verify-human selects and presents leaves (happy path first, agent-chosen expectations as decisions, a feature-level floor) and tightened verify-self; the problem itself is the same.

Problem statement unchanged (F9b after F12) — ambiguous wording in the new rules, not a change in the problem.
## Evidence — session-log inventory (operator-mandated first step)

Corpus: every assistant-authored `## Manual Verification` block in `~/.claude/projects/-Users-stayman-*/*.jsonl` (temp/test-harness project dirs excluded) — **724 checklist blocks, 2327 items, 13 projects**. Extractor + annotated tables: session scratchpad `vh/` (`extract.py`, `annotated_pushback.md`, `annotated_other.md`).

Two annotated samples:
- **Pushback set** — all 37 blocks where the operator's reply pushed work back to the agent (89 items).
- **Stratified set** — 73 blocks across 10 projects, oversampling boundary-`curl` and `UNVERIFIED` items (225 distinct items; 198 app-project, 27 this repo).

Findings (pre-review — to be corrected by the operator):
1. **RUN-CMD asks are pure fact.** 35/35 RUN-CMD items had a pass/fail answer; 61 of 93 FACT items were fully agent-drivable, many already run upstream. The operator pushed back 37 times ("can you run it and let me review the output", "you run it, I don't need to see this").
2. **The boundary mandate is ceremony.** ~22 boundary-`curl` items: the agent often said it had already run it; only 3 were actually pasted; none produced a rejection.
3. **Seeing vs not seeing is split, not uniform.** After handing back, the operator wanted to see output ~23× and explicitly didn't ~14×, drifting toward "don't need to see" over time (Jun–Jul → Aug–Sep). Best discriminator seen: the operator wants to see when *they* know what correct looks like (518: channel data vs their own notes → "let me check"; DB round-trip → "verify this for me").
4. **The highest-yield human catches were FACT defects verify-self had passed** — slide composites vs `/sample` (543, 602), text overflow logged as cosmetic (561), focus accent not rendering (236), split-pane regression (133), game board facts (307, 607). Common cause: **the agent did not hold the expected result**, so it observed correctly and judged wrongly.
5. **DECIDE items work.** One-word decisions with options + a recommendation are kept by the operator and sometimes overridden (682, 479, 467) — the gate's real value.
6. **Ratify-my-own-change items are rubber-stamped.** Agent asking the operator to bless its plan edits / evidence gaps — approved in one word.
7. **Drivability is under-estimated.** Native-window, pty, and "would pop windows" checks were handed over as undrivable; the operator said driving them was fine (44, 85, 236).
8. **State-mutating checks were handed to the human** (TRUNCATE, DB UPDATE, `chmod 000`) — plausibly because the verify-self runner is observe-only.
9. **Real misalignment surfaced outside the checklist** in operator asides ("why is it still localhost?", "is there a web UI for CRUD?").

## Evidence — second pass (Q8, 2026-09-29)

Full corpus, corrected extraction (first-pass reply capture dropped slash-command arguments and kept injected skill text — fixed by reading the operator's real messages; all counts below use the corrected data). Session scratchpad `vh/r2_*.md`.

- **Catches at verify-human (all 727 checklists):** 164/727 checklists (22.6%) had ≥1 real catch; 203 catches. Path: **happy 132 (65%)**, decision/scope/premise 53 (26%), sad/edge 18 (9%). Kind: intent/scope 76, visual/UI 60, operator-held data/behaviour 32, agent-checkable fact 27, other 8. **Items under an edge/sad heading produced 4/203 catches.**
- **Sad paths:** 11 of 18 were UX-critical + unconventional — and almost none were on the checklist: the operator found them by exploring while running the happy path. The 7 conventional ones escaped because no test or agent drive reached them (native dialog, real restart, live external output). Several edge cases had an **agent-chosen expected value that was wrong** (82, 115, 687) — a test would have locked it in.
- **Agent-checkable facts (27, 13%):** several were already marked PASS by verify-self (a minimap, an "empty-state fixed" screenshot, output PNGs never looked at).
- **Late corrections:** common (~44), mostly after a first "you run it" hand-back; a few after an explicit approval.
- **Undrivable (79 real items):** truly undrivable 25 (physical objects, target hardware, operator's own accounts, household/domain facts, hand feel, taste without a reference, multi-day use); no harness in the project 15 (≈13 buildable — one later was: the Tauri MCP bridge); **env gap mistaken for undrivable 22** (stale build/app not launched, synthetic events instead of real OS input, the agent's own output files unread); destructive/cost 4; other 13. Stated reason matched the real one 57%. All 12 operator pushbacks were on the agent-doable part.
- **Skipped gates (300 real skips):** later in-scope defect in **20/300** (15 incidents; a floor — no comparison group of non-skipped phases). **14 of 15 were caught by a later human look in the same work package**; 1 reached production use (unquoted hook path, `99a48d5`).
- **Reliability (blind re-annotation, 91 items):** answer shape 95.6% agreement (κ 0.93); drivable 85.7% (κ 0.78). First-pass "RUN-CMD 35/35 FACT" → correctly "RUN-CMD is never JUDGMENT (22% MIXED)"; "61/93 drivable" → quote as ~55–70.

## Review Decisions (inventory review with operator)

**Q1 — routing axis (ANSWERED 2026-09-29: yes).** Route each check on two questions — *can the agent drive it?* and *does the agent hold the expected result?* — not on fact-vs-judgment.

| | Agent holds the expected result | Only the operator holds it |
|---|---|---|
| **Agent can drive it** | verify-auto / verify-self; never a verify-human leaf | agent runs it; verify-human presents captured evidence + one alignment question |
| **Agent cannot drive it** | rare — usually drivability under-estimated | operator runs it; agent asks only for the minimal input |

The "only the operator holds it" column contains three kinds: (1) rendered output vs a reference or taste (visual), (2) data/behaviour whose ground truth is the operator's (domain meaning, own files), (3) decisions. A command's pass/fail is never there; a command's *output content* can be, when it is domain data (646, 518). When a reference exists on disk (`/sample`), verify-self must compare against it (543, 602, 561 were catchable upstream).

Evidence behind the refinement: of 18 real catches in the annotated sample — 8 visual/UI, 4 operator-held data/behaviour, 6 decision overrides/extensions, **0 from RUN-CMD items**.

**Q2 — what verify-human shows for agent-driven, agent-judged checks (ANSWERED 2026-09-29: digest).** Never a leaf. verify-human opens with an **"Already verified by agent" digest** — one line per check (what ran, result, key output line), no action asked; the operator can pull any line back ("show me that one"). Guards against a silently-disappearing check class (the backlog's over-routing risk). Evidence: after hand-back, ~23× "let me see" vs ~14× "don't need to see", drifting toward the latter.

**Q3 — zero-leaf phases (ANSWERED 2026-09-29: agree).** One rule replaces both the boundary "F11 forbidden + human-run curl" mandate and the 4-gate auto-skip: **zero alignment leaves → phase advances, digest always printed.** Mode 3 advances without asking (digest = read-time veto); Mode 2 asks one line ("Nothing here needs you — continue?"); Mode 4 unchanged (skipped). The integration boundary still binds — but upstream: verify-self must drive the consuming surface and it appears in the digest. Accepted risk: a boundary phase can pass autopilot unseen if the digest isn't read.

**Q4 — state-changing checks (ANSWERED 2026-09-29: agree).** The verify-self runner stays observe-only by default. A state-changing step is allowed only when `feature-plan` **declares** it in the Observable Outcome AND it targets the project's own dev/test environment (dev DB, local container, a named temp file). **Never:** git operations; shared, production, or paid resources (fal/LLM spend, external accounts); anything outside the project dir. Undeclared or out-of-fence steps stay a verify-human leaf, marked `destructive — needs your OK` — never silently skipped.

**Q5 — operator-stated at Phase 1 verify-human (2026-09-29).** *"The agent can probably judge if a behavior matches the spec. But me saying 'yes' when doing feature-spec may not indicate that I fully realise its implication until I see the implementation in action."* So spec-conformance is agent-checkable and moves upstream, but **spec approval is not informed consent**: the first time a spec decision's consequence becomes visible, verify-human shows it in action (captured evidence) and asks "now that you see it, is this still what you want?" — not "does it match the spec?". Priority goes to the spec's **Assumed** list (defaults the operator never saw as a question) and to decisions whose consequence is behavioural rather than textual.

**Q6 — operator-stated at Phase 2 verify-human (2026-09-29).** *"Happy path is implied in 'Does this match what you meant?' … it should prioritize the happy path whenever applicable, and in most cases leave sad path to verify-codify, except one that would be critical to the UX and unconventional."* → alignment leaves lead with the happy path; sad paths go to verify-codify (tests), except a sad path that is both UX-critical and unconventional.

**Q7 — operator-stated at Phase 2 verify-human (2026-09-29).** Genuinely undrivable cases remain the human's: a UI framework with no driver/MCP for the agent, a legacy project with no dev environment and no tests. Distinguish from the environment gap already handled (a server that exists but is stopped → the agent starts it).

**Q8 — operator asked for a second, comprehensive pass over the evidence (2026-09-29)** — pending scope confirmation.

**Q9 — second-pass amendments (ANSWERED 2026-09-29: "all good").** (1) happy path first — no edge-case sections; (2) the operator's sad-path exception cannot be picked at plan time (the exception-class sad paths were found by exploring) → alignment items invite the operator to try the happy path in the running thing; a sad path goes to verify-codify only when a test can reach it, else verify-self drives it with real input or it is genuinely undrivable; (3) an expected behaviour the agent had to choose (spec silent) is a Decision leaf, never silently baked into a test; (4) verify-self stricter — open what you produced, real OS input over synthetic events, rebuild/launch before calling anything undrivable, and for no-harness say once whether one could be built; (5) **feature-level floor** — if every earlier phase of the feature advanced with zero operator leaves, the last phase's verify-human carries one "see it in action" leaf (main happy path end to end + the spec defaults it depends on) before ship. FSD (Mode 4) still skips verify-human entirely — the operator opted out.

## User Stories
- As the operator, I want verify-human to ask me only what I alone can answer — does this match what I meant, is this output right against what I know, which option do I pick — so my attention goes where it catches real defects.
- As the operator, I want every check the agent could drive to be driven upstream and shown to me as a one-line digest, so I never copy-paste a command, and I can still pull any line back.
- As the operator in autopilot, I want a phase with nothing for me to advance on its own with the digest printed, so autopilot does not stop for ceremony.
- As the agent at verify-self, I want a clear rule for which state-changing steps I may run, so I neither hand destructive checks to the human by reflex nor improvise a mutation.

## Acceptance Criteria
- **AC-1 Admissibility rule (`feature-verify-human` §2/§3).** A leaf is admissible only if (a) the operator holds the expected result — rendered output vs a reference/taste, or data/behaviour whose ground truth is theirs — or (b) it is a decision, or (c) the agent genuinely cannot drive it (physical hardware, the operator's own account/files, external access), or (d) it is an out-of-fence destructive step (Q4), or (e) it shows a spec decision's consequence **in action for the first time** (Q5) — the question is "now that you see it, still what you want?", never "does it match the spec?" (spec-conformance itself is agent-checked upstream). A command's pass/fail is never a leaf. The pre-filter keys on this rule, not on "did verify-self happen to cover it."
- **AC-2 Fixed checklist shape.** verify-human presents, in order: **Already verified by agent** (digest: one line per check — what ran, result, key output line; no action asked); **Does this match what you meant?** (each leaf shows the captured evidence + one alignment question); **Decisions** (options + recommendation); **Needs you to run** (agent-undrivable, with why + the minimal input needed); **Destructive — needs your OK**. Empty sections are omitted. Agent-ratify items ("accept my plan edit / evidence gap") are not leaves — they go in an **Assumed** list under the digest.
- **AC-3 Zero-leaf rule replaces the boundary mandate and the 4-gate auto-skip.** Zero leaves → Mode 3 emits F11 without asking (digest printed as read-time veto); Mode 2 asks one line; Mode 4 unchanged. The "F11 forbidden on boundary + human-run curl" text and the 4-gate block (incl. its known-limitation note) are removed. `transitions.md`, `agents/feature-workflow/AGENTS.md`, the verify-human cheat-sheet, and `session-start`'s S12 description agree.
- **AC-4 verify-self drives what moved upstream (`feature-verify-self` + `feature-verify-self-runner`).** On an integration boundary, verify-self drives the consuming surface and records captured evidence for the digest. When a reference exists on disk (sample images, expected output), it compares against it. "Not Playwright-shaped" (TTY via pty, native window, interactive CLI, popping windows) is never a reason to defer; `UNVERIFIED` requires a stated reason the check cannot be driven.
- **AC-5 Mutation fence (runner `AGENTS.md`).** Observe-only default; declared-only, dev/test-only state changes per Q4; an explicit prohibition list (`git stash`/`checkout`/`reset`/`clean`/`commit`, shared/prod/paid resources, outside the project dir). The same git prohibition goes into `agents/code-quality-reviewer/AGENTS.md`.
- **AC-6 verify-auto owns deterministic checks of changed code and config,** including the consuming config surface (e.g. `npm run check` after a tsconfig edit); verify-human never re-asks for one.
- **AC-7 `feature-plan` authoring.** Every correctness outcome is written so the agent can drive it; state-changing steps are declared in the outcome; each phase gets a separate **Alignment questions** list (the operator-held checks), kept apart from Observable Outcomes, and seeded from the spec's decisions — **Assumed** items first — whose consequence first becomes visible in that phase (Q5).
- **AC-8 `drive_mode` is stamped into WIP frontmatter** by `feature-spec` §3 and `feature-plan` §4 at file creation, from the active session mode (so AC-3's Mode-3 path actually fires).
- **AC-9 Tests.** Structural pins for AC-1…AC-8 surfaces (via `/test-assertion-review`), plus behavioral scenarios: a boundary phase with all-PASS verify-self and no alignment questions → F11 with digest in Mode 3; a RUN-CMD candidate never appears as a leaf; a visual-vs-reference outcome → an alignment leaf carrying evidence; an undeclared destructive step → a `destructive` leaf. Existing scenarios asserting the old boundary/auto-skip behaviour are updated or retired, each discrimination-tested by deleting the prose it guards.
- **AC-10 Docs.** `arch.md` revision entry; root `CLAUDE.md` "Integration-boundary rule" bullet rewritten; both absorbed SURFACEs plus `SURFACE-2026-07-28-WIP-TEMPLATE-OMITS-DRIVE-MODE-FRONTMATTER` and `SURFACE-2026-07-29-WIP-DRIVE-MODE-FRONTMATTER-BLOCKS-AUTOSKIP` resolved at finalize.

## Out of Scope
- `task-verify` (task workflow) and `incident-codify` — same smell may exist; not changed here.
- A new transition ID — F11/F12/F13 keep their meanings; only F11's trigger condition changes.
- Enforcing the mutation fence mechanically (hooks, tool restrictions) — the fence is prompt-level, like the existing observe-only contract.
- `task-plan` / `incident-report` `drive_mode` stamping.
- Persisting the raw annotated inventory in the repo (it quotes other projects, incl. work ones); the condensed evidence in this WIP is the record.

## Technical Constraints
- `feature-verify-self-runner` is **observe-only** by contract (and `SURFACE-2026-07-27-VERIFY-SELF-RUNNER-MUTATED-WORKING-TREE` shows the tool surface does not enforce it). Any front-loaded check that mutates state (migrations, DB writes, TTY-driven CLIs that write) needs an explicit ruling on which stage may run it.
- verify-self spawns its runner unconditionally; front-loading is a **routing** change, not a new capability (runner already holds Playwright + Bash).
- The Mode-3 auto-skip gate (a) reads `drive_mode` from WIP frontmatter; `SURFACE-2026-07-28-WIP-TEMPLATE-OMITS-DRIVE-MODE-FRONTMATTER` / `SURFACE-2026-07-29-WIP-DRIVE-MODE-FRONTMATTER-BLOCKS-AUTOSKIP` mean it rarely fires today — relevant if the taxonomy simplifies the gates.
- State machine sync: any transition change touches `transitions.md`, SKILL.md prose, and `tests/scenarios/*.yaml`; the pause-policy cheat-sheets in the four touched skills must stay consistent with `agents/feature-workflow/AGENTS.md`.
- Assertions in `tests/` require `/test-assertion-review` first.

## Open Questions
- [x] Joint inventory review with the operator — Q1–Q4 answered (see Review Decisions). No research unknowns remain.

## Asked / Assumed

**Asked:** Q1 routing axis → yes (refined to three operator-held kinds); Q2 agent-judged checks → digest; Q3 zero-leaf phases → advance, digest printed; Q4 state-changing checks → declared, dev/test-only fence.

**Assumed (not asked — cheap to reverse or implied):**
- The fixed section headings in AC-2 replace the current ad-hoc ones (logs showed headings invented per block).
- Agent-ratify items move to an Assumed list, not a leaf (Q1 package; logs: always one-word approvals).
- No standing "anything else off?" intent-check leaf — misalignment asides already happen unprompted; revisit if they stop.
- `drive_mode` stamping (AC-8) is in scope because AC-3's Mode-3 path is dead without it.
- The code-quality-reviewer gets the same git prohibition (cheap, same near-miss class).
- In-flight WIPs in other projects pick the new rules up at their next verify-human; no migration.
- Raw inventory stays out of the repo (see Out of Scope).

## Work Tree

**Test env note:** on this machine the pyenv `python3` lacks `pyyaml`, so every suite runs as `PATH=/usr/bin:$PATH <cmd>`. Baseline under that PATH: `check-structure.sh` → **596 PASS / 1 FAIL** (the pre-existing settings-fixture drift). "No new FAIL" below means the `[FAIL]` set equals that baseline. **Bootstrap-skip:** edited SKILL.md prose is not served to this session's own Skill calls — behavioral checks go through `tests/run-tests.sh` (fresh subprocess).

- [x] Phase 1: Upstream stages own what moves out of verify-human
  **Observable outcomes:**
  - CLI: `PATH=/usr/bin:$PATH ./tests/check-structure.sh` → `[FAIL]` set identical to baseline (only settings-fixture drift)
  - CLI: `grep -n "drive_mode:" skills/feature-plan/SKILL.md skills/feature-spec/SKILL.md` → ≥1 hit in each file, inside the WIP template's leading frontmatter block
  - CLI: `grep -c "Alignment questions" skills/feature-plan/SKILL.md` ≥ 1 and the template shows it as a per-phase block separate from `**Observable outcomes:**`
  - CLI: `grep -E "CAPTURED|^evidence:|evidence:" agents/feature-verify-self-runner/AGENTS.md` → both the `CAPTURED` status and an `evidence:` result field present
  - CLI: `grep -E "git stash" agents/feature-verify-self-runner/AGENTS.md agents/code-quality-reviewer/AGENTS.md` → hit in each file, inside a prohibition list
  - CLI: `PATH=/usr/bin:$PATH ./tests/run-tests.sh --id F-boundary-self` → PASS (existing verify-self boundary behaviour preserved)
  **Alignment questions:**
  - Does the mutation-fence wording (declared + dev/test-only; never git/shared/prod/paid/outside project) read as the line you agreed in Q4?
  - [x] P1.1 `feature-plan` §4: stamp `drive_mode:` frontmatter in the WIP template (from the active session mode); add per-phase **Alignment questions** block; authoring rules — every correctness outcome agent-drivable (pty/native/interactive included), state-changing steps declared in the outcome, operator-held checks go to Alignment questions not Observable outcomes
  - [x] P1.2 `feature-spec` §3: stamp `drive_mode:` frontmatter in the WIP template
  - [x] P1.3 `feature-verify-auto`: ownership line — deterministic checks of changed code/config incl. the consuming config surface; verify-human never re-asks for one
  - [x] P1.4 `feature-verify-self` SKILL.md: boundary ⇒ drive the consuming surface + capture evidence for the digest; compare against an on-disk reference when one exists; "not Playwright-shaped" never defers; `UNVERIFIED` needs a stated undrivable reason; pass Alignment questions to the runner for evidence capture; record evidence lines in the WIP tree
  - [x] P1.5 `feature-verify-self-runner` AGENTS.md: `evidence:` field per result row; `CAPTURED` status for alignment-question evidence (no PASS/FAIL judgment); pty/native driving; mutation fence (observe-only default, declared dev/test-only changes, explicit prohibition list); reconcile "do NOT modify any files"
  - [x] P1.6 `code-quality-reviewer` AGENTS.md: same git prohibition list
  - [x] verify-auto — evidence: `PATH=/usr/bin:$PATH ./tests/check-structure.sh` → 596 PASS / 1 FAIL, `[FAIL]` set == baseline (settings drift only); frontmatter YAML parses for all 6 edited files
  - [x] verify-self (runner `feature-verify-self-runner`, 6 outcomes + 1 alignment capture)
    - [x] check-structure `[FAIL]` set == baseline — evidence: `PATH=/usr/bin:$PATH ./tests/check-structure.sh` → exit 1, 596 PASS / 1 FAIL (settings-fixture drift only)
    - [x] `drive_mode:` in both templates — evidence: grep → feature-plan/SKILL.md:102, feature-spec/SKILL.md:126, each first key inside the template's leading `---` block
    - [x] Alignment questions block separate — evidence: `grep -c` → 2; plan template line 117 `**Observable outcomes:**`, line 122 `**Alignment questions:**`, rule at line 161
    - [x] runner `CAPTURED` + `evidence:` — evidence: runner AGENTS.md:71 `status: PASS | FAIL | UNVERIFIED | CAPTURED`, :74 `evidence: …`
    - [x] git prohibition in both subagents — evidence: runner AGENTS.md:60 "Never … `git stash`, `git checkout`, …"; code-quality-reviewer AGENTS.md:15 "`Bash` is for reading only. Never run `git stash` …"
    - [x] `F-boundary-self` behaviour preserved — evidence: harness verdict SOFT_PASS (exit 0) on the edited skill; runner flagged it BLOCKING because the literal outcome said PASS. A/B measured: committed skill **0/4 PASS (4/4 SOFT_PASS)**, edited skill **1/5 PASS (4/5 SOFT_PASS)** — the scenario never reached structured `F9b` before this change, so not a regression; plan outcome was written assuming a PASS baseline that did not exist. SURFACED below.
    - [x] align: mutation-fence wording as agreed in Q4 — evidence: runner AGENTS.md lines 54–62 `## Mutation fence` (quoted in the verify-human checklist)
  - [x] verify-human — operator: "looking good" (all three) + Q5 refinement, applied to spec + feature-plan rule
    - [x] P1.verify-human.1 align: mutation-fence wording matches Q4
    - [x] P1.verify-human.2 align: Alignment-questions rule in feature-plan matches Q1 — approved; extended per Q5 (seed from spec decisions, Assumed first)
    - [x] P1.verify-human.3 boundary evidence: F-boundary-self A/B read as pre-existing weakness, not regression — accepted
  - [x] verify-codify
    - [x] `[Phase 23]` in `tests/check-structure.sh` — 6 section-scoped pins (plan §4 drive_mode + Alignment block + 2 rule anchors; spec §3 drive_mode; runner result block CAPTURED + evidence; runner mutation fence; reviewer read-only Bash; verify-self Driving scope). Reviewed via `/test-assertion-review` (AT-RISK → fixed: emphasis anchor replaced, both boundaries fail closed, anchors in arrays). Live: 602 PASS / 1 FAIL (baseline drift). Sweep on copies: **56 cases, 0 wrong** — each anchor deleted, each anchor moved to EOF, each end boundary removed, each start boundary removed, nonexistent file → all FAIL; 6 live → PASS.
    - [x] Scenario regression batch for edited skills (19) — evidence: `run-tests.sh --id …` → 10 PASS / 6 SOFT / 1 FAIL / 2 FLAKY-passed-on-retry, $1.88, 459s (`tests/results/run-2026-09-29-111908.json`). F3 FAIL triaged below as pre-existing flaky. SOFTs F1/F28/F29/F-boundary-self match their prior history; F10b-shortcut/F24 have no prior record.

- [x] Phase 2: verify-human asks only operator-held questions; zero-leaf rule
  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — operator approved Phase 1 and added Q5
  - Requirements unchanged: yes — Q5 refines AC-1/AC-7 (spec decision in action), already folded in
  - Solution still feasible: yes
  - No superior alternative discovered: yes
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `grep -c -E "F11 skip path is forbidden|copy-paste-run|Auto-skip gate \(Mode 3" skills/feature-verify-human/SKILL.md` → 0
  - CLI: `grep -c -E "^### (Already verified by agent|Does this match what you meant\?|Decisions|Needs you to run|Destructive — needs your OK)" skills/feature-verify-human/SKILL.md` → 5 (inside the §4 checklist template)
  - CLI: `grep -n "zero" workflow-system/product/transitions.md agents/feature-workflow/AGENTS.md skills/session-start/SKILL.md skills/feature-verify-human/SKILL.md` → the F11/verify-human rows in all four describe the zero-leaf rule; no remaining "no integration boundary + verify-self all-PASS" auto-skip wording (`git grep -c "no integration boundary + verify-self all-PASS"` → 0)
  - CLI: `PATH=/usr/bin:$PATH ./tests/check-structure.sh` → `[FAIL]` set identical to baseline (old-text pins at lines ~184–186 and the `F11 (AUTO-SKIP` cheat-sheet comparator updated in this phase, not left failing)
  - CLI: `PATH=/usr/bin:$PATH ./tests/run-tests.sh --id F11,F-boundary-human,F-verify-human-auto-skip-fires,F-verify-human-auto-skip-blocked` → all PASS against their updated expectations
  **Alignment questions:**
  - A rendered sample verify-human output for a boundary phase (digest + one alignment leaf + one decision): is this the shape you want to read?
  - [x] P2.1 `feature-verify-human` §2: replace boundary mandate + 4-gate auto-skip + known-limitation note with the admissibility rule (AC-1) and the zero-leaf rule (AC-3, Modes 2/3/4)
  - [x] P2.2 `feature-verify-human` §3/§4: pre-filter keyed on admissibility; fixed five-section checklist + Assumed list under the digest (AC-2); leaf expansion from the phase's Alignment questions + decisions + undrivable + out-of-fence items
  - [x] P2.3 `feature-verify-human` cheat-sheet + §8 F11 wording
  - [x] P2.4 State-machine sync: `transitions.md` (Drive modes table + F11 row + boundary rule §311), `agents/feature-workflow/AGENTS.md` (row + AUTO-SKIP paragraph), `skills/session-start/SKILL.md` (S12, mode table, menu line); `feature-verify-self` edge-pause paragraph's "auto-skip gate" reference
  - [x] P2.5 [as built: comparator row prefixes kept (`F11 (human-confirmed`, `F11 (AUTO-SKIP`) so no comparator edit was needed; `F-verify-human-auto-skip-blocked` replaced by `F-verify-human-boundary-digest-advances` (the old one asserted the removed behaviour); two new fixtures `feature-verify-human-boundary-evidence.md` / `-no-evidence.md` so the shared `wire-into-existing` fixture stays untouched; `tools/replay-paired.sh` left as-is — it is a frozen measurement arm quoting the old prose] Downstream contract impacts: `tests/check-structure.sh` old-text pins (auto-skip affirmation line, 4-gate heading, `F11 (AUTO-SKIP` comparator row) → re-anchor on new text (via `/test-assertion-review`); update scenarios `F11`, `F-boundary-human`, `F-verify-human-auto-skip-fires`, `F-verify-human-auto-skip-blocked` + fixture `feature-verify-wire-into-existing.md` to the new rules
  - [x] P2.6 verify-human §2/§4 + feature-plan Alignment-questions rule: happy path first; alignment leaf invites trying the happy path in the running system; no sad-path listing; sad path → verify-codify only if a test can reach it, else verify-self drives it with real input or it is (d) (Q6, Q9.1–2)
  - [x] P2.7 verify-human (c) + feature-plan: an expected behaviour the agent chose where the spec was silent is a Decision leaf (Q9.3)
  - [x] P2.8 feature-verify-self + runner: open what you produced; real OS input over synthetic events; rebuild/launch before undrivable; kind (d) sub-types (truly undrivable list vs no-harness — say once whether a harness could be built) (Q7, Q9.4)
  - [x] P2.9 verify-human feature-level floor (Q9.5) — last phase + every earlier phase zero-leaf → one "see it in action" leaf; Modes 1–3; FSD unchanged; sync the floor into AGENTS.md AUTO-SKIP prose + transitions.md F11 row
  - [x] verify-auto — evidence: `PATH=/usr/bin:$PATH ./tests/check-structure.sh` → 602 PASS / 1 FAIL (baseline settings drift; re-anchored zero-leaf pins PASS); frontmatter YAML parses (verify-human, session-start, feature-workflow AGENTS); `tests/scenarios/feature.yaml` parses and `run-tests.sh --dry-run` lists the 4 updated scenarios · **re-run after F9b:** check-structure 602 PASS / 1 FAIL (baseline); `bash -n tests/run-tests.sh` ok (TEST_DUMP_DIR hook); feature.yaml + AGENTS.md frontmatter parse · **re-run after F12:** check-structure 602/1 (baseline); frontmatter parses for the 5 edited files; `#### Feature-level floor` heading present; checklist template ids renumbered 1–6 · **re-run after F9b #2:** check-structure 602/1 (baseline); verify-human frontmatter parses; §2 Steps 1–5 present (5 step headers + 5a/5b) · **re-run after F9b #3:** check-structure 602/1; feature.yaml + verify-human frontmatter parse; 2 new fixtures present
  - [x] verify-self — re-run after F9b (fresh runner): 5/5 outcomes PASS — removed phrases 0; five headings at l.118–132 inside the §4 fence; all F11/verify-human rows (transitions.md 42/70/337, AGENTS.md 95/175/208, session-start 42/54, verify-human 23/34/36–37/72–80) describe the zero-leaf rule, retired phrases 0; check-structure 602/1 (baseline); 4 scenarios PASS first attempt, 0 SOFT (`tests/results/run-2026-09-29-115846.json`). Runner also flagged root `CLAUDE.md:162` still stating "verify-human cannot use the F11 skip path" — already scheduled as P3.3.
    - [x] align: sample boundary-phase verify-human output — evidence: scratchpad `vs2/F-verify-human-boundary-digest-advances-attempt1.txt` (digest of 5 lines incl. "Consuming surface: POST /distribution/match → 200, mp-031", then "Nothing here needs you — advanced per drive_mode=autopilot.", `TRANSITION: F11`)
    - [x] P2.verify-self.1 removed phrases absent — evidence: `grep -c -E "F11 skip path is forbidden|copy-paste-run|Auto-skip gate \(Mode 3"` → 0
    - [x] P2.verify-self.2 five checklist headings — evidence: `grep -c` → 5, lines 117–131 inside the §4 template
    - [x] P2.verify-self.3 state-machine sync — fixed in F9b: AGENTS.md l.61 (stage summary), l.95 (F11 transition row), l.133 (skip-confirmation rule) rewritten to the zero-leaf rule; re-verify: `grep -n "human confirms skip\|explicit human confirmation" agents/feature-workflow/AGENTS.md` → 0
    - [x] P2.verify-self.4 check-structure `[FAIL]` set == baseline — evidence: 602 PASS / 1 FAIL
    - [x] P2.verify-self.5 4 verify-human scenarios — fixed in F9b (3 prose changes to feature-verify-human: environment gap ≠ undrivable in kind (d); a missed upstream check is never a leaf / never a command for the operator; the zero-leaf rule gained an explicit boundary-evidence **precondition** at the F11 decision point; plus TRANSITION-line-carries-the-ID-alone) and the F-boundary-human assertion tightened (strict `### Needs you to run` failure-proxy; verified via `verify_result` both directions: captured bad output rc=2, good back-loop rc=0, endpoint-missing rc=2). Re-verify evidence (same depth, haiku): F-boundary-human **1/6 before the precondition move → 6/6 after**; F-verify-human-boundary-digest-advances 6/6 then 3/3 after; F-verify-human-auto-skip-fires 3/3 after; F11 PASS (runner run). Harness: `run-tests.sh` gained opt-in `TEST_DUMP_DIR` (per-attempt model output) — the diagnosis was impossible without it.
    - [x] P2.verify-self.align sample verify-human output — evidence: captured via `TEST_DUMP_DIR` (runner could not: results JSON stores no model output → harness gained opt-in `TEST_DUMP_DIR`); samples in session scratchpad `dump/`
    - [x] P2.verify-self.F12 after-F12 re-run: 5/7 PASS → fixed in F9b: "Happy path first" rewritten as an ordering rule that creates no leaf on its own; floor now says "any later phase NOT-STARTED → not the last phase, skip"; Assumed list limited to process choices that do not change what ships; `(decision)` align items → Decisions; template leaf 1 marked "(only if admissible)". [was: coherence read — "Happy path first" read as a mandatory leaf, clashing with zero-leaf + floor; live 2/6 attempts paused non-last phases (auto-skip-fires attempt1 applied the floor to Phase 1 with Phase 2 NOT-STARTED; digest-advances attempt1 made the consuming surface a "Main flow" leaf). Minor: Assumed list overlaps kind (c); sorting table sends all `align:` to "Does this match" though `(decision)` belongs in Decisions ] Re-verify (haiku, same depth): after the first wording fix digest-advances 4/6 + auto-skip-fires 5/6 and F-boundary-human regressed 1/3 → §2 **restructured into an ordered Steps 1–5 procedure** (digest → boundary evidence stop → five named sources only → order → zero-leaf with floor 5a / advance 5b) → 4 scenarios ×6: boundary-human 5/6, digest-advances 5/6, auto-skip-fires 3/6 (all 6 transitioned F11; misses printed a prose summary instead of the digest), F11 4/6 → 5b now requires the digest in §4 format → digest-advances 4/6 + auto-skip-fires 5/6 first-attempt (**9/12**; all pass on harness retry). Sonnet ×6: auto-skip-fires 5/6, digest-advances 2/6 — sonnet did not open the fixture under testing mode (SURFACE-2026-09-29-SONNET-NARRATES-INSTEAD-OF-READING-FIXTURE); not a prose defect, no sonnet tag.
    - [x] P2.verify-self.F9b3 third runner (after the Steps 1–5 restructure): 3/5 PASS → fixed in F9b #3: (1) verify-self `FAILED` (BLOCKING) or `NOT-STARTED` had no home under the five-source rule and could be advanced past with F11 → Step 2 now back-loops F12 on either, §3 table row updated; (2) scenarios F11/F12/F13 used a fixture with verify-self NOT-STARTED (obsolete under Step 2 — triaged) → two new fixtures with verify-self evidence (`feature-verify-self-passed-backend.md`, `…-align.md`); F12's rejection text reworded to answer the presented alignment leaf (triaged). Re-verify (haiku; F13 sonnet-tagged): F11 3/3, F13 3/3, F12 0/3 → 2/3 after the reword (retry passes), F-boundary-human 2/3, auto-skip-fires 2/3, digest-advances 2/3 first-attempt; all pass on retry. check-structure 602/1.
    - [x] P2.verify-self.F9b4 fourth runner: 3/4 PASS → shortcut fix (see Discoveries SHORTCUT-2026-09-29) → fresh coherence re-read 2/2 PASS: all 10 cases resolve to one outcome; F12 descriptions include the Step 2 back-loop; row (a) now excludes `(decision)` items explicitly.
  - [x] verify-human
    - [x] P2.verify-human.1 align (a): sample boundary-phase output shape — "all good"
    - [x] P2.verify-human.2 align (b): unreached consuming surface → back-loop — "all good", with Q7 nuance (a surface that CANNOT be driven in this project is still the human's)
    - [x] P2.verify-human.3 align (b, Assumed): five fixed section headings — "all good"; Q6: happy path lives in "Does this match what you meant?"
    - [x] P2.verify-human.4 operator review of the second-pass evidence → amendments built (P2.6–P2.9) and re-presented in action — "all good" (incl. operator-reported defect → Decision "fix now or defer?" handling)
  - [x] verify-codify
    - [x] `[Phase 24]` in `tests/check-structure.sh` — 5 pins (§2 ordered procedure: 10 anchors; §4 five sections; verify-self stricter driving rules; floor named in transitions.md F11 row and AGENTS.md AUTO-SKIP prose), reusing [Phase 23]'s fail-closed `check_section_anchors`. Live 607 PASS / 1 FAIL (baseline). Sweep on copies: **56 cases, 0 wrong**.
    - [x] Re-anchored the old auto-skip pins (zero-leaf advance line + heading) during P2.5; scenarios updated/replaced: F-boundary-human, F-verify-human-auto-skip-fires, F-verify-human-boundary-digest-advances (new), F11/F12/F13 + F13-prefiltered (new fixtures; triaged obsolete), F12 reply reworded (triaged).
    - [x] Regression batch (19: verify-human ×9, verify-self ×6, session S7/S8/S12/S14) — 12 PASS / 4 SOFT / 1 FAIL / 2 FLAKY (`tests/results/run-2026-09-29-155456.json`, $2.14). FAIL = auto-skip-fires, triaged flaky (re-run 3/3 pass). SOFTs (F-boundary-self, S7, S12, S14) match their recorded history.

- [x] Phase 3: New behavioral coverage + docs
  **Relevance check (before Phase 3):**
  - Requester still needs this: yes — Phase 2 approved "all good"
  - Requirements unchanged: yes — Q5–Q9 already folded into Phases 1–2
  - Solution still feasible: yes
  - No superior alternative discovered: yes
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `PATH=/usr/bin:$PATH ./tests/run-tests.sh --id <new scenario IDs>` → all PASS, each run ≥6× (per the sample-size rule): RUN-CMD never a leaf; visual-vs-reference → alignment leaf with evidence; undeclared destructive → `destructive` leaf; agent-chosen expected value → Decision leaf; feature-level floor fires on the last phase of an all-zero-leaf feature
  - CLI: each new scenario FAILs when the verify-human prose it guards is deleted (discrimination test, recorded in Discoveries)
  - CLI: `PATH=/usr/bin:$PATH ./tests/check-structure.sh` → baseline `[FAIL]` set + new pins PASS
  - CLI: `grep -n "Revision 2026-09-29" workflow-system/product/arch.md` ≥1; root `CLAUDE.md` "Integration-boundary rule" bullet no longer says verify-human cannot use F11
  - [x] P3.1 New scenarios + fixtures (4) in `tests/scenarios/feature.yaml`, anchored on output vocabulary from a live capture [as built: F-vh-align-visual, F-vh-destructive, F-vh-decision, F-vh-floor; fixtures renamed neutral `notif-prefs-a..d.md`; one shared neutral prompt naming the fixture path + conditional approve-all reply; all expect F13]
    - [x] P3.1-measure — evidence (2026-11-02, haiku): **new prose 24/24 first-attempt** (6 rounds × 4); **old prose (git HEAD) 0/12** incl. retries (F-vh-floor → F11 2/3, others miss the required section). Path to get there: (1) dumps showed 8/8 runs never read the fixture (no Glob, Read EISDIR on the dir, shell forbidden) → name the path in the prompt, rename fixtures neutral so the name cannot recite the answer; (2) floor fixture carried a spec Assumed list, so leaves came from source (b) not the floor → list removed; (3) F-vh-decision passed old prose 2/5 (model invents `### Decisions` from the "(decision)" label, and handed the operator a curl) → also requires "Already verified by agent" (new 24/24 outputs, old 0/23); re-scored on the real dumps: new 6/6, old 0/3. /test-assertion-review CLEAR. Root cause logged on SURFACE-2026-09-29-SONNET-NARRATES-INSTEAD-OF-READING-FIXTURE.
  - [x] P3.2 New structural pins for AC-1…AC-8 surfaces, section-scoped (via `/test-assertion-review`) [as built: delivered earlier as `[Phase 23]` (Phase 1 codify) and `[Phase 24]` (Phase 2 codify), both sweep-verified 56/0]
  - [x] P3.3 Docs: `arch.md` revision entry; root `CLAUDE.md` Integration-boundary bullet — `arch.md` "Revision 2026-09-29" + frontmatter `updated:`; root `CLAUDE.md` Integration-boundary bullet rewritten + new "verify-human is for alignment" bullet
  **Verify simplification (operator, 2026-11-02):** "with my experience so far using the new version of the skill, I'm already pretty happy with it" — Phases 1–2 have been live (symlinked) since 2026-09-29. Phase 3 has no Alignment questions and the floor does not apply (Phases 1–2 had operator leaves), so: verify-auto = one check-structure run; verify-self = direct check of the 4 outcomes (no runner spawn); verify-human = zero-leaf, operator live-use statement recorded as evidence; verify-codify = the 4 new scenarios are the codification, recorded, no extra sweep.
  - [x] verify-auto — evidence: `PATH=/usr/bin:$PATH ./tests/check-structure.sh` → exit 1, 607 PASS / 1 FAIL, `[FAIL]` set == baseline (settings-fixture drift only; its drifted keys are now effortLevel/idleCompaction/modelSettings — live-settings churn, same assertion); `tests/scenarios/feature.yaml` parses; `run-tests.sh --dry-run` lists the 4 new scenarios
  - [x] verify-self (direct check, no runner spawn — operator-simplified 2026-11-02)
    - [x] P3.verify-self.1 new scenarios ≥6× all PASS — evidence: 6 rounds × 4 scenarios → 24/24 PASS first attempt (`tests/results/run-2026-11-02-15*.json`, dumps in session scratchpad `m/NEW1..6`)
    - [x] P3.verify-self.2 discrimination — evidence: old prose (`git show HEAD:skills/feature-verify-human/SKILL.md`) 0/12 incl. retries after the F-vh-decision tightening (re-scored on real dumps `m/OLD1..3` via `verify_result`); live SKILL.md restored, `cmp` == new copy
    - [x] P3.verify-self.3 check-structure baseline — evidence: 607 PASS / 1 FAIL (settings-fixture drift only)
    - [x] P3.verify-self.4 docs — evidence: `grep -c "Revision 2026-09-29" workflow-system/product/arch.md` → 1; root `CLAUDE.md:162` Integration-boundary bullet: "verify-human cannot use the F11" → 0 hits, now "verify-human's digest must carry that captured evidence (it never hands the operator a command to run …)"
    - No integration boundary in the runtime sense — phase adds scenarios, fixtures and docs; the consuming surface (`tests/run-tests.sh`) was driven by the measurement itself. Alignment questions: none.
  - [x] verify-human — zero admissible leaves (no Alignment questions, no spec decision first visible here, no UNVERIFIED/cosmetic items; floor not applicable — Phases 1–2 had operator leaves); digest printed; advanced per drive_mode=autopilot (F11). Operator live-use statement 2026-11-02 recorded as alignment evidence for the feature.
  - [x] verify-codify (operator-simplified 2026-11-02: the 4 new scenarios are the codification; no extra sweep)
    - [x] `tests/scenarios/feature.yaml` F-vh-align-visual / F-vh-destructive / F-vh-decision / F-vh-floor + fixtures `tests/fixtures/wip/notif-prefs-a..d.md` — new 24/24, old prose 0/12 (see P3.1-measure); reviewed via `/test-assertion-review` (CLEAR)
    - [x] Regression scope: Phase 3 changed only scenarios/fixtures/docs (no skill or agent prose), so no other scenario can regress from it; check-structure 607/1 (baseline) in verify-auto; verify-human scenarios last swept in Phase 2 codify against the same SKILL.md
    - No integration boundary — phase adds isolated new test artifacts and docs only

## Current Node
- **Path:** Feature > Completed
- **Active scope:** none
- **Blocked:** none
- **Unvisited:** (none)
- **Open discoveries:** P1.5/P1.6 add the git-write prohibition to both observe-only subagents — resolves the prompt-level half of SURFACE-2026-07-27-VERIFY-SELF-RUNNER-MUTATED-WORKING-TREE (credit at finalize)

## Test Triage — F3 (feature:spec → research when unknowns exist)
Classification: Flaky test — failure unrelated to new code; inconsistent across runs (pre-existing)
Confidence: high
Evidence: recorded history shows F3 failing in 9 of its last 13 runs since 2026-07-29 (before this feature), already tracked as SURFACE-2026-07-29-F3-SCENARIO-FLAKY-ON-BOUNDARY-GATE; this phase's only feature-spec edit is the `drive_mode` frontmatter line + one stamping sentence in §3, outside the F3/F4 decision prose.
Action: none — no test or code modified; the harness already retried it (2 attempts). Left to the existing SURFACE.

## Test Triage — F11 / F12 / F13 (fixture `feature-verify-auto-passed.md`)
Classification: Obsolete test — the new feature intentionally supersedes what the fixture assumed (verify-human reached with verify-self `NOT-STARTED` and no evidence lines)
Confidence: high
Evidence: new §2 Step 2 back-loops (F12) when verify-self is `NOT-STARTED`; the fixture's L20 `verify-self <!-- status: NOT-STARTED -->` makes F11 and F13 unreachable by design (live run: F11 "passed" only by inventing an evidence-free digest).
Action: point the three scenarios at two new fixtures with verify-self passed + `evidence:` lines — `feature-verify-self-passed-backend.md` (Alignment questions: none → F11) and `feature-verify-self-passed-backend-align.md` (one captured alignment question → F12/F13). The old fixture is left unchanged.

## Test Triage — F12 (feature:verify-human back-loops to build when human rejects)
Classification: Obsolete test — the scenario's rejection text targets correctness facts (PATCH validation, 404 vs 200, API contract) that the new verify-human never presents as leaves; the model therefore presents its one alignment leaf and waits
Confidence: high
Evidence: rv6 dumps r1–r3 attempt1 — each presents "P1.verify-human.1 Default categories for a new user … is this what you want?" and ends awaiting input; the prompt's rejection never answers that leaf.
Action: reword the scenario's human reply so it rejects the presented alignment leaf (wrong defaults) and reports one of the original correctness defects as an aside; expectation unchanged (F12). Measure n≥3.

## Test Triage — F13-prefiltered (feature:verify-human excludes verify-self [x] items from checklist)
Classification: Obsolete test — the feature intentionally supersedes the asserted contract: verify-self PASS items now appear in the "Already verified by agent" digest (never as leaves), and a phase with nothing operator-held advances via the zero-leaf rule (F11), not F13; its fixture `feature-verify-self-passed.md` also shows verify-self in-progress with NOT-STARTED leaves, which Step 2 back-loops
Confidence: high
Evidence: scenario `not_contains: "GET /api/notification-preferences"` forbids exactly the digest line the new §2 Step 1 requires; fixture L21–24 verify-self `in-progress` / leaves `NOT-STARTED`.
Action: point at `feature-verify-self-passed-backend.md` (verify-self passed with evidence, Alignment questions none); expect `transition_id_any: [F11, F13]` + `contains_required_any: ["Already verified by agent"]`; keep the intent (passed checks never become leaves) via lenient `not_contains` on a "run this / paste" hand-over. Shared fixture left unchanged (also used by verify-self scenarios).

## Test Triage — F-verify-human-auto-skip-fires (Phase 2 codify batch)
Classification: Flaky test — failure unrelated to new code; inconsistent across runs (the model sometimes summarises the digest in prose instead of printing the §4 heading)
Confidence: high
Evidence: batch run 2026-09-29-155456 FAIL (2 attempts); re-run 3× → FLAKY, PASS, PASS; across the session its first-attempt rate is ~3–5/6 with every run passing within 2 attempts; transition is F11 in every recorded run (the behaviour is right; only the digest heading is missing).
Action: none to code or test. Residual logged as SURFACE-2026-09-29-VERIFY-HUMAN-DIGEST-FORMAT-ADHERENCE.

## Code-Quality Review

## Code-Quality Review — verify-human-alignment-only

### Strengths
- F11's trigger rewrite is consistent across every surface that states it (transitions.md, feature-workflow AGENTS.md, session-start, verify-human cheat-sheet, root CLAUDE.md); no "no integration boundary + verify-self all-PASS" wording survives in live prompts.
- `check_section_anchors` ([Phase 23]) applies the seventh guard-nothing mechanism by design — fail-closed on missing file and on both boundaries, per-anchor isolation, line-start anchors that reject a field deletion with prose left behind.
- Scenarios follow the prompt-leakage lesson: one neutral conditional prompt, neutral fixture names (`notif-prefs-a..d`) because the path is in the prompt, load-bearing `contains_required`, discrimination against pre-feature prose (0/12). Zero-leaf fixtures keep a `Phase 2 NOT-STARTED` node, so auto-skip-fires doubles as a floor negative control.
- Runner mutation fence and reviewer read-only-`Bash` rule are minimal, incident-justified, and section-pinned.
- Rules carry their evidence base inline (727 checklists, 14/15 skipped-gate defects, synthetic-vs-real input); `TEST_DUMP_DIR` is a minimal opt-in diagnosability hook.

### Issues
**CRITICAL**
- [workflow-system/product/transitions.md:338, agents/feature-workflow/AGENTS.md:96] F12's trigger changed (verify-human §2 Step 2 now emits F12 agent-initiated: verify-self NOT-STARTED / BLOCKING-failed / missing consuming-surface evidence) but both state-machine tables still say only "human rejects"; only arch.md mentions the new trigger. — Three-location sync rule violated; dispatch unaffected (F12 AUTO either way); fix is two table cells.

**MAJOR**
- [skills/feature-verify-self/SKILL.md:160, agents/feature-verify-self-runner/AGENTS.md:98-100] Playwright-unavailable fallback still writes `UNVERIFIED: Playwright MCP not available — check manually` / `could not verify this browser outcome`, outside the new `undrivable` / `no harness` forms that verify-human Step 2 and §3 recognise. — A legacy-format leaf has no home → Step 2 catch-all → F12 → build can't fix a missing tool → loop; "check manually" contradicts the no-handover rule.
- [skills/feature-verify-human/SKILL.md:77-81, tests/fixtures/wip/notif-prefs-d.md:28] The floor (5a) needs to know earlier phases advanced with zero leaves, but 5b never says to record that; the F-vh-floor fixture uses an annotation the procedure never writes. — Floor must infer from "`[x]` with no children", ambiguous with legacy skips/hand edits; the scenario tests a WIP shape the skill doesn't produce. Fix: 5b writes a canonical marker that 5a reads.
- [tests/check-structure.sh:3447-3476 (also 2983-3036, 3140-3190)] `check_section_anchors` is the third copy of the section-window extractor ([Phase 20], [Phase 21] each inline their own); all three count the end boundary file-wide, not after the start line, so an end heading moved above the start still lets the window run to EOF. — Next hardening has to land three times; consolidate and scope the end precondition to after-start.

**MINOR**
- [tests/scenarios/feature.yaml:1446, 1815] `F-boundary-human` and `F-verify-human-boundary-digest-advances` are fixture-dependent but don't name the WIP path, unlike the four F-vh-* scenarios in the same commit.
- [skills/feature-verify-auto/SKILL.md:49] The record-evidence instruction sits in the pre-Procedure examples block; the Procedure's tree update only says mark `verify-auto` `[x]`, while verify-human Step 1 assumes every leaf carries `evidence:`.
- [skills/feature-verify-human/SKILL.md:55] Step 2 is one ~250-word paragraph with four branches; a bullet per branch would be easier to maintain.
- [workflow-system/product/arch.md:4] `updated: 2026-09-29` / "Revision 2026-09-29" predate the 2026-11-02 commit.

### Assessment
A well-reasoned, carefully tested redesign that leaves the codebase better: it replaces a rule-by-category gate with a rule-by-who-holds-the-answer, backed by mined evidence, hardened structural pins, and both-directions behavioral scenarios. The gaps are at the edges of the new contract — F12's new trigger reached only the skill and arch.md; the UNVERIFIED-format change left a legacy annotation verify-human cannot place; the floor reads a marker no step writes; the new test helper is a third copy of shared logic. Each is a small edit.

### Disposition (F40 refactor, 2026-11-02)
- **Fixed:** CRITICAL F12 rows (transitions.md:338, feature-workflow AGENTS.md:96 — now name the §2 Step 2 agent-initiated trigger); MAJOR-1 Playwright fallback → `UNVERIFIED: no harness — …; buildable:` in verify-self SKILL.md + runner AGENTS.md (+ arch.md:221 design-property line); MAJOR-2 verify-human 5b writes `— zero admissible leaves (F11)`, 5a reads it (legacy: `[x]` with no child leaves); MINOR verify-auto Procedure now records `evidence:` per check; MINOR arch.md `updated: 2026-11-02`.
- **Backlogged:** MAJOR-3 extractor triplication (medium); MINOR boundary scenarios fixture-blind (low); MINOR Step 2 density (low) — `backlog-quality-findings.md` → `# verify-human-alignment-only — 2026-11-02`, pointer in `backlog.md`.
- **Re-verify:** check-structure 607 PASS / 1 FAIL (baseline); frontmatter parses (4 files); floor + zero-leaf scenarios re-run ×6 (haiku): **F-vh-floor 6/6 first-attempt**; F-verify-human-auto-skip-fires 3/6 first-attempt, 5/6 within retries — matches its recorded ~3–5/6 baseline (Test Triage above); the misses are fixture-blind (no attempt names the fixture path; R2 guessed F13 from the prose alone), logged on SURFACE-2026-11-02-QUALITY-BOUNDARY-SCENARIOS-FIXTURE-BLIND.

### If you disagree
Edit this section and mark a finding `[DISMISSED]` before `feature-finalize` archives the WIP.

## Retrospect
- **What changed in our understanding:** verify-human's job is *alignment*, not correctness — the mined corpus (727 checklists) showed RUN-CMD items never produced a catch, while the real catches were operator-held (visual vs reference, own data, decisions) and mostly on the happy path. The old gate routed on "did verify-self happen to cover it", not "does the answer belong to the operator". Spec approval is also not informed consent (Q5): the first in-action sight of a spec default is a leaf in its own right.
- **Assumptions that held:** the two-axis routing (can the agent drive it × who holds the expected result); the digest as read-time veto; the zero-leaf rule replacing both the boundary mandate and the 4-gate auto-skip; the declared-only dev/test mutation fence. The operator used Phases 1–2 live for a month and was "pretty happy with it".
- **Assumptions that were wrong:** (1) that scenario-harness runs see their fixture — the model cannot list `workflow-system/state/wip/` (no Glob, Read EISDIR, shell forbidden), so fixture-dependent scenarios were partly guessing from prose; naming the path fixed it (1/24 → 24/24), and naming it forces neutral fixture names. (2) "Only F11's trigger changes" — F12 gained an agent-initiated trigger too, missed in two tables (review CRITICAL). (3) The floor could infer zero-leaf history from the tree — it needed an explicit marker. (4) A green scenario on the new prose is enough — F-vh-decision passed the *old* prose 2/5 until it also required the digest heading.
- **Approach delta:** Phase 2 grew Q5–Q9 amendments after an operator-requested second evidence pass (happy path first, agent-chosen expectations as Decisions, stricter verify-self, feature-level floor) and an ordered Steps 1–5 rewrite. Phase 3 resumed after a 34-day gap; the operator simplified its verify sequence on the strength of live use. Review-quality found 1 CRITICAL / 3 MAJOR / 4 MINOR → F40 refactor fixed five, backlogged three.

**Feature complete:** verify-human is now an alignment gate — the operator sees a digest of what the agent already verified and is asked only what they alone can answer (does this match what you meant, which option, what the agent cannot drive or may not run); phases with nothing for them advance on their own in autopilot. Live in every project since 2026-09-29 via the `~/.claude/skills` symlinks; shipped `fd84fb4`, refactor `2c03691`. Requester = operator — closure notice for self-record.

## Discoveries
- [SURFACED-2026-09-29] feature-spec — arch.md exceeds size guard (474 lines), truncated to headings. Consider summarizing.
- [SURFACED-2026-09-29] Phase 1 verify-self — `F-boundary-self` is weak on haiku: 0/4 structured `F9b` on the committed skill; it survives only via the `contains_any` fallback, so it barely guards the boundary back-loop. Logged as SURFACE-2026-09-29-F-BOUNDARY-SELF-SOFT-PASS-ONLY.
- [SHORTCUT-2026-09-29] P2.verify-self.F9b4 — in-place fix of just-written §2 prose: Step 2 catch-all now excludes checks verify-self recorded UNVERIFIED undrivable/no-harness/destructive (they go to Step 3 (d)/(e)); F12 descriptions (L24, §8) now include the agent-initiated Step 2 back-loop; removed the §8 "ID alone" sentence (the decorated TRANSITION lines come from `tests/run-tests.sh` L44's own instruction, and the parser accepts both). Re-verified by a fresh subagent coherence read (below).
