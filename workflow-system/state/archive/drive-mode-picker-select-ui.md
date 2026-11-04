---
drive_mode: fsd
---

# Feature: Drive-mode picker — select UI, and skip it under Claudesk

**Workflow:** feature
**State:** finalize (complete)
**Completed:** 2026-11-03 (ship commit `6160eb0`, local)
**Created:** 2026-11-03
**Source:** backlog `SURFACE-2026-11-02-DRIVE-MODE-PICKER-SELECT-UI-AND-CLAUDESK-SKIP` ← inbox `workflow-system/inbox/archive/2026-11-02-claudesk-drive-mode-picker.md` (Claudesk M16.5 WP5 task 5.8)

## Problem Statement

`session-start` (step 3) and `session-restore` (step 4b) show the drive-mode pick as a typed
numbered menu ("Type 1–4" / "press Enter to keep current"). Two changes were asked for: (1) show the
pick through `AskUserQuestion` (CC's select UI), with the current (restore) or default (start) mode
first and the wire strings `stepping`/`orchestrated`/`autopilot`/`fsd` unchanged; (2) when the context
contains Claudesk's hook line `Claudesk reports the drive mode for this workspace as <mode>.`, use
that mode, show **no** picker, and name it in one line. Live restores on 2026-11-02 in two Claudesk
workspaces read the value but still showed the menu: the skills read the line for its *value* and not
as permission to *skip*. Only an explicit rule in the skills fixes that (Claudesk keeps its line a fact
on purpose). Without the line (a bare terminal), behavior changes only by Ask 1.

Problem statement unchanged (2026-11-03, F9b re-entry): the skill behaves correctly, and verify-self showed that S35 passes with the rung present. What failed is the *evidence that S35 guards the feature*. The Claudesk rule is restated in four places outside rung 2, so deleting only rung 2 and the 4b skip paragraph left the feature intact. That is a defect in the discrimination arm, not in the root problem.

## Plan-time decisions (autopilot — taken without asking, disclosed here)

**Asked:** none (plan is AUTO in autopilot; every open point below has a stated lean from the request
or a common-sense default, and each one first becomes visible as an Alignment question below).

**Assumed:**
- **A1. Restore precedence:** `tour:` pointer > Claudesk line > `.session.md` `drive_mode:` > `state_file`
  `drive_mode:` > `orchestrated` default. The Claudesk line beats the pointer because it is the operator's
  live per-workspace setting, while the pointer records the mode at handoff time (this is Claudesk's lean).
  When the Claudesk mode differs from the WIP's `drive_mode:`, restore rewrites the WIP frontmatter to
  the Claudesk mode and says so in its one line. Otherwise `feature-verify-human` would read a stale mode.
- **A2. `tour:` outranks the Claudesk line.** A tutorial run sets its mode on purpose and reveals the modes at
  its own scripted point. The existing tour arm is unchanged: no menu, no mode named.
- **A3. The incident override outranks the Claudesk line.** An incident always runs Mode 2. Under a Claudesk
  line both skills say so in the one line ("Claudesk reports Autopilot; incidents always run
  Orchestrated").
- **A4. `session-start` keeps its classification confirmation** when the mode is preset. Claudesk asked only for
  the *mode* part to be skipped, and the confirmation is the guard against a wrong workflow or a wrong backlog
  item. The pause stays and becomes a one-line confirmation that names the mode (`AskUserQuestion` with
  "Drive it" / "I'll run `/<entry>` myself").
- **A5. Non-interactive fallback:** when `AskUserQuestion` is unavailable (`claude -p` / the scenario
  harness), print the same four options as a numbered text list. The exact wording depends on P1.1's spike.
- **A6. Tours (our call): tour replay menus switch to `AskUserQuestion` too, and the Claudesk line does NOT
  skip them.** A tour's gear pick *is* the lesson, and a first run is forced to Stepping regardless.
  Tour first-run copy (the mode reveal at Step-8 graduation) is unchanged.
- **A7. Which line counts:** the **most recent** `Claudesk reports the drive mode for this workspace as <mode>.`
- **A8 (operator-directed, 2026-11-03 at P1.verify-human.2): handoff defers instead of snapshotting.** Under a Claudesk line, `/session-handoff` writes a non-mode marker (`drive_mode: from-claudesk` plus an inline comment saying what to do and what to fall back to). It does NOT write the literal mode, because a fresh session reading a literal mode will use it (the 2026-11-02 failure shape), while a marker that cannot be mistaken for a mode forces the live lookup. The marker's form is the agent's choice, made at the operator's request ("think about what's the best way to communicate that idea to yourself in a fresh session").
  in context, and only when `<mode>` is one of the four wire strings. Any other value is ignored, and the
  skill falls back to the ordinary path.

## Work Tree

- [x] Phase 1: `session-restore` — Claudesk skip + select-UI pick
  **Observable outcomes:**
  - CLI: `env CLAUDESK_DRIVE_MODE=autopilot ./tests/run-tests.sh --id S32` still PASSes with the menu offered (the harness strips the inherited var; P1.0).
  - CLI: P1.1 spike recorded in `## Discoveries`: what a model sees when it calls `AskUserQuestion` under `claude -p` (the harness surface), quoted from a real run, not inferred.
  - CLI: `grep -n 'Claudesk reports the drive mode for this workspace as' skills/session-restore/SKILL.md` ≥1 hit inside step 4. The step-4 precedence ladder names, in order, `tour:` → Claudesk line → `.session.md` → `state_file` → `orchestrated`, and step 4b names `AskUserQuestion` plus the text-list fallback.
  - CLI: `PATH=/usr/bin:$PATH ./tests/run-tests.sh --id <new-claudesk-restore-id>`: pointer `drive_mode: stepping` + Claudesk line `autopilot` in `system_prompt_extra` → response names Autopilot, contains no menu strings (`4  FSD`, `Orchestrated  standard policy`), emits S6. Passes in ≥5 of 6 runs, and FAILS when the new step-4 Claudesk rung is deleted (discrimination test). [Amended 2026-11-03 at F9b: deleting rung 2 alone is not a valid negative arm, because the rule is restated at four other skill lines that carry the behavior on their own. Verify-self measured 3/3 PASS with only the rung deleted. The discrimination arms are now (a) the pre-feature HEAD skill and (b) the current skill with every Claudesk statement removed; S35 must FAIL on both.]
  - CLI: a tour-pointer + Claudesk-line scenario → the tour arm still wins (S6, no mode named; existing S31 negatives hold). The incident + Claudesk scenario → Orchestrated is named.
  - CLI: existing S15, S16, S31, S32 still PASS (S32 = negative control: no Claudesk line → orchestrated default + menu still offered).
  - CLI: `./tests/check-structure.sh` → new Phase-1 pins PASS. The only FAIL is the pre-existing settings-fixture drift (baseline 607 PASS / 1 FAIL).
  **Alignment questions:**
  - A1 in action (decision): restoring a handoff recorded as **Stepping** in a Claudesk **Autopilot** workspace now restores Autopilot, rewrites the WIP's `drive_mode:` to `autopilot`, and says so in one line (captured scenario transcript). Still what you want, or should a recorded handoff mode win?
  - Bare-terminal pick: the restore mode pick in the select UI, current mode first as `<Mode> (current)` (pty capture of a real interactive `/session-restore` if drivable, else `UNVERIFIED: undrivable`). Is this the shape you meant?
  - [x] P1.0 Harness isolation: `tests/run-tests.sh` runs `claude` under `env -u CLAUDESK_DRIVE_MODE` so an operator's Claudesk session cannot leak the hook line into scenarios (added at build — see Discoveries).
  - [x] P1.1 Spike: run one `claude -p` turn with the harness's flags that is told to call `AskUserQuestion`. Record what the model sees (unavailable / error / auto-answered) to settle A5's fallback wording.
  - [x] P1.2 Rewrite `skills/session-restore/SKILL.md` step 4 (precedence ladder: Claudesk rung, A7 line rule, A3 incident rung, A1 WIP rewrite) and step 4b (`AskUserQuestion` with current mode first + A5 fallback; skip entirely under a Claudesk line or `tour:`). Keep the `tour:` arm and its schema-of-record citation intact.
  - [x] P1.3 Sync `workflow-system/product/transitions.md` S15/S16 rows (S15 = pick presented, bare terminal only; under a Claudesk line restore exits S6).
  - [x] P1.4 Scenarios in `tests/scenarios/session.yaml` (+ fixtures as needed): Claudesk-skip restore, tour-beats-Claudesk, incident-beats-Claudesk. Environmental facts only in `system_prompt_extra` (the hook line as it appears in context, plus the WIP path), never the expected answer (prompt-leakage rule). Anchor on output vocabulary seen in a live capture.
  - [x] P1.5 `tests/check-structure.sh` pins for the restore rule, section-scoped to step 4/4b with fail-closed start AND end boundaries. Invoke `/test-assertion-review` first.
  - [x] verify-auto
    — evidence: `bash -n tests/run-tests.sh` → 0; `bash -n tests/check-structure.sh` → 0
    — evidence: `yaml.safe_load(tests/scenarios/session.yaml)` → 0; session-restore frontmatter parses (`argument-hint, description, name`)
    — evidence: `./tests/run-tests.sh --dry-run --id S31,S32,S35,S36,S37` → all 5 listed `[DRY]` (harness parses the new/edited scenarios)
    — evidence: `./tests/check-structure.sh` → 611 PASS / 1 FAIL; [Phase 25] 4/4 PASS; sole FAIL = pre-existing settings-fixture drift (baseline 607/1)
    — evidence (re-run after F9b): `grep -c "(default)" skills/session-restore/SKILL.md` → 0; frontmatter parses; [Phase 25] 4/4 PASS; WIP section headings (Work Tree / Current Node / Discoveries) each count 1
  - [x] verify-self  <!-- re-run after F9b: all BLOCKING resolved; 1 alignment leaf UNVERIFIED (no harness) handed to verify-human -->
    - [x] harness strips inherited Claudesk var — evidence: `env CLAUDESK_DRIVE_MODE=autopilot ./tests/run-tests.sh --id S32-…` → exit 0, 1 PASS; dump shows "Current: Orchestrated  [Enter = keep]", "TRANSITION: S15"
    - [x] P1.1 spike recorded + re-probed — evidence: fresh `claude --print … dontAsk` probe → "ToolSearch select:AskUserQuestion … No matching deferred tools found", denials []
    - [x] step-4 ladder order + 4b pick/fallback — evidence: grep hit SKILL.md:41 inside step 4; ladder lines 39–45 tour → Claudesk → .session.md → state_file → orchestrated; incident override l.47
    - [x] S35 passes + discriminates — evidence (fresh runner, `--retry 1`): feature present 6/6 PASS ("Restoring in **FSD**, the mode Claudesk reports for this workspace… skip the mode pick", S6); arm (a) pre-feature HEAD skill 0/3 (menu + "Restoring in Autopilot"; S15 ×2); arm (b) Claudesk-stripped 0/3 (S15 ×3; its literal filter also removed rung 1 / 4b header, so arm (a) is the clean negative). Skill restored byte-identical (cmp). Dumps /private/tmp/claude-501/-Users-stayman-Personal-projects-my-claude-code-customization/e9675bfb-2dfd-48ff-a015-374482ae31df/scratchpad/vself2/dumps/
    - [x] S36 tour beats Claudesk + S37 incident beats Claudesk — evidence: run-2026-11-03-100615 S36 PASS, S37 PASS first attempt; S37 "Claudesk reports **Autopilot** … incidents always run **Orchestrated**"
    - [x] S15, S16, S31, S32 regression — evidence: same batch, session 7 PASS / 0 FAIL, 172s
    - [x] check-structure — evidence: 611 PASS / 1 FAIL (pre-existing settings drift); [Phase 25] 4/4
    - [x] fallback list "(default)" label removed — evidence: `grep -c "(default)" skills/session-restore/SKILL.md` → 0; S32 PASS, fallback reads "3  Autopilot     only pause at verify-human" / "Current: Orchestrated  [Enter = keep]"
    - [x] align: A1 Claudesk-wins precedence — evidence: S35 dump line 1: "Restoring in **FSD**, the mode Claudesk reports for this workspace. The handoff recorded **Autopilot**, so I would also update `drive_mode:` to `fsd`." (/private/tmp/claude-501/-Users-stayman-Personal-projects-my-claude-code-customization/e9675bfb-2dfd-48ff-a015-374482ae31df/scratchpad/vself/dumps/batch/S35-claudesk-line-decides-restore-mode-attempt1.txt)
    - [x] align: bare-terminal select UI — UNVERIFIED: no harness — interactive claude in a temp project stops at the workspace-trust dialog; accepting writes a trust entry to ~/.claude.json (outside the mutation fence); buildable: yes (operator pre-trusts /private/tmp/claude-501/-Users-stayman-Personal-projects-my-claude-code-customization/e9675bfb-2dfd-48ff-a015-374482ae31df/scratchpad/vself/proj, then re-run …/scratchpad/vself/scripts/drive.py)
  - [x] verify-human
    - [x] P1.verify-human.1: (b) Assumed defaults A2/A3/A5/A7 in action — operator: "ok" (2026-11-03)
    - [x] P1.verify-human.2: (c) decision A1 — operator: Claudesk mode wins (option A) (2026-11-03). Operator added: "moving forward for hand off, if claudesk mode is present when the skill is invoked, it should just … go by claudesk mode", so `/session-handoff` records the Claudesk mode → new leaf P2.0
    - [x] P1.verify-human.3: (d) bare-terminal select UI + live no-pick check — run by the Claudesk workspace in the Claudesk dev build (inbox reply `2026-11-03-claudesk-drive-mode-picker-live-check-results.md`). Check A PASS: real `hook_additional_context` line, no AskUserQuestion/list, "The drive mode is **Autopilot**, the mode Claudesk reports… recorded **Stepping**, so I changed the `drive_mode:` field…", WIP → `drive_mode: autopilot`, S6. Check B PASS: no-mode workspace (no hook line, same condition as a bare terminal) rendered the select "1. Stepping (current), 2. Orchestrated, 3. Autopilot, 4. FSD". Ask 3: Claudesk never parses `.session.md` body, so `from-claudesk` is safe.
  - [x] verify-codify
    — coverage: S35 (line decides, no pick), S36 (tour outranks), S37 (incident outranks), S31/S32/S15/S16 (fallback + regression), [Phase 25] pins (rung order, 4b skip, AskUserQuestion/current-first, harness `env -u`, S15 row). NEW: S38 (WIP `drive_mode:` realigned to the Claudesk mode). The gap came from the live check; the S38 anchor was fixed after the first version scored real rewrites 3/6 (a dot in the filename stopped `[^.]*`). Final: 3/3 fresh + 6/6 re-scored real dumps; pre-feature skill 0/3 (S15).
    — integration boundary: `/session-restore` is the consuming surface; S35–S38 drive it end to end through `claude --print`.
    — full sweep: `./tests/run-all.sh` 6081s → haiku 140 PASS / 42 SOFT / 12 FAIL / 2 FLAKY (196), sonnet 15/1/1 (17). All 13 failures triaged as pre-existing/unrelated (see Test Triage); operator: proceed. `check-structure` 611/1 (pre-existing settings drift).

- [x] Phase 2: `session-start` + `session-handoff` — Claudesk skip + select-UI pick; handoff records the Claudesk mode
  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — Claudesk's reply asks for the Phase 2 ship note and will live-check `/session-start`
  - Requirements unchanged: yes, with one addition — P2.0 (`from-claudesk` handoff marker), operator-directed at P1.verify-human.2 and cleared by Claudesk (Ask 3)
  - Solution still feasible: yes — the same rung pattern is proven in Phase 1 (S35–S38)
  - No superior alternative discovered: yes
  **Verdict:** proceed
  **Sweep cadence (operator, 2026-11-03, now in root CLAUDE.md):** no full `run-all.sh` sweep at this phase's codify. Run Phase 2's own scenarios (n≥3 + discrimination arm) and `check-structure` only. The full sweep runs once, at Phase 3 (last phase) codify.
  **Observable outcomes:**
  - CLI: `skills/session-handoff/SKILL.md`: when the Claudesk line is present at invocation (and the pointer is neither a `tour:` nor an incident), the `.session.md` it writes carries the deferral marker `drive_mode: from-claudesk` with its self-explaining inline comment, NOT a literal mode. A scenario with the Claudesk line `fsd` + a WIP recording `autopilot` → the described pointer contains `from-claudesk` and does not contain `drive_mode: fsd` / `drive_mode: autopilot`. It FAILS on the pre-feature skill. Restore: a pointer with `from-claudesk` + the Claudesk line → that line's mode; with no line → the `state_file` mode, no error, pick offered. [Added 2026-11-03 from the P1.verify-human.2 operator decision; marker form refined by operator same day]
  - CLI: `grep -n 'Claudesk reports the drive mode for this workspace as' skills/session-start/SKILL.md` ≥1 hit inside step 3. Step 3 names `AskUserQuestion` with Autopilot first as the default, the A5 fallback, the A4 retained classification confirmation, and the incident override over the Claudesk mode.
  - CLI: `PATH=/usr/bin:$PATH ./tests/run-tests.sh --id <new-claudesk-start-id>`: Claudesk line `fsd` + a feature request → response names FSD, contains no 1–4 menu strings, still asks to confirm the classification. Passes in ≥5 of 6 runs and FAILS with the new step-3 rule deleted.
  - CLI: incident request + Claudesk line `autopilot` → Orchestrated named (incident override).
  - CLI: existing S10–S14, S18, S22, S23 still PASS (S10 = no-line negative control: menu still shown).
  - CLI: `transitions.md` "Session-start prompt" block matches the new step 3 (no stale "Type 1–4" there). `check-structure.sh` new pins PASS, baseline otherwise unchanged.
  **Alignment questions:**
  - A4 in action (decision): under Claudesk, `/session-start` still stops once to confirm the classification, now naming the preset mode ("I'll drive the feature workflow in **FSD**, the mode Claudesk reports. Drive it?"). Is that one stop still wanted, or should a preset mode drive straight through?
  - [x] P2.0 `skills/session-handoff/SKILL.md` (the pointer schema of record) + `skills/session-restore/SKILL.md` rung 3: the deferral marker `drive_mode: from-claudesk  # not a mode: on restore, use the live "Claudesk reports the drive mode…" line; no line → use state_file's drive_mode`. Written only when the Claudesk line is present at handoff. Tour pointers, incidents and no-line handoffs keep a literal mode. The WIP `drive_mode:` stays literal. Restore rung 3 treats `from-claudesk` as "skip to rung 4" (not a defect). Scenarios (handoff writes marker; restore with marker + line; restore with marker + no line) + [Phase 25] pins. Operator decision 2026-11-03.
  - [x] P2.1 Rewrite `skills/session-start/SKILL.md` step 3: the Claudesk rung (A7), `AskUserQuestion` pick with Autopilot first + A5 fallback, the A4 confirmation shape, the incident override over Claudesk, and "Other" free text covering the "no → run it manually" reply. Keep the reply-interpretation list for the text fallback.
  - [x] P2.2 Sync the `transitions.md` "Session-start prompt" block.
  - [x] P2.3 Scenarios: Claudesk-skip start, incident-beats-Claudesk start (environmental facts only; name fixture paths).
  - [x] P2.4 `check-structure.sh` pins for step 3 (section-scoped, both boundaries fail-closed; `/test-assertion-review` first).
  - [x] verify-auto
    — evidence: frontmatter parses for session-start / session-handoff / session-restore SKILL.md (`argument-hint, description, name`); `yaml.safe_load(tests/scenarios/session.yaml)` → 0
    — evidence: the marker pointer fixture's frontmatter parses with the inline comment stripped: `drive_mode` → `'from-claudesk'`
    — evidence: `bash -n tests/check-structure.sh` → 0; `./tests/run-tests.sh --dry-run --id S38,S39,S40,S41,S42` → 5 `[DRY]`
    — evidence: `./tests/check-structure.sh` → 616 PASS / 1 FAIL ([Phase 25] 9/9; sole FAIL = pre-existing settings drift); `git status tests/fixtures/wip/` → only the new `notif-prefs-e.md` (no tracked fixture modified)
  - [x] verify-self
    - [x] handoff marker + restore fallback — evidence: S39 PASS (pointer `drive_mode: from-claudesk  # not a mode…`, 0 hits for a literal fsd/autopilot); HEAD session-handoff S39 0/3 (`drive_mode: autopilot`); S40 PASS (Stepping current, pick, S15); ad-hoc restore with marker + `fsd` line → "Restoring in **FSD**, the mode Claudesk reports…", no pick, S6 (/private/tmp/claude-501/-Users-stayman-Personal-projects-my-claude-code-customization/e9675bfb-2dfd-48ff-a015-374482ae31df/scratchpad/vself-p2/dumps/)
    - [x] session-start step 3 content — evidence: grep hit l.126 inside step 3; confirmation kept l.128, incident override l.129, AskUserQuestion Autopilot-first l.131, fallback l.142
    - [x] S41 — evidence: 6/6 single-attempt PASS (FSD named, "Drive it", no menu strings); HEAD session-start 0/3 (used FSD but skipped the confirmation)
    - [x] S42 incident outranks Claudesk — evidence: runner 1/1 + orchestrator 3/3 (`--retry 1`) + build 3/3 = 7/7 ("Claudesk reports **Autopilot** … Incidents always run **Orchestrated** (Mode 2)", S4, no menu). The runner flagged its own n=1 as too light, so I added samples (no code change). Pre-feature HEAD also 3/3 (the existing incident override), so S42 is a regression guard.
    - [x] regression set — evidence: S11, S13, S18 PASS; S23, S10 SOFT_PASS; S12 0/3, S14 0/3, S22 0/3 on the current AND HEAD session-start at equal n (single-attempt). No regression caused by Phase 2; see Test Triage — Phase 2 regression set. The runner noted S10 is not a valid no-line menu control ("no stops" in its request makes the model pick FSD), so a real control is added at codify.
    - [x] transitions + pins — evidence: block rewritten; "Type 1–4" only inside the kept fallback menu (identical to step 3 l.146–151); check-structure 616/1 ([Phase 25] 9/9; sole FAIL = pre-existing settings drift)
    - [x] align: A4 one classification stop under Claudesk — CAPTURED: "I'll drive the `feature` workflow in **FSD**, the mode Claudesk reports for this workspace. Drive it?" (/private/tmp/claude-501/-Users-stayman-Personal-projects-my-claude-code-customization/e9675bfb-2dfd-48ff-a015-374482ae31df/scratchpad/vself-p2/dumps/cur-S41-r1/); all 6 runs stopped once, no mode pick
  - [x] verify-human — SKIPPED (drive_mode fsd, operator 2026-11-03). Decision A4 (one classification stop kept under Claudesk) taken at its plan default and queued for the operator's morning review, with the captured line above.
  - [x] verify-codify
    — coverage: S39 handoff marker (discriminates: pre-feature 0/3), S40 marker + no line (guard), S41 session-start under the line (discriminates: pre-feature 0/3), S42 incident outranks the line (guard, 7/7), [Phase 25] Phase-2 pins (16/16 mutations caught). Marker + line on restore is covered by rung 2 (S35) plus the runner's ad-hoc run. NEW: S43, the no-line session-start control (S10 could not serve). Its first anchors scored real menus 1/3 (bold numbering, pick described rather than printed); widened per Test Triage, then 6/6 fresh with all 3 wrong-output cases FAIL.
    — integration boundary: `/session-start` (S41/S42/S43), `/session-handoff` (S39, S17), `/session-restore` (S40, S35, S15) driven end to end via `claude --print`.
    — run (phase-own only; no full sweep per root CLAUDE.md): S39 3/3, S40 2/2, S41 2/2, S17 2/2, S35 1/1, S15 1/1, S43 6/6; check-structure 616/1 (pre-existing settings drift).

- [x] Phase 3: Tour replay gear menus → select UI
  **Relevance check (before Phase 3):**
  - Requester still needs this: yes — Claudesk left the tours to us ("your call"); the plan chose A6 (tours follow the select UI; the Claudesk line does not skip a replay's pick)
  - Requirements unchanged: yes
  - Solution still feasible: yes — the flow doc's invariant 4 says the replay menu has "the same shape as `/session-start`", which now uses the select UI
  - No superior alternative discovered: yes
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `grep -c 'Type 1–4' skills/tutorial-greenfield-workflow-tour/SKILL.md skills/tutorial-brownfield-workflow-tour/SKILL.md` → 0 each. [Amended 2026-11-03 at verify-auto: the count is 1 per arm by design. The numbered menu is kept verbatim as the non-interactive fallback (A5, same as session-start in Phase 2), and T3's first-run leak negatives and the narration probe's anchor read that copy. The intent this checked, "the replay now asks via AskUserQuestion", is pinned by [Phase 25]'s replay-branch anchors (12/12 mutations caught).] Each arm's replay branch names `AskUserQuestion` (Autopilot first, as recommended), the A5 fallback, and states that a Claudesk line does NOT skip the tour's gear pick.
  - CLI: `PATH=/usr/bin:$PATH ./tests/run-tests.sh --group tutorial` → no new FAILs vs a pre-change baseline run at equal depth. The first-run withholds-the-reveal scenario still passes: no menu on first run, Claudesk line or not.
  - CLI: `check-structure.sh` tour narration-probe pins all PASS (anchors still LIVE against the edited arms' copy; the "drive-mode reveal" leak shape is still caught).
  **Alignment questions:**
  - A6 in action (decision): a tour replay inside a Claudesk workspace still asks for a gear (select UI) even though Claudesk reports a mode. Still what you want?
  - [x] P3.1 Edit both arms' replay-menu copy to `AskUserQuestion` + A5 fallback + an A6 sentence. Leave first-run copy and `tutorial-product-cycle-tour` (no-mode-menu invariant) untouched.
  - [x] P3.2 Re-check the `tests/scenarios/tutorial.yaml` negatives and the check-structure narration anchors against the new copy. Update any anchor that went dead (`/test-assertion-review` first).
  - [x] verify-auto
    — evidence: frontmatter parses for both tour arms + tutorial-getting-started (`argument-hint, description, name`); `bash -n tests/check-structure.sh` → 0
    — evidence: `grep -c 'Type 1–4'` → 1 per arm (the fallback, by design; outcome amended above); `git diff --stat` touches only the 2 arms, tutorial-getting-started (1 line), the flow doc, root CLAUDE.md (tour bullet)
    — evidence: `./tests/check-structure.sh` → 618 PASS / 1 FAIL (narration probe all PASS; replay-branch pins 2/2; sole FAIL = pre-existing settings drift)
  - [x] verify-self
    - [x] replay-branch content — evidence: `grep -c 'Type 1–4'` → 1 per arm (fallback, per amendment); AskUserQuestion at greenfield l.120/124, brownfield l.127/131; "A Claudesk drive-mode line does not skip this pick."; [Phase 25] replay pins PASS ×2
    - [x] tutorial group vs HEAD at equal depth — evidence: current T1/T2/T4 SOFT_PASS, T3 FLAKY; HEAD all SOFT_PASS; T3 re-run ×3 each arm: current 3/4, HEAD 1/4. All 13 T3 dumps were hand-checked: every miss is a positive-anchor miss ("empty folder"/"empty-directory"), no strict-negative (menu leak) hit on either arm. T3 is on the known pre-existing list, and it is not worse on the current files. An ad-hoc first run under a Claudesk autopilot line revealed no mode ("Got it, first run. We'll go step by step…", 0 mode/menu tokens). HEAD swaps restored, `cmp` identical ×3 (/private/tmp/claude-501/-Users-stayman-Personal-projects-my-claude-code-customization/e9675bfb-2dfd-48ff-a015-374482ae31df/scratchpad/vself-p3/)
    - [x] narration probe — evidence: [Phase 18b] 21/21 PASS (anchors live, drive-mode reveal caught, case-stable); check-structure 618/1 (pre-existing settings drift)
    - [x] align: A6 replay under Claudesk still asks — CAPTURED: "Pick your gear: 1. **Stepping** … 4. **FSD** … — The Claudesk line reports `fsd` for this workspace, but that doesn't pick your gear. On a replay the choice is the point of the run, so you pick. … Enter alone means **3 Autopilot**." (numbered fallback under --print; /private/tmp/claude-501/-Users-stayman-Personal-projects-my-claude-code-customization/e9675bfb-2dfd-48ff-a015-374482ae31df/scratchpad/vself-p3/replay-claudesk-fsd.txt)
  - [x] verify-human — SKIPPED (drive_mode fsd). Decision A6 (a tour replay still asks for a gear under a Claudesk line) taken at its plan default and queued for the operator's morning review, with the captured text above.
  - [x] verify-codify (LAST phase: full sweep run)
    — coverage: [Phase 25] replay-branch pins (12/12 mutations caught); T3 + narration probe (first run reveals nothing); NEW T5 (replay under a Claudesk line still asks; SOFT_PASS 3/3 + sweep SOFT_PASS; wrong outputs simulated FAIL).
    — integration boundary: `/tutorial-greenfield-workflow-tour` driven end to end (T3, T5).
    — FULL SWEEP for the whole feature (`./tests/run-all.sh` 5977s, results run-2026-11-03-213423-combined.json): haiku 144 PASS / 45 SOFT / 11 FAIL / 2 FLAKY (202), sonnet 15/1/1 (17). Every scenario this feature added or edited passed (S15–S17, S31, S32, S35–S42, T5 soft), except S43, whose too-narrow anchor was triaged, widened and re-run 8/8. F-vh-decision PASS (fixture restore confirmed). All other failures are on the known pre-existing list, plus DP-consult-changes (flaky, untouched; triaged). check-structure 618/1 (pre-existing settings drift).

## Test Triage — S31-tour-pointer-restore-keeps-stepping-and-hides-modes

- **Failure:** after its fixture path was named (P1.4), S31 went 1/6. Each failure read the pointer correctly, named no mode, emitted S6, and failed `contains_required_any: Stepping`.
- **Case:** obsolete test, high confidence. S31 requires the word "stepping", but session-restore step 4, added in the same commit (`ccfedac`), says a tour restore "name[s] no mode at all, not even the one you are restoring in". The requirement only ever passed when the model echoed the fixture's `drive_mode:` without following the rule.
- **Fix:** replaced the requirement with direct assertions of the scenario's stated intent (reject the July fall-through to Orchestrated): `not_contains` "orchestrated" and "Restoring in <Stepping>", strict. The other negatives are unchanged. `verify_result` simulation: correct output PASS; fall-through, mode-named and menu outputs FAIL.
- **Not softened:** the scenario rejects more wrong outputs than before (it now also rejects a reply that names the tour's mode).

## Test Triage — Phase 1 verify-codify full sweep (run-all 2026-11-03: haiku 12 FAIL, sonnet 1 FAIL)
Classification: pre-existing failures, unrelated to Phase 1 (not a code regression, not an obsolete test). Phase 1 changed only `skills/session-restore/SKILL.md`, the `env -u CLAUDESK_DRIVE_MODE` line in `tests/run-tests.sh`, and session.yaml scenarios S31/S32/S35–S38. None of the 13 failing scenarios exercises session-restore.
Confidence: high for 12; low/ambiguous for F-verify-human-auto-skip-fires.
Evidence: A/B at n=3 per arm, current hermetic harness vs a temporary copy that keeps the inherited Claudesk autopilot line (≈ the pre-change condition from a Claudesk session). F-verify-human-boundary-digest-advances 0/3 vs 0/3; F-boundary-human 1/3 vs 1/3; F-vh-decision 0/3 vs 0/3 (already FAIL on 2026-11-02); S14 0/3 vs 0/3; T3 2/3 soft vs 2/3 flaky. Hermetic only: F16-order-flip 0/3, DP-capture-skips-bare-fact 0/3 (+1 flaky), S22 0/3, T2 flaky; S3 (sonnet) FAIL `found S1` (session-start classification, untouched). S33/S34 are KNOWN-FAILING by design (WP7o). Ambiguous: F-verify-human-auto-skip-fires 0/3 hermetic vs 2/3 with-line (Fisher p≈0.4). Its fixture already carries `drive_mode: autopilot`, so the line supplied no missing data.
Action: no test or code modified. Paused for the operator per the persistent-failure rule. Proposed: log the 11 non-design failures as one backlog SURFACE for `/util-backlog-paydown`, and proceed to Phase 2.
**CORRECTION (2026-11-03, Phase 2 build):** F-vh-decision was NOT pre-existing. While codifying S38 I created `tests/fixtures/wip/notif-prefs-c.md`, overwriting the tracked fixture F-vh-decision uses, and the sweep and A/B both ran afterwards. After restoring it from HEAD (S38 moved to its own `notif-prefs-e.md` / `notif-prefs-e-handoff.md`), F-vh-decision → 3/3 PASS. Its earlier 2026-11-02 FAIL predates the overwrite, so it may also be flaky, but its sweep FAIL was mine. No other failing scenario uses that fixture (grep). It is removed from the standing list and from the backlog SURFACE.
**Operator decision (2026-11-03):** "proceed. and apply the same decision for phase 2 and 3." Standing rule for this feature: at Phase 2/3 verify-codify, a sweep failure in THIS listed set (F-verify-human-auto-skip-fires, F-verify-human-boundary-digest-advances, F-boundary-human, S14, T3-tour-first-run-hides-drive-modes-until-graduation, F16-order-flip, DP-capture-skips-bare-fact, S22, T2-tour-recommends-auto-permission-mode, S3 [sonnet], S33, S34) is recorded and does NOT pause. A failure outside the set still gets the full triage (including any of the phase's own scenarios). Logged as `SURFACE-2026-11-03-SCENARIO-SWEEP-PREEXISTING-FAILURES`.

**Drive-mode switch (operator, 2026-11-03, at Phase 2 verify-self):** "switch to fsd. you drive this feature end to end from here. I'm going to bed … I want to see this done and fully tested (not including the failing tests we already know)". `drive_mode: fsd` from here to finalize. This explicit instruction overrides the workspace's Claudesk line, which still reports autopilot. FSD skips verify-human and review-quality. The A4/A6 decision leaves are taken at their plan defaults and listed for the operator's morning review. Push: the repo's ship default is commit + push to `main` (memory `project_ship_process`), but `main` is already 1 ahead with `33c077c` (the previous feature's finalize), whose push the 11-02 handoff explicitly left as "the operator's call", and any push now would carry it. So ship commits locally and does NOT push. Both pushes are left for the operator in the morning.

## Test Triage — Phase 2 regression set (S12, S14, S22; S10 control)
Classification: pre-existing, unrelated to Phase 2 (not a code regression, not an obsolete test).
Confidence: high. Each fails at the SAME rate on the HEAD (pre-feature) session-start as on the current one (single-attempt, equal n: S12 0/3 vs 0/3, S14 0/3 vs 0/3, S22 0/3 vs 0/3).
Evidence: S12's strict negatives match explanatory prose ("I would not auto-chain to verify-codify", "run `/feature-verify-codify`"), a strict-mode fragility per root CLAUDE.md. S14 and S22 were already on the standing list. S12 is newly observed: it passed within retries in the Phase 1 sweep, so it is flaky-pre-existing. S10 (SOFT_PASS on both) never shows the menu because its request says "no stops", so it is not the no-line control the plan assumed.
Action: no test modified. S12 and the S10 control gap are added to `SURFACE-2026-11-03-SCENARIO-SWEEP-PREEXISTING-FAILURES`. A proper no-line session-start control scenario is written at Phase 2 codify. Proceed (FSD, operator standing rule).

## Test Triage — S43-start-without-claudesk-line-offers-mode-pick (new at Phase 2 codify)
Classification: obsolete/defective test — my newly written assertion is too narrow; the skill is correct.
Confidence: high. In all 3 dumped runs the model offers the drive-mode choice with no Claudesk line ("No Claudesk line is present … here is the text menu"). The 2 FAILs are anchor misses: `1\. Stepping` does not match the bolded `1. **Stepping**`, and one run describes the AskUserQuestion pick ("Autopilot as default … Pick a drive mode (Enter takes Autopilot)") instead of printing the menu.
Evidence: dumps under scratchpad/dumps-s43/r1..r3 (r1 PASS "1. Stepping:"; r3 FAIL "1. **Stepping**"; r2 FAIL describes the select).
Action: widen the anchors to bold-tolerant `1\. [*]*Stepping` plus the observed pick vocabulary (`Pick a drive mode`, `Which drive mode`, `Autopilot as default`), re-score the real dumps and the wrong-output cases through verify_result, then re-run.

## Test Triage — final sweep (run-all 2026-11-03 213423: haiku 11 FAIL / 2 FLAKY of 202; sonnet 1 FAIL of 17)
Known pre-existing (standing list, operator: proceed): F-verify-human-auto-skip-fires, F-verify-human-boundary-digest-advances, S14, S22, T3, F16-order-flip, DP-capture-skips-bare-fact, S33, S34 (by design), S3 [sonnet]. F-boundary-human and S12 appear in the FLAKY/soft list only.
### S43-start-without-claudesk-line-offers-mode-pick (this feature's own scenario)
Classification: obsolete/defective test (my anchor set is too narrow); the skill is correct.
Confidence: high. The failing re-run dump says "No Claudesk drive-mode line is in context, so I'd ask for the drive mode with `AskUserQuestion`. Autopilot is the default…", which is correct behavior in a third wording class the anchors did not foresee (after bold numbering and "Pick a drive mode").
Evidence: scratchpad/dumps-final/s43-4; sweep FAILs had the same "required-any content missing".
Action: add the stable signal, the tool name `AskUserQuestion` (a correct no-line reply either names the tool or prints the menu; a reply that skips the pick has no reason to name it), plus "ask for the drive mode". Re-score all 7 saved S43 dumps and the wrong-output cases through verify_result, then run fresh n≥6.
### DP-consult-changes (not on the standing list)
Classification: flaky test — failure unrelated to new code.
Confidence: high. It runs `product-wbs` against the stock `fixtures/CLAUDE.md`, and this feature changed neither (`git diff --name-only`). It was FLAKY in the Phase 1 sweep, under the same `env -u` harness. Re-run: FAIL, PASS, FAIL (inconsistent, i.e. flaky).
Action: no change; added to `SURFACE-2026-11-03-SCENARIO-SWEEP-PREEXISTING-FAILURES`.

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize (review-quality SKIPPED in FSD via F17b)
- **Blocked:** none
- **Unvisited:** ship → review-quality (SKIPPED in FSD) → finalize (CHANGELOG, archive, send the Claudesk ship note from scratchpad/claudesk-ship-note-draft.md)
- **Open discoveries:** 2 (mid-run Claudesk mode change — out of scope, logged; harness env leak — in scope as P1.0)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
- [SURFACED-2026-11-03] session-start step 4 (orchestrator loop) — Claudesk lets the operator change the workspace mode from its header at any time, and its line re-arrives on every turn. Only start/restore read it in this feature. Once a workflow is running, the orchestrator re-reads only the WIP's `drive_mode:`, so a mid-run Claudesk change is ignored. Out of scope here (Claudesk asked only about the pick). Logged as `SURFACE-2026-11-03-MID-RUN-CLAUDESK-MODE-CHANGE-IGNORED`.
- [SPIKE-2026-11-03] P1.1 — `AskUserQuestion` is **absent from the tool set** under `claude --print` with the harness flags (haiku: "there is no `AskUserQuestion` tool in this session", found by two ToolSearch queries, `permission_denials: []`). So in the scenario harness the A5 text-list fallback is the only path that can run. Scenarios assert on the fallback list, and the select-UI path is verifiable only interactively.
- [SURFACED-2026-11-03] P1.0 (harness) — `tests/run-tests.sh` subprocesses inherit `CLAUDESK_DRIVE_MODE` from the operator's shell. When the suite is launched from a Claudesk-spawned session, the user-level Claudesk `UserPromptSubmit` hook injects `Claudesk reports the drive mode for this workspace as autopilot.` into **every** scenario. Verified 2026-11-03: the line is present with the inherited var and absent under `env -u CLAUDESK_DRIVE_MODE`. Once this feature's skip rule lands, every menu-expecting scenario (S10, S15, S32) would go non-hermetic and fail only when run from Claudesk. In scope as P1.0 because this phase's outcomes depend on it.
- [BUILD-2026-11-03] P1.5 — `check_section_anchors` (from [Phase 23]) passes its boundaries through `awk -v`, which processes backslash escapes. A `\*\*` boundary reaches the regex as a bare `**`, and the window comes back EMPTY. It fails closed: every anchor reports "missing", so nothing passes silently. Fixed by using `[*]` in the boundaries, with a comment at the [Phase 25] call site. Pins: 13/13 single mutations (8 anchor deletions, 2 boundary renames, rung-order swap, harness `env -u` removal, S15-row scope) plus 1 moved-out-of-section mutation each yield FAIL. Clean tree: 0 FAIL. Wrong-output simulation through `verify_result` (S35–S37): all 6 wrong outputs FAIL and all 3 correct outputs PASS.
- [BUILD-2026-11-03] P1.4 — First live run: S35–S37 failed 3/3 because the model narrated a hypothetical restore without reading the fixtures ("Do NOT run any commands" in the shared prompt). Naming the pointer + WIP paths in `system_prompt_extra` (root CLAUDE.md fixture-path rule) → 3/3 PASS. **S31 regressed on the new prose under the same artifact:** 2/3 on the HEAD skill vs 0/3 after (each time `found S15`). The unread pointer means `tour:` is never seen, and the new 4b text steers the model toward "bare terminal → fallback → S15". This is harness-only (a real restore reads `.session.md`). Fixed by naming the path in S31/S32 too (assertions unchanged).
- [BUILD-2026-11-03] P1.4 measured (haiku): S35 6/6, S36 6/6, S37 6/6, S31 (triaged) 6/6, S32 3/3, S15 2/2, S16 2/2, S32 with an inherited `CLAUDESK_DRIVE_MODE=autopilot` 2/2 (P1.0 isolation holds). Still owed by verify: the S35 discrimination run (rung deleted → FAIL).
- [BUILD-2026-11-03] F9b re-verify gate: S35 3/3 with the feature present; discrimination arm (a) pre-feature HEAD skill 0/3 and arm (b) Claudesk-stripped skill 0/3, each `found S15`. Arm (a) shows "Restoring in **Autopilot** mode, from the handoff pointer" plus the menu, the same user-visible shape as the 2026-11-02 live failure. Skill restored and `cmp` byte-identical. S32 2/2 after the "(default)" label edit; check-structure 611/1 (unchanged).
- [BUILD-2026-11-03] P2.0 (self-inflicted, fixed) — writing S38's fixture overwrote the tracked `tests/fixtures/wip/notif-prefs-c.md` (used by F-vh-decision) because I did not check that the name existed. It was caught by `git diff --stat` showing it as modified, not new. Restored from HEAD; S38 moved to `notif-prefs-e*`; F-vh-decision 3/3 and S38 3/3 after. Phase 1's sweep triage is corrected above.
- [BUILD-2026-11-03] P2.0 — S39 (handoff under a Claudesk line writes `drive_mode: from-claudesk`): 3/3 with the change; pre-feature HEAD handoff 0/3 (writes the WIP's literal mode). S40 (restore of a marker pointer with NO line → WIP mode Stepping as current, pick offered, S15): 3/3 with the change, but **also 3/3 on the pre-P2.0 restore, and 3/3 with a comment-free bare marker on the pre-P2.0 restore**. The model treats `from-claudesk` as an invalid mode and falls through to the WIP on common sense alone. So S40 is a regression guard, not a discriminator; the rung-3 sentence and the inline comment are defense in depth. The discriminating half of P2.0 is the handoff side (S39).
- [BUILD-2026-11-03] P2.4 — [Phase 25] Phase-2 pins: 5 new checks (session-start step-3 anchors ×7, session-handoff step-2 anchors ×4, handoff source order, restore rung-3 marker, S17 row). Mutation sweep 16/16 → exactly 1 FAIL each (anchor deletions, both end boundaries, source-order swap); clean tree 0 FAIL; check-structure 616 PASS / 1 FAIL (pre-existing settings drift).
- [BUILD-2026-11-03] P2.3 — S41 (session-start under a Claudesk `fsd` line): 3/3 with the change ("I'll drive the feature workflow in **FSD**, the mode Claudesk reports for this workspace. Drive it?"; no menu); pre-feature HEAD session-start 0/3 (menu shown). S42 (incident under a Claudesk autopilot line → Orchestrated, no pick): 3/3 with the change and also 3/3 pre-feature, because the existing incident override already skipped the menu ("always runs Orchestrated (Mode 2), regardless of the workspace's autopilot setting"). S42 is a regression guard against the new rung overriding incidents, not a discriminator. session-start restored and `cmp` byte-identical.
- [BUILD-2026-11-03] P3.1 — both arms' REPLAY branches now say: speak the opening line, then ask with `AskUserQuestion` (`Autopilot (recommended)` first); "A Claudesk drive-mode line does not skip this pick" (the gear choice is the lesson); the numbered menu is kept verbatim as the fallback, so T3's first-run leak negatives ("Drive mode is how much the workflow chains", "Orchestrated") and the probe's "drive-mode menu" anchor stay live. Stale "numbered menu the workflow shows" wording was updated in both arms, `tutorial-getting-started`, the flow doc (invariant 4 + "Mode-switching") and root CLAUDE.md's tour bullet. No test anchored on it (grep). First-run copy and `tutorial-product-cycle-tour` are untouched.
- [BUILD-2026-11-03] P3.2 — check-structure 618/1: narration probe all PASS (anchors live in the arms, clean against session-reflect/handoff/capture); 2 new [Phase 25] replay-branch pins. Mutation sweep: 10/12 at first; the bare `AskUserQuestion` anchor survived deletion because the window's fallback sentence also names the tool (mechanism 4). Tightened to the instruction text, then 12/12 FAIL, clean 0.
- [CODIFY-2026-11-03] Phase 3 — NEW T5-tour-replay-under-claudesk-line-still-asks-gear (tutorial.yaml): a replay under a Claudesk `fsd` line still presents the gear pick. Tour arms emit no TRANSITION, and verify.sh enforces `contains_required*` only on an ID match, so T5 is `contains_any` (SOFT_PASS) + a strict negative. A skipped pick has no gear-pick anchor → FAIL. Simulated: the real verify-self capture → SOFT_PASS; "line skips the pick" and "session-start phrasing" → FAIL. Live 3/3 SOFT_PASS ("Pick your gear"). Full `run-all.sh` sweep started (last-phase codify).
- [SHIP-2026-11-03] Final verification: check-structure 618/1 after the arch.md as-built entry. The full `run-all.sh` sweep finished minutes earlier (5977s). The only scenario-affecting change since was S43's anchor widening (re-verified fresh 8/8), so a second ~100-min sweep was judged redundant. Committed locally; NOT pushed (see the drive-mode switch note).

## Retrospect
- **What changed in our understanding:** Claudesk's hook line was read for its *value* but never treated as *permission to skip*, and only an explicit rung in each skill fixes that (the 2026-11-02 failure, reproduced 0/3 on the pre-feature skills). The scenario harness was not hermetic: every suite launched from a Claudesk session injected the autopilot line into every scenario, so pre-2026-11-03 "green" baselines are not clean. `AskUserQuestion` does not exist under `claude --print`, so the harness can only ever exercise the numbered fallback, and the select UI is checkable only live (Claudesk ran that check).
- **Assumptions that held:** the precedence ladder (tour > Claudesk > recorded > state_file > orchestrated; incident override on top), Claudesk's leans on all four open decisions, and the `from-claudesk` marker being safe for Claudesk (confirmed, Ask 3).
- **Assumptions that were wrong:** (1) deleting one copy of a rule is a valid negative arm. S35 kept passing because the rule is restated in four other lines, so the negative arm became the pre-feature HEAD skill. (2) My anchors matched real model wording. Four times they missed a correct paraphrase (S38 filename dot, S43 ×2, the tour `AskUserQuestion` pin), each caught only by reading dumps or by mutation. (3) Every new scenario discriminates. S40 and S42 pass on the old skills too (common sense / the existing incident override), so they are regression guards. (4) I overwrote a tracked fixture (`notif-prefs-c.md`) by not checking the name, which faked an F-vh-decision "pre-existing" failure until it was restored.
- **Approach delta:** P1.0 (harness `env -u CLAUDESK_DRIVE_MODE`) was added mid-build. P2.0 (handoff deferral marker) was added by the operator at P1 verify-human, with the marker shape the agent's choice at the operator's request. The operator switched to FSD at Phase 2 verify-self, so verify-human was skipped for Phases 2–3 and A4/A6 were taken at plan defaults for review. A new repo rule landed: full sweep only at the last phase's codify. The Phase 3 outcome `grep -c 'Type 1–4' → 0` was amended to 1 (fallback kept by design).

## Closure (communicate)
> **Feature complete:** Drive-mode picker (select UI + Claudesk skip) has shipped. Under Claudesk, `/session-start` and `/session-restore` now take the workspace's reported mode and show no mode pick, `/session-handoff` defers the mode to Claudesk with a `from-claudesk` marker, and bare terminals get an `AskUserQuestion` select. Verify it live in a Claudesk workspace (`/session-start` should name the mode once and ask only "Drive it?"); scenarios S35–S43 and T5 cover it in the harness.
Requester = Claudesk workspace (inbox) + operator. The ship note goes to Claudesk's inbox; operator closure is the morning summary.

