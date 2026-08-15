# API reference — specification

**PR**: 4 · **Depends on**: PR 2 · **Status**: specification
**Scope**: `docs/api_reference.jl`, `docs/src/api/*`, `docs/make.jl` (the `pages=` API node)

## Objective

Replace a hand-maintained, alphabetical, partly-dead list of ~125 symbols with **thematic
pages generated from a Julia manifest**, so the reference cannot drift from the code again.

The user's framing: *"l'api par méthode"* — grouped so you can find a function by what it
does, not by its initial.

## The problem with what exists

`docs/src/api/public.md` is 160 lines: an `@autodocs` block for the module docstring, then one
`@docs; canonical=true` block listing ~125 symbols alphabetically, by hand. It has drifted:

| Entry | Status |
| --- | --- |
| `*(::CTFlowsODE.AbstractFlow)` | `CTFlowsODE` **no longer exists** |
| `Lie`, `⋅` | removed from the ecosystem |
| `success` | never had a method; `success` is `Base.success` |
| `time` | no longer re-exported |
| `CTModels.OCP.constraint` / `.objective` / `.variable` | submodule reorganised into `Components` / `Models` / `Solutions` |
| `CTDirect.discretize`, `CTSolvers.Optimization.*` in the `solve` signatures | paths changed |

And it is missing everything new: `ad`, `dg_ad_backend`, `dg_ad_backend!`, the whole
`MultiPhase` group (`n_phases`, `get_flow(s)`, `get_jump(s)`, `get_switching_time(s)`),
`CPU`/`GPU`, `force`, `evaluate_at`, `final_state`, `SciML`, `control_law`,
`pseudo_hamiltonian`, and the entire `CTBase.Data` type vocabulary.

For scale: `names(OptimalControl)` returns **193 symbols** today (measured, see
[`99-api-coverage.md`](99-api-coverage.md)). The hand-written page lists ~125, several of
which no longer exist.

The Handbook is explicit: *"never hand-write API pages"*
(`Handbook/philosophy/documentation.md` §Principles). This PR brings OptimalControl back in
line — with one adaptation, because OptimalControl's public surface is almost entirely
**re-exported**, and `automatic_reference_documentation` selects symbols by *defining source
file*. A file-based scan of `src/` would find only `solve`, `methods` and the private helpers.

## The design: a thematic manifest

Keep `with_api_reference` / `_cleanup_pages` (they work). Add a manifest to
`docs/api_reference.jl` mapping a theme to a symbol list, and generate one `.md` per theme.

```julia
# docs/api_reference.jl

const API_THEMES = [
    (id="modelling", title="Modelling", symbols=[
        Symbol("@def"), Symbol("@init"),
        :time!, :state!, :control!, :variable!, :dynamics!,
        :objective!, :constraint!, :time_dependence!, :build,
        :build_initial_guess,
    ]),
    (id="problem", title="Problem", symbols=[...]),
    (id="solving", title="Solving", symbols=[...]),
    (id="options", title="Options and strategies", symbols=[...]),
    (id="solution", title="Solution", symbols=[...]),
    (id="flows", title="Flows", symbols=[...]),
    (id="geometry", title="Geometry", symbols=[...]),
    (id="types", title="Types", symbols=[...]),
    (id="io", title="Plotting and I/O", symbols=[...]),
]
```

Each theme becomes `docs/src/api/<id>.md`, written at build time and removed by
`_cleanup_pages` afterwards — same lifecycle as the existing `api/private.md`. The page body
is a `@docs; canonical=true` block over the theme's symbols, plus a one-paragraph lead.

Themes mirror the sitemap ([`00-cahier-des-charges.md`](00-cahier-des-charges.md) §7) so a
reader moving from a guide to the reference lands somewhere recognisable.

### The completeness check — the part that stops the drift

Generate, in the same script, the set of symbols OptimalControl actually exports:

```julia
exported = setdiff(names(OptimalControl), (:OptimalControl,))
covered  = union(Set.(t.symbols for t in API_THEMES)...)

missing_syms = setdiff(exported, covered)   # exported but in no theme
stale_syms   = setdiff(covered, exported)   # in a theme but not exported
```

Emit an `@warn` (or fail the build under a flag) when either set is non-empty. **This is the
whole point of the rework**: `Lie` and `⋅` sat in `public.md` for a full release cycle because
nothing checked. Wire the same two sets into
[`99-api-coverage.md`](99-api-coverage.md).

### Imported-but-not-exported symbols

Some names are legitimately reachable only as `OptimalControl.X` — `PreModel`, `Model`,
`Solution`, `AbstractSolution`, `Collocation`, `ADNLP`, `Exa`, `Ipopt`, `MadNLP`, `MadNCL`,
`Knitro`, `Uno`, `LiftedHamiltonianFunction`, the `CTException` family. They belong in the
reference (guides use them) but are **not** in `names(OptimalControl)`.

Give them their own theme, `api/qualified.md` — "Reachable as `OptimalControl.X`" — and
exclude it from the `exported` check. A user who has to type the prefix deserves to be told
which names those are, in one place.

## Pages produced

```
API reference
    Modelling                api/modelling.md          generated
    Problem                  api/problem.md            generated
    Solving                  api/solving.md            generated
    Options and strategies   api/options.md            generated
    Solution                 api/solution.md           generated
    Flows                    api/flows.md              generated
    Geometry                 api/geometry.md           generated
    Types                    api/types.md              generated
    Plotting and I/O         api/io.md                 generated
    Qualified access         api/qualified.md          generated
    Internals                api/internals.md          generated (was "Private")
    Ecosystem                api/ecosystem.md          hand-written, 1 page
```

Two renames worth doing while the file is open:

- **"Private" → "Internals"**, matching the Handbook's wording
  (`title="Internals"`, `filename="internals"`).
- **"Subpackages" → "Ecosystem"**. The current `api/subpackages.md` is ten lines of `@extref`
  links to six sibling packages and it is the main place the CTX split leaks into the
  user-facing site. Rewrite it as a short *"this package is assembled from these; you do not
  need to know that, but here is the map"* page — and **add CTLie**, which is missing today.

## Themes: the symbol assignment

Full lists live in [`99-api-coverage.md`](99-api-coverage.md); this is the partition rule.

| Theme | Contains |
| --- | --- |
| Modelling | `@def`, `@init`, the `PreModel` builders, `build`, `build_initial_guess` |
| Problem | every model getter and trait: dimensions, names, components, times, dynamics, cost, constraints, `definition`, `is_autonomous`, `has_control`, … |
| Solving | `solve`, `methods`, `discretize`, `ocp_model`, `nlp_model`, `ocp_solution`, `get_build_examodel` |
| Options and strategies | `describe`, `id`, `metadata`, `options`, `option_*`, `has_option`, `route_to`, `bypass`, `force`, `is_user`/`is_default`/`is_computed`, `create_registry`, `strategy_ids`, `type_from_id`, `parameter`, `default_parameter`, `available_parameters`, `CPU`, `GPU` |
| Solution | `state`, `control`, `costate`, `variable`, `objective`, `time_grid`, `times`, `status`, `message`, `successful`, `iterations`, `constraints_violation`, `infos`, `model`, `is_empty`, `dual` + the constraint duals |
| Flows | `Flow`, `control_law`, `pseudo_hamiltonian`, the `MultiPhase` group, `SciML`, `AbstractIntegrator`, `AbstractIntegrationResult`, `final_state`, `evaluate_at` (+ the accessor re-exports decided in PR 8) |
| Geometry | `ad`, `Lift`, `Poisson`, `∂ₜ`, `@Lie`, `dg_ad_backend`, `dg_ad_backend!` |
| Types | the `CTBase.Data` vocabulary: `VectorField`, `Hamiltonian`, `HamiltonianVectorField`, `PseudoHamiltonian`, `PseudoHamiltonianVectorField`, `ControlledVectorField`, `ComposedHamiltonian`, `ComposedVectorField`, `ControlLaw`, `OpenLoop`, `ClosedLoop`, `DynClosedLoop`, `PathConstraint`, `StateConstraint`, `ControlConstraint`, `MixedConstraint`, `Multiplier`, and their `Abstract*` supertypes |
| Plotting and I/O | `plot`, `plot!`, `export_ocp_solution`, `import_ocp_solution` |
| Qualified access | `PreModel`, `Model`, `Solution`, the strategy component types, `LiftedHamiltonianFunction`, the `CTException` family |

Judgement calls, recorded so they are not re-argued:

- **`variable` is in Solution, not Problem.** It is one generic over both; put it where it is
  most used and cross-reference.
- **`describe` is in Options**, not Solving — it introspects strategies, including the
  indirect ones (`:di`, `:sciml`).
- **`CPU`/`GPU` are in Options**, not Solving — they are strategy parameters.
- **The `CTException` family goes in Qualified access.** It is not exported, and a reader
  looking for it is debugging.

## Also in this PR

- **Delete `docs/src/api/public.md`** and `docs/src/api/subpackages.md` (the latter is
  replaced by `api/ecosystem.md`).
- **Keep the `!!! tip` about re-exports** in spirit but rewrite it: the current text
  (`api/public.md:9-21`) explains that `CTFlows.Lift` works from OptimalControl — a
  double error (it is CTLie's now, and the prefix is no longer shown anywhere). The
  replacement belongs on `api/ecosystem.md`, phrased as *"everything documented here is
  reachable from `using OptimalControl`"*.
- **Verify `src/helpers/describe.jl` is in the Internals file list** (added in PR 2).
- **Add `docs/api_reference.jl`'s new manifest to the review checklist** for every future
  source PR that adds an export.

## Acceptance criteria

- [x] `docs/src/api/public.md` and `api/subpackages.md` are deleted.
- [x] Every theme page is generated at build time and removed by `_cleanup_pages`.
- [x] The completeness check runs and reports **zero** missing and **zero** stale symbols.
- [x] `api/ecosystem.md` lists all seven packages including **CTLie**, and every link
      resolves through `InterLinks`.
- [x] The Internals page is titled "Internals" and includes `describe`.
- [x] No `@docs` block anywhere under `docs/src/` outside `api/` — the guides link to the
      reference, they do not inline it (this deletes the inline block currently at the end of
      `attic/manual-macro-free.md`).
- [x] `docs/make.jl`'s API node is built from the manifest, not from a literal list.

Verified by an independent full rebuild (`julia --project=docs docs/make.jl` +
`npx vitepress build build/1`), not just re-checked against the diff: all seven criteria hold,
and this rework also fixes the 10 unresolved self-`@ref`s for `solve`/`methods`/`describe` on
the old `api/private.md` found while auditing PR 2's build. Not fixed here, and out of scope
(structural, not a regression from this PR — `external_modules_to_document` is unchanged from
`main`): a large number of "cannot resolve `@ref`" warnings on the generated theme pages, from
sibling-package docstrings whose own "See also" cross-references use bare `@ref` (correct only
within their own doc build, not when the docstring is reused here). `warnonly=true` already
tolerates these; fixing them would mean rewriting docstrings across several sibling repos.

## Outgoing links

- Symbol partition and the coverage checklist: [`99-api-coverage.md`](99-api-coverage.md)
- Sitemap the themes mirror: [`00-cahier-des-charges.md`](00-cahier-des-charges.md) §7
- The `describe.jl` file-list fix: [`01-infrastructure.md`](01-infrastructure.md) §3.5
- The flow-accessor re-export decision that changes the Flows theme:
  [`05-flows-indirect.md`](05-flows-indirect.md) §`flows/accessors.md`
