---
name: sprint-plan
description: "Generates a new sprint plan or updates an existing one based on the current milestone, completed work, and available capacity. Pulls context from production documents and design backlogs."
---

# Sprint Plan

This is the Codex-adapted version of the original workflow. Use only `.codex/` runtime assets when following it.

Arguments: `[new|update|status]`

When this skill is invoked:

1. **Read the current milestone** from `production/milestones/`.

2. **Read the previous sprint** (if any) from `production/sprints/` to
   understand velocity and carryover.

3. **Scan design documents** in `design/gdd/` for features tagged as ready
   for implementation.

4. **Check the risk register** at `production/risk-register/`.

For `new`:

5. **Generate a sprint plan** following this format:

```markdown
# Sprint [N] -- [Start Date] to [End Date]

## Sprint Goal
[One sentence describing what this sprint achieves toward the milestone]

## Capacity
- Total days: [X]
- Buffer (20%): [Y days reserved for unplanned work]
- Available: [Z days]

## spawn_agents

### Must Have (Critical Path)
| ID | spawn_agent | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

### Should Have
| ID | spawn_agent | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

### Nice to Have
| ID | spawn_agent | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|

## Carryover from Previous Sprint
| spawn_agent | Reason | New Estimate |
|------|--------|-------------|

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|

## Dependencies on External Factors
- [List any external dependencies]

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] All tasks pass acceptance criteria
- [ ] No S1 or S2 bugs in delivered features
- [ ] Design documents updated for any deviations
- [ ] Code reviewed and merged
```

For `status`:

5. **Generate a status report**:

```markdown
# Sprint [N] Status -- [Date]

## Progress: [X/Y tasks complete] ([Z%])

### Completed
| spawn_agent | Completed By | Notes |
|------|-------------|-------|

### In Progress
| spawn_agent | Owner | % Done | Blockers |
|------|-------|--------|----------|

### Not Started
| spawn_agent | Owner | At Risk? | Notes |
|------|-------|----------|-------|

### Blocked
| spawn_agent | Blocker | Owner of Blocker | ETA |
|------|---------|-----------------|-----|

## Burndown Assessment
[On track / Behind / Ahead]
[If behind: What is being cut or deferred]

## Emerging Risks
- [Any new risks identified this sprint]
```

### Agent Consultation

For comprehensive sprint planning, consider consulting:
- `producer` agent for capacity planning, risk assessment, and cross-department coordination
- `game-designer` agent for feature prioritization and design readiness assessment
