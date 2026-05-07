---
type: case-study
date: 2026-05-06
incident: 2026-05-06-incident-canva-permission-denied
feature: 2026-05-06-canva-permission-warmup
relates-to: docs/product/transitions.md "Future Transitions — Hierarchy of facts"
---

# Case Study: User Domain Memory vs. API Error String

## Summary

During a P1 production incident on 2026-05-06, the agent (Claude) initially reached the wrong root-cause diagnosis by reading the Canva API error message at face value. The user pushed back on that diagnosis, citing a specific memory of how a prior, similar-looking incident had actually been resolved. When the agent re-investigated using the user's framing, the real root cause — which was structurally invisible from the API error string alone — was confirmed within minutes. This document records what happened, in sequence, with evidence.

## The Setup

### The reported failure

At 13:44 the user reported that the distribution wizard step 2 ("Canva 导出与拆分预览") was fully blocked. Four designs (`mialashstory7`, `hannah7lash`, `noragrowth`, `victorialash7daily`) all showed ERROR badges with the message:

> Canva Permission Denied: The authorized account does not have access to this design. Please ensure the design is shared with the authorized Canva account/team.

The user attached a screenshot and explicitly noted: "But I can access the designs just fine in browser using the canva user associated with the authentication here."

The token validity badge in the wizard read **239 minutes remaining**.

### The information available to the agent

The error string above was the agent's own translation/wrapping of the upstream Canva response. From `docker logs replicator_backend`, the actual Canva 403 body was:

```json
{
  "code": "permission_denied",
  "message": "Not allowed to access design with id DAHIiP36Sqs"
}
```

The wrapping copy lived at `backend/app/services/distribution_service.py:181` and `frontend/src/locales/{en,zh}/translation.json`. It blamed *sharing/team setup* — a reasonable-sounding interpretation of `permission_denied`, but one that turned out to be misleading.

## The First Diagnosis (Wrong)

### What the agent did

Between 13:47 and 13:55, the agent ran a structured investigation:

1. **Decoded the OAuth token JWT** to confirm scopes and brand context. Result:
   ```json
   {
     "sub": "oUYcIoD8KLuUeN3PYqTsog",
     "brand": "oBYcIhW4lNpVweHTMoaLZk",
     "scopes": ["asset:read","asset:write","design:content:read","folder:read"],
     "act_as": "u",
     "bundles": ["CT02"]
   }
   ```
2. **Confirmed scopes were sufficient.** `design:content:read` is the export-relevant scope; if it had been missing, Canva would have returned `missing_scope`, not `permission_denied`. So scope mismatch (H1) was correctly rejected.
3. **Walked the token's brand folder tree** via `GET /folders/root/items`. Found 1,105 designs in brand `oBYcIhW4lNpVweHTMoaLZk`. None of the four rejected IDs appeared in this brand's folder tree.

### What the agent concluded

From step 3, the agent inferred that the rejected designs were owned by a *different* brand/team than the one the OAuth token was bound to. This neatly matched the user-facing error copy: "Please ensure the design is shared with the authorized Canva account/team." The agent surfaced this as the diagnosis: the user had authorized the wrong brand context, and re-authorizing under the brand that owns those four designs would fix it.

This was wrong. Not by misreading the evidence — the evidence was real — but by following the API error string's framing of *what kind of problem* the evidence represented.

## The Pushback

### The user's response (verbatim)

> No. I'm pretty sure your assessment is wrong. The previous issue was resolved when the owner of the design provided 'can edit' permission (originally read-only permission). So the owner or team shouldn't matter. Also, use Playwright MCP to check. I'm pretty sure the design in question actually belongs to the team.

Three distinct pieces of information are packed into this message:

1. **Domain memory:** The user remembered a specific resolution path from a prior incident — "owner provided 'can edit' permission." This is a fact about the system's actual behavior that does not appear in the API documentation, the error message, or the source code.
2. **Logical implication:** From that memory, "the owner or team shouldn't matter" — a deduction that directly contradicted the agent's diagnosis.
3. **Method correction:** "Use Playwright MCP to check" — a tool-selection instruction that the agent had not been using.

The user was not just disagreeing; they were redirecting the investigation with a higher-information signal than the agent had been working from.

## The Re-Investigation (Right)

### What the agent did the second time

Between 13:56 and 14:00, the agent used Playwright MCP to drive Canva's web editor in the user's authenticated session, while simultaneously running `httpx` probes from inside the `replicator_backend` container against `https://api.canva.com/rest/v1/exports` for the same four design IDs.

The before/after table:

| Step | Action | DAHIiP36Sqs | DAHIiGxRfvw | DAHIjxn6QE4 | DAHIj78uC0c |
|------|--------|-------------|-------------|-------------|-------------|
| 1 | None opened | 403 | 403 | 403 | 403 |
| 2 | Opened DAHIiP36Sqs in browser | **200** | 403 | 403 | 403 |
| 3 | Opened DAHIiGxRfvw in browser | 200 | **200** | 403 | 403 |
| 4 | Opened DAHIjxn6QE4 and DAHIj78uC0c | 200 | 200 | **200** | **200** |

Same token. Same scopes. Same brand context. The only thing that changed `403 → 200` was whether the user had loaded the design in their browser.

### The actual root cause

Canva's Connect API does **lazy permission materialization** for shared designs: when a design is shared with a user (via link or explicit grant), the access record on the API side does not exist until the user loads the design's editor in their authenticated web session. Until that browser visit happens, the API returns `403 permission_denied: Not allowed to access design with id X` — even with all required scopes and an otherwise-valid sharing link.

This also retro-explained the prior incident the user remembered. The fix that time was characterized as "owner upgraded permission from view to edit." But the necessary co-trigger — also present in that timeline but not previously credited — was that the user opened the design in-browser to verify the new permission. The browser visit was doing the materialization work; the permission upgrade alone would not have been sufficient.

### Mitigation

By the end of step 4, all four designs had been browser-warmed as a side effect of verification. The user re-ran distribution wizard step 2; all four exports succeeded. Incident resolved at 14:08, 24 minutes after report.

## Anatomy of the Misdiagnosis

The agent's first diagnosis was **internally consistent** — every observation (scopes correct, designs not in brand folder, token bound to one brand) was real and correctly interpreted within the framing the agent had adopted. The framing itself was the failure mode.

That framing came from one place: the API error string. `permission_denied` plus "Not allowed to access design with id" reads as *"this token does not have access rights to this resource."* That is a true statement, but it conflates two structurally different conditions:

1. **The token's identity lacks rights to the resource.** (e.g., wrong brand, missing scope, revoked grant.)
2. **The token's identity has rights, but Canva has not yet materialized the access record.** (Lazy permission materialization — discoverable only by side-channel observation.)

Canva's API returns the same `permission_denied` code for both. The user-facing error copy in our codebase only described condition (1), so the investigation never considered condition (2). The brand folder walk that "confirmed" condition (1) was actually evidence-neutral — a shared design that the user has access to via canva.link sharing also doesn't appear in the brand folder. Both states produce the same observation.

## Why the User Was Right

The user did not have technical evidence the agent lacked — at the moment they pushed back, the agent had read the JWT, walked the folder tree, and confirmed scopes; the user had not. What the user had was **historical evidence about the system's actual behavior** that no API documentation or error message could surface:

- **Specific past-resolution path:** "Owner provided 'can edit' permission." This locates the working-vs-failing axis somewhere other than brand context.
- **Negative implication:** "The owner or team shouldn't matter." Eliminates an entire class of hypothesis the agent was inside.
- **Tool-selection signal:** "Use Playwright MCP to check." Suggests the user thinks the answer requires an interactive browser session, which is a strong hint about the nature of the failure.

None of this information was retrievable from the API error string, the codebase, or the database. It existed only in the user's memory of how the system had behaved before.

## Sequence of Events (compressed)

| Time | Actor | Action |
|------|-------|--------|
| 13:44 | User | Reports P1, attaches screenshot, notes browser access works |
| 13:46 | Agent | Triages P1, fully blocked, must-fix-now |
| 13:47–13:55 | Agent | Decodes JWT, walks brand folder, diagnoses brand-mismatch |
| 13:55 | User | Pushes back, cites prior-incident resolution path, instructs Playwright |
| 13:56–14:00 | Agent | Re-investigates with Playwright, builds before/after table, confirms lazy permission materialization |
| 14:00 | Agent | Mitigation complete — all four designs warmed via browser visits |
| 14:08 | User | Confirms wizard step 2 proceeds; incident resolved |

Total elapsed: 24 minutes. Time spent on the wrong diagnosis: 8 minutes (13:47–13:55). Time from pushback to root-cause confirmation: 5 minutes (13:55–14:00).

## What the Codebase Carried Forward

The following artifacts now encode this experience in the project:

- **`workflow/archive/2026-05-06-incident-canva-permission-denied.md`** — full incident report with the verification table and rejected hypotheses.
- **`docs/product/research.md`** — Canva Connect API quirks section, "Lazy permission materialization."
- **`backend/app/services/distribution_service.py`** — 403 detection now matches `code: "permission_denied"` AND message containing "Not allowed to access design with id"; raises a typed `CanvaPermissionNotWarmedError` carrying `design_id`, `design_edit_url`, `design_share_url`. Other 403 shapes raise generic `ValueError("Canva access denied: ...")` so they remain visibly distinct.
- **`backend/app/api/v1/endpoints/distribution.py`** — emits a structured 400 with `error_code: "canva_permission_not_warmed"` so the wizard can drive the warm-up without re-parsing strings.
- **`frontend/src/locales/{en,zh}/translation.json`** — `dist.canva_permission_not_warmed_msg`, `dist.open_in_canva_btn`, `dist.auto_warming_designs`. The old "shared with the authorized account/team" copy that misled the original investigation has been removed (verified by `grep` returning 0 matches).
- **Chrome extension v1.1.0** — warms shared Canva designs in hidden background tabs to materialize the permission record automatically.

## Bottom Line

The Canva API returned a true error message — `permission_denied` was not a lie. But the error string described one possible cause, and the actual cause was a different thing that produced the same string. The agent's investigation, anchored to the string, walked confidently in the wrong direction. The user, anchored to a memory of how the system had actually behaved, redirected the investigation. The user's redirect was not a guess; it was a higher-information signal than anything available to the agent at the moment of pushback.
