# Retrieval and inheritance — how the knowledge base is organized, and what "update the knowledge base" means

The detail leaf for the one-line rule in the root `AGENTS.md`. Acronym-free, no invented
nicknames, em-dashes sparingly. This convention makes retrieval just-in-time: an agent narrows to
the right folder by the tree, reads a thin index, and pulls only the specific file it needs.

## The five parts

1. **Subdirectories are the taxonomy.** Do not pile flat files in one folder. Categorize with the
   file system: personas in one subdirectory, workflows in another, tools in another, and go deeper
   when a category earns it (for example quality-control personas as a leaf under personas, or
   per-domain personas as further leaves). The directory tree is itself a retrieval index, so the
   path narrows the search before any file is opened. Anti-flat rule: more than about five primary
   notes in a folder means it wants a subfolder.

2. **Every directory carries an `agents.md`, and that `agents.md` indexes its own contents.** At the
   root and at every subdirectory and leaf, the `agents.md` holds the local rules and process AND a
   content index: one line per file and one line per child folder in that directory, saying what
   each holds. The index is what an agent reads first; it tells the agent what is inside before it
   retrieves the whole thing.

3. **Thin at the top, specific in the leaves.** Parent `agents.md` files are short and general (the
   root file caps around forty-five lines, children around eighty). Specificity increases as you go
   deeper. The cascade means higher levels load into context early; leaves are read only when the
   path leads there.

4. **Detail lives behind pointers.** A parent states a thin rule and points to a detail leaf (as the
   root `AGENTS.md` points here). Do not inline long detail high in the tree; link down to it.

5. **Modules over duplication.** Shared capability logic lives once in `Ops/System/modules/`; other
   files and skills are thin wrappers that point into a module rather than copying it.

## What "update the knowledge base" means, every time
When Jose says "update the knowledge base," follow this convention: choose the right layer (the base
sirven-kb for anything universal that all tenants should inherit; the tenant's own knowledge base for
tenant-specific things); put a thin instruction at the correct parent level; put the detail in a
linked leaf deeper in the tree; create subdirectories and leaves as the taxonomy needs; keep parents
thin and leaves specific; and update the directory's `agents.md` content index so the new file is
discoverable just-in-time.

## Enforcement
A convention-scoreboard check verifies that every knowledge-base directory has an `agents.md` and
that the `agents.md` names the directory's own files and child folders (the content index). A
directory that adds a file without updating its index fails the check.

## Lineage
This is the base's existing just-in-time-retrieval, per-directory-`agents.md`, and
module-inheritance conventions, sharpened 2026-07-18 with the explicit content-index requirement
Jose named (the flat `.agent` folder with a dozen un-nested files was the anti-pattern to avoid).
