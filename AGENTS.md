# OptimalControl.jl — Agent Navigation Guide

Quick-reference for any agent working on this repository.

---

## Repository Layout

OptimalControl is the ecosystem's user-facing DSL package: a single flat module that
orchestrates and re-exports the lower-level control-toolbox packages (CTBase, CTModels,
CTLie, CTDirect, CTSolvers, CTFlows). It does not follow the "one submodule per
responsibility" layout used by sibling packages.

```text
src/imports/   # Per-dependency reexports (`@reexport import Pkg: sym`) — builds the public API
src/helpers/   # Internal helpers (routing, completion, registry, printing)
src/solve/     # `solve` dispatch: mode detection, descriptive/explicit paths
test/suite/    # Test suite: organised by functionality, not by src/ layout
docs/          # Documentation site (DocumenterVitepress)
.ct-conventions/  # ct-conventions, cloned at the pinned tag (git-ignored)
.ct-agents/    # ct-agents, cloned at the pinned tag (git-ignored)
```

There is no `ext/`: optional backends (ADNLPModels, ExaModels, AD) are armed by
dependency presence, wired in `src/imports/*.jl`, not weak-dependency extensions.

---

## Conventions

The coding conventions live in
[ct-conventions](https://github.com/control-toolbox/ct-conventions), pinned below to a
SemVer release tag (`vX.Y.Z`). Read them from a local clone in `.ct-conventions/`
(git-ignored, not a submodule). If it is missing, or `git -C .ct-conventions describe --tags`
is not the pinned tag, (re)create it:

```bash
rm -rf .ct-conventions
git -c advice.detachedHead=false clone --quiet --depth 1 --branch v0.9.0 https://github.com/control-toolbox/ct-conventions.git .ct-conventions
```

**Pinned version: ct-conventions v0.9.0.** Cite rules by identifier (`MOD3`, `TST1`), and
state the version you applied in plans and reports.

Read in this order:

| File | Content |
| --- | --- |
| [`rules/general.md`](.ct-conventions/rules/general.md) | Rules that hold everywhere — **always read** |
| [`README.md`](.ct-conventions/README.md) | Index of the rule files, one per area (`MOD`, `TYP`, `DIM`, `EXC`, `PERF`, `DOC`, `TST`, `SITE`, `CHG`, `REL`) |
| [`method.md`](.ct-conventions/method.md) | How to work: tests, coverage, docs build, output capture |
| [`plan-template.md`](.ct-conventions/plan-template.md) | Template for a substantial piece of work |

How agents behave on these repositories is described in
[ct-agents](https://github.com/control-toolbox/ct-agents). The CI workflows and their
trigger labels are described in
[CTActions `docs/WORKFLOWS.md`](https://github.com/control-toolbox/CTActions/blob/main/docs/WORKFLOWS.md).

---

## Key Conventions

- **English everywhere** — code, docs, commits, issues, PRs (`GEN1`).
- **Exports a curated public API** — unlike sibling packages (`MOD8`: no top-level
  exports), OptimalControl is the ecosystem's DSL entry point: it re-exports selected
  symbols from CTBase, CTModels, CTLie, CTDirect, CTSolvers, CTFlows.
- **`@reexport import Pkg: sym`** — the one place `import` is intentional in this
  ecosystem (an exemption from `MOD3`): `src/imports/*.jl` builds the exported surface
  this way; everywhere else, qualified `using` only (`using Pkg: Pkg`, `MOD4`).
- **Fake types at module top-level** — never inside test functions (`TST3`).
- **Structured errors** — seven typed exceptions; pick by the choice rule (`EXC1`).
- **Type stability enforced** — hot paths `@inferred`-clean, verified with JET (`TYP8`, `PERF1`–`PERF5`).
- **1-D is a scalar** — a one-dimensional state/control/variable is a `Number` (`DIM1`).
- **Plan before code** — a local agent proposes a plan ([`plan-template.md`](.ct-conventions/plan-template.md)) and waits for confirmation before working on code. The process for remote agents is still to be defined.
- **Docstrings last** — written once the implementation is stable (`DOC1`–`DOC8`).
- **The human merges** — an agent never merges a pull request, except a release PR in `autonomous` mode, and then only with `release.jl merge` (see below).

---

## Recurring tasks

How a recurring task is done lives in [ct-agents](https://github.com/control-toolbox/ct-agents),
pinned below to a SemVer release tag (`vX.Y.Z`). Read it from a local clone in `.ct-agents/`
(git-ignored, not a submodule). If it is missing, or `git -C .ct-agents describe --tags` is
not the pinned tag, (re)create it:

```bash
rm -rf .ct-agents
git -c advice.detachedHead=false clone --quiet --depth 1 --branch v0.4.0 https://github.com/control-toolbox/ct-agents.git .ct-agents
```

**Pinned version: ct-agents v0.4.0.** State it, with the ct-conventions version, in
plans and reports.

- **Release.** When asked, in any language, to prepare a release, follow
  [`recipes/release.md`](.ct-agents/recipes/release.md) (rules `REL1`–`REL7`). Stable or
  beta is the human's choice: if the request does not say, ask; never infer it. State in
  the proposal the versions you apply: ct-agents, ct-conventions, and the commit of the
  CTActions clone `release.jl` runs from.
