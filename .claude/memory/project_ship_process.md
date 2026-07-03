---
name: Project ship process — commit + push to main
description: Standard shipping process for the my-claude-code-customization repo
type: project
originSessionId: c1fb4898-6bda-4a1f-a801-2f07f20aa725
---
For the `my-claude-code-customization` repo, the standard `/feature-ship` process is **commit + push directly to `main`**.

**Why:** the repo's git history shows direct-to-main commits (no PR workflow). Each feature is reviewed live during the workflow's verify-human steps, so review-of-record happens in the conversation, not in PR review. User confirmed this explicitly on 2026-05-14.

**How to apply:**
- When `/feature-ship` runs in this repo, treat commit + `git push origin main` as the default action, not as a high-risk operation requiring per-feature confirmation.
- Do NOT propose a branch-and-PR flow unless the user asks for one — it's a departure from the repo's actual workflow.
- Still ask before bundling unrelated pre-existing in-flight changes — that's a *commit-content* question (what goes in), distinct from the *commit-and-push* question (what to do with it).
