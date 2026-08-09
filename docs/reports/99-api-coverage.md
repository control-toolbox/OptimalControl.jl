# API coverage matrix

**Status**: specification · **Generated from**: `names(OptimalControl)` on
OptimalControl 2.1.0-beta, resolved environment (CTBase 0.28.9-beta, CTModels 0.15.3-beta,
CTFlows 0.16.3-beta, CTLie 0.1.5-beta, CTSolvers 0.4.34-beta)

## What this is

The objective acceptance criterion for the whole rewrite: **every exported symbol appears in
at least one guide page and in exactly one API-reference theme.**

`names(OptimalControl)` returns **193 symbols** (excluding `:OptimalControl` itself). They are
partitioned below. A symbol with an empty *Guide* cell is a hole — either a page must cover it
or it must be justified as reference-only.

Regenerate the ground truth with:

```bash
julia --project=. -e 'using OptimalControl;
  ns = filter(n -> n !== :OptimalControl, names(OptimalControl));
  println(length(ns)); foreach(println, ns)'
```

PR 4 wires the same computation into `docs/api_reference.jl` as a build-time check
([`09-api-reference.md`](09-api-reference.md) §"The completeness check").

Page ids refer to the sitemap in [`00-cahier-des-charges.md`](00-cahier-des-charges.md) §7.

---

## 1. Module aliases — 6

Re-exported so generated code and macro expansions can qualify. Not user-facing API.

| Symbol | Why it is exported | Guide | API theme |
| --- | --- | --- | --- |
| `CTBase` | `@Lie` expands to `CTBase.Traits.*` | `geometry-lie-macro` | qualified |
| `CTLie` | `@Lie` expands to `CTLie._lie_mac` | `geometry-lie-macro` | qualified |
| `CTFlows` | generated code prefix; escape hatch for `system`/`integrator` | `flows-accessors` | qualified |
| `CTModels` | escape hatch (`CTModels.JLD2Tag`, …) | `results-save-load` | qualified |
| `ADNLPModels` | arms the `CTSolversADNLPModels` extension | `getting-started-installation` | qualified |
| `ExaModels` | arms the ExaModels path | `solve-gpu` | qualified |

`CTSolvers`, `CTDirect` and `CTParser` are **not** exported. Never write them in an example.

## 2. Macros — 3

| Symbol | Guide | API theme |
| --- | --- | --- |
| `@def` | `modelling-abstract-syntax` | modelling |
| `@init` | `solve-initial-guess` | modelling |
| `@Lie` | `geometry-lie-macro` | geometry |

## 3. Modelling — 10

| Symbol | Guide | API theme |
| --- | --- | --- |
| `time!` `state!` `control!` `variable!` `dynamics!` `objective!` `constraint!` `time_dependence!` `build` | `modelling-functional-api` | modelling |
| `build_initial_guess` | `solve-initial-guess` | modelling |

## 4. Problem introspection — 47

All on `modelling-inspect` unless noted; API theme **problem**.

**Dimensions and names (12)**
`state_dimension` `state_name` `state_components` `control_dimension` `control_name`
`control_components` `variable_dimension` `variable_name` `variable_components`
`components` `dimension` `name`

**Generic component accessors (3)**
`index` `expression` `criterion`

**Times (14)**
`initial_time` `final_time` `times` `time_name` `initial_time_name` `final_time_name`
`has_fixed_initial_time` `has_free_initial_time` `has_fixed_final_time` `has_free_final_time`
`is_initial_time_fixed` `is_initial_time_free` `is_final_time_fixed` `is_final_time_free`

**Dynamics and cost (7)**
`dynamics` `mayer` `lagrange` `has_mayer_cost` `has_lagrange_cost`
`is_mayer_cost_defined` `is_lagrange_cost_defined`

**Constraints (11)**
`constraint` `constraints` `path_constraints_nl` `boundary_constraints_nl`
`state_constraints_box` `control_constraints_box` `variable_constraints_box`
`dim_path_constraints_nl` `dim_boundary_constraints_nl` `dim_state_constraints_box`
`dim_control_constraints_box` `dim_variable_constraints_box`

**Definition (3)**
`definition` `has_abstract_definition` `is_abstractly_defined`

**Traits (7)** — also on `modelling-without-control` for the control pair
`is_autonomous` `is_nonautonomous` `is_variable` `is_nonvariable` `has_variable`
`has_control` `is_control_free`

> `objective` and `variable` are generics over both a model and a solution. They are counted
> once, in §6.

## 5. Solving — 8

| Symbol | Guide | API theme |
| --- | --- | --- |
| `solve` | `solve-overview` | solving |
| `methods` | `solve-choosing-a-method` | solving |
| `discretize` | `solve-explicit-mode` | solving |
| `ocp_model` `nlp_model` `ocp_solution` | `solve-explicit-mode` | solving |
| `get_build_examodel` | `solve-gpu` | solving |
| `describe` | `solve-choosing-a-method`, `flows-overview`, `geometry-ad-backend` | options |

## 6. Solution — 27

All on `results-solution` unless noted; API theme **solution**.

**Trajectories (5)** — also `flows-simulation`
`state` `control` `costate` `variable` `time_grid`

**Objective (1)** — also `flows-simulation`
`objective`

**Status (7)**
`status` `message` `successful` `iterations` `constraints_violation` `infos` `model`

**Emptiness (2)**
`is_empty` `is_empty_time_grid`

**Duals (12)**
`dual` `path_constraints_dual` `boundary_constraints_dual`
`state_constraints_lb_dual` `state_constraints_ub_dual`
`control_constraints_lb_dual` `control_constraints_ub_dual`
`variable_constraints_lb_dual` `variable_constraints_ub_dual`
`dim_dual_state_constraints_box` `dim_dual_control_constraints_box`
`dim_dual_variable_constraints_box`

## 7. Options and strategies — 22

All on `solve-options` or `solve-choosing-a-method`; API theme **options**.

| Symbol | Guide |
| --- | --- |
| `route_to` `bypass` `force` | `solve-options` |
| `options` `option_names` `option_type` `option_default` `option_defaults` `option_description` `option_value` `option_source` `has_option` | `solve-options` |
| `is_user` `is_default` `is_computed` | `solve-options` |
| `id` `metadata` `create_registry` `strategy_ids` `type_from_id` | `solve-choosing-a-method` |
| `parameter` `default_parameter` `available_parameters` | `solve-gpu` |
| `CPU` `GPU` | `solve-gpu` |

## 8. Flows — 17

API theme **flows**.

| Symbol | Guide |
| --- | --- |
| `Flow` | `flows-from-ocp`, `flows-from-hamiltonians`, `flows-simulation` |
| `control_law` `pseudo_hamiltonian` | `flows-accessors` |
| `MultiPhaseFlow` `MultiPhaseStateFlow` `MultiPhaseHamiltonianFlow` `AnyMultiPhaseFlow` | `flows-multi-phase` |
| `n_phases` `get_flow` `get_flows` `get_switching_time` `get_switching_times` `get_jump` `get_jumps` | `flows-multi-phase` |
| `SciML` `AbstractIntegrator` `AbstractIntegrationResult` | `flows-overview` |
| `final_state` `evaluate_at` | `flows-overview` |

**Pending PR 8 — 7 more rows, decided but not yet implemented.** `hamiltonian`,
`hamiltonian_vector_field`, `vector_field`, `get_hamiltonian_gradient`,
`get_variable_gradient`, `get_pseudo_hamiltonian_gradient`, `get_pseudo_variable_gradient`
are exported by `CTFlows` but not re-exported here, while their siblings `control_law` and
`pseudo_hamiltonian` are. PR 8 closes the gap
([`05-flows-indirect.md`](05-flows-indirect.md) §`flows/accessors.md`); all seven belong on
`flows-accessors`, API theme **flows**. `system` and `integrator` stay deliberately
unexported — qualified as `CTFlows.Flows.system(f)`.

After PR 8 the exported count becomes **200**.

## 9. Geometry — 7

API theme **geometry**.

| Symbol | Guide |
| --- | --- |
| `ad` | `geometry-ad` |
| `Lift` | `geometry-lift` |
| `Poisson` | `geometry-poisson` |
| `∂ₜ` | `geometry-ad` §"Partial time derivative" |
| `dg_ad_backend` `dg_ad_backend!` | `geometry-ad-backend` |

(`@Lie` counted in §2.)

## 10. Type vocabulary — 27

API theme **types**. Primary guide `flows-from-hamiltonians`; the constraint types also on
`flows-constrained-arcs`, the law types also on `flows-simulation`.

**Vector fields (6)**
`AbstractVectorField` `VectorField` `AbstractControlledVectorField` `ControlledVectorField`
`ComposedVectorField` `controlled_vector_field`

**Hamiltonians (7)**
`AbstractHamiltonian` `Hamiltonian` `ComposedHamiltonian`
`AbstractHamiltonianVectorField` `HamiltonianVectorField`
`AbstractPseudoHamiltonian` `PseudoHamiltonian`

**Pseudo-Hamiltonian fields (2)**
`AbstractPseudoHamiltonianVectorField` `PseudoHamiltonianVectorField`

**Control laws (5)** — `flows-simulation`, `flows-from-ocp`
`AbstractControlLaw` `ControlLaw` `OpenLoop` `ClosedLoop` `DynClosedLoop`

**Constraints and multipliers (7)** — `flows-constrained-arcs`
`AbstractPathConstraint` `PathConstraint` `StateConstraint` `ControlConstraint`
`MixedConstraint` `AbstractMultiplier` `Multiplier`

## 11. Plotting and I/O — 4

| Symbol | Guide | API theme |
| --- | --- | --- |
| `plot` `plot!` | `results-plot` | io |
| `export_ocp_solution` `import_ocp_solution` | `results-save-load` | io |

---

## 12. Reachable only as `OptimalControl.X`

Not in `names(OptimalControl)`, but used by guides. API theme **qualified**.
This list is the reason that theme exists: a user who has to type the prefix should be able to
find out which names those are, in one place.

| Symbol | Used on | Note |
| --- | --- | --- |
| `PreModel` `Model` | `modelling-functional-api` | the builder and the built model |
| `Solution` `AbstractSolution` | `results-solution` | never write bare `Solution` in an example |
| `AbstractInitialGuess` `InitialGuess` | `solve-initial-guess` | |
| `Collocation` | `solve-explicit-mode` | |
| `ADNLP` `Exa` | `solve-explicit-mode` | |
| `Ipopt` `MadNLP` `MadNCL` `Knitro` `Uno` | `solve-explicit-mode` | |
| `AbstractDiscretizer` `DiscretizedModel` `AbstractNLPModeler` `AbstractNLPSolver` | `solve-explicit-mode` | the types mode detection dispatches on |
| `LiftedHamiltonianFunction` | `geometry-lift` | the former `HamiltonianLift` |
| `CTException` `IncorrectArgument` `PreconditionError` `NotImplemented` `ParsingError` `AmbiguousDescription` `ExtensionError` | `migration`, error demos across the site | `SolverFailure` is **not** imported at all — see §14 |
| `NotProvided` `NotProvidedType` `ctNumber` | — | reference only |
| `AbstractStrategy` `StrategyRegistry` `StrategyMetadata` `StrategyOptions` `RoutedOption` `BypassValue` `AbstractStrategyParameter` `OptionDefinition` `OptionValue` | — | reference only; the functions are the API |

Not exported and **not** documented as available: `OptimalControl.get_strategy_registry`,
`get_full_strategy_registry`, `solve_explicit`, `solve_descriptive`,
`display_ocp_configuration`, `will_solver_print`, `SolveMode`. Exception:
`get_full_strategy_registry` is mentioned once on `flows-overview` as the introspection entry
point that merges the solve and flow registries.

---

## 13. Deprecated names re-introduced by PR 3

These become defined again, as throwing shims. They belong in the reference so a search for
them lands on the explanation, not on nothing.

| Symbol | Guide | API theme |
| --- | --- | --- |
| `Lie` `⋅` `HamiltonianLift` | `migration` | qualified (marked deprecated) |

`Base.success` and `Base.time` gain methods but no export — they need no reference entry, only
a row in the migration table.

---

## 14. Open holes

Recorded so they are decided, not forgotten.

| Hole | Where it belongs | Status |
| --- | --- | --- |
| `hamiltonian`, `hamiltonian_vector_field`, `vector_field`, `get_*_gradient` not re-exported, while `control_law` / `pseudo_hamiltonian` are | §8 | ✅ **decided**: PR 8 re-exports the seven; `system`/`integrator` stay qualified |
| CTModels serialization: how is the format selected? | §11 | ✅ **resolved**: `format::Symbol` = `:JLD` \| `:JSON`, plus `filename` without extension. The `*Tag` types are internal dispatch and must not appear in the docs |
| `CTDirect.DirectShooting` exists but is in neither `methods()` nor the registry | §5 | ✅ **closed**: not functional yet — out of scope, do not mention it |
| `SolverFailure` is exported by `CTBase.Exceptions` but imported nowhere in OptimalControl | §12 | open — PR 3: surface it or note the omission |
| CTModels init helpers not re-exported: `initial_guess`, `pre_initial_guess`, `validate_initial_guess`, `initial_state`, `initial_control`, `initial_variable`, `PreInitialGuess` | §3 | open — PR 5/6 |
| `@def_exa` exists in CTParser but is not re-exported | §2 | open — PR 5 |
| `time` and `success` are `Base` names with no OptimalControl binding | §13 | open — PR 3 |

## 15. How to use this file

1. When a docs PR is written, tick its symbols off by filling the *Guide* column with the page
   that actually covers them (not the one that was planned).
2. Before merging PR 12, re-run the `names(OptimalControl)` command above and diff against
   §§1–11. A new symbol with no row is a missing docs change.
3. After PR 4, the build itself reports missing and stale symbols; this file becomes the
   record of the *guide*-side coverage, which the build cannot check.
