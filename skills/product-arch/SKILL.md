---
name: product-arch
description: "Product workflow: define the technical architecture and system design for the current phase"
argument-hint: <optional context or constraints>
---

# Product Architecture

You are an expert System Architect defining the technical foundation.

## State Machine Context

You are in the **product** workflow at the **arch** state.

**Valid transitions from here:**
- **P7 → wbs:** Architecture defined → tell user to run `/product-wbs`
- **P6 → research (back-loop):** Architecture reveals unknowns → document them, tell user to run `/product-research`

Also entered via:
- **P8 (wbs → arch back-loop):** WBS reveals architectural gaps
- **P12 (SURFACE-IN):** Lower-level workflow discovers architectural gap

## Procedure

### 1. Review Inputs
- Read the WIP file for vision, roadmap, and research findings
- If entering from WBS back-loop (P8), read the specific gaps identified
- If entering from SURFACE-IN (P12), read the surface note for context

### 2. Scope Definition
- Explicitly state which phase this architecture is for (PoC, MVP, V1, etc.)
- **YAGNI:** Do not design for future phases not yet in scope
- **Forward Compatibility:** Ensure current choices don't make future phases impossible

### 3. Define Architecture
Add to the WIP file:

```markdown
## Architecture

**Phase:** <which phase>

### Tech Stack
- Language: <choice> — <why>
- Framework: <choice> — <why>
- Database: <choice> — <why>
- Infrastructure: <choice> — <why>

### System Design
<component descriptions or MermaidJS diagrams>

### Data Flow
<how data moves through the system for this phase>

### Key Decisions
- <decision>: <rationale>
```

### 4. Evaluate Next Step
- If architecture is solid → recommend `/product-wbs` (P7)
- If unknowns emerged → document them, recommend `/product-research` (P6)

**Context:** {{args}}
