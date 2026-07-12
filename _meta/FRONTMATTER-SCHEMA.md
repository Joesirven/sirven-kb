---
title: "Frontmatter schema"
type: meta
status: active
updated: 2026-07-12
tags: [meta, frontmatter, schema]
---

# Frontmatter schema

The single source of truth for the frontmatter every markdown file in this base (and every
fork of it) is expected to carry. This document and the executable validator
(`~/Projects/meadow/tools/validate_frontmatter.py`, a sibling repository — not part of this
base) are one contract: the two enums below must match the validator's `TYPES` and `STATUS`
sets character for character. If you change one, change the other in the same change set.

## Base fields (every file)

| Field | Required | Notes |
|---|---|---|
| `title` | yes | Human-readable title, quoted if it contains a colon. |
| `type` | yes | One value from the enum below. |
| `status` | yes | One value from the enum below. |
| `updated` | yes | `YYYY-MM-DD`, the date the file's content was last substantively changed. |
| `tags` | no | Free-form list; keep short. |
| `related` | no | Backlinks to other documents (`[[Other-Doc]]` or a relative path). |

`README.md` and lowercase `agents.md` / `AGENTS.md` files are exempt — they carry no
frontmatter by convention.

## The two enums

The reconciled enum set, matching the validator exactly:

```
type: ops | architecture | data | model | product | research | brand | library | meta | readme | project | business | synthesis
status: draft | active | locked | complete | archived | planned | in-progress | research-complete
```

### `type` — what each value means and when to use it

| Value | Use for |
|---|---|
| `ops` | Operational process docs, session rituals, agent-state machinery. |
| `architecture` | Structural or technical decisions about how a system is built. |
| `data` | A dataset, data source, or data-handling document — carries extra required fields (below). |
| `model` | A model card, training plan, or evaluation result for a trained or fine-tuned model. |
| `product` | User-facing product specs, feature descriptions, or roadmaps. |
| `research` | A source card capturing an external paper, report, or article — carries extra required fields (below). |
| `brand` | Identity, voice, visual language, or copy standards. |
| `library` | A captured web source or reference snapshot — carries an extra required field (below). |
| `meta` | Documents about the base or fork itself: schemas, personas, contribution rules. |
| `readme` | A narrative overview document, when it needs frontmatter (most `README.md` files don't). |
| `project` | A per-project knowledge-base document (charter, plan, status). |
| `business` | Business-facing material: goals, finances, planning that isn't a `product` spec. |
| `synthesis` | A synthesized digest routed out from `Research/` into `Docs/` or a project area. |

### `status` — what each value means and when to use it

| Value | Use for |
|---|---|
| `draft` | Not yet reviewed or acted on. |
| `active` | Current and in use. |
| `locked` | Frozen — changes require a recorded decision first (see `Ops/System/modules/decision-log.md`). |
| `complete` | Finished and not expected to change further. |
| `archived` | Superseded or no longer relevant; kept for history. |
| `planned` | Not started yet, but scoped. |
| `in-progress` | Actively being worked on right now. |
| `research-complete` | A `research` source card whose capture and source-quality assessment are finished. |

This `status` enum describes a document's own lifecycle. It is a different axis from a
decision's lifecycle — this base never uses a freestanding decision-status field (see
`Ops/System/modules/decision-log.md` R3 and `Ops/System/modules/decision-schema-scorable.md`).

## Additional required fields by type

Beyond the base fields above, these types require extra frontmatter keys:

- **`research`** — `citation` (plain-text citation string), `url` (the canonical
  retrieval-handle key — not `source_url`), `topic_cluster` (which cluster this source
  belongs to), `published` (the source's own publication date, `YYYY-MM-DD` or a coarser
  form if that is all the source gives). See `Research/PAPER-TEMPLATE.md` for the full card
  shape.
- **`data`** — `pii` (`true`/`false` — does this describe or reference data containing
  personally-identifying information), `license_terms` (what license or terms govern the
  data's use).
- **`library`** — `topic` (which topic folder this capture belongs under).

A fork may add further type-specific requirements in its own copy of this document, but
should not remove a base requirement without recording why (see `_meta/CONTRIBUTING.md`).

## Keeping this in sync

The validator lives in a separate repository (Meadow) and is the executable arbiter — this
document is descriptive, not enforcing. When the validator's `TYPES` or `STATUS` sets
change, update the pipe-delimited lines above in the same change, so the two never drift.
