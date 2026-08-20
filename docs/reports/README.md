# Documentation rewrite — specification set

**Date**: 2026-08-09 · **Target**: OptimalControl.jl v2.1.0-beta · **Status**: specification
**Scope**: `docs/` (full rewrite) + `src/deprecated.jl` (new)

The v2.1.0-beta upgrade ([`.reports/upgrade-v2.1.0-beta.md`](../../.reports/upgrade-v2.1.0-beta.md))
deliberately left `docs/` out of scope. This is that follow-up. It is too large for one PR, so
the work is split in two levels: **this specification set**, then **one PR per section**, each
backed by its own report here.

> **Why `docs/reports/` and not `.reports/`.** `.reports/` is untracked local scratch; this
> specification is the contract for twelve PRs and has to survive in the repository. It sits
> beside `docs/src/`, not inside it, so Documenter and VitePress never see it — same
> arrangement as `docs/attic/`.

## How to read this

- Start with [`00-cahier-des-charges.md`](00-cahier-des-charges.md) — audience, principles,
  the sitemap, the cross-cutting conventions. Everything else refines it.
- [`01-infrastructure.md`](01-infrastructure.md) is what must land first; nothing else builds
  without it.
- Reports `02`–`08` are the per-section page specs. They share one template (§"Template" in
  the cahier des charges) and are meant to be kept open while writing the pages.
- [`99-api-coverage.md`](99-api-coverage.md) is the objective acceptance criterion for the
  whole effort: every re-exported symbol lands in at least one guide page and in the API
  reference.

## Files

| File | Role |
| --- | --- |
| [`00-cahier-des-charges.md`](00-cahier-des-charges.md) | Main spec: audience, principles, sitemap, conventions, acceptance criteria |
| [`01-infrastructure.md`](01-infrastructure.md) | `docs/Project.toml`, `make.jl`, `api_reference.jl`, VitePress, Literate, InterLinks, archiving |
| [`02-getting-started.md`](02-getting-started.md) | Installation · First problem · Guided tour |
| [`03-modelling.md`](03-modelling.md) | Formulation · `@def` · Functional API · No control · Inspect · AI |
| [`04-solve-direct.md`](04-solve-direct.md) | Overview · Initial guess · Choosing a method · Options · Explicit mode · GPU |
| [`05-flows-indirect.md`](05-flows-indirect.md) | PMP · From an OCP · From Hamiltonians · Loops · Accessors · Multi-phase · Constrained arcs · Shooting |
| [`06-geometry.md`](06-geometry.md) | `Lift` · `ad` · `Poisson` & `@Lie` · `∂ₜ` · AD backend |
| [`07-results.md`](07-results.md) | Solution object · Plotting · Save & load |
| [`08-examples.md`](08-examples.md) | The example gallery |
| [`09-api-reference.md`](09-api-reference.md) | Thematic generated pages + Internals + Ecosystem |
| [`10-migration.md`](10-migration.md) | `src/deprecated.jl` design + the "Migrating to v2.1" page |
| [`99-api-coverage.md`](99-api-coverage.md) | Symbol → page matrix |

## Work board

Status legend: ⬜ not started · 🟡 in progress · ✅ merged

| # | PR | Section | Spec | Depends on | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | `docs: specification reports` | — | all of this directory | — | ✅ |
| 2 | [`docs: infrastructure`](https://github.com/control-toolbox/OptimalControl.jl/pull/854) | build + skeleton | [`01`](01-infrastructure.md) | 1 | ✅ |
| 3 | [`feat: deprecation shims`](https://github.com/control-toolbox/OptimalControl.jl/pull/855) | `src/deprecated.jl` | [`10`](10-migration.md) §1 | 1 | ✅ |
| 4 | [`docs: API reference`](https://github.com/control-toolbox/OptimalControl.jl/pull/856) | API reference | [`09`](09-api-reference.md) | 2 | ✅ |
| 5 | [`docs: modelling`](https://github.com/control-toolbox/OptimalControl.jl/pull/865) | Modelling | [`03`](03-modelling.md) | 2 | 🟡 in review |
| 6 | `docs: solve` | Solve (direct) | [`04`](04-solve-direct.md) | 5 | 🟡 branch ready, build verified green, not yet opened as a PR |
| 7 | `docs: results` | Results | [`07`](07-results.md) | 6 | ⬜ |
| 8 | `docs: flows` | Flows (indirect) | [`05`](05-flows-indirect.md) | 6 | ⬜ |
| 9 | `docs: geometry` | Geometry | [`06`](06-geometry.md) | 8 | ⬜ |
| 10 | `docs: examples` | Examples | [`08`](08-examples.md) | 8, 9 | ⬜ |
| 11 | `docs: getting started` | Getting started + `index.md` | [`02`](02-getting-started.md) | 5–10 | ⬜ |
| 12 | `docs: migration + cleanup` | Migration page, drop `docs/attic/` | [`10`](10-migration.md) §2 | all | ⬜ |

PR 3 is code-only and independent — it can run in parallel with any docs PR.

## Decisions already taken

Recorded here so they are not re-litigated mid-PR.

| Question | Decision |
| --- | --- |
| Top-level structure | **By capability**, not Diátaxis buckets. Sections are named after what the user is doing. The catch-all "Manual" node disappears. |
| Deprecation shims | **One `src/deprecated.jl` in OptimalControl**, covering removed *names* and removed *call signatures*. Piracy accepted; it is the package the user loads. |
| Old markdown | **Archive to `docs/attic/`**, rewrite from a blank page, harvest from the attic, delete the attic in PR 12. |
| API reference | **Thematic pages generated from a Julia manifest** in `docs/api_reference.jl`. No hand-written symbol list. |
| `[compat]` | `docs/Project.toml` **mirrors the root `Project.toml` exactly**. The newer sibling releases (CTBase 0.29, CTModels 0.16, CTFlows 0.17, CTLie 0.2, CTSolvers 0.5) will not resolve — CTDirect and CTParser still require the older ones. |
| Shapes | **"1-D is a scalar" is in force and tested** (`test/suite/shape/test_shape_contract.jl`). Guides write scalar-style for 1-D; only the in-place buffer stays a vector. The old functional-API page teaches the opposite and that section is deleted. |
| Flow accessors | PR 8 re-exports `hamiltonian`, `hamiltonian_vector_field`, `vector_field` and the four `get_*_gradient` functions. `system` / `integrator` stay qualified. |
| `DirectShooting` | Out of scope — not functional yet. Not mentioned anywhere in the docs. |
| Serialization | The user API is `format=:JLD` / `:JSON`; the `*Tag` types are internal and stay out of the docs. |

## Branching

**No stacking.** Each PR branches from `main`, is reviewed, and merges back.

PR 1 (this directory) is inert — it adds `docs/reports/` and nothing under `docs/src/`, so
neither Documenter nor VitePress reads it and no CI job changes behaviour. It can merge to
`main` immediately, which is the whole point: once it is in, every later branch starts from a
`main` that already contains the specification.

```
main ──●──────●──────●──────●── …
        \      \      \      \
         PR 1   PR 2   PR 3   PR 5 …
       (spec) (infra) (shims) (modelling)
```

The one real ordering constraint is **PR 2**: it creates the page skeleton with the final
`@id` anchors that PRs 4–11 fill in. Branch those from `main` *after* PR 2 has merged. If PR 2
is still in review and you want to start a content PR, branch from PR 2's head rather than
from `main` — that is the only case where stacking is justified, and it should be temporary.

A long-lived integration branch collecting all twelve PRs would defeat the purpose: the value
of the split is that each piece is reviewable and mergeable on its own.

## Conventions for these reports

- Every claim about the code cites `file:line`. If it is not cited, it was not verified.
- Every page spec names the exact symbols it must cover — that is what feeds
  [`99-api-coverage.md`](99-api-coverage.md).
- "Source" on a page spec is either `attic/<file>.md §<section>` (harvest) or
  `new` (write from scratch). No page is ever "keep as is" — the API changed under all of them.
