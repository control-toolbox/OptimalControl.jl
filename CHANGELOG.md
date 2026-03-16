# Changelog

All notable changes to **OptimalControl.jl** are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
