---
workflow: feature
state: ship (complete)
created: 2026-05-29
shipped: 2026-05-29
ship_commit: b7718ae
cycle: claude-time-visualize-v3
wbs_item: WP3
drive_mode: autopilot
---

# Feature: v3 WP3 — Unified `--window` flag

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-29
**Entry:** spec (complex feature) → plan
**WBS:** `docs/product/wbs.md` → Phase 1, WP3 (M, depends on WP1)

## Problem Statement

`claude-time visualize` currently exposes a sprawl of view-selecting CLI flags — `--date`, `--week`, `--month`, `--range`, `--compare`, `--compare-range`, plus context-expansion knobs `--context-days-prior`/`--context-days-after`. Each was added incrementally during v2 to support a new view type, and they cumulatively encode the load-bearing decision "what does this CLI invocation render?" at the CLI layer.

v3's emit-model pivot (one invocation → pre-rendered up-to-~90-day window with all sub-payloads; frontend handles every Day/Week/Month/Compare slice as client-side state swap) makes the v2 flag sprawl architecturally wrong: the CLI no longer needs to pick a view, only a **time-range** to pre-render. The view selection moves entirely to URL-hash dispatch on the frontend (Phase 2 — WP5–WP9).

WP3 introduces a single unified `--window` flag that supersedes all the v2 view-selecting flags by expressing only the time-range. WP4 deletes the v2 flags immediately afterward. This is the cleanest expression of the v3 emit model at the CLI surface, and it's the prerequisite for the Phase 2 frontend refactor (the frontend needs the new payload shape under a stable CLI surface to consume).

## User Stories

- **As the single user of claude-time**, I want to invoke `claude-time visualize` with no flags and get a default dashboard covering the current calendar month plus the prior 2 months (≈MTD-2), so that Month-view nav always shows full prior months instead of a mid-month-truncated leading month.
- **As the single user**, I want to express "the same calendar-anchored shape with a different N" as `--window MTD-N` (e.g., `--window MTD-3` for current month + 3 priors), so that overriding the default is consistent with how the default is shaped.
- **As the single user**, I want to express "show me the last N days from today" as `--window Nd` (e.g., `--window 30d`), so that rolling-from-today queries are short and memorable.
- **As the single user**, I want to express "show me this specific range" as `--window YYYY-MM-DD:YYYY-MM-DD`, so that audit-style "what happened between dates X and Y" queries are unambiguous.
- **As the single user**, I want consistent error messages when I mistype the window, so that I can self-correct without consulting the README.

## Decision: Flag syntax

**Decision:** A single `--window <value>` flag, where `<value>` is one of three parser-discriminated forms:

| Form | Shape | Meaning | Example (today = 2026-05-29) |
|---|---|---|---|
| **MTD + N prior calendar months** | `^MTD-(\d+)$` | Month-to-date PLUS N prior calendar months, anchored to the 1st of the earliest month; end = today | `--window MTD-2` → `2026-03-01 : 2026-05-29` |
| **Rolling N days** | `^(\d+)d$` | Last N calendar days ending today (inclusive) | `--window 30d` → `2026-04-30 : 2026-05-29` |
| **Explicit range** | `^(\d{4}-\d{2}-\d{2}):(\d{4}-\d{2}-\d{2})$` | Explicit `START:END` ISO range, inclusive | `--window 2026-04-01:2026-05-26` |

**Anything else** → argparse error message: `error: --window expects MTD-N (e.g. MTD-2), Nd (e.g. 30d), or YYYY-MM-DD:YYYY-MM-DD (e.g. 2026-04-01:2026-05-26), got <value>`.

**`MTD-N` end-date rule:** end is *today*, not end-of-current-month. Never include future days (no events there; matches the existing v2 `end <= today` validation rule). `MTD-0` = just this month so far. `MTD-2` = this month so far + 2 prior calendar months.

**Default (no flag):** `--window MTD-2` — current calendar month + 2 prior calendar months, anchored to the 1st of the earliest month, ending today.

### Why calendar-anchored, not rolling, for the default

User-decided 2026-05-29: a rolling-90 default produces a window like `2026-02-28 : 2026-05-29`, which means the Month view's `month_payloads_by_iso["2026-02"]` would contain only Feb 28's data — a near-empty payload, confusing when the user clicks through Month nav. The MTD+N model puts **full calendar months in the window** so the Month view always shows complete months (except the current MTD). Day-count varies 59–92 days across the calendar (worst-case ≈92 days on the last day of a long month with two prior 31-day months — still within WP2's measured budget; WP2 confirmed ≤2s/≤500KB up to 120 days).

### Why three forms, not two

`MTD-N` is **not equivalent** to any `Nd` value — they have distinct semantics (calendar-anchored vs rolling-from-today). Keeping all three:

- **MTD-N** is the natural shape for "I want the current calendar position with N priors" — including being the default.
- **Nd** is the natural shape for "I want the last N days" — rolling-from-today queries (e.g., "last week").
- **Explicit range** is the natural shape for "what happened between these specific dates" — audit-style queries.

Each form has a clear operational meaning that the other two can't express as cleanly.

### Why one combined flag, not split (`--window-mtd` + `--window-days` + `--window-range`)

- A split surface has three flags users must learn instead of one.
- A discriminator on value-form (regex match) is ~15 lines of parsing logic with one clear error message. The split would require ~30 lines (three arg definitions + mutex guard).
- The combined form lets the default be expressed as `MTD-2` consistently, not as a hidden default with no flag-form.

### Why **not** `WTD` / `YTD` / etc.

Out of scope for WP3. If the user later wants week-to-date or year-to-date shorthands, they can be added in a follow-up WP without breaking the three-form contract — just additional regex branches.

## Acceptance Criteria

The feature is done when:

1. **`viz` subparser gains `--window`.** `claude-time visualize --window MTD-2` succeeds; `claude-time visualize --window 30d` succeeds; `claude-time visualize --window 2026-04-01:2026-05-26` succeeds; `claude-time visualize` (no flag) succeeds with the default `MTD-2` window.
2. **Parser validates the three forms.** Bad input produces a single-line argparse error naming all three accepted shapes with examples. Exit code 2 (argparse convention). No DB or filesystem work happens on bad input.
3. **MTD-N computation is correct.** For today = 2026-05-29: `MTD-0` → `2026-05-01:2026-05-29`; `MTD-1` → `2026-04-01:2026-05-29`; `MTD-2` → `2026-03-01:2026-05-29`; `MTD-12` → `2025-05-01:2026-05-29`. Year-boundary crossing works (`MTD-5` on 2026-03-15 → `2025-10-01:2026-03-15`). End is *always today*, never end-of-month.
4. **Window bounds are validated.** `end >= start`; `end <= today`; `day_count <= viz_window_max_days` (new config key, default 365). Each violation produces a distinct, actionable error message.
5. **`_cmd_visualize` routes `--window` to `build_window_data`.** When the flag is present (or defaulted), the resolved `(start_iso, end_iso)` are passed to `build_window_data`; the returned payload is emitted as `window.CT_DATA` with the new shape (sub-payload maps).
6. **`--demo` mutex.** `--window` + `--demo` together → exit code 2 with message `error: --window is incompatible with --demo (demo data is single-day)`.
7. **`--help` text** shows the `--window` flag with all three forms documented (plus `--demo`, `--no-open`, `--out`). v2 legacy flags are still present in WP3 (they get deleted in WP4) but should be marked deprecated in their help strings if cheap; otherwise leave them untouched and let WP4 do the cleanup.
8. **`viz_window_max_days` config key exists.** Default 365. Validates as non-negative int via existing `_validate_nonneg_int` path. Loadable from `~/.claude-time/config.json`.
9. **`test_visualize_cli.sh` covers the new surface.** At minimum: `--window MTD-2` produces a payload whose `day_payloads_by_iso` spans from the 1st of the earliest month through today; `--window 30d` produces a payload whose `day_payloads_by_iso` has 30 keys; `--window 2026-04-01:2026-05-26` matches explicit bounds; default invocation produces an MTD-2 payload; `--window` + `--demo` → rc=2; bad shape → rc=2 with the expected error message.
10. **Python test suite passes.** `tests/run-all.sh` (or the project's existing python suite) reports 0 FAIL.
11. **Structure pins pass.** `tests/check-structure.sh` reports 0 FAIL.

## Out of Scope

- **Legacy flag removal.** `--date`, `--week`, `--month`, `--range`, `--compare`, `--compare-range`, `--context-days-prior`, `--context-days-after` stay in place during WP3 — they still work in their v2 behavior. **WP4** deletes them. WP3's job is to land `--window` as a new flag that can coexist briefly. Rationale: separating "add the new" from "remove the old" keeps the diff scoped and lets WP3 verify-self exercise the new flag against a stable backdrop.
- **Frontend changes.** No `viz_render.py` interactive-dashboard changes. The emitted `window.CT_DATA` shape changes (sub-payload maps replace the single-view payload), but the existing frontend views still read what they currently read — `window.CT_DATA.today`, `window.CT_DATA.comparison`, etc. **WP5–WP9** rewire each view to consume the new sub-payload maps. **For WP3 to compile and ship, `build_window_data`'s return shape MUST include `today` / `comparison` / etc. as backwards-compat aliases** (see Technical Constraints below) — or the legacy frontend breaks before WP5 lands.
- **URL-hash schema additions.** No new hash keys in WP3. WP5–WP9 add `date=`, `week=`, `month=` etc.
- **Config-tunable default window shape.** No `viz_default_window` config key. The `MTD-2` default is hardcoded; user override is the `--window` flag at invocation time. (Per WBS scope line 40: "Configurable window size beyond default 90-day — no UI affordance to tune the default.")
- **Other calendar-anchored shorthands** (`WTD`, `YTD`, `LASTWEEK`, etc.). Out of scope for WP3 — only `MTD-N` is implemented. Future WPs may add additional regex branches.
- **`MTD-N` ending end-of-month** (instead of today). Rejected — never include future days, since there are no events there; matches the existing v2 `end <= today` validation rule.

## Technical Constraints

### Coexistence with v2 frontend (the hidden constraint)

**This is the most important detail in the spec.** WP3 changes the emitted `window.CT_DATA` shape from "one view payload" to "sub-payload maps under `day_payloads_by_iso`, `week_payloads_by_monday`, etc." But the v2 frontend (`viz_render.py::_interactive_dashboard` and the components it injects) still reads the old keys (`window.CT_DATA.today`, `window.CT_DATA.comparison`, etc.).

**WP3 must NOT break the frontend.** Two options:

- **Option A — Backwards-compat alias keys.** `build_window_data` already returns the sub-payload maps; WP3 additionally populates legacy top-level keys (`today`, `comparison`, `range`, etc.) by aliasing the relevant sub-payload (e.g., `today = day_payloads_by_iso[end_iso]`, the most-recent day in the window; `comparison = compare_payloads_by_preset["wow"]` or whatever v2 defaulted to). The legacy frontend continues to render today's slice as if nothing changed; the new sub-payload maps are inert until WP5 wires them up.
- **Option B — Frontend coexistence stubs.** `viz_render.py` is edited to read sub-payload maps when present, falling back to legacy keys otherwise. Rejected: this is WP5's territory and would force WP3 to touch frontend code.

**Decision: Option A.** `build_window_data` returns BOTH the new sub-payload maps AND the legacy top-level keys (as derived aliases). The frontend stays untouched. WP5–WP9 wire the new keys and the legacy alias keys become dead weight; WP9's verify-codify removes them. This is a temporary structural cost (one extra ~15-line aliasing block in `viz_data.py::build_window_data`) for the benefit of fully isolated WPs.

### Mutex landscape (interim, during WP3)

Until WP4 deletes them, the v2 flags coexist with `--window`. The interim mutex rules:

- `--window` + `--demo` → error (decided above)
- `--window` + any of `--date`/`--week`/`--month`/`--range`/`--compare`/`--compare-range` → **`--window` wins silently** (the others become no-ops). Rationale: these are deprecated and getting deleted in WP4 within days; an explicit error here would just produce noise the user has to dismiss.
- `--window` + `--context-days-prior`/`--context-days-after` → **the context-days flags become no-ops** (silently ignored). Rationale: in v3 the pre-rendered window IS the context; there is nothing left to expand. WP4 deletes them.
- All existing v2 mutex rules between legacy flags remain unchanged during the WP3/WP4 transition.

### `viz_window_max_days` config key

- **New default:** 365.
- **Purpose:** Sanity cap on the explicit-range form (prevents `--window 2020-01-01:2026-05-29` from emitting ~6 years of data and OOM-ing the browser).
- **Validation:** Reuse `_validate_nonneg_int`. Honors the same silent-fallback discipline as the other config keys.
- **Error message** when violated: `error: --window range spans <N> days, exceeds viz_window_max_days cap (<cap>); reduce range or raise viz_window_max_days in ~/.claude-time/config.json`.

### Existing `viz_context_days_*` config keys

**Removed in WP4 alongside `--context-days-*` flags.** Rationale: they encoded the v2 single-day-with-context viewport model that v3 supersedes entirely. WP3 does not touch them; WP4 deletes both the config keys and the flags in one move. The user's `~/.claude-time/config.json` may still have them set after WP4 ships — the silent-drop config loader handles unknown keys gracefully.

### `_cmd_visualize` integration point

The existing function already handles the v2 flag landscape. WP3 adds an early branch at the top:

```python
# WP3: --window (or default to MTD-2) wins over v2 flags during the transition.
# WP4 deletes the v2 flags entirely.
window_arg = args.window if args.window is not None else "MTD-2"
start_iso, end_iso = _parse_window_arg(window_arg, today=date.today(),
                                       max_days=cfg["viz_window_max_days"])
if start_iso is None:  # parse/validation failed; _parse_window_arg printed error
    return 2
if args.demo:
    print("error: --window is incompatible with --demo ...", file=sys.stderr)
    return 2
# Load events for the full window, build pre-rendered payload, emit.
events = _load_events_for_window(db_path, start_iso, end_iso)
payload = build_window_data(start_iso, end_iso, events_by_day=events,
                            cfg=cfg, auto_alias_fn=resolve_auto_alias)
# Legacy alias keys (Option A — coexistence with v2 frontend).
payload["today"] = payload["day_payloads_by_iso"][end_iso]
payload["comparison"] = payload["compare_payloads_by_preset"]["wow"]
# ... etc.
_emit_html(payload, ...)
return 0
```

The v2 flag branches below this become unreachable when `--window` is implicit-defaulted; WP4 deletes them outright.

### URL-hash schema (no impact in WP3)

The existing schema (per CLAUDE.md "Claude-time visualize URL-hash state") is untouched in WP3. WP5–WP9 add the new keys (`date=`, `week=`, `month=`). The colon-separated convention of `--window 2026-04-01:2026-05-26` happens to harmonize with the existing hash convention (`range=2026-05-01:2026-05-07`); this is reassuring but not a hard requirement WP3 has to satisfy.

## Open Questions

None. The spec is clear. Proceed to `/feature-plan`.

(Should anything surface during plan or build, attach as a discovery to the WIP file's `## Discoveries` section.)

---

## Work Tree

- [x] Phase 1: Parser + validation + config key  <!-- complete 2026-05-29 — parser implementation, validation, config key + help-text contract codified -->
  **Observable outcomes:**
  - CLI: `python -c "import sys; sys.path.insert(0,'tools/claude-time'); from importlib.machinery import SourceFileLoader; m=SourceFileLoader('claude_time','tools/claude-time/claude-time').load_module(); s,e=m._parse_window_arg('MTD-2', today=__import__('datetime').date(2026,5,29), max_days=365); print(f'{s}|{e}')"` exits 0 and stdout matches `2026-03-01|2026-05-29`
  - CLI: same one-liner with `'30d'` stdout matches `2026-04-30|2026-05-29`; with `'2026-04-01:2026-05-26'` stdout matches `2026-04-01|2026-05-26`
  - CLI: same one-liner with `'garbage'` exits non-zero AND stderr contains `error: --window expects MTD-N`, `Nd`, and `YYYY-MM-DD:YYYY-MM-DD`
  - CLI: same one-liner with `'2020-01-01:2026-05-29'` (>365 days) exits non-zero AND stderr contains `exceeds viz_window_max_days`
  - CLI: `python -c "import json,sys; sys.path.insert(0,'tools/claude-time'); from importlib.machinery import SourceFileLoader; m=SourceFileLoader('claude_time','tools/claude-time/claude-time').load_module(); print(m.DEFAULT_CONFIG['viz_window_max_days'])"` exits 0 and stdout matches `365`
  - [x] P1.1 Add `viz_window_max_days: 365` to `DEFAULT_CONFIG`; add it to the `_validate_nonneg_int` allow-list in `load_config` next to the existing `viz_context_days_*` / `viz_custom_range_max_days` keys
  - [x] P1.2 Add `--window` argument to the `viz` subparser (positional `metavar="VALUE"`, default `None`, help text documenting all three forms with one example each)
  - [x] P1.3 Implement `_parse_window_arg(raw: str, *, today: date, max_days: int) -> tuple[date, date] | tuple[None, None]` at module level. Three regex branches (MTD-N, Nd, START:END) tried in order; first match wins; non-match prints error message and returns `(None, None)`. Validation: `end >= start`; `end <= today`; `day_count <= max_days`. Each violation prints a distinct error to stderr and returns `(None, None)`.
  - [x] P1.4 MTD-N date arithmetic: walk back N calendar months from today's `(year, month)` using zero-indexed month-count arithmetic (`m_idx = year*12 + (month-1) - n`; `divmod(m_idx, 12)`); anchor to day=1 of resulting month. Year-boundary crossing verified by Phase 1 outcome `MTD-5 on 2026-03-15 → 2025-10-01:2026-03-15`. End is always `today`.
  - [x] verify-auto  <!-- Phase 1 — py_compile clean; module-load smoke confirms DEFAULT_CONFIG['viz_window_max_days']=365 and _parse_window_arg callable; --help mentions --window -->
  - [x] verify-self  <!-- Phase 1 — 7/7 observable outcomes PASS (MTD-2, 30d, explicit range, garbage→error, >365d→error, config default 365, --help mentions --window/MTD-N/Nd). Integration boundary acknowledged: `--window` arg added to existing `viz` subparser; `claude-time visualize --help` outcome cites the consuming surface. -->
  - [x] verify-human  <!-- Phase 1 — user approved both leaves 2026-05-29: P1.verify-human.1 help-text contract confirmed; P1.verify-human.2 config-key contract (viz_window_max_days=365) confirmed -->
    - [x] P1.verify-human.1 Consuming-surface check: `--help` shows all three `--window` forms with examples, default MTD-2, `--demo` mutex, v2-supersession note. User confirmed reads sensibly.
    - [x] P1.verify-human.2 Decision-artifact ack: config-key `viz_window_max_days=365` confirmed as the right contract to lock in.
  - [x] verify-codify  <!-- Phase 1 — added one shell-test pin in `test_visualize_cli.sh` §1c covering the consuming-surface contract: `--help` lists `--window VALUE` at column 3, names all three forms (MTD-N, Nd, YYYY-MM-DD:YYYY-MM-DD), states MTD-2 default. Test suite 198/0 (was 197/0). Parser correctness behaviors deferred to Phase 3 shell tests where the full CLI surface is testable (consistent with project convention: existing parsers _parse_range_flag/_parse_month_flag have no Python unit tests either; they're tested only at shell-level via CLI invocation). No integration-boundary regression — Phase 1's only consuming-surface mutation is the `--help` text, and it's now codified. -->

- [x] Phase 2: `_cmd_visualize` integration + legacy alias keys + `--demo` mutex  <!-- complete 2026-05-29 — integration wired, legacy alias keys cover today/week/comparison/metrics/meta/months, --demo mutex enforced, boundary-contract test codified at verify-codify, 33 obsolete v2-flag tests cleaned up with collateral refactor -->
  **Observable outcomes:**
  - CLI: `claude-time visualize --window MTD-2 --out /tmp/wp3-mtd2.html --no-open` exits 0; `/tmp/wp3-mtd2.html` contains a `window.CT_DATA =` literal with `day_payloads_by_iso`, `week_payloads_by_monday`, `month_payloads_by_iso`, `compare_payloads_by_preset`, `metrics`, AND legacy alias keys `today`, `comparison` at the top level
  - CLI: same invocation, the emitted JSON's `window.start` equals the 1st of (today's month minus 2 months); `window.end` equals today's ISO; `day_payloads_by_iso` has a key for every ISO day in `[window.start..window.end]` inclusive
  - CLI: `claude-time visualize --window 30d --out /tmp/wp3-30d.html --no-open` exits 0; emitted `day_payloads_by_iso` has exactly 30 keys
  - CLI: `claude-time visualize --out /tmp/wp3-default.html --no-open` (no `--window` flag) exits 0; emitted `window.start`/`window.end` match an MTD-2 window
  - CLI: `claude-time visualize --window 30d --demo --no-open` exits with code 2 AND stderr contains `error: --window is incompatible with --demo`
  - CLI: `claude-time visualize --window garbage --no-open` exits with code 2 AND stderr contains the three accepted shapes
  - Browser: opening `/tmp/wp3-mtd2.html` in Playwright loads without JS console errors (legacy frontend keeps rendering off the alias keys — this is the regression-protection check)
  - [x] P2.1 In `_cmd_visualize`, added the `--window`/default resolution branch at the top of the function (after viz-asset check, before all v2 flag handling). Branch fires when `args.window is not None OR not args.demo` (the bypass: bare `--demo` keeps v2 demo path — see SURFACED-2026-05-29 discovery). On parse fail returns rc=2 (printed by `_parse_window_arg`).
  - [x] P2.2 Added `--window` + `--demo` mutex check at the top of the new branch (fires only when `args.window is not None AND args.demo`). Prints `error: --window is incompatible with --demo (demo data is single-day)` to stderr, returns rc=2.
  - [x] P2.3 Loaded events for the full window via the existing `_load_window_events(db_path, day)` helper (re-used the same per-day helper the v2 paths use; iterates `[win_start..win_end]` building `events_by_day`). Called `build_window_data(win_start.isoformat(), win_end.isoformat(), events_by_day=..., cfg=cfg, auto_alias_fn=_auto_alias_for_cwd)`. Added DB-missing guard matching v2's "no DB + no --demo" rc=1 helpful-error UX.
  - [x] P2.4 Legacy alias-key block added after `build_window_data` returns. Audited `viz_render.py` via grep `CT_DATA\\.` and found 5 distinct top-level keys the v2 frontend reads: `today`, `comparison`, `metrics`, `meta`, `months`. Aliased each: `today = day_payloads_by_iso[end_iso]`; `comparison = compare_payloads_by_preset["wow"]`; `metrics` already top-level; `meta = {snapshot: now().isoformat}`; `months = month_payloads_by_iso`. v3 sub-payload maps (`day_payloads_by_iso`, `week_payloads_by_monday`, `month_payloads_by_iso`, `compare_payloads_by_preset`, `window`) all top-level alongside aliases. WP9 verify-codify removes the aliases as dead weight.
  - [x] P2.5 v2 flag silent-override: when `--window` is set OR no `--demo`, the new branch always returns rc=0 before reaching the v2 handlers below. The v2 flags (`--date`/`--week`/`--month`/`--range`/`--compare`/`--compare-range`/`--context-days-*`) are silently no-op'd in WP3 (they remain on `args` but unused). No warning emitted. WP4 deletes them entirely.
  - [x] verify-auto  <!-- Phase 2 — py_compile clean; module-load smoke confirms _cmd_visualize + _parse_window_arg callable, viz_window_max_days=365; --help parses cleanly (argparse wiring intact after splice). -->
  - [x] verify-self  <!-- Phase 2 — 10/10 outcomes PASS (7 CLI: default MTD-2, --window 30d, --window 2026-04-01:2026-05-26, --window+--demo mutex, --window garbage error, bare --demo preserved, legacy+v3 keys present) + (3 browser via Playwright subagent: page loads w/o JS errors, Day view renders content, headline metrics card renders). Hit one BLOCKING fail mid-skill (alias-key audit missed `week` destructure + `meta.{start,end,day_count}` reads); fixed in-place at P2.4 alias block; re-verified via fresh subagent — see SURFACED-2026-05-29 P2.4 entry under ## Discoveries for procedure-deviation note + audit-trail. -->
  - [x] verify-human  <!-- Phase 2 — user approved both leaves 2026-05-29: P2.verify-human.1 consuming-surface check (real-browser eyeball) confirmed; P2.verify-human.2 procedure-deviation ack confirmed (verify-self in-place fix accepted; two backlog items to be filed after Phase 2 closes). -->
    - [x] P2.verify-human.1 Consuming-surface check: real-browser eyeball of `file:///tmp/wp3-test/wp3-30d.html` confirmed dashboard renders cleanly.
    - [x] P2.verify-human.2 Procedure-deviation ack: user OK with in-place fix during verify-self; two backlog items deferred to Phase 2 close.
  - [x] verify-codify  <!-- Phase 2 — added boundary-contract scenario at test_visualize_cli.sh §"v3 WP3 Phase 2 codify" (2 assertions: --window 30d emits HTML rc=0; emit has BOTH v3 sub-payload keys + legacy alias keys side-by-side). Test triage cleanup: deleted 33 obsolete v2-flag scenarios (--week/--date/--context-days-*, WP5b codify, WP8-P1 view-selecting/validation/mutex 10 scenarios, WP7-P1 view-selecting/validation/mutex 12 scenarios), rerouted 6 collateral source HTMLs to --window 7d emits, fixed 1 code regression (no-DB error message phrasing). Final: test_visualize_cli.sh 167/0; Python 130/0; structure pins 125/0. -->

- [x] Phase 3: `test_visualize_cli.sh` pins  <!-- complete 2026-05-29 — 8 new shell-test scenarios codify --window MTD-2 default, 30d day_count, explicit range, default-invocation regression, --window+--demo mutex, three bad-shape error sub-cases. Test suite end-state: 175/0 visualize + 130/0 Python + 125/0 structure pins. -->
  **Observable outcomes:**
  - CLI: `tools/claude-time/test/test_visualize_cli.sh` exits 0 with the new scenarios added
  - CLI: `python -m unittest discover tools/claude-time/test -p 'test_*.py'` (or equivalent suite invocation) exits 0 with no regressions
  - CLI: `tests/check-structure.sh` exits 0 with all pins green
  - [x] P3.1 Added `--window MTD-2` scenario asserting calendar-anchored start (1st of (today's month − 2)), end=today, correct day_count. Expected bounds computed dynamically per run via Python (`date.today()` + month-arithmetic) so the test stays correct across calendar boundaries.
  - [x] P3.2 Added `--window 30d` scenario asserting `day_payloads_by_iso` has exactly 30 keys AND `window.start == today-29` AND `window.day_count == 30`. Uses JSON parse via `re.search` + `json.loads` (matches existing project pattern at WP10-P1 codify-9).
  - [x] P3.3 Added `--window 2026-04-01:2026-05-26` scenario asserting explicit bounds match + `window.day_count == 56`.
  - [x] P3.4 Added bare-invocation regression-pin: `visualize --no-open --out X` (no `--window`) → `window.start` matches MTD-2 anchor + `window.end == today`. Guards against a future change silently shifting the default.
  - [x] P3.5 Added `--window 30d --demo` mutex scenario: rc=2 + stderr contains `"incompatible with --demo"`.
  - [x] P3.6 Added 3 bad-shape sub-scenarios: (a) `--window garbage` → rc=2 + stderr names all three forms; (b) `--window 2026-05-29:2026-05-01` (inverted) → rc=2 + stderr names `"end >= start"`; (c) `--window 2020-01-01:2026-05-29` (oversize 2341 days) → rc=2 + stderr names `"exceeds viz_window_max_days"`. Note: dropped the originally-planned `--window 2026-99-99:2026-01-01` sub-scenario because `2026-99-99` would also fail the explicit-range regex match BEFORE reaching the bounds check — the inverted-range case is a more direct bounds-validation pin.
  - [x] P3.7 Ran full Python test suite (130/0) + structure pins (125/0). No regressions.
  - [x] verify-auto  <!-- Phase 3 — bash -n parse on test_visualize_cli.sh PASS; file is executable; all 8 new Phase 3 scenarios PASS in targeted run. shellcheck not installed on this machine (informational, not a regression). -->
  - [x] verify-self  <!-- Phase 3 — 3/3 observable outcomes PASS: test_visualize_cli.sh 175/0 (all 8 new scenarios + every prior scenario); Python suite 130/0; structure pins 125/0. No integration boundary (test file only). No BLOCKING fails, no COSMETIC fails. -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [x] verify-human  <!-- Phase 3 — F11 skip-affirmation taken 2026-05-29. No integration boundary (test file only). User confirmed skip after affirmation. -->
  - [x] verify-codify  <!-- Phase 3 — Phase 3 IS the codification phase (8 new shell-test scenarios ARE the codification artifact). No additional test work needed. Full suite green: test_visualize_cli.sh 175/0, Python 130/0, structure pins 125/0. No test triage needed (zero failures). -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** WP3 shipped via commit `b7718ae` on origin/main; finalize in progress (retrospect + CHANGELOG + WBS update + backlog file + archive).
- **Blocked:** none
- **Unvisited:** finalize → (next WP: WP4 legacy flag removal)
- **WP3 final state:**
  - Phase 1 (parser + validation + config key): SHIPPED
  - Phase 2 (`_cmd_visualize` integration + legacy alias keys + `--demo` mutex): SHIPPED, including the cleanup of 33 obsolete v2-flag test scenarios and refactor of 6 collateral source HTMLs
  - Phase 3 (test codification — 8 new shell-test scenarios): SHIPPED
  - Test baseline: **test_visualize_cli.sh 175/0, Python 130/0, structure pins 125/0** — all green
- **Backlog candidates to file at finalize time (3):**
  - (a) Alias-key audit method needs destructuring-pattern coverage, not just `prop\.` grep — caught at Phase 2 verify-self.
  - (b) verify-self in-place-fix shortcut policy when the fix is a trivial extension of the just-completed leaf — process gap surfaced at Phase 2 verify-self.
  - (c) WP3 plan-level miss: the 33 obsolete v2-flag tests should have been flagged in the plan's downstream-contract-impacts pass as a Phase 2 deliverable, not surfaced as a 25-FAIL surprise at verify-codify. The triage gate caught it, but planning should have.
- **Phase 3 verify-auto evidence:** `bash -n` parse on `test_visualize_cli.sh` PASS; file is executable; all 8 new Phase 3 scenarios PASS in targeted run.
- **Phase 3 verify-self evidence:** 3/3 observable outcomes PASS — `test_visualize_cli.sh` 175/0 (8 new scenarios + all prior scenarios still green), Python suite 130/0, structure pins 125/0. No integration boundary (test file only — not a consuming surface). No BLOCKING fails, no COSMETIC fails.
- **Open discoveries:** Two SURFACED-2026-05-29 entries under `## Discoveries` — still to be filed to `workflow/backlog.md` after WP3 ships, plus a new third backlog candidate: "WP3 plan-level miss — the 33 obsolete v2-flag test scenarios should have been flagged in the plan-level downstream-contract-impacts pass as a Phase 2 deliverable; instead they surfaced at verify-codify Test Triage as a 25-FAIL surprise. The triage gate caught it, but planning should have."
- **Phase 2 verify-codify evidence:** Test triage classified 25 failures into Triage-1 (24 obsolete v2-flag tests, HIGH confidence) + Triage-2 (1 code regression in error-message phrasing, HIGH confidence, auto-fixed). User chose path (b) — delete-now + refactor collateral. 33 v2-flag scenarios deleted (24 failing + 9 PASSing-but-also-obsolete like --range happy/--month help/--range+--demo mutex), 6 source HTMLs rerouted to --window emits, 1 wrapper-integrity test rerouted, kept 6+ source-shape pins that survive the v2/v3 distinction. Final: test_visualize_cli.sh 167/0 (down from 200/25, net -36+3 with one added boundary-contract test = 167); Python 130/0; structure pins 125/0.
- **Blocked:** none
- **Unvisited:** Phase 2 (verify-codify), Phase 3 (full)
- **Open discoveries:** Two SURFACED-2026-05-29 entries under `## Discoveries` — (a) `--demo` UX preservation (resolved in-code at P2.1); (b) alias-key audit miss + in-skill fix at P2.4 (procedure-deviation note for audit-trail; both findings tagged for backlog after Phase 2 closes).
- **Phase 2 verify-self evidence:** 10/10 outcomes PASS — 7 CLI (default MTD-2 → 2026-03-01:2026-05-29/90; --window 30d → 30 day_payloads; explicit range → day_count=56; --window+--demo mutex rc=2; --window garbage rc=2; bare --demo preserved 181KB emit; legacy+v3 keys present) + 3 browser (Playwright subagent confirmed page loads without JS errors, Day view renders 4 projects/7 sessions, headline metrics card shows "Past 30 days · 2026-04-30 → 2026-05-29" — proving meta.start/end aliases work). One mid-skill BLOCKING fail (alias-key audit missed `week` + `meta.{start,end,day_count}`) fixed in-place at P2.4, then re-verified clean.

## Test Triage — Phase 2 verify-codify (`test_visualize_cli.sh` 25 FAILs)

Phase 2 verify-codify ran the full `test_visualize_cli.sh` and observed 175 PASS / 25 FAIL. Triage per `## CLAUDE.md` six-case table:

### Triage entry 1 — 24 of 25 failures: obsolete v2-flag tests

**Failing tests (24):** `--week sets CT_INITIAL_VIEW="week"`; `--date 1970-01-01`; `WP5b: --context-days 0/0 keeps single-day shape`; `WP5b codify: config.json applied`; `WP5b codify: invalid-config-fallback`; `WP5b codify: week-coexists`; `WP5b codify: target_iso path-divergence`; `WP8-P1 codify: --range emits CT_INITIAL_VIEW="custom"`; `WP8-P1 codify: --range meta.start/end/day_count`; `WP8-P1 codify: validation end<start`; `WP8-P1 codify: validation days>cap`; `WP8-P1 codify: validation end>today`; `WP8-P1 codify: validation bad shape`; `WP8-P1 codify: warning on combined flags`; `WP8-P1 codify: config cap override`; `WP7-P1 codify: --month emits CT_INITIAL_VIEW="month"`; `WP7-P1 codify: months map keys`; `WP7-P1 codify: default-emit no-months`; `WP7-P1 codify: bad shape exit`; `WP7-P1 codify: month bounds exit`; `WP7-P1 codify: future month exit`; `WP7-P1 codify: --month + --range mutex`; `WP7-P1 codify: D6 fallback identity`; `WP10-P1 codify-9: window math`.

**Classification:** Obsolete test — new feature intentionally supersedes what the test checked.

**Confidence:** **High.** Each of these 24 tests asserts a v2-flag behavior (`--date`/`--week`/`--month`/`--range`/`--context-days-*` view-selecting effects, their argparse validation messages, the v2 single-window meta shape) that the v3 emit model intentionally retires. Phase 2 silently no-ops the v2 flags (default-to-MTD-2 always fires); WP4 deletes them outright per WBS task 4.1. The supersession is documented in the WP3 spec under "Out of Scope" → "Legacy flag removal" and in WBS task 3.4 ("Legacy flags are removed in WP4 — WP3 does not need to preserve them"). Each failure has exactly one explanation: the v2 flag's effect was intentionally subsumed by the v3 `--window` flag. No hedging required.

**Evidence:** Each of the 24 failures reports either `rc=0` where the test expected rc=2 (v2 validation no longer fires because `--window` defaults take precedence) OR a missing `CT_INITIAL_VIEW`/`meta.start`/`months` value (the v3 emit shape replaces the v2 single-view shape). All 24 are downstream of the same single architectural change: Phase 2 routes all CLI invocations through `build_window_data` regardless of v2 flags.

**Action taken (user chose path b — delete-now + refactor collateral, 2026-05-29):**

The initial "24-line surgical delete" estimate was wrong. The obsolete tests shared setup blocks with adjacent PASSing tests, and downstream blocks consumed the v2-flag-emitted HTMLs ($WP5B_OUT5, $WP8_HAPPY, $WP7_HAPPY) for source-shape pins that were agnostic to which CLI flag emitted them. Full execution:

1. **Sections 8 + 9 + 9b** (`--week`, `--date`, `--context-days 0/0`): deleted as standalone obsolete blocks (test_visualize_cli.sh:172–198).

2. **WP5b codify block** (6 scenarios, 4 FAIL): all 6 scenarios deleted (they all tested viz_context_days_* behaviors that v3 retires). The downstream **WP5b-P2 codify block** (renderer multi-day source-shape pins on `dashboard.jsx`/`viz_render.py` internals — `dayOffsetMin`, `pickTickInterval`, `DataWindowContext`, `SessionRow.key`, etc.) was preserved with its $WP5B_OUT5 source rerouted from `--date 2026-05-22` emit to `--window 7d` emit.

3. **WP8 Phase 1 codify block** (13 scenarios, 8 FAIL): 10 scenarios deleted (--range view-selecting effects, validation, mutex). 3 scenarios kept + rerouted to `--window 7d` emit: WP8-4 (CT_MAX_RANGE_DAYS template injection — still relevant for Compare-custom-range UI), WP8-12 (invalid viz_custom_range_max_days config fallback — config key still exists), WP8-13 (test file regex hardening — unrelated to --range). $WP8_HAPPY source rerouted to `--window 7d`; the WP8 Phase 2 codify block downstream (Custom tab + RangePicker + validateRange UI source-shape pins) survives because those are source pins, not data-shape pins.

4. **WP7 Phase 1 codify block** (13 scenarios, 8 FAIL): 12 scenarios deleted (--month view-selecting effects, validation, mutex, two-month payload shape). 1 scenario kept: WP7-P1-13 (viz_render.render_html Python signature pin — unrelated to --month flag). $WP7_HAPPY source rerouted to `--window 7d` emit; the WP7 Phase 2 codify block downstream (MonthView UI source-shape pins) survives.

5. **WP10-P1 codify-9** (1 FAIL — trailing-7-day window math): $WP10C_HAPPY emit rerouted from bare `visualize --no-open` (which now defaults to MTD-2/90-day) to `--window 7d` so the trailing-7-day assertion holds.

6. **WP5-P1 codify wrapper-integrity** (1 FAIL — collateral damage from section 8's `v-week.html` deletion): rerouted source HTML from `$TMPDIR/v-week.html` to a fresh `--window 7d` emit. The pin is a source-shape check on `function Dashboard(` + `ViewportContext`, agnostic to initial view.

**Final state after cleanup (2026-05-29):**
- `test_visualize_cli.sh`: **167 PASS / 0 FAIL** (was 200/25 pre-cleanup; net delta = 33 scenarios removed, 3 new scenarios added — §1c help-text contract + 2 boundary-contract assertions)
- Python suite: **130 / 0 FAIL**
- Structure pins: **125 / 0 FAIL** (was 124 / 1 FAIL because visualize test was wrapped)

WP4's WBS task 4.3 still applies — replacing the deleted scenarios with `--window`-based equivalents where the v2 behavior is still in scope. The current state is "all v2-flag-specific assertions removed"; WP4 will add `--window`-coverage for behaviors that genuinely need coverage. The kept-and-rerouted assertions (WP8-4, WP8-12, WP8-13, WP7-P1-13, WP5b-P2-* x9, WP10C-9, WP5-P1 wrapper integrity) all assert behaviors that are NOT v2-specific and still relevant under v3.

---

### Triage entry 2 — `no DB + no --demo: helpful error`

**Failing test (1):** `no DB + no --demo: exits non-zero with helpful error` (line 226 of `test_visualize_cli.sh`).

**Classification:** Code regression — new code subtly broke the test contract.

**Confidence:** **High.** The test asserts `rc != 0` AND stderr contains the phrase `"does not exist"` (case-insensitive grep at line 226). My new branch returns `rc=1` ✓ but emits `"DB not found at <path>; create it via the claude-time hook or use --demo to render with mock data."` — which doesn't contain "does not exist". The phrase mismatch is the entire failure.

**Evidence:** Test failure output: `rc=1, out='error: DB not found at /var/folders/.../events.sqlite; create it via the claude-time hook or use --demo to render with mock data.'` — confirms rc is correct but the message wording diverges from the v2 wording.

**Action:** Auto-fix code by aligning the new branch's error message to contain "does not exist" (the v2 phrasing). One-line edit at `_cmd_visualize`'s no-DB-no-demo branch. Re-run after.

---

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-05-29] Phase 2 build P2.1 — spec ambiguity resolved: the `--window` MTD-2 default applies only when `--demo` is NOT set. Bare `--demo` (no `--window`) continues to render the v2 single-day demo path. Explicit `--window` + `--demo` together is the rc=2 error. Rationale: `--demo` is a data-source flag (not a view-selecting flag), and the spec's whole `--window`/`--demo` mutex point is "demo data is single-day, so windowing makes no sense for it" — that's a statement about an EXPLICIT user pairing, not a license to break bare-`--demo` UX. Confirmed by re-reading spec lines 83 + 116 + P2.1 wording. Decision encoded in code via order-of-checks: explicit-`--window`-resolution branch checks `args.demo` first and returns rc=2 if both; default-to-MTD-2 branch fires only when `args.window is None AND args.demo is False`. (Not backlogged — this is a Phase 2 internal disambiguation that doesn't affect downstream WPs.)

[SURFACED-2026-05-29] Phase 2 verify-self P2.4 — initial alias-key audit was incomplete. The `grep CT_DATA\.` audit I ran during build P2.4 missed two contracts that the v2 frontend reads via destructuring rather than direct property access: (1) `const {today, week} = window.CT_DATA` at viz_render.py:69 (and dashboard.jsx:3198), so `week` must be aliased; (2) `data.meta.start`/`data.meta.end`/`data.meta.day_count` at dashboard.jsx:2317/2346/2955, so `meta` needs more than just `{snapshot}`. First browser-load attempt crashed Dashboard on mount with `TypeError: Cannot read properties of undefined (reading 'projects')` (3 BLOCKING fails from one root cause). Fixed in-place by extending P2.4's alias-key block: added `payload["week"] = week_payloads_by_monday[end_monday_iso]` with fallback-to-last-Monday for narrow windows; expanded `payload["meta"]` from `{snapshot}` to `{snapshot, start, end, day_count}`. Re-verified via fresh browser subagent: 3/3 PASS, Dashboard mounts, metrics subtitle reads "Past 30 days · 2026-04-30 → 2026-05-29" (proving the meta.start/end aliases are wired correctly). **Procedure deviation note:** verify-self is contractually "observe only" with code fixes going through F9b back-loop. I shortcut that to in-place fix because (a) the bug was a one-line extension of the same P2.4 alias block I'd just written, (b) re-verification went through a fresh subagent (same audit artifact as a back-loop would produce), and (c) formal back-loop would have produced 3 extra Skill invocations for the same outcome. Tagging here for audit-trail clarity. Backlog SURFACE candidate (lower-priority): "verify-self in-place-fix shortcut when fix is a trivial extension of the just-completed leaf" — capture as a workflow-system tweak rather than re-litigating now. ALSO: the alias-key-audit miss itself is a more important learning — the audit method was "grep CT_DATA\." but the v2 frontend uses destructuring, requiring a separate "grep for `const \\{.*\\} = window.CT_DATA`" pass. Logging both to backlog after Phase 2 closes.

## Retrospect

- **What changed in our understanding:**
  - **Calendar-anchored default is the right model, not rolling-N-days.** The plan-time draft had the default as rolling-90; user pushed back at spec time with "today, I want MTD + Apr + Mar, not Mar 29 – May 29." Counter-proposed three-form parser with `MTD-N` as a first-class form (originally rejected as redundant); user confirmed. The downstream Month-view payload integrity argument (rolling-90 produces a near-empty leading month) was the load-bearing reason the user's intuition was correct. Lesson: the spec's "load-bearing question" framing surfaced this disagreement at the right venue (spec elicitation, not build).
  - **Alias-key audits need destructuring-pattern coverage.** Phase 2 P2.4 grep `CT_DATA\.` missed `const {today, week} = window.CT_DATA` destructure + `meta.{start,end,day_count}` reads. The v2 frontend reads CT_DATA both via direct property access AND via destructuring; the grep only caught the former. Caught at verify-self via Playwright subagent — Dashboard crashed on mount, 3 BLOCKING fails. Fixed in-place during verify-self (procedure deviation noted).
  - **Plan-level "downstream contract impacts" pass is critical when removing a CLI flag.** WP3's plan deferred the test-codification entirely to Phase 3; never surfaced that Phase 2's "silently no-op the v2 flags" decision would obsolete ~33 existing test scenarios. Surfaced at verify-codify as a 25-FAIL surprise; Test Triage gate caught it, but planning should have. (See backlog candidate `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS`.)
  - **Test-cleanup scope underestimated by ~10×.** Initial estimate was "24-line surgical delete." Actual scope was ~250 lines crossing 3 setup blocks (WP5b, WP8-P1, WP7-P1), with 6 source-HTML emissions requiring reroute from `--date`/`--range`/`--month` to `--window 7d`. The downstream source-shape pins on `dashboard.jsx`/`viz_render.py` internals (renderer multi-day, RangePicker UI, MonthView UI) had to be preserved — they're agnostic to which CLI flag emitted the bundle but they need *an* emit to assert against. The cleanup itself took as long as the build did.

- **Assumptions that held:**
  - WP1's `build_window_data` coordinator slotted cleanly into the new `--window` branch with no shape changes — the pre-WP3 perf probe (WP2) validated the 30→120-day cost range, and WP3's MTD-N default lands within that envelope.
  - WP2's "90-day default" decision survived the spec-time pivot to calendar-anchored MTD-2 (which produces 59–92 days depending on calendar date — still inside WP2's measured perf envelope).
  - The integration-boundary rule fired correctly at verify-self / verify-human / verify-codify and shaped the test set appropriately (per-phase boundary citations + consuming-surface tests).
  - The project's shell-level CLI testing convention (no Python unit tests for parsers) held — Phase 1 verify-codify's deferral of parser correctness tests to Phase 3 matched the codebase pattern.

- **Assumptions that were wrong:**
  - **"24 obsolete tests = 24 isolated 6-line blocks."** Reality was 3 large blocks with shared setup and downstream source-shape consumers. Re-scoping mid-skill cost an extra ~30 minutes of careful surgery + reroute work.
  - **"Grep `CT_DATA\.` catches all v2 frontend reads."** Missed destructuring patterns entirely. The audit method needs to grep `const \{.*\} = window.CT_DATA` too.
  - **"`--demo` mutex is straightforward."** Took a spec re-read mid-build to disambiguate: explicit `--window` + `--demo` is the error, but BARE `--demo` (no `--window`) should bypass the MTD-2 default and use the v2 demo path. The spec's mutex language was about the explicit pairing, not the implicit default. Logged as `SURFACED-2026-05-29 P2.1 spec ambiguity` under `## Discoveries`.

- **Approach delta:**
  - Spec's "two forms (Nd + START:END)" became "three forms (MTD-N + Nd + START:END)" mid-spec at user request. Followed through cleanly in plan, build, and codify.
  - Phase 2 verify-self deviated from observe-only by fixing the alias-key audit miss in-place (vs F9b back-loop). Documented as audit-trail in `## Discoveries`; user approved at verify-human.
  - Phase 2 verify-codify expanded scope to include obsolete-test cleanup (~33 scenarios deleted, 6 source-HTML rerouted). Plan deferred this to "WP4 will handle it"; user chose path (b) — clean it up now to ship green.
  - Phase 3 verify-codify is effectively a no-op (the codification artifact IS Phase 3's build). Confirmed test suite green; no new test work.
  - Otherwise the implementation matched the plan: 3 phases, observable outcomes mechanically verifiable, build → verify-auto → verify-self → verify-human → verify-codify loop on each phase, autopilot drive mode throughout.

## Communicate

> **Feature complete:** claude-time visualize v3 WP3 (unified `--window` flag) has shipped. The CLI now accepts `--window MTD-N` (calendar-anchored), `--window Nd` (rolling), or `--window YYYY-MM-DD:YYYY-MM-DD` (explicit range), defaulting to `MTD-2` (current month + 2 priors). The legacy v2 flags (`--date`, `--week`, `--month`, `--range`, `--compare*`, `--context-days-*`) coexist as silent no-ops; WP4 will delete them. To verify, run `claude-time visualize --window 30d --no-open --out /tmp/check.html` and confirm the emitted dashboard shows a 30-day window.
>
> Requester = operator — closure notice for self-record.

## Plan-level notes

### Why three phases, not two

The natural temptation is to fold Phase 3 (`test_visualize_cli.sh` pins) into Phase 2 (`_cmd_visualize` integration). I split them deliberately:

- Phase 2's verify-self exercises the new flag in isolation — observable outcomes hit the emitted HTML directly via grep/file inspection. That's enough to confirm the flag works end-to-end.
- Phase 3 codifies those behaviors as **shell-test scenarios** that run on every future commit. This is the long-term regression guard for the contract.
- If P2 verify-self passes but P3 codification reveals a corner case (e.g., a date-boundary edge in `MTD-N` arithmetic), the back-loop is to Phase 1's parser, not to Phase 2's integration. Separating the phases keeps that back-loop clean.

### Integration-boundary check (per per-phase verify loop rule)

- **Phase 1** modifies isolated module-level functions (`_parse_window_arg`, `DEFAULT_CONFIG` dict) — no integration boundary touched (no endpoint, UI, CLI surface, job, external call consumes them yet). verify-self can use the F11 skip-affirmation path. **But:** the spec's `viz_window_max_days` config key IS a new public config surface — verify-human should ack the key name + default value as a one-leaf checklist item (consistent with WP2's probe-WP pattern where decision-artifact outcomes need humans-only review).
- **Phase 2** modifies the `viz` CLI subcommand — **integration boundary present** (the CLI is the user-consuming surface). verify-self MUST run the live CLI; verify-human MUST do a manual eyeball of the emitted HTML in a browser; verify-codify MUST add at least one shell-test scenario asserting the boundary contract.
- **Phase 3** is the test-codification phase itself. verify-codify is effectively the body of work; verify-self confirms the test suite is green end-to-end.

### Things that could surface during build (pre-flag risk list)

- **`build_window_data` legacy-key audit.** The spec says the legacy alias keys are derived from the new sub-payloads. But the v2 frontend may read keys we haven't enumerated yet. Phase 2 P2.4 includes a `grep` audit step — if the audit surfaces an unexpected key, attach a discovery and back-loop to spec for the alias-set decision.
- **`MTD-N` year-boundary arithmetic.** Walking back N months across a year boundary is the classic off-by-one bug. The Phase 1 outcome includes a `MTD-5 on 2026-03-15` test case specifically to catch this. If it fails, it's caught at P1's verify-self.
- **Event-loading path for multi-day windows.** v2's event-loader supports `--range`; v3 reuses it but the window may be much wider (up to 365 days vs v2's 90-day cap). If perf regresses past WP2's 2s budget at the upper bound, that's a discovery for Phase 2.
- **`test_visualize_cli.sh` is shell, not Python.** Date arithmetic for "1st of (today's month minus 2)" in bash requires `date -d` GNU coreutils OR `python -c` interpolation. Phase 3 likely uses `python -c` for date math then asserts via `grep` on emitted HTML. If the existing test file establishes a different pattern, follow it.

### Sequence-of-execution (for `## Current Node` Unvisited field)

Phase 1 → Phase 2 → Phase 3, sequentially. No parallelism (each phase's verify-self depends on the prior phase's code being in place).
