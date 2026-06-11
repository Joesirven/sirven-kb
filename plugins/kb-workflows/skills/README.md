# kb-workflows / skills

Skill source files for the `kb-workflows` plugin. Each skill is a directory containing a `SKILL.md`.

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md` — the skill definition (trigger description, steps, module pointer).
2. Register it in `../../.claude-plugin/marketplace.json` under the `kb-workflows` plugin's `skills` array.
3. Bump the version in `marketplace.json` (patch for additions; minor for new capabilities).
4. Commit, tag, push. Teammates run `/plugin marketplace update agent-kb-base` to pull.

## Registered skills
| Skill dir | Trigger | Module |
|---|---|---|
| `meeting-prep/` | Pre-meeting prep block | `Ops/System/modules/meeting-prep.md` |
| `meeting-ingestion/` | Post-meeting ingestion | `Ops/System/modules/meeting-ingestion.md` |
| `inbox-triage/` | Email inbox triage | `Ops/System/modules/inbox-triage.md` |
| `issue-draft/` | Issue ticket drafting | `Ops/System/modules/jira-draft.md` |
| `staleness-check/` | Upstream doc drift detection | `Ops/System/modules/staleness-check.md` |

## Forced-eval hook
Per Scott Spence's finding (2026), skill activation without a forced-eval hook is unreliable (~20% trigger rate vs ~84% with hook). When packaging for rollout, add a `forced-eval` skill that explicitly triggers skill selection on each session start. Register it first in the `skills` array so it loads before the capability skills.
