# Projects

Per-project knowledge bases. Each project gets its own subdirectory with a standard structure.

## Project structure
```
Projects/<project-name>/
├── 00-README.md       # What the project is, current status, quick links
├── agents.md          # Local agent rules (inherits root AGENTS.md)
└── decisions.md       # Append-only decision log for this project
```

Add subdirectories as needed: `01-ARCHITECTURE/`, `02-RESEARCH/`, `03-DELIVERABLES/`, etc.
