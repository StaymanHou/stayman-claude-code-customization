---
name: Multi-turn replay research mirrors production conditions
description: When spiking the multi-turn session-replay harness, research/spike runs use Opus 4.7 + dot-free /tmp/claude-replay-<uuid> cwd to mirror real bug conditions rather than a cheap proxy
type: feedback
originSessionId: 8a022eb1-e1df-47f9-b6e5-1adfc5f7f1b5
---
When researching or spiking the multi-turn session-replay harness (or its tool_result manufacturing / pause-detection signal), invoke `claude --resume` against **Opus 4.7** and the **dot-free `/tmp/claude-replay-<uuid>` working directory**. Do not substitute a cheaper model or a non-prod path even when "the API shape is what we're testing."

**Why:** The autopilot-pause-policy bug class is a narrative-cadence-drift failure that may be model-specific or context-window-shape-specific. The 2026-05-16 single-shot replay attempt produced 3/3 PASS (false negatives) even with `system_prompt_extra` stripped — exact root cause for that PASS is still open. Running spikes on a different model would risk shipping a harness that "works" in research but misses the production bug for the same class of reason. User explicitly confirmed 2026-05-17: "Let's try to mirror the real bug conditions."

**How to apply:** Default model for `claude --resume` in `tools/replay-session-*.sh` and any feature-research spike scripts targeting this harness = Opus 4.7. Use `/tmp/claude-replay-<uuid>` (no `.` characters in slug) for the cwd handed to `claude --resume`. If a future cost-pressure decision wants to override this for non-bug-reproducing scenarios, that's a per-scenario opt-out, not a default flip.

**Ratified per-scenario opt-out (2026-09-21, operator-confirmed).** The `opus5-edge-pause`
WBS scopes **opus-5**, not 4.7. This is the opt-out this memory's "How to apply" anticipates,
not a default flip: the bug under study there is a *measured opus-5-specific* regression
(8.2% vs 1.6% on opus-4-8 at F10b, Fisher p = 4.1×10⁻⁶), so 4.7 is the wrong instrument —
it largely does not exhibit the behaviour. The 4.7 default still stands for the original
2026-05-16 autopilot-pause-policy bug class. The dot-free `/tmp` cwd rule is **unaffected**
and still applies. See [[project_pain_points]].
