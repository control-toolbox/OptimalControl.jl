# OptimalControl.jl — Agent Navigation Guide

Quick-reference for any agent working on this repository.

---

## Repository Layout

OptimalControl is the ecosystem's user-facing DSL package: a single flat module that
orchestrates and re-exports the lower-level control-toolbox packages (CTBase, CTModels,
CTLie, CTDirect, CTSolvers, CTFlows). It does not follow the "one submodule per
responsibility" layout used by sibling packages.

```text
src/imports/  # Per-dependency reexports (`@reexport import Pkg: sym`) — builds the public API
src/helpers/  # Internal helpers (routing, completion, registry, printing)
src/solve/    # `solve` dispatch: mode detection, descriptive/explicit paths
test/suite/   # Test suite: organised by functionality, not by src/ layout
docs/         # Documentation site (DocumenterVitepress)
```

There is no `ext/`: optional backends (ADNLPModels, ExaModels, AD) are armed by
dependency presence, wired in `src/imports/*.jl`, not weak-dependency extensions.

---

## Developer Resources

Design philosophy, operational rules, plan templates, and CI/CD conventions live in the
[control-toolbox Handbook](https://github.com/control-toolbox/Handbook):

| Topic | Link |
| --- | --- |
| Code philosophy (modules, types/traits, exceptions, docstrings, testing, docs) | [`PHILOSOPHY.md`](https://github.com/control-toolbox/Handbook/blob/main/PHILOSOPHY.md) |
| Operational rules (tests, coverage, docs, git) | [`RULES.md`](https://github.com/control-toolbox/Handbook/blob/main/RULES.md) |
| Plan template | [`PLAN.md`](https://github.com/control-toolbox/Handbook/blob/main/PLAN.md) |
| CI/CD workflows (centralized reusable workflows, label-gated triggers) | [`WORKFLOWS.md`](https://github.com/control-toolbox/Handbook/blob/main/WORKFLOWS.md) |

---

## Key Conventions

- **Exports a curated public API** — unlike sibling packages ("no top-level exports"),
  OptimalControl is the ecosystem's DSL entry point: it re-exports selected symbols from
  CTBase, CTModels, CTLie, CTDirect, CTSolvers, CTFlows.
- **`@reexport import Pkg: sym`** — the one place `import` is intentional in this
  ecosystem: `src/imports/*.jl` builds the exported surface this way; everywhere else,
  qualified `using` only (`using Pkg: Pkg`), never bare `using Pkg`.
- **Fake types at module top-level** — never inside test functions.
- **Structured errors** — seven typed exceptions under `CTException`; pick by the
  IncorrectArgument / PreconditionError / NotImplemented rule.
- **Type stability enforced** — hot paths must be `@inferred`-clean, verified with JET;
  setup-path dispatch is fine.
- **1-D is a scalar** — a one-dimensional state/control/variable is a `Number`, never a
  length-1 vector.
- **Plans before code** — write a plan and confirm with the user before touching files.
- **Docstrings last** — written only after all implementation steps are stable.
- **Never commit or push without explicit user approval.**
