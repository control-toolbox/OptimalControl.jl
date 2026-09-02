<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to **OptimalControl.jl** are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.2.0-beta] — 2026-08-28

Dependency realignment onto the released control-toolbox ecosystem, the v2.0 → v2.1 compatibility shims, and a full documentation-site rewrite. No breaking change to OptimalControl's own API; two near-breaking notes — see [BREAKING.md](BREAKING.md).

### ✨ New Features

- **v2.0 → v2.1 compatibility shims** (`src/deprecated.jl`, [#855](https://github.com/control-toolbox/OptimalControl.jl/pull/855)). Five spellings removed in [2.1.0-beta] now throw a typed `CTBase.Exceptions.PreconditionError` naming their replacement instead of a bare `UndefVarError`/`MethodError`: `Lie(X, f)` / `Lie(X, Y)` / `X ⋅ f` → `ad`; `HamiltonianLift` → `Lift` / `CTLie.LiftedHamiltonianFunction`; `time(ocp)` / `time(sol)` → `times` / `time_grid`; `success(sol)` → `successful`; `Flow(f::Function)` and the obsolete 5-/4-positional flow calls → typed constructors / keyword `variable=`. Two spellings are deliberately **not** shimmed — `Flow(ocp, u, g, μ)` (3 positional) and `augment=true` — because a shim would overwrite CTFlows' own method and break precompilation; tracked upstream as [CTFlows#401](https://github.com/control-toolbox/CTFlows.jl/issues/401) and [CTFlows#402](https://github.com/control-toolbox/CTFlows.jl/issues/402). See [Migration](@ref migration).

  **Not carried by the `v2.1.0-beta` tag itself** — that release (2026-07-30) predates this PR by two weeks and ships none of these shims; installing exactly `v2.1.0-beta` still gets the bare error. The structured messages are new here, in 2.2.0-beta.

### 🐛 Bug Fixes

- **`using ExaModels` alongside `using OptimalControl` is no longer suggested anywhere.** ExaModels 0.12 newly exports `objective` and `constraint`, both of which OptimalControl also exports; importing ExaModels unqualified shadows the accessors and the next `objective(sol)` throws `UndefVarError`. The `:exa` modeler needs no `using ExaModels` at all — the module is already bound through `using OptimalControl`. `docs/src/solve/gpu.md` and `docs/src/getting-started/installation.md` dropped the bare import and now state that `:exa` needs no extra package. See [#882](https://github.com/control-toolbox/OptimalControl.jl/issues/882)

### 🛠 Enhancements

- **Explicit `solve` mode rejects unconsumed keyword arguments** instead of silently ignoring them ([#853](https://github.com/control-toolbox/OptimalControl.jl/pull/853)). A mistyped or misplaced strategy option used to be dropped without warning; it now raises an actionable error naming the option, and the explicit-mode documentation is clearer that strategy-specific options are set at construction time. **Near-breaking**: a script that relied on an unconsumed option being silently ignored will now raise. See [BREAKING.md](BREAKING.md)

### 🔄 Refactoring

- The documentation-build label gate (`run documentation`), briefly removed in [#875](https://github.com/control-toolbox/OptimalControl.jl/pull/875), was restored in [#876](https://github.com/control-toolbox/OptimalControl.jl/pull/876) — the gate is deliberate, not an oversight, and stays

### 🧪 Testing

- **Export-collision canary**: a regression test pins `intersect(names(ExaModels), names(OptimalControl))`, filtered to bindings that actually differ (so the shared `:ExaModels` module name does not count), to its known genuine-clash set `[:constraint, :objective]` — the next colliding upstream export lands as a red test rather than a user bug report

- **GPU capability checks aligned with the CTSolvers contract** ([#883](https://github.com/control-toolbox/OptimalControl.jl/issues/883)). `TestCapabilities` moved into `test/runtests.jl` as `Main`-bound constants (`CUDA_FUNCTIONAL`, `ON_GPU_RUNNER`, `GPU_EXTENSION_ARMED`), replacing the `test/helpers/capabilities.jl` functions; `ON_GPU_RUNNER` now matches the `kkt` / `occidata` *substring* of `RUNNER_NAME` (the self-hosted runners register as `…-runner`, [CTSolvers#223](https://github.com/control-toolbox/CTSolvers.jl/pull/223)). A new `test/suite/environment/test_environment_contract.jl` centralises the loud device requirement on the GPU runner and greps the suite for the `isdefined`-against-`Main` and unbraced-device-guard anti-patterns. Fixes the asymmetry where a lost GPU device failed loudly in `test_gpu_routing.jl` but skipped silently in `test_options_forwarding.jl`

### 📚 Documentation

- The documentation site was rewritten onto a new sitemap (getting started, modelling, solve, results, flows, geometry, an examples gallery, and a thematic API reference) and a v2.0 → v2.1 migration page added. The retired v2.0 manuals are kept under `docs/attic/`

- **`_strategy_parameter` docstring no longer emits an unresolvable `@extref`** ([#943](https://github.com/control-toolbox/OptimalControl.jl/issues/943)). It cross-referenced `CTBase.Strategies.parameter` by method signature (`parameter(T, default)` / `parameter(T)`), but CTBase's auto-generated reference indexes the function under a single anchor, so neither link resolved. Collapsed to the one anchor; `docs/make.jl`'s `warnonly` comment refreshed. The remaining `@extref` warnings (`Plots.plot(::CTModels.Solutions.Solution)`) are fixed upstream in [CTModels 0.19.4-beta](https://github.com/control-toolbox/CTModels.jl/issues/427).

- **`docs/make.jl` runs `draft = false` by default** ([#948](https://github.com/control-toolbox/OptimalControl.jl/issues/948)). The build used to ship `draft = true` globally with a `@meta Draft = false` block repeated in 43 pages to opt each one back into execution — a double negative that also blocked a fast `draft = true` pass for link/nav checks. Now the default executes every page; flip the one flag in `make.jl` for a fast local build, or set `Draft = true` in a single page's `@meta` to exclude it. The guided-tour `Draft = false` Literate injection is removed.

### 📦 Dependencies

- **Realigned on the released ecosystem** — every sibling resolves from the General registry with no `Pkg.develop`: CTBase `0.28`→`0.29`, CTModels `0.15`→`0.18`, CTSolvers `0.4`→`0.5`, CTFlows `0.16`→`0.17`, CTParser `0.8`→`0.9`, CTLie `0.1`→`0.2`; CTDirect stays pinned to `1` (the major alone, per the pinning-granularity rule)

- **ExaModels `0.11`→`0.12`** — not optional: CTParser 0.9 emits `add_var` / `add_con` / `add_obj`, which do not exist in ExaModels 0.11, so every `:exa` solve fails at run time on the older version

- `docs/Project.toml` and `docs/src/assets/{Project,Manifest}.toml` mirror the root environment exactly

### ✅ Compatibility

- **No breaking changes to OptimalControl's own public API.** Two near-breaking notes: `using ExaModels` now collides with the `objective` / `constraint` accessors (see 🐛 above), and explicit-mode `solve` now rejects options it used to ignore silently (see 🛠 above). See [BREAKING.md](BREAKING.md).

---

## [2.1.0-beta] — 2026-07-30

Dependency upgrade onto the restructured control-toolbox stack, CTLie integration, and a substantial test rework. See [BREAKING.md](BREAKING.md) for the migration guide.

### Breaking

- **`Flow` now requires an integrator to be loaded.** SciML is no longer a hard dependency; add `using OrdinaryDiffEqTsit5` (or another integrator) before building a flow. This changes every example's preamble.

- **Differential geometry moved to CTLie**: `Lie(X, f)` → `ad(X, f)`; `X ⋅ f` **removed** with no alias; `HamiltonianLift` → `CTLie.LiftedHamiltonianFunction`, which is `<: Function` and **no longer** `<: AbstractHamiltonian`

- **Flow call convention**: the variable has no positional slot any more and `variable=` is mandatory on `NonFixed` problems; `augment=` → `variable_costate=`; new `unsafe=` to suppress the ODE retcode check

- **Constrained flows** take the paired keywords `constraint=` / `multiplier=` instead of three positional arguments. `constraint` now also accepts a `Symbol` naming a `:path` constraint already declared in the OCP

- **Constructor keywords** take an `is_` prefix: `autonomous=` → `is_autonomous=`, `variable=` → `is_variable=`, on the `Data` constructors and on `@Lie`

- **`time` and `success` are no longer re-exported.** Both resolve to bare `Base` functions — `CTModels.Components` extends `Base.time` without exporting it, and `CTModels.Solutions` exports the name `success` while defining no method for it, so `success(sol)` was always a `MethodError`. Use `successful(sol)`

- **For package authors**: a custom `AbstractStrategy` must now implement `CTBase.Strategies.parameter`. This is not a rename of `get_parameter_type`, which defaulted to `nothing`; the CTBase generic throws `NotImplemented`, and option routing calls it

- **`OpenLoop` is unconditionally non-autonomous.** An open-loop control depends only on time, `u(t)` (or `u(t, v)`) — autonomy is a property of the OCP, not of the control, so `is_autonomous` is not a real choice for `OpenLoop` the way it is for `ClosedLoop`/`DynClosedLoop`. `is_autonomous` is kept as a misuse-detector keyword that warns rather than doing nothing. See [CTBase.jl#515](https://github.com/control-toolbox/CTBase.jl/issues/515)

### Added

- **CTLie** as a dependency: `ad`, `Lift`, `Poisson`, `∂ₜ`, `@Lie`, and `dg_ad_backend` / `dg_ad_backend!` for global AD-backend control

- **The full `CTBase.Data` type vocabulary** is re-exported — `Flow` dispatches on these, so building a flow explicitly previously meant reaching into the package by hand. Note that `OpenLoop`, `ClosedLoop`, `DynClosedLoop` and the constraint kinds are factory functions, not types: the kind is a trait parameter

- `CTFlows.MultiPhase` (`n_phases`, `get_flow`, `get_switching_time`, …) and `CTSolvers.Integrators` (`SciML`, `final_state`, `evaluate_at`)

- **`describe` now covers the full strategy surface.** `describe(:di)` and `describe(:sciml)` work from the same entry point as `describe(:ipopt)`, merging the solve registry with CTFlows' flow registry via `Base.merge` (CTBase ≥ 0.28.8-beta)

- **Test problems are available in two front-end forms**, `:abstract` (the `@def` DSL) and `:functional` (the `CTModels.Building` API), and declare which solution methods they are fixtures for

- **Indirect test fixtures carry their own shooting derivation** (`TestProblem.shoot_builder`, next to the problem itself), consumed generically by a single shooting sweep instead of being re-derived per problem and per test file

- New test groups: extension arming, front-end equivalence, `hamiltonian_type`, the `Flow` API surface, the 1-D = scalar contract across both the direct and indirect paths, `describe` over the full strategy surface, and CPU/GPU routing — the device tier now *requires* a functional GPU on the self-hosted `kkt` runner rather than skipping unconditionally, so a degraded runner fails loudly instead of reporting green having run nothing

### Changed

- **Dependencies**: CTBase `0.28`, CTModels `0.15`, CTSolvers `0.4`, CTFlows `0.16`, CTDirect `1`, CTParser `0.8`; CTLie `0.1` added. SciML moved to `[extras]`. Direct dependencies 21 → 17

- **Imports point at owning submodules** throughout, per the Handbook `modules.md` rule

- **Extensions are explicitly armed.** A `[deps]` entry fires no extension — Julia loads one when its trigger package is loaded. ADNLPModels and DifferentiationInterface are now imported by `src/imports/`, without which the ADNLP modeler and the whole differential-geometry API were dead capabilities we still paid to install

### Fixed

- `_extract_strategy_parameters` no longer crashes on a strategy that has not implemented the optional parameter contract — display code should not be what fails on a third-party strategy. It now warns once per strategy type instead of staying silent, forwarding to CTBase's non-throwing `parameter(T, default)` accessor (CTBase ≥ 0.28.8-beta) rather than rolling its own `try`/`catch`

---

## [2.0.5-beta] — 2026-07-24

### Added

- **Paderborn tutorial**: New tutorial with Literate + Binder setup for interactive execution
  - Double integrator and Goddard problem examples with direct and indirect methods
  - Bang-bang comparison plots, LQR remark, Euler scheme demonstration
  - Binder integration for running tutorial in the browser without local installation

- **CI improvements**: GitHub Actions workflow for project integration

### Changed

- **Dependencies**: Narrowed compat for **CTBase** to `=0.18.8` (was `0.18`) and **CTModels** to `=0.10.1` (was `0.10`) for stricter version pinning

- **Documentation**: Updated README with latest ABOUT.md, INSTALL.md, CONTRIBUTING.md and badges; updated DOI in citation

- **Code formatting**: Applied JuliaFormatter to all `.jl` files

---

## [2.0.4] — 2026-04-22

### Added

- **Documentation improvements**:
  - Added scalar vs vector convention warning in functional API documentation explaining that callbacks always receive vectors (use x[1], u[1], v[1] for dim 1), while solution access returns scalars for dim 1 components (consistent with @def)
  - Added example demonstrating scalar return from control(sol)(t) after solving dim-1 control problem
  - Added modeler compatibility warning in functional API documentation: :exa modeler requires @def, only :adnlp is compatible with functional API
  - Updated solve manual :exa description to mention incompatibility with functional API

### Changed

- **Documentation**:
  - Added ExampleSizeThresholdFilter logger in make.jl to silence harmless warning about @example blocks exceeding example_size_threshold (SVG fallback is used automatically)
  - Added manual-macro-free.md to size_threshold_ignore in HTML configuration
  - Removed redundant section separators (---) between examples in manual-macro-free.md
  - Fixed heading level in index.md (### -> **) for "Free times and extra variables" section

---

## [2.0.3] — 2026-04-18

### Added

- **Functional API**:
  - New macro-free functional API for defining optimal control problems programmatically
  - Uses `OptimalControl.PreModel` as a mutable builder with setter functions: `time!`, `state!`, `control!`, `variable!`, `dynamics!`, `objective!`, `constraint!`, `time_dependence!`, `build`
  - Complete mathematical formulation correspondence table between math and functional API
  - Six comprehensive examples comparing @def syntax with functional API:
    - Double integrator: energy minimisation
    - Double integrator: time minimisation (free final time)
    - Control-free problems (parameter estimation)
    - Problems mixing control and variable
    - Singular control (three-dimensional state, state and control box constraints)
    - State constraint (velocity upper bound)
  - API Reference section documenting all functional API functions

### Changed

- **Documentation**:
  - Restructured documentation TOC with "Define a problem" section containing both abstract syntax and functional API
  - Fixed constraint dimension functions in CTModels v0.9.15-beta API compatibility
  - Updated CTModels dependency to v0.10 (widening support)

- **Dependencies**:
  - Updated CTModels from v0.9.15-beta to v0.10

---

## [2.0.2] — 2026-04-14

### Added

- **Documentation examples**:
  - New comprehensive state constraint example (`example-state-constraint.md`) demonstrating first-order and second-order (Bryson-Denham) state constraints
  - Direct method implementation with parametric OCP for both touch point and boundary arc cases
  - Indirect methods for touch point (2-arc) and boundary arc (3-arc) cases with shooting functions
  - Theoretical references: Bryson et al. (1963), Jacobson et al. (1971), Bryson & Ho (1975)
  - Hamiltonian-based adjoint chain explanations for boundary arc dynamics
  - New example for problems mixing control and variable (`example-control-and-variable.md`) with two examples:
    - Exponential growth rate estimation with control (non-autonomous problem)
    - Harmonic oscillator pulsation optimization with control (autonomous problem)
  - Demonstrates optimal control problems with both control variables and constant parameters to optimize
  - Indirect methods with augmented Hamiltonian and maximising control laws

- **Documentation improvements**:
  - Added "Syntax rules" subsection to `@init` macro documentation explaining LHS/RHS rules, default component names (x₁, x₂), and prohibition of indexed syntax x[i](t)
  - Added "Cross-spec substitution" section to `@init` macro documentation with examples: temporal→temporal, transitive chain, constant→temporal, constant→constant, and mixing with aliases
  - Updated "Component labels and time variable" callout to mention default subscripted component names

### Changed

- **Documentation organization**:
  - Extracted state constraint section from `example-double-integrator-energy.md` into dedicated example file
  - Added cross-references between energy minimization and state constraint examples
  - Added "Control and variable" example to Basic Examples section in documentation navigation
  - Fixed heading level in `example-control-free.md` (## -> ###) for proper hierarchy

- **Dependencies**:
  - Updated UnoSolver from v0.2 to v0.3

---

## [2.0.1] — 2026-04-13

### Changed

- **Exports**:
  - `build_initial_guess` is now explicitly reexported with `@reexport import` for better visibility

- **Documentation improvements**:
  - Added anchor link to "Strategy options" section in manual-solve.md for better navigation
  - Updated `route_to` documentation to support multi-strategy routing with positional syntax
  - Changed `route_to` syntax examples from keyword arguments (`route_to(exa=12)`) to positional arguments (`route_to(:exa, 12)`)
  - Added documentation for routing the same option to multiple strategies with different values using alternating strategy-value pairs

---

## [2.0.0] — 2026-04-03

**Major version release** with complete solve architecture redesign. This release introduces breaking changes from v1.1.6 (last stable release). See [BREAKING.md](BREAKING.md) for detailed migration guide.

### Breaking Changes

- **Removed functions** from v1.1.6:
  - `direct_transcription` → replaced by `discretize`
  - `set_initial_guess` → replaced by `@init` macro
  - `build_OCP_solution` → replaced by `ocp_solution`

- **Changed exports**:
  - CTBase exceptions: removed `IncorrectMethod`, `IncorrectOutput`, `UnauthorizedCall`; added `PreconditionError`
  - CTFlows types: `VectorField`, `Hamiltonian`, `HamiltonianLift`, `HamiltonianVectorField` no longer exported (use qualified access)

- **New solve architecture**:
  - `methods()` now returns 4-tuples `(discretizer, modeler, solver, parameter)` instead of 3-tuples
  - Parameter (`:cpu` or `:gpu`) is now required for complete method specification

### Added

- **Complete solve architecture redesign**:
  - **Descriptive mode**: `solve(ocp, :collocation, :adnlp, :ipopt, :cpu)` with symbolic strategy specification
  - **Explicit mode**: `solve(ocp; discretizer=Collocation(), modeler=ADNLP(), solver=Ipopt())` with typed components
  - **Partial specification**: Auto-completion of missing strategies using first matching method
  - **Method introspection**: `methods()` lists all available solving methods

- **GPU/CPU parameter system**:
  - 4th parameter in method tuples for execution backend (`:cpu` or `:gpu`)
  - Explicit GPU support via `:gpu` parameter with ExaModels + MadNLP/MadNCL
  - 12 total methods: 10 CPU methods + 2 GPU methods

- **Advanced option routing system**:
  - `describe(strategy)`: Display available options for any strategy (discretizer, modeler, solver)
  - `route_to(strategy=option=>value)`: Disambiguate shared options between strategies
  - `bypass(strategy=option=>value)`: Pass undeclared options to strategies
  - Automatic option routing to appropriate components
  - Option introspection: `options()`, `option_names()`, `option_type()`, `option_description()`, `option_default()`

- **Initial guess with @init macro**:
  - New `@init` macro for constructing initial guesses
  - Alias `init` for `initial_guess` keyword argument in solve
  - Replaces functional initial guess construction from v1.1.6

- **Control-free problems support**:
  - Optimal control problems without control variables
  - Optimization of constant parameters in dynamical systems
  - Full integration with solve pipeline
  - **Augmented Hamiltonian approach**: `augment=true` feature in CTFlows for automatic costate computation
  - **Simplified flow creation**: `Flow(ocp)` directly creates Hamiltonian flow from control-free problems
  - **Mathematical framework**: Complete transversality conditions for variable parameters
  - **Documentation**: Comprehensive examples with exponential growth and harmonic oscillator

- **New solvers**:
  - **Uno**: CPU-only nonlinear optimization solver (methods with `:uno`)
  - **MadNCL**: GPU-capable solver (methods with `:madncl`)
  - Total of 5 solvers: Ipopt, MadNLP, Uno, MadNCL, Knitro

- **Additional discretization schemes**:
  - Basic schemes: `:trapeze`, `:midpoint`, `:euler` (and aliases), `:euler_implicit` (and aliases)
  - ADNLP-specific schemes: `:gauss_legendre_2`, `:gauss_legendre_3` (high-order collocation)

- **Comprehensive documentation rewrite**:
  - New solve manual with descriptive/explicit modes
  - Advanced options guide with routing and disambiguation
  - GPU solving guide
  - Initial guess guide with `@init` macro
  - Differential geometry tools manual
  - Control-free problems example

- **Modernized reexport system**:
  - Using `@reexport import` from Reexport.jl
  - Organized by source package (ctbase.jl, ctdirect.jl, ctflows.jl, ctmodels.jl, ctparser.jl, ctsolvers.jl)
  - Cleaner separation between imported and exported symbols

- **CTFlows enhancements**:
  - **Augmented Hamiltonian computation**: `augment=true` automatically computes costates for variable parameters
  - **Direct OCP flow creation**: `Flow(ocp)` creates Hamiltonian flow without manual Hamiltonian definition
  - **Transversality conditions**: Automatic handling of $p_\lambda(t_f) = 0$ for Lagrange costs and $p_\omega(t_f) = -2\omega$ for Mayer costs
  - **Mathematical rigor**: Complete augmented system dynamics with proper initial conditions

- **Strategy registry system**:
  - `StrategyRegistry` with metadata for all strategies
  - `StrategyMetadata` with id, options, and parameter support
  - `OptionDefinition` with type, default, description, and aliases
  - Dependency injection support for testing

### Changed

- **Solve function signatures**:
  - Layer 3 (canonical): `solve(ocp, strategies...; kwargs...)`
  - Layer 2 descriptive: `solve_descriptive(ocp, strategies...; kwargs...)`
  - Layer 2 explicit: `solve_explicit(ocp; discretizer, modeler, solver, kwargs...)`
  - Automatic mode detection based on argument types

- **Component completion**:
  - Intelligent completion of missing strategies using registry
  - First-match priority from `methods()` list
  - Support for partial method specifications

- **Display system**:
  - Configuration box showing applied strategies and options
  - Option source tracking (user, default, computed)
  - Parameter display for GPU/CPU distinction
  - Improved formatting and clarity

- **Test infrastructure**:
  - Comprehensive test suite for solve pipeline (422+ tests)
  - Integration tests with real strategies
  - Mock registry for dispatch testing
  - Parametric mocks for strategy testing
  - Level 3 signature freezing tests for API stability

### Dependencies

- **CTBase**: 0.18.x (was 0.16-0.17)
- **CTModels**: 0.9.x (was 0.6.x)
- **CTDirect**: 1.x (was 0.x)
- **CTSolvers**: 0.4.x (new dependency)
- **CTParser**: 0.8.x (was 0.7-0.8)
- **CTFlows**: 0.8.x

**New dependency**: CTSolvers.jl handles NLP modeling, solving, and strategy orchestration.

### Notes

This release consolidates all beta versions (1.2.0-beta through 1.3.1-beta) into a stable 2.0.0 release. The comparison is made against v1.1.6, the last stable release before the architectural redesign.

For users migrating from v1.1.6, please consult [BREAKING.md](BREAKING.md) for detailed migration instructions and examples.

---

## [1.3.1-beta] — 2026-03-17

### Added

- **Uno solver integration**: Full support for the Uno nonlinear optimization solver
  - Added to solver registry with CPU-only support
  - Added methods `(:collocation, :adnlp, :uno, :cpu)` and `(:collocation, :exa, :uno, :cpu)` to available methods
  - Uno compatible with both ADNLP and Exa modelers
  - Comprehensive test coverage with Beam and Goddard problems
  - Extension error handling when `UnoSolver` package not loaded

- **Solver requirements documentation**: Clear documentation of required imports for each solver
  - New "Solver requirements" section in `manual-solve.md`
  - Updated examples in `manual-solve-explicit.md` with import instructions
  - GPU requirements clarification in `manual-solve-gpu.md`
  - Based on CTSolvers extension triggers:
    - Ipopt: `using NLPModelsIpopt`
    - MadNLP: `using MadNLP` (CPU) or `using MadNLPGPU` (GPU)
    - Uno: `using UnoSolver`
    - MadNCL: `using MadNCL` and `using MadNLP`
    - Knitro: `using NLPModelsKnitro` (commercial license)

- **Solver output detection**: `will_solver_print(::CTSolvers.Uno)` method to check if Uno will produce output based on `logger` option (silent when `logger="SILENT"`)

### Changed

- **Solver count**: Updated from 4 to 5 available solvers (Ipopt, MadNLP, Uno, MadNCL, Knitro)
- **Method count**: Updated from 10 to 12 available methods (10 CPU + 2 GPU)
- **Test structure**: Restructured canonical tests to use modeler-solver pairs, Uno now works with both ADNLP and Exa
- **Documentation**: Updated solver lists and examples throughout documentation to include Uno

---

## [Unreleased] — branch `action-options`

### Added

- **Action options routing**: `initial_guess` and `display` are now routed through
  `CTSolvers.route_all_options`, enabling alias support and a cleaner separation of
  concerns between action-level and strategy-level options.
- **Alias `init`** for `initial_guess` in all solve modes:
  ```julia
  solve(ocp, :collocation; init=x0)
  ```
- **`_extract_action_kwarg`** helper in `src/helpers/kwarg_extraction.jl`: alias-aware
  extraction with conflict detection (raises `CTBase.IncorrectArgument` when two aliases
  are provided simultaneously).
- **DRY constants** in `src/helpers/descriptive_routing.jl`:
  - `_DEFAULT_DISPLAY = true`
  - `_DEFAULT_INITIAL_GUESS = nothing`
  - `_INITIAL_GUESS_ALIASES_ONLY = (:init,)` — used in `OptionDefinition`
  - `_INITIAL_GUESS_ALIASES = (:initial_guess, :init)` — used in `_extract_action_kwarg`
- **Docstring** for the Layer 3 `CommonSolve.solve` method in `src/solve/canonical.jl`.

### Changed

- `CommonSolve.solve` top-level signature simplified: `initial_guess` and `display` are
  no longer explicit named arguments — they are extracted from `kwargs...` by the routing
  layer.
- `solve_descriptive` no longer accepts `initial_guess` and `display` as explicit named
  arguments; they are extracted from `kwargs...` via `_build_components_from_routed`.
- `solve_explicit` extracts `initial_guess` (with alias `init`) and `display` from
  `kwargs...` using `_extract_action_kwarg`.
- `_build_components_from_routed` now receives `ocp` as first argument to call
  `CTModels.build_initial_guess`.

### Removed

- Alias `:i` for `initial_guess` (too short, risk of collision with user variables).

---

## [1.3.0-beta] — 2026-03-16

### Added

- **Level 3 signature freezing tests** for reexport API across all CTX packages:
  - Type hierarchy checks for inheritance relationships (e.g., `Collocation <: AbstractDiscretizer`)
  - Method signature checks with `hasmethod()` for key functions (e.g., `discretize`, `solve`, `ocp_model`)
  - Missing symbols `solve` and `plot!` now properly tested
  - 503 reexport tests passing, up from 497

### Changed

- **Simplified ExaModels documentation**: removed warnings about coordinate-by-coordinate
  dynamics and scalar nonlinear constraints requirements, improving user experience
  when using the `:exa` modeler for GPU solving
- **Removed outdated API documentation**: `docs/src/api/private.md` deleted

### Fixed

- **API breakage detection**: tests now detect when CTX packages modify their APIs,
  preventing silent breakages in OptimalControl.jl

---

## [1.2.3-beta] — 2026-03-07

### Added

- **Comprehensive unit tests** for display helper functions (29 new tests):
  - Parameter extraction tests
  - Display strategy determination tests
  - Source tag building tests
  - Component formatting tests

- **Helper functions** for improved code architecture:
  - `_extract_strategy_parameters`: Extract parameters from strategies
  - `_determine_parameter_display_strategy`: Decide parameter display logic
  - `_print_component_with_param`: Format components with parameters
  - `_build_source_tag`: Build option source tags (DRY elimination)

### Changed

- **Refactored `display_ocp_configuration`** to follow SOLID principles:
  - Extracted focused helper functions (Single Responsibility)
  - Eliminated code duplication (DRY)
  - Improved testability and maintainability
  - Reduced function length from ~180 to ~120 lines

- **Enhanced test coverage**: 75 tests for print helpers (46 existing + 29 new)
- **Adjust allocation limits** in component completion tests for realistic bounds

### Fixed

- **Parameter extraction** now correctly handles real strategies with default parameters
- **Source tag building** properly handles empty parameter arrays
- **All 1215 tests pass** with improved architecture

---

## [1.2.2-beta] — 2026-03-06

### Added

- **Complete GPU/CPU parameter system** with 4-tuple methods returning parameter
- **Strategy builders** with ResolvedMethod support and parameter-aware mapping
- **Comprehensive test coverage**: 422 tests total across all helper modules
- **Registry enhancements** for parameter-based strategy routing
- **Dependency handling** for both provided and build strategy construction paths

### Changed

- **Methods API**: `Base.methods()` now returns 4-tuples with parameter symbol
- **Registry**: Parameter-aware strategy mapping and resolution
- **Strategy builders**: Enhanced with parameter support and ResolvedMethod integration
- **Test infrastructure**: Comprehensive test suites for all helper functions

---

## [1.2.1-beta] — 2026-03-05

### Added

- **Initial GPU/CPU parameter infrastructure**
- **Parameter-aware method resolution** system
- **Basic strategy registry** with parameter support
- **Foundation for GPU solving** via ExaModels backend

### Changed

- **Internal architecture** preparation for parameter system
- **Test structure** for parameter-aware components

---

## [1.1.8-beta] — 2026-01-17

### Changed

- Widened compat for **CTParser** to accept `0.7` and `0.8` (preparation for CTParser
  v0.8.x migration, tracked in control-toolbox/CTParser.jl#207).
- Widened compat for **CTBase** to accept `0.16` and `0.17`.

---

## [1.1.7-beta] — 2026-01-17

### Changed

- Added compat for **CTBase v0.17**.
- Merged test dependencies into the main `Project.toml` (previously in a separate
  `test/Project.toml`).

---

## [1.1.6] — 2025-10-31

### Added

- **`RecipesBase`** added as a direct dependency, enabling plot recipes for solutions
  without requiring `Plots.jl` to be loaded.

### Fixed

- Improved error handling for the `Plots.jl` extension: a clear `CTBase.IncorrectArgument`
  is now raised when plotting is attempted without `Plots.jl` loaded (#653).
- Fixed maximisation objective sign for ExaModels backend (#663).
- Replaced `Minpack` by `NonlinearSolve` in the shooting extension.

### Changed

- Bumped compat for **NLPModelsIpopt** to `0.11`.

---

## [1.1.5] — 2025-10-23

### Added

- AI assistant buttons in the documentation to try examples interactively.
- Spell-check CI workflow (`SpellCheck.yml`).

---

## [1.1.4] — 2025-10-05

### Fixed

- Improved error handling for the `Plots.jl` extension (#653): raises a descriptive
  error instead of a cryptic `MethodError` when `Plots` is not loaded.

### Added

- JuliaCon Paris 2025 documentation page.
- Responsive CSS columns (math vs code) in documentation.

---

## [1.1.3] — 2025-09-25

### Added

- Documentation for AI-assisted problem description generation (`manual-ai-ded.md`).
- Documentation for GPU solving (`manual-solve-gpu.md` update).
- Usage of `MadNLPMumps` in documentation examples.

---

## [1.1.2] — 2025-09-25

### Added

- **Trapeze scheme** support via CTDirect v0.17 (`scheme=:trapeze`).
- **ExaModels v0.9** compat.
- Indirect method examples in documentation.
- Detailed solver options documentation.

### Changed

- Bumped compat for **CTDirect** to `0.17`.
- Bumped compat for **CTParser** to `0.7`.
- Default scheme documented explicitly.

---

## [1.1.1] — 2025-08-06

### Changed

- Bumped compat for **ExaModels** to `0.9`.
- Updated GPU solve documentation.

---

## [1.1.0] — 2025-08-05

### Added

- **`ADNLPModels`** and **`ExaModels`** added as direct dependencies, enabling GPU
  solving via ExaModels backend out of the box.
- GPU solving documentation (`manual-solve-gpu.md`).
- Export of `dual` function.
- Flow with state constraints support (CTFlows update).
- Non-autonomous flow tutorial.
- `display` option for `solve`: shows a compact configuration table before solving.
- MadNLP solver added to the registry and available methods.
- Documentation for the `solve` function arguments (tutorial-solve.md).
- Manual pages for OCP model interaction and solution inspection.
- JLESC17 and JuliaCon 2025 conference documentation.

### Changed

- Bumped compat for **CTBase** to `0.16`.
- Bumped compat for **CTDirect** to `0.16`.
- Bumped compat for **CTModels** to `0.6`.
- Bumped compat for **CTParser** to `0.6`.
- Bumped compat for **ADNLPModels** to `0.8`.
- Bumped compat for **ExaModels** to `0.8`.

---

## [1.0.3] — 2025-05-08

### Changed

- Bumped compat for **CTModels** to `0.3`.
- Bumped compat for **CTBase** to `0.16`.
- Removed tutorials from the documentation (moved to separate repositories).
- Pretty URLs in documentation.

---

## [1.0.2] — 2025-05-05

### Changed

- Renamed `export`/`import` keyword (internal change following CTBase update).
- Bumped compat for **CTBase**.
- Added `Breakage.yml` CI workflow.

---

## [1.0.1] — 2025-05-04

### Added

- Scalar vs dimension-one variable handling improvement (#478).
- Documentation updates: dependency graph, tutorials, README.

### Fixed

- Typo in tutorial (#475, @oameye).

---

## [1.0.0] — 2025-04-18

Initial stable release.

### Dependencies

| Package | Compat |
|---|---|
| CTBase | 0.15 |
| CTDirect | 0.14 |
| CTFlows | 0.8 |
| CTModels | 0.2 |
| CTParser | 0.2 |
| CommonSolve | 0.2 |
| Julia | ≥ 1.10 |

---

## Breaking Changes Summary

This section summarises all breaking changes since v1.0.0 for users upgrading across
multiple versions.

### v1.2.0-beta (current `action-options` branch)

- **`solve` signature change**: `initial_guess` and `display` are no longer positional
  or explicitly named keyword arguments in the top-level `CommonSolve.solve`,
  `solve_descriptive`, and `solve_explicit`. They are now extracted from `kwargs...`.
  Existing call sites using `solve(ocp; initial_guess=x0, display=false)` continue to
  work unchanged — only internal dispatch signatures changed.
- **Alias `:i` removed**: `solve(ocp; i=x0)` now raises `CTBase.IncorrectArgument`.
  Use `init=x0` or `initial_guess=x0` instead.

### v1.1.0

- **CTBase v0.16 required** (from v0.15): users of CTBase directly may need to update.
- **CTModels v0.6 required** (from v0.2–v0.3): significant internal API changes in
  CTModels; users relying on internal CTModels types should review the CTModels changelog.
- **CTParser v0.6 required** (from v0.2): parser API updated.
- **CTDirect v0.16 required** (from v0.14): discretization API updated.
- **`ADNLPModels` and `ExaModels` are now direct dependencies**: they will be installed
  automatically. This should not break existing code but increases installation size.

### v1.0.2

- **`export`/`import` keyword renamed**: if you used `export=...` or `import=...` as
  keyword arguments to any OptimalControl function, rename to the new keyword (see
  CTBase changelog for details).

[2.2.0-beta]: https://github.com/control-toolbox/OptimalControl.jl/compare/v2.1.0-beta...v2.2.0-beta
[2.1.0-beta]: https://github.com/control-toolbox/OptimalControl.jl/compare/v2.0.5-beta...v2.1.0-beta
[2.0.5-beta]: https://github.com/control-toolbox/OptimalControl.jl/compare/v2.0.4...v2.0.5-beta
[2.0.4]: https://github.com/control-toolbox/OptimalControl.jl/compare/v2.0.3...v2.0.4
[2.0.3]: https://github.com/control-toolbox/OptimalControl.jl/compare/v2.0.2...v2.0.3
[2.0.2]: https://github.com/control-toolbox/OptimalControl.jl/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/control-toolbox/OptimalControl.jl/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/control-toolbox/OptimalControl.jl/releases/tag/v2.0.0
[Unreleased]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.8-beta...HEAD
[1.1.8-beta]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.7-beta...v1.1.8-beta
[1.1.7-beta]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.6...v1.1.7-beta
[1.1.6]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.5...v1.1.6
[1.1.5]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.4...v1.1.5
[1.1.4]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.3...v1.1.4
[1.1.3]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.0.3...v1.1.0
[1.0.3]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/control-toolbox/OptimalControl.jl/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/control-toolbox/OptimalControl.jl/releases/tag/v1.0.0
