        # Command Map

        Codex does not auto-import repository-local custom slash commands. This layer keeps the original workflow names as skills.

        ## Native Codex Commands
        | Original Intent | Codex Command | Notes |
        | --- | --- | --- |
        | `plan` | `/plan` | Native Codex command |
| `review` | `/review` | Native Codex command |
| `status` | `/status` | Native Codex command |
| `debug-config` | `/debug-config` | Native Codex command |
| `statusline` | `/statusline` | Native Codex command |

        ## Migrated Workflow Commands
        | Claude Command | Codex Path | Notes |
        | --- | --- | --- |
        | `/architecture-decision` | Use the `architecture-decision` skill | Migrated Claude workflow |
| `/asset-audit` | Use the `asset-audit` skill | Migrated Claude workflow |
| `/balance-check` | Use the `balance-check` skill | Migrated Claude workflow |
| `/brainstorm` | Use the `brainstorm` skill | Migrated Claude workflow |
| `/bug-report` | Use the `bug-report` skill | Migrated Claude workflow |
| `/changelog` | Use the `changelog` skill | Migrated Claude workflow |
| `/code-review` | Use the `code-review` skill | Migrated Claude workflow |
| `/design-review` | Use the `design-review` skill | Migrated Claude workflow |
| `/design-system` | Use the `design-system` skill | Migrated Claude workflow |
| `/estimate` | Use the `estimate` skill | Migrated Claude workflow |
| `/gate-check` | Use the `gate-check` skill | Migrated Claude workflow |
| `/hotfix` | Use the `hotfix` skill | Migrated Claude workflow |
| `/launch-checklist` | Use the `launch-checklist` skill | Migrated Claude workflow |
| `/localize` | Use the `localize` skill | Migrated Claude workflow |
| `/map-systems` | Use the `map-systems` skill | Migrated Claude workflow |
| `/milestone-review` | Use the `milestone-review` skill | Migrated Claude workflow |
| `/onboard` | Use the `onboard` skill | Migrated Claude workflow |
| `/patch-notes` | Use the `patch-notes` skill | Migrated Claude workflow |
| `/perf-profile` | Use the `perf-profile` skill | Migrated Claude workflow |
| `/playtest-report` | Use the `playtest-report` skill | Migrated Claude workflow |
| `/project-stage-detect` | Use the `project-stage-detect` skill | Migrated Claude workflow |
| `/prototype` | Use the `prototype` skill | Migrated Claude workflow |
| `/release-checklist` | Use the `release-checklist` skill | Migrated Claude workflow |
| `/retrospective` | Use the `retrospective` skill | Migrated Claude workflow |
| `/reverse-document` | Use the `reverse-document` skill | Migrated Claude workflow |
| `/scope-check` | Use the `scope-check` skill | Migrated Claude workflow |
| `/setup-engine` | Use the `setup-engine` skill | Migrated Claude workflow |
| `/sprint-plan` | Use the `sprint-plan` skill | Migrated Claude workflow |
| `/start` | Use the `start` skill | Migrated Claude workflow |
| `/team-audio` | Use the `team-audio` skill | Migrated Claude workflow |
| `/team-combat` | Use the `team-combat` skill | Migrated Claude workflow |
| `/team-level` | Use the `team-level` skill | Migrated Claude workflow |
| `/team-narrative` | Use the `team-narrative` skill | Migrated Claude workflow |
| `/team-polish` | Use the `team-polish` skill | Migrated Claude workflow |
| `/team-release` | Use the `team-release` skill | Migrated Claude workflow |
| `/team-ui` | Use the `team-ui` skill | Migrated Claude workflow |
| `/tech-debt` | Use the `tech-debt` skill | Migrated Claude workflow |

        ## Guidance
        - Use `/review` for whole-working-tree review.
        - Use the `code-review` skill for targeted subsystem or file review.
        - Use `/statusline` to inspect or adjust footer configuration.
