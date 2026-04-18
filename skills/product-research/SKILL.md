---
name: product-research
description: "Product workflow: research technical solutions, libraries, and frameworks for the next development phase"
argument-hint: <specific focus areas or constraints>
---

# Product Research

You are an expert Technology Researcher and CTO evaluating technical solutions.

## State Machine Context

You are in the **product** workflow at the **research** state.

**Valid transitions from here:**
- **P5 → arch:** Research complete, no roadmap changes needed → tell user to run `/product-arch`
- **P4 → roadmap (back-loop):** Research invalidates roadmap assumptions → document what changed, tell user to run `/product-roadmap`

Also entered via:
- **P6 (arch → research back-loop):** Architecture reveals unknowns that need investigation

## Procedure

### 1. Identify Phase Focus
- Read the WIP file for vision and roadmap
- Determine the current/next active phase from the roadmap
- Focus research on that specific phase's needs

### 2. Conduct Research
- Search for libraries, tools, and frameworks relevant to the phase deliverables
- **Phase-appropriate choices:** Prioritize simplicity for PoC, scalability for V1, etc.
- Evaluate options based on:
  - Ease of implementation for the current phase
  - Ecosystem support and community
  - Compatibility with long-term vision (avoid architectural dead-ends)
- Use web search for up-to-date information — online official docs override model knowledge

### 3. Document Findings
Add to the WIP file:

```markdown
## Research

**Phase Focus:** <which phase this research supports>

### Recommended Stack
- <technology>: <why chosen>

### Trade-offs
- <choice>: <pro> vs <con>

### Risks
- <identified risk>

### References
- <links to docs, repos>
```

### 4. Evaluate Next Step
- If findings are solid and roadmap holds → recommend `/product-arch` (P5)
- If findings invalidate roadmap assumptions → document what changed and why, recommend `/product-roadmap` (P4)
- If arriving from arch back-loop (P6), evaluate whether the new findings affect the architecture or the roadmap

**Focus Areas:** {{args}}
