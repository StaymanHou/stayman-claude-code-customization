# `claude-time visualize` — URL-hash view state

> Extracted from the repo-root `CLAUDE.md` on 2026-07-28 by `/util-prune-claude-md`
> (content verbatim). The root `CLAUDE.md` now carries a one-line pointer here.
> This convention governs the visualize dashboard only — it is **not** a
> project-wide URL pattern.

The `claude-time visualize` dashboard persists view state in the URL fragment so reloads survive and links are shareable. Introduced in WP5 Phase 3 of the `claude-time-visualize-v2` cycle. **This convention applies only to the visualize dashboard; it is not a project-wide URL pattern.** Downstream WP6 (Day rename), WP7 (Month view), WP8 (Custom-range), WP9 (Filter chips), WP13 (Collapsible projects) all extend this same hash schema rather than inventing a new one.

### Key shape

```
#viewport=480:1320;view=day;filters=active,subagent;expanded=projectA,projectB
```

- **Separator between pairs:** `;` (semicolon).
- **Key/value separator:** `=`.
- **Values are URL-encoded** via `encodeURIComponent`. Keys are URL-decoded on read but should stay alphanumeric in practice.
- **Order is not significant.** The hash is a set of key=value pairs, not a sequence.
- **No leading `#` in stored state** — the leading `#` is the URL fragment indicator only.

### Merge semantics

Each consumer owns one or more keys. Read and write go through shared helpers in `viz/dashboard.jsx`:

- `parseHash(): {key: value}` — reads `window.location.hash`, returns decoded key/value object. Missing hash → empty object.
- `updateHash(patch)` — applies `patch` to the current hash, preserving other keys, then calls `history.replaceState(null, '', '#<serialized>')`. **Values of `null` or `undefined` in `patch` delete the key entirely** (this is how default-elision is implemented).
- `serializeHash(obj): string` — produces the `key=value;key=value` form, skipping null/empty values.

Writes never `pushState` — viewport mutations are continuous (drag, wheel, key-repeat), so adding browser-history entries would be noisy. Always `replaceState`.

### Reload behavior

On Dashboard initial mount (`React.useEffect([])`), each consumer reads its own keys, parses, validates, and applies via the relevant `useState` initializer. Malformed values are ignored — the consumer falls back to its default. Round-trip stability is required: `parseHash(serializeHash(state))` ≡ `state` for every consumer's slice.

### Default-elision rule

When a consumer's current value equals its component-default (e.g., viewport equals "fit data window"; view equals `"day"`; filters is the empty/all-on set), the key is **omitted** from the hash. This keeps URLs short for the common "haven't customized anything" case. Each consumer is responsible for its own default-comparison: pass `null` to `updateHash({key: null})` when value equals default.

### Per-consumer key reservations (one-line examples)

| Consumer WP | Key | Example value | Default-elision when |
|---|---|---|---|
| WP5 (viewport) | `viewport` | `480:1320` (integer-minute pair, decimal, colon-separated) | viewport equals data-derived `_initialViewport()` |
| v3 WP5 (day iso) | `date` | `2026-05-29` (YYYY-MM-DD) | `dayIso === window.CT_DATA.window.end` (the most-recent pre-rendered day; the default landing) |
| v3 WP6 (week monday) | `week` | `2026-05-25` (YYYY-MM-DD, Monday-anchored) | `mondayIso === current_week_monday` (the Monday of the ISO-week containing `window.CT_DATA.window.end`) |
| WP6 (view tab) | `view` | `day` \| `week` \| `month` \| `custom` | `view == 'day'` (default) |
| WP7 (month) | `month` | `2026-05` (YYYY-MM) | view ≠ `month` |
| WP8 (custom range) | `range` | `2026-05-01:2026-05-07` (start:end ISO) | view ≠ `custom` |
| WP9 (filter chips) | `filters` | `active,subagent` (comma-separated kind names) | all kinds enabled (default) |
| WP10 (metrics card) | `metrics` | `expanded` (the only non-default value) | card is collapsed (default) |
| WP11 (compare preset) | `preset` | `wow` \| `today-vs-trailing` \| `mom` \| `custom` | view ≠ `compare` |
| WP11 (compare custom ranges) | `ranges` | `2026-05-13:2026-05-19,2026-05-20:2026-05-26` (two `:`-joined ISO pairs, comma-separated) | preset ≠ `custom` (and view ≠ `compare`) |
| WP13 (expanded projects) | `expanded` | `my-thing,om-design` (comma-separated project aliases) | default collapsed-state matches user pref |

### Round-trip example

```
#viewport=480:1320;view=month;month=2026-05;filters=active,subagent
↓ parseHash
{viewport: "480:1320", view: "month", month: "2026-05", filters: "active,subagent"}
↓ each consumer reads its own keys
WP5 viewport: { visible_start_min: 480, visible_end_min: 1320 }
WP6 view:     "month"
WP7 month:    "2026-05"
WP9 filters:  { active: true, subagent: true, reading: false, thinking: false, away: false }
```

### When to extend

Future WPs that need to persist state in the URL must (a) reserve a key in the table above with a one-line PR to this section, (b) implement read+write via `parseHash`/`updateHash`, (c) define their default-elision condition explicitly. Do not introduce alternate serializers (no JSON-in-fragment, no query-string `&` separators).
