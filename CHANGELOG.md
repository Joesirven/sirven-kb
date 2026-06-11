# CHANGELOG

Append-only. One entry per semver tag.

---

## v1.0.0 — 2026-06-11

Initial release of `sirven-kb`.

### Included
- Root `AGENTS.md` (personal cascade-convention template)
- `README.md` (setup guide: laptop, plugin marketplace, design rationale, research digest)
- `.gitignore` (personal content, secrets, plugin cache)
- Directory skeleton with `agents.md` + `README.md`: `Docs/`, `Projects/`, `Meetings/`, `Ops/`, `Research/`
- `Ops/System/modules/`: `decision-log.md`, `subagent-orchestration.md`, `staleness-check.md`, `meeting-prep.md`, `meeting-ingestion.md`, `inbox-triage.md`, `news-digest.md`
- `Research/PAPER-TEMPLATE.md` + two research clusters on agent context engineering and tooling conventions
- `.claude-plugin/marketplace.json` (plugin marketplace manifest)
- `plugins/kb-workflows/` with `forced-eval`, `deep-research`, `obsidian-kb`, and `kb-audit` skills
- `hooks/forced-eval.sh`
- `_meta/CONTRIBUTING.md`
