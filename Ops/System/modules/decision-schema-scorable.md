# module: decision-schema-scorable

> inherits: Ops/System/modules/decision-log.md

**Scope:** an opt-in, heavier alternative to the default append-only keyed `decisions.md`
log, for a decision that is worth tracking all the way to a resolution with an attached
confidence level and a date to revisit it — not every decision needs this; most should stay
on the lightweight log.

## When to use this tier versus the default log

The default `decision-log.md` module (unchanged by this document) is the right choice for
the overwhelming majority of decisions in this vault: a keyed, append-only entry, currency
inferred by recency, no lifecycle field. Use it unless a decision specifically needs more
than that.

Reach for this opt-in, scorable tier only when a decision:
- is significant enough to warrant tracking to an actual resolution, not just a recorded
  rationale;
- carries real uncertainty worth expressing as an explicit confidence level; and
- should be revisited on a schedule rather than left to be noticed by chance.

If none of those apply, use the default log instead — do not adopt this tier by default.

## The file-per-decision shape

Where the default log keeps every decision as one entry in a shared `decisions.md`, this
tier gives each qualifying decision its own file (file-per-decision), so it can carry more
structure than a single log entry comfortably holds. Each such file documents, at minimum:

- **What was decided** and why, in the same terms as a default log entry.
- **`confidence`** — how confident the decision's author is that it will hold up, expressed
  as a level or a number on a scale the vault area defines once and reuses consistently.
  This is a property of the decision's owner's certainty, not a lifecycle marker.
- **`revisit_date`** — a concrete date by which this decision should be actively
  re-examined, not left to go stale silently. A decision with no natural revisit point
  probably belongs on the default log instead.
- **`resolution`** — what actually happened: whether the decision played out as expected,
  what was learned, and what (if anything) changed as a result. This field starts empty and
  is filled in at or after the revisit date — a decision file with a long-empty resolution
  field is a signal to go check on it.

## What this tier deliberately does not add back

This module does not reintroduce a freestanding lifecycle marker for the decision itself
(the pattern the default log's rationale document explicitly retired). If you want to
illustrate this schema's shape for a colleague, describe the fields in prose, as above, or
use a placeholder word other than the retired lifecycle values — do not write an example
line pairing a lifecycle-style field with one of the retired values. `confidence`,
`revisit_date`, and `resolution` together carry the information a lifecycle field used to
carry (and more, since they are checkable at the revisit date), without the drift problem:
nobody has to remember to flip a flag, because the revisit date forces the check.

## Where a decision made this way lives

A qualifying decision gets its own file under the area's own decision-record location (for
example an `ADRs/` or `Decisions/` subdirectory next to that area's `decisions.md`), named
so it is independently findable. The area's default `decisions.md` may still carry a short
pointer entry noting that a fuller, scorable record exists at that path — the pointer entry
itself follows the default log's own append-only, keyed format.
