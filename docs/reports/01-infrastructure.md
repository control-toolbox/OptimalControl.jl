# Infrastructure — specification

**PR**: 2 · **Depends on**: 1 · **Status**: specification
**Scope**: `docs/Project.toml`, `docs/make.jl`, `docs/api_reference.jl`, `docs/inventories/`,
`docs/src/.vitepress/`, `docs/src-literate/`, archiving `docs/src/*.md`

## Objective

Make the documentation buildable again, land the final navigation, and move the old pages out
of the way — so every later PR is "write pages", never "and also fix the build".

**This PR ships a green build with mostly empty pages.** That is intentional. A skeleton that
builds is the platform for the eleven PRs that follow.

---

## 1. The versions the docs are written against

Critical, and easy to get wrong: **the sibling checkouts in `../` are ahead of what
OptimalControl resolves.** The root `Manifest.toml` pulls registry versions:

| Package | Resolved (root `Manifest.toml`) | Local checkout in `../` | Root `[compat]` |
| --- | --- | --- | --- |
| CTBase | **0.28.9-beta** | 0.29.3 | `"0.28"` |
| CTModels | **0.15.3-beta** | 0.16.1 | `"0.15"` |
| CTFlows | **0.16.3-beta** | 0.17.0 | `"0.16"` |
| CTLie | **0.1.5-beta** | 0.2.0 | `"0.1"` |
| CTSolvers | **0.4.34-beta** | 0.5.2 | `"0.4"` |
| CTDirect | 1.x | 1.0.12 | `"1"` |
| CTParser | 0.8.x | 0.8.17-beta | `"0.8"` |

**Rule for every docs PR: verify each symbol against the resolved version in
`~/.julia/packages/<Pkg>/<hash>/`, not against `../<Pkg>/src/`.** The two agree on
everything this specification asserts — spot-checked on the points that matter most:

- `CTLie 0.1.5-beta` (`cHxPr`) exports exactly `ad`, `Lift`, `LiftedHamiltonianFunction`,
  `Poisson`, `∂ₜ`, `@Lie`, `dg_ad_backend`, `dg_ad_backend!` (`src/CTLie.jl:50-56`).
  No `Lie`, no `⋅`.
- `CTFlows 0.16.3-beta` (`PsDmR`) has the same ten `Flow` methods as the checkout
  (`src/Flows/building.jl:33,66,118,157,269,406,478,557,792,1019`), the same
  `constraint=`/`multiplier=` keyword pair, and `variable_costate` on the call
  (`src/Flows/calling.jl:93`).

But the two are **not** identical everywhere. Any API detail this spec does not explicitly
cite must be re-checked before it goes in a page.

> **Decision (settled with the maintainer, 2026-08-09): `docs/Project.toml` mirrors the root
> `Project.toml` `[compat]` exactly. Do not chase the newer releases.**
>
> The ecosystem has moved a full breaking unit past OptimalControl's `[compat]` (CTBase 0.29,
> CTModels 0.16, CTFlows 0.17, CTLie 0.2, CTSolvers 0.5) and those releases are stable — but
> **CTDirect and CTParser have not been updated and still require the older versions**, so
> the newer ones simply will not resolve. Bumping is a separate, source-side
> `upgrade-v2.1.0-beta`-sized PR that has to start upstream, and it is not a prerequisite for
> this work.
>
> Practical consequence for every docs PR: the root `Project.toml` is the single source of
> truth for `[compat]`. If a page needs an API that only exists in a newer sibling release,
> the page is wrong, not the pin.

---

## 2. `docs/Project.toml`

### 2.1 Missing dependencies — the reason nothing works

| Add | Why |
| --- | --- |
| `CTLie` | owns `ad`, `Lift`, `Poisson`, `∂ₜ`, `@Lie`. The whole Geometry section is undocumentable without it, and `make.jl` cannot `setdocmeta!` its docstrings |
| `DifferentiationInterface` | arms `CTBaseDifferentiationInterface`. **Without it every `ad` / `Poisson` / `∂ₜ` / `@Lie` call is inert** and AD-backed `Flow`s do not build |
| `ForwardDiff` | the concrete backend behind the above |
| `OrdinaryDiffEqTsit5` | the integrator every flow page's preamble loads. `OrdinaryDiffEq` (already present) is the heavy meta-package; the docs should show the light one, as `BREAKING.md` §"Start here" does |

### 2.2 Compat realignment

Every CT pin is a breaking unit or more behind the root. Align to the root `[compat]`, and
apply the ecosystem granularity rule (`X == 0` → pin the minor; `X ≥ 1` → pin the major
alone; `julia` is the exception, it states a minimum):

| Entry | Now | Target | Note |
| --- | --- | --- | --- |
| `CTBase` | `"=0.18.8"` | `"0.28"` | drop the exact pin |
| `CTModels` | `"=0.10.1"` | `"0.15"` | drop the exact pin |
| `CTFlows` | `"0.8"` | `"0.16"` | |
| `CTLie` | — | `"0.1"` | new |
| `CTDirect` | `"1"` | `"1"` | ok |
| `CTParser` | `"0.8"` | `"0.8"` | ok |
| `CTSolvers` | `"0.4"` | `"0.4"` | ok |
| `DifferentiationInterface` | — | `"0.7"` | new, matches root |
| `ForwardDiff` | — | `"0.10, 1"` | new, matches root |
| `OrdinaryDiffEqTsit5` | — | `"2"` | new, matches root |
| `ExaModels` | `"0.9"` | `"0.11"` | root says `"0.11"` |
| `CUDA` | `"5"` | `"5, 6"` | root says `"5, 6"` |
| `MadNLP` | `"0.9"` | `"0.9, 0.10"` | root says so |
| `MadNLPGPU` | `"0.8"` | `"0.8, 0.10"` | root says so |
| `OrdinaryDiffEq` | `"6"` | `"6, 7"` | root says so |

> The exact pins `CTBase = "=0.18.8"` / `CTModels = "=0.10.1"` are a **different** constraint
> from the one that legitimately exists in `OptimalControl/.extras` (where they prevent a
> beta-version skew that breaks CTModels precompilation). Do not carry them over here.

### 2.3 Deps that may be droppable

Audit while you are in the file — each costs resolve time and CI minutes:

| Dep | Used by | Verdict |
| --- | --- | --- |
| `BenchmarkTools` | grep `docs/src` — no hit found | drop unless a page plans to use it |
| `DataFrames` | no hit found | drop |
| `LiveServer` | developer convenience (`servedocs`) | keep, but it belongs in a comment |
| `CommonSolve`, `MarkdownAST` | `make.jl` `using` lines | keep |
| `CUDA`, `MadNLPGPU` | `solve/gpu.md` | keep |
| `NonlinearSolve` | `flows/shooting.md` and the indirect examples | keep — **required** |

### 2.4 Acceptance

```bash
julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
```

must succeed. It currently does not. Delete `docs/Manifest.toml` first — it is gitignored
(`docs/.gitignore`), so regenerating is free.

---

## 3. `docs/make.jl`

### 3.1 Dead extension handle — a latent crash

`docs/make.jl:108`:

```julia
const CTFlowsODE = Base.get_extension(CTFlows, :CTFlowsODE)
```

That extension no longer exists. CTFlows' extensions are now `CTFlowsPlots`,
`CTFlowsSciMLFlows`, `CTFlowsSciMLIntegrator`, `CTFlowsStaticArrays`. The call returns
`nothing`, `nothing` is pushed into `Modules` (`make.jl:124`), and the `setdocmeta!` loop at
`make.jl:126-129` interpolates it into `:(using $Module)`.

**Fix**: drop the `CTFlowsODE` line, and make the whole extension-handle block defensive:

```julia
_ext(pkg, sym) = Base.get_extension(pkg, sym)

Modules = Any[CTBase, CTLie, CTFlows, CTDirect, CTModels, CTSolvers,
              CTParser, OptimalControl]

for (pkg, syms) in [
    CTModels => (:CTModelsJLD, :CTModelsJSON, :CTModelsPlots),
    CTSolvers => (:CTSolversIpopt, :CTSolversKnitro,
                  :CTSolversMadNLP, :CTSolversMadNCL),
    CTFlows => (:CTFlowsPlots, :CTFlowsSciMLFlows,
                :CTFlowsSciMLIntegrator),
]
    for s in syms
        m = _ext(pkg, s)
        isnothing(m) || push!(Modules, m)
    end
end
```

An unarmed extension must skip, never crash. `api/public.md:34` also references
`CTFlowsODE.AbstractFlow`; that file disappears entirely in PR 4.

### 3.2 CTLie is absent everywhere

Three additions:

1. `using CTLie` alongside the other CT packages (`make.jl:7-13`).
2. `CTLie` in `Modules`, so `setdocmeta!` gives its docstrings a `DocTestSetup`.
3. An `InterLinks` entry (§4).

Without (1) and (2), `@docs ad` cannot resolve and no doctest in the Geometry section runs.

### 3.3 `pages=`

Replace the whole `pages=` block with the sitemap from
[`00-cahier-des-charges.md`](00-cahier-des-charges.md) §7. Keep the
`# index.md is the VitePress root — not listed here` comment; it is correct and non-obvious.

The `"API Reference"` node keeps coming from the `with_api_reference` do-block, but its shape
changes in PR 4 — see [`09-api-reference.md`](09-api-reference.md). **PR 2 leaves
`api_reference.jl` alone** apart from §3.5.

### 3.4 Literate

`make.jl:189` hardcodes `for file in ["tutorial.jl"]`, and `tutorial_postprocess` is an
identity function with a commented-out body. Two cleanups:

- Delete `docs/src-literate/tutorial_pre.jl` — never referenced.
- Either delete `tutorial_postprocess` or restore its intent. The commented line injects
  `@meta Draft = false` so the tutorial executes even under a global `draft = true`; that is
  useful, and the comment above it (`make.jl:191`) still claims it happens. Decide and make
  the code and the comment agree.

The guided tour keeps the Literate pipeline (markdown + notebook + script). Its output path
moves to `docs/src/getting-started/guided-tour.md` — see
[`02-getting-started.md`](02-getting-started.md).

### 3.5 `describe` is invisible in the API

`docs/api_reference.jl:29-44` lists 14 source files. `src/helpers/describe.jl` is **not**
among them, so `describe` — documented on four separate guide pages — appears in no generated
API page. Add it to the list. (Cheap, and independent of the PR 4 rework.)

---

## 4. `InterLinks` and `docs/inventories/`

`make.jl:42-98` declares 11 `InterLinks` entries, each with a third element
`joinpath(@__DIR__, "inventories", "<Pkg>.toml")`. **`docs/inventories/` does not exist.**
`DocumenterInterLinks` tries each location in order and uses the first reachable one, so this
silently degrades to "always fetch from the network" — every build depends on
control-toolbox.org being up, and `@extref` to an unreleased sibling cannot resolve at all.

Three actions:

1. **Add CTLie** to the `InterLinks` list. Until this lands, no page may write
   `[`ad`](@extref)` — the reference will not resolve and `warnonly=true` will hide it.
2. **Create `docs/inventories/`** with the fallback inventories, or delete the third element
   from every entry so the intent is honest. Prefer creating it.
3. **Point the CT entries at the sibling local builds first**, per
   `Handbook/philosophy/documentation.md` §"Local fallback for sibling packages":

```julia
"CTLie" => (
    "https://control-toolbox.org/CTLie/stable/",
    joinpath(@__DIR__, "..", "..", "CTLie",
             "docs", "build", "1", "objects.inv"),
    "https://control-toolbox.org/CTLie/stable/objects.inv",
),
```

First reachable wins, so this resolves locally during cross-repo development and falls back to
the published inventory in CI.

Note the URL: CTLie's repository has **no `.jl` suffix** (`../CTLie`, not `../CTLie.jl`),
unlike CTFlows.jl / CTModels.jl / CTDirect.jl / CTParser.jl. Same for CTBase and CTSolvers.
Check the deployed URLs before committing them.

---

## 5. Archiving the old pages

Decision (recorded in [`README.md`](README.md)): **archive, do not delete.**

```
docs/attic/          ← git mv every docs/src/*.md here
```

- `git mv` all 22 root-level `docs/src/*.md` **except `index.md`**, plus
  `docs/src/api/public.md` and `docs/src/api/subpackages.md`.
- `index.md` stays put — it is the VitePress root and PR 11 rewrites it in place.
- `docs/attic/` is **not** under `docs/src/`, so Documenter never sees it and VitePress never
  builds it. No `pages=` entry, no `.gitignore` entry needed.
- Add `docs/attic/README.md`: one line saying this is the pre-v2.1 documentation kept for
  harvesting, and that PR 12 deletes the directory.
- Per-section reports cite harvest sources as `attic/<file>.md §<section>`.

Also move, since they are outputs of a page being rewritten:

- `docs/src/notebooks/tutorial.ipynb` and `docs/src/scripts/tutorial.jl` — regenerated by
  Literate on every build. **Decide whether they should be committed at all**; they are build
  artifacts sitting in the source tree. Recommendation: gitignore them, keep only
  `docs/src-literate/tutorial.jl` as the source of truth. Same question for
  `docs/src/assets/Manifest.toml` (127 KB, copied by `make.jl:135`).

Assets that **stay**: `docs/src/assets/{chariot.svg, chariot_q.svg, rocket-def.png,
custom.css}`, `docs/src/.vitepress/**`, `docs/src/components/*.vue`.

---

## 6. Page skeleton

Create every file in the §7 sitemap with a minimal stub so the build is green from day one:

```markdown
# [Plot a solution](@id results-plot)

!!! warning "Under construction"
    This page is being written. See [the specification](https://github.com/...).
```

Rules for the stubs:

- The `@id` anchor is **final** from PR 2 on. Later PRs fill content; they never rename
  anchors, because other PRs will already be linking to them.
- Anchor naming: file path with `/` → `-`. `flows/from-ocp.md` → `@id flows-from-ocp`.
- The `!!! warning` block disappears when the page is written.

This is what makes the PRs independent: PR 8 can link `[the solution object](@ref results-solution)`
before PR 7 has written a word of it.

---

## 7. VitePress

`docs/src/.vitepress/config.mts` needs **no structural change** — the sidebar is injected by
DocumenterVitepress (`sidebar: 'REPLACE_ME_DOCUMENTER_VITEPRESS'`, line 106) from `pages=`.

Two things to preserve, both non-obvious:

- **The `{{`/`}}` escaping plugin** (`config.mts:61-71`). It exists so
  `` `@Lie {{H, K}, L}` `` is not parsed as a Vue template expression. The Geometry section
  will use that notation heavily. Do not touch it.
- **`nav`** (`config.mts:20-23`) is just `Home` + the version picker. With nine top-level
  sections in the sidebar that is fine; if the sidebar gets crowded, `sidebarDrawer` is already
  on (`make.jl:218`).

`docs/package.json` and the theme CSS need no change.

---

## 8. Acceptance criteria

- [ ] `julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'` succeeds.
- [ ] `docs/Project.toml` has `CTLie`, `DifferentiationInterface`, `ForwardDiff`,
      `OrdinaryDiffEqTsit5`; no `=` pin; every CT compat matches the root.
- [ ] `docs/make.jl` has `using CTLie`, `CTLie` in `Modules`, no `CTFlowsODE`, and the
      extension loop skips `nothing`.
- [ ] `docs/inventories/` exists (or the third `InterLinks` element is gone), and CTLie has an
      entry.
- [ ] `src/helpers/describe.jl` is in the `api_reference.jl` file list.
- [ ] `docs/src-literate/tutorial_pre.jl` deleted.
- [ ] Every page of the §7 sitemap exists as a stub with its final `@id`.
- [ ] `docs/attic/` holds the 24 old markdown files and a `README.md`.
- [ ] `julia --project=docs docs/make.jl` completes with `draft = true`, **and the log has no
      `cannot resolve` / `Error:` lines** (`warnonly=true` will not fail the build for you).
- [ ] `cd docs && npm install && npx vitepress build build/1` completes.

## Outgoing links

- Sitemap and conventions: [`00-cahier-des-charges.md`](00-cahier-des-charges.md) §7, §8
- API reference rework that lands next: [`09-api-reference.md`](09-api-reference.md)
- Guided tour output path: [`02-getting-started.md`](02-getting-started.md)
