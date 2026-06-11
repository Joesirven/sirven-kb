# modules

Shared capability logic for the KB system. Each module is the single source of truth for one cross-cutting capability. Skills and scheduled tasks invoke modules — they never duplicate logic.

## Adding a module
1. Create `<capability-name>.md` here.
2. Document the module interface (scope, trigger, inputs, outputs) at the top.
3. If it extends another module, add `> inherits: Ops/System/modules/<base>.md` as the first non-blank line.
4. Register it in `Ops/System/AGENTS.md` under the modules index.
5. Record the decision in `Ops/System/decisions.md`.

See `_meta/CONTRIBUTING.md` for the full guide.
