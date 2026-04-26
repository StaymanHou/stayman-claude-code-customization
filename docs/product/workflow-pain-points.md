# Workflow Pain Points — Diagnostic Reference

*Captured: 2026-04-25. Raw diagnosis only — no fixes proposed here. Use this as input when designing improvements to skills and the WIP format.*

---

## Pain Point 1: No Live Problem Tree — the Workflow is Linear When it Must be Recursive

### What was observed

- Agent holds a verification checklist [A, B, C, D] in `verify-human`.
- Human checks A. It fails (e.g., login page broken — can't log in, text contrast bad).
- Agent re-enters `build`, fixes A across multiple rounds, then auto-advances.
- B, C, D were never checked — some of them (e.g., anything requiring login) were blocked by A's failure.
- Agent forgot they existed, or treated them as implicitly done.

- While fixing A.1, agent discovers new work that belongs to node B (e.g., retry logic needed in B's domain).
- There is nowhere in the tree to attach that discovery. It goes to the flat backlog, which is not re-read when B is eventually reached.

### Root causes

**RC1-1: The WIP file is a linear checklist, not a tree.** There is no parent-child relationship between a phase, its verification items, and the individual failed leaves. No node has an explicit status. No parent tracks whether its children are complete.

**RC1-2: `verify-human` produces a flat checklist, not a subtree.** Each item is a checkbox with no persistent identity. When the agent re-enters `build`, it has no record of which specific items failed vs. passed. It re-enters with "fix phase 2," not "fix A.3.1 and A.3.2."

**RC1-3: No rule prevents advancing a parent node until all children are done.** The agent can mark a phase complete even when individual verification leaves are still open. There is no enforcement mechanism.

**RC1-4: Re-entry scope is not passed as structured args.** When `verify-human` sends the agent back to `build`, it does not pass which specific leaves failed. The agent infers scope from conversation context, which is lossy.

**RC1-5: Discoveries cannot attach to a specific tree node.** The backlog is a flat append-only log. A discovery made while working on A.1 that belongs to B has no link to B's node. When the agent reaches B, it does not re-read the backlog by default.

**RC1-6: Dependency-blocked items have no explicit status.** "Can't test C without A working" is not representable in the current format. The agent either skips C silently or marks it untested without flagging the dependency.

---

## Pain Point 2: Agent Self-Verification is Shallow and Premature

### What was observed

- Agent runs unit tests, they pass, it declares the phase done and hands off to human.
- Human opens the browser — blank page, obvious JS console error. Agent never opened the browser.
- Human reports failure. Agent fixes it. Says "fixed." Human re-opens — still broken, different error underneath.
- Agent never re-verified after its own fix before handing back to human.
- Verification bar is asymmetric: agent applies lenient standard to itself, escalates strict verification to human.

### Inferred scenario coverage

**Web UI:** blank page (JS bundle error, missing env var, bad import); broken layout (CSS not loaded); non-responsive element (wrong event handler target, JS error on click); silent form submission failure; SPA routing / stale cache issues.

**API/Backend:** 200 with wrong response shape; passes without auth middleware; background job silently fails in real env (missing env var, wrong queue); migration applied but queries still fail.

**CLI tools:** exits 0 but wrong stdout; works with fixture data, fails on real data; fails on second run (idempotency bug).

**3rd-party integrations:** webhook registered but never fires (wrong URL, missing secret); API call works in staging, fails in real env (key scope, rate limit, version).

**Cross-cutting:** fix works for the reported case but breaks a sibling case; fix introduces regression in unrelated area.

### Root causes

**RC2-1: The agent treats "code is written" as equivalent to "behavior is correct."** No step forces it to observe the running system as a user would — in a browser, via curl, via a real CLI invocation with real data.

**RC2-2: `feature-verify-auto` is scoped to the test suite only.** It has no mandate to start the application and observe it. "Automated" means test runner, not live system observation.

**RC2-3: The handoff to `verify-human` is too early.** The agent escalates to human review before exhausting what it could verify itself with available tools (Playwright MCP, curl, Bash with real endpoints). Human eyes are treated as a cheap resource.

**RC2-4: No re-verify gate after a fix.** When the agent re-enters `build` from a human rejection, it fixes the code and immediately transitions back to `verify-human`. It does not re-run its own observable checks before handing back.

**RC2-5: No behavioral definition of done.** The WIP plan describes implementation tasks ("add endpoint," "wire up form") but not observable outcomes ("hitting /login returns 200 with session cookie," "login page renders a form with two inputs and a submit button"). Without a target, the agent has no criterion for self-verification.

**RC2-6: Failure severity is not classified.** The agent has no concept of "blank page" (ship-blocking) vs. "button 2px off-center" (cosmetic). It either escalates everything to human or fixes everything itself — no triage between blocking and non-blocking observations.

---

## Pain Point 3: WBS Decomposition Order Optimizes for Architecture, Not Learning

### What was observed

The WBS for Replicator-1.0 front-loaded:
- Docker environment (WP1)
- Full API clients for Canva and GeeLark (WP2)
- Full DB schema and models (WP3)
- Celery + Redis orchestration layer (WP4)

...before any API behavior was confirmed with real calls, before any UX was validated, and before the synchronous path was proven.

The desired order was:
1. "Hello world" CLI scripts hitting real Canva and GeeLark API endpoints — prove connectivity, discover actual input/output shapes
2. Frontend-only with mockup data — validate UX before any backend exists
3. Backend without orchestration — build against confirmed API shapes and confirmed UX contracts
4. Introduce orchestration last — refactor in async layer only after synchronous path is proven

Note: Docker environment setup should still be the very first step (WP0), since it is the foundation that every subsequent command runs inside. The issue is not Docker first — it is everything *after* Docker being ordered by architectural completeness rather than learning sequence.

### Root causes

**RC3-1: The agent decomposes by "what does the final system need" rather than "what do we need to learn first."** Build dependencies (what must exist to compile) drive the order, not learning dependencies (what must be known before something is worth building). These orderings are often opposite.

**RC3-2: No concept of a "spike" or "probe" class of work package.** Everything in the WBS is a "build this" item. There is no vocabulary for "learn this cheaply before committing." Without that distinction, the agent defaults to building.

**RC3-3: 3rd-party API unknowns are hidden inside work packages rather than treated as blockers.** WP2 assumes known API shapes. Those assumptions propagate forward — DB models, task logic, frontend contracts are all defined against assumed schemas. If the real API differs, WP2–WP8 are all wrong.

**RC3-4: UX is treated as downstream of backend.** Frontend depends on backend API, which depends on models and orchestration. The first time a human sees the actual experience is near the end. UX problems discovered then require unwinding decisions made in WP3, WP4, WP5.

**RC3-5: The orchestration layer is treated as a foundation concern rather than a refactor concern.** Celery/Redis adds async indirection that multiplies debugging surface area. Every failure could be in task logic, the queue, the worker, or the broker. Introducing it before the synchronous path is proven means every early bug is harder to isolate. The orchestration layer also can't be meaningfully verified by a user — it's invisible infrastructure.

**RC3-6: No explicit "de-risking order" heuristic in the WBS skill.** The `product-wbs` skill prompt instructs the agent to identify dependencies and size work packages, but does not instruct it to order phases by risk/uncertainty reduction. The critical principle — "validate the unknown before building on top of it" — is absent.

---

## Cross-Cutting Observation

All three pain points share a common underlying failure: **the agent optimizes for the appearance of progress (code written, tests passing, WBS complete) rather than for validated understanding at each step.** The problem-solving algorithm this workflow is based on treats the iterative hypothesis→verify→learn→pivot loop as the primary activity. The current workflow treats building as the primary activity and verification as a gate at the end. Closing that gap is the common thread across all three fixes.

---

## Framework Gaps — Current Workflow vs. Problem-Solving Algorithm

*Reference: `problem_solving_algorithm` repo (1_overview.md, 2_framework.md, 9_all_together.rb). The algorithm defines 6 steps — Identify → Decompose → Prioritize → Build → Test & Analyze → Retrospect & Communicate — wrapped in a recursive/iterative loop with explicit exit conditions. Gaps below are ordered by diagnosed severity.*

---

### Gap F1: Root Problem Re-Identification Happens Once, Not Every Iteration (HIGH)

**Algorithm:** `identify(problem)` is the first thing called on every pass through the while loop. It re-checks whether the presented problem is the root problem, re-acquires domain knowledge, and re-specifies desired I/O. If the root problem has shifted, the entire recursion re-anchors. This fires on every iteration, not just the first.

**Current workflow:** `feature-spec` and `task-plan` prompt for a problem statement at entry. That understanding is written to the WIP file and never formally revisited. The ESCALATE mechanism (task → feature → product) moves work upward when scope grows, but it is triggered by size, not by "are we still solving the right problem?" There is no moment in the build→verify→fix loop where the agent asks: "given what I now know, is the original problem statement still correct?"

**Consequence:** The agent can spend multiple fix iterations solving the wrong subproblem because the root problem was misframed at spec time and never re-examined as evidence accumulated.

---

### Gap F2: Test & Analyze Drives Learning in the Algorithm; it is Only a Gate in the Workflow (HIGH)

**Algorithm:** `test_and_analyze(solution, desired_io, problem)` is the engine of iteration. Its output is not pass/fail — it is new understanding. It explicitly grows or prunes the problem tree based on what was learned. A failed test is a signal about a wrong hypothesis, wrong decomposition, or wrong problem definition — not just wrong code. The agent then decides whether to iterate at the solution level, the decomposition level, or the problem identification level.

**Current workflow:** `feature-verify-auto` runs the test suite and produces a binary result. `feature-verify-human` produces a checklist with pass/fail per item. Neither skill prompts the agent to ask: "what does this failure tell me about my understanding of the problem?" or "does this failure mean the decomposition was wrong, not just the implementation?" The verify loop sends the agent back to `build` — always the same level — regardless of what the failure actually revealed.

**Consequence:** The workflow can loop between build and verify indefinitely without the agent ever re-examining whether the plan or spec is the actual source of the problem. Fixes address symptoms at the implementation level when the root is at the decomposition or problem-definition level.

---

### Gap F3: Prioritization is Implicit, Not a Named Step (MEDIUM)

**Algorithm:** `prioritize(subproblems)` is a dedicated step between Decompose and Build. It requires explicitly reasoning about: dependencies, impact vs. urgency, risk/unknown weighting ("big levers first," "biggest risks first"), hotfix vs. perfect tradeoff, and agile SOR (situation-observation-resolution). The rationale is written down, not just implied by ordering.

**Current workflow:** `feature-plan` produces an ordered set of phases, and `product-wbs` assigns sizing and dependency arrows, but neither skill requires the agent to articulate *why* the ordering is what it is. There is no moment where the agent surfaces: "I'm doing X before Y because Y depends on knowing X's output shape" or "I'm doing the 3rd-party probe before the DB model because the model's schema depends on what the API actually returns." The ordering is a silent consequence of the plan, not an explicit decision with stated rationale.

**Consequence:** The agent picks orderings that feel architecturally natural (build dependencies) rather than orderings that reduce risk first (learning dependencies). This is Pain Point 3 in concrete form. When the ordering is wrong, there is no artifact that records why it was chosen — so it can't be corrected by reasoning, only by noticing the downstream damage.

---

### Gap F4: Exit Conditions (Relevance Check) Are Not Evaluated Per Iteration (MEDIUM)

**Algorithm:** `problem.still_relevant?` is evaluated on every pass through the while loop. It returns false — and terminates the loop — if: the requester no longer needs it, business priorities changed, the solution is no longer feasible, a superior solution was discovered, or requirements changed. Abandonment is a first-class outcome of every iteration, not a special case.

**Current workflow:** There is no state or prompt that asks "should we still be doing this?" between phases of a feature. The workflow assumes forward progress unless the human explicitly cancels or the agent escalates via ESCALATE. There is no checklist of relevance signals the agent runs before each phase. A feature that has become irrelevant due to a discovery mid-build will continue to completion unless the human notices and intervenes.

**Consequence:** Work continues past the point where it should have been abandoned or redirected. This is especially likely during long-running features where external circumstances (product direction, 3rd-party API changes, new information from a spike) change the relevance of what's being built.

---

### Gap F5: Retrospect & Communicate Are Optional and Thin (MEDIUM)

**Algorithm:** `retrospect` and `communicate` are explicit named outputs of every solve cycle — both mandatory. Retrospect produces a `lesson_learned` artifact. Communicate explicitly delivers the result to the requester/stakeholder. The algorithm calls out communication as a failure mode specific to engineers: completing work without ensuring the other party knows it is done and what it does.

**Current workflow:** `/session-reflect` and `/session-store-learning` exist but are meta-operations invoked manually, not guaranteed steps at the end of every cycle. `task-close` has a light retrospection note. `feature-finalize` includes documentation. But no skill explicitly prompts: "what did you learn that changed your understanding of the problem?" and no skill explicitly asks: "have you communicated the result to the requester in a form they can act on?" The two are also conflated — learning (internal) and communication (external) are different activities with different audiences.

**Consequence:** Lessons accumulate in conversation context but are not systematically captured. Stakeholders may not know work is done or what changed. The growth loop (hypothesis → verify → learn → *store*) is broken at the store step.

---

### Gap F6: Unknown-Unknown Detection Has No Formal Home (MEDIUM)

**Algorithm:** `acquire_domain_knowledge` contains a 4-quadrant model: (1) know that I know → proceed; (2) don't know that I know → revisit when needed; (3) know that I don't know → learn it fast, prototype; (4) don't know that I don't know → requires research or mentorship to even surface. Quadrant 4 is explicitly handled: if you can detect the unknown, research it; if you can't detect it, seek mentorship or study adjacent fields. The algorithm treats unknown-unknowns as a class of problem requiring its own response.

**Current workflow:** `feature-research` handles quadrant 3 (known unknowns) well — it is explicitly a REDIRECT for when an unknown is identified during build. But quadrant 4 is handled only implicitly via the back-loop from build to research (F22) when something unexpected surfaces. There is no step that says "before building, enumerate what you don't know you don't know" — e.g., by building a minimal probe, reading adjacent documentation, or checking whether your assumptions about a 3rd-party system are even valid. The agent discovers unknown-unknowns by colliding with them during build, not by probing for them in advance.

**Consequence:** Unknown-unknowns surface as build failures or plan invalidations, which are expensive to recover from. A cheap probe (a "hello world" script against a real API, a one-page UI mockup) would surface them earlier at a fraction of the cost. This is the mechanism behind Pain Point 3.

---

### Gap F7: No Recursive Sub-Task Decomposition Within the Task Workflow (LOW — by design)

**Algorithm:** `problem.manageable?` is evaluated recursively at every level. If a problem is not manageable, it is decomposed further. There is no floor — decomposition continues until the leaf is actionable. A task that turns out to be unmanageable mid-execution spawns sub-tasks, which are solved recursively before the parent resumes.

**Current workflow:** The three-level hierarchy (product → feature → task) handles upward escalation (ESCALATE) but not downward decomposition within a task. A task that turns out to be larger than expected either back-loops to `task-plan` (replan at the same level) or escalates to a feature. There is no mechanism for a task to spawn sub-tasks that each go through plan → act → close before the parent resumes. This is a deliberate design choice (see `docs/product/transitions.md` → Task Workflow) to avoid infinite nesting complexity.

**Consequence:** Occasionally a task that is correctly scoped as a task (not a feature) still contains internal sub-problems that would benefit from explicit decomposition. The back-loop to `task-plan` handles this partially but does not enforce the full recursive solve-cycle on each sub-piece.

---

### Summary Table

| Algorithm Concept | Workflow Coverage | Gap Level | Pain Point Link |
|---|---|---|---|
| Root problem re-identification per iteration | Once at spec/plan entry only | **HIGH** | PP1 (tree), PP3 (WBS order) |
| Test & Analyze as learning engine | Binary gate (pass/fail) | **HIGH** | PP1 (verify loop), PP2 (self-verify) |
| Explicit prioritization with rationale | Silent ordering in plan | **MEDIUM** | PP3 (WBS order) |
| Per-iteration relevance / exit check | None | **MEDIUM** | — |
| Retrospect + Communicate (both, mandatory) | Optional, conflated | **MEDIUM** | — |
| Unknown-unknown detection (quadrant 4) | Collision-based only | **MEDIUM** | PP3 (spikes), PP2 (behavioral DoD) |
| Recursive sub-task decomposition | Upward escalation only | **LOW** | By design |
