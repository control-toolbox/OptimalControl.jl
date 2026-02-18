# Design of `solve` (Orchestration)

**Layer**: 1 (Public API - Entry Point)

## R0 - High-Level Description

`solve` is the main entry point that orchestrates optimal control problem resolution by:

- Detecting the resolution mode (explicit vs. descriptive) from `description` and `kwargs`
- Normalizing the initial guess
- Dispatching to `_solve` via a `SolveMode` type, passing `description` as a `Tuple`

**`CommonSolve.solve` is a pure orchestrator** — it does not extract components from
`kwargs`. Each `_solve` method handles its own needs:

- `_solve(::ExplicitMode, ...)` extracts typed components from `kwargs` itself
- `_solve(::DescriptiveMode, ...)` receives `description` as a positional `Tuple` argument

This gives each `_solve` a **clean, self-contained signature** with no unnecessary coupling.

`_solve(::ExplicitMode, ...)` directly absorbs the logic of `solve_explicit`. The existing
`solve_explicit` function is **renamed to `_solve_explicit`** (internal helper) or removed
entirely — its logic lives in `_solve(::ExplicitMode, ...)`.

`_solve(::DescriptiveMode, ...)` is initially a stub that raises `NotImplemented`, to be
replaced when `solve_descriptive` is implemented.

### Impact on existing code

`solve_explicit` is renamed/absorbed. The following must be updated:

- `src/solve/solve_explicit.jl`: rename `solve_explicit` → `_solve_explicit` (or remove)
- `test/suite/solve/test_explicit.jl`: update all calls from `solve_explicit(ocp, init; ...)`
  to `_solve(ExplicitMode(), ocp, (); initial_guess=init, ...)`
- `src/OptimalControl.jl`: remove export of `solve_explicit` if present

## R1 - Signature and Delegation

```julia
# ============================================================================
# LAYER 1: Public API - Handles defaults and normalization
# ============================================================================

function CommonSolve.solve(
    ocp::CTModels.AbstractModel,
    description::Symbol...;
    initial_guess::Union{CTModels.AbstractInitialGuess, Nothing}=nothing,
    display::Bool=__display(),
    kwargs...
)::CTModels.AbstractSolution

    # 1. Detect mode and validate (raises on conflict)
    mode = _explicit_or_descriptive(description, kwargs)

    # 2. Normalize initial guess ONCE at the top level
    normalized_init = CTModels.build_initial_guess(ocp, initial_guess)

    # 3. Get registry for component completion
    registry = get_strategy_registry()

    # 4. Dispatch — description passed as Tuple, kwargs forwarded as-is
    return _solve(
        mode, ocp, description;
        initial_guess=normalized_init,
        display=display,
        registry=registry,
        kwargs...
    )
end
```

### Key Design Decisions

1. **`CommonSolve.solve` is a pure orchestrator**: It does not extract components from
   `kwargs`. Each `_solve` method handles its own needs. Layer 1 stays minimal.

2. **`description` passed as `Tuple` to `_solve`**: `description::Symbol...` is captured as
   a tuple and forwarded positionally. `_solve(::ExplicitMode, ...)` ignores it;
   `_solve(::DescriptiveMode, ...)` uses it.

3. **`SolveMode` dispatch**: Instead of `if/else` branching, a `SolveMode` type is returned
   by `_explicit_or_descriptive` and used for multiple dispatch on `_solve`. This follows the
   Open/Closed Principle — new modes can be added without modifying `solve`.

4. **Validation at detection time**: `_explicit_or_descriptive` raises immediately if the user
   mixes explicit components with a symbolic description.

5. **Registry created once at Layer 1**: Passed down to avoid repeated creation.

6. **`_solve(::ExplicitMode, ...)` absorbs `solve_explicit`**: `solve_explicit` is renamed
   `_solve_explicit` (internal) or removed. Extraction of typed components from `kwargs`
   happens inside `_solve(::ExplicitMode, ...)`.

7. **`_solve(::DescriptiveMode, ...)` is a stub initially**: Raises `NotImplemented` until
   `solve_descriptive` is implemented. This allows testing the orchestration layer first.

### Functions Called (R2 candidates)

- `_explicit_or_descriptive(description, kwargs)` — Detect mode + validate
- `CTModels.build_initial_guess(ocp, initial_guess)` — Normalize initial guess
- `get_strategy_registry()` — Build the strategy registry (already implemented)
- `_solve(mode, ocp, description; initial_guess, display, registry, kwargs...)` — Dispatch

### Responsibilities

1. **Default values**: All user-facing defaults defined here (`display`, `initial_guess`)
2. **Mode detection**: Delegate to `_explicit_or_descriptive`
3. **Normalization**: Convert raw `initial_guess` to `AbstractInitialGuess`
4. **Registry**: Create and pass the strategy registry
5. **Dispatch**: Call `_solve` with the detected mode — nothing more

---

## R2 - Helper Functions

### `SolveMode` types

**Objective**: Carry mode information for dispatch on `_solve`.

```julia
# ============================================================================
# R2.1: Mode types for dispatch
# ============================================================================

abstract type SolveMode end
struct ExplicitMode <: SolveMode end
struct DescriptiveMode <: SolveMode end
```

**Design note on `::Type{ExplicitMode}` vs `::ExplicitMode`**:

Use **instance dispatch** (`::ExplicitMode`, i.e., pass `ExplicitMode()`), not type dispatch
(`::Type{ExplicitMode}`). Reasons:

- Instance dispatch is the idiomatic Julia pattern for tag/sentinel dispatch
- `::Type{T}` dispatch is for functions that operate on types themselves (e.g., constructors,
  `sizeof`, `zero`)
- Cleaner call site: `_solve(ExplicitMode(), ...)` vs `_solve(ExplicitMode, ...)`
- Consistent with how Julia's own dispatch system works (e.g., `Val{:symbol}()`)

---

### `_explicit_or_descriptive`

**Objective**: Detect the resolution mode from the call arguments and validate consistency.

```julia
# ============================================================================
# R2.2: Mode detection and validation
# ============================================================================

function _explicit_or_descriptive(
    description::Tuple{Vararg{Symbol}},
    kwargs::Base.Pairs
)::SolveMode

    # Detect presence of explicit components by type (no extraction — just presence check)
    has_explicit = any(v -> v isa CTDirect.AbstractDiscretizer ||
                            v isa CTSolvers.AbstractNLPModeler  ||
                            v isa CTSolvers.AbstractNLPSolver,
                       values(kwargs))
    has_description = !isempty(description)

    if has_explicit && has_description
        throw(CTBase.IncorrectArgument(
            "Cannot mix explicit components with symbolic description",
            got="explicit components + symbolic description",
            expected="either explicit components OR symbolic description",
            suggestion="Use either solve(ocp; discretizer=..., modeler=..., solver=...) OR solve(ocp, :collocation, :adnlp, :ipopt)",
            context="solve function call"
        ))
    end

    return has_explicit ? ExplicitMode() : DescriptiveMode()
end
```

**Responsibilities**:

- Detect **presence** of explicit components in `kwargs` by type (not by name, not extracting)
- Detect presence of symbolic description
- Raise `CTBase.IncorrectArgument` on conflict
- Return the appropriate `SolveMode` instance

**Note**: `_explicit_or_descriptive` only checks presence — it does not extract values.
Extraction happens in `_solve(::ExplicitMode, ...)` via `_extract_kwarg`.

---

### `_extract_kwarg`

**Objective**: Extract a value of a given abstract type from `kwargs`, or return `nothing`.

```julia
# ============================================================================
# R2.3: Type-based kwarg extraction
# ============================================================================

function _extract_kwarg(
    kwargs::Base.Pairs,
    ::Type{T}
)::Union{T, Nothing} where {T}
    for (_, v) in kwargs
        v isa T && return v
    end
    return nothing
end
```

**Responsibilities**:
- Scan `kwargs` values for a match against abstract type `T`
- Return the first match, or `nothing`
- Pure function, no side effects

---

### `_solve` — Explicit mode

**Objective**: Resolve an OCP using explicit components. Absorbs the logic of `solve_explicit`
directly. Extracts typed components from `kwargs` itself.

```julia
# ============================================================================
# R2.4: _solve dispatch — Explicit mode
# ============================================================================

function _solve(
    ::ExplicitMode,
    ocp::CTModels.AbstractModel,
    description::Tuple{Vararg{Symbol}};  # ignored in explicit mode
    initial_guess::CTModels.AbstractInitialGuess,
    display::Bool,
    registry::CTSolvers.Strategies.StrategyRegistry,
    kwargs...
)::CTModels.AbstractSolution

    # Extract typed components from kwargs (by type, not by name)
    discretizer = _extract_kwarg(kwargs, CTDirect.AbstractDiscretizer)
    modeler     = _extract_kwarg(kwargs, CTSolvers.AbstractNLPModeler)
    solver      = _extract_kwarg(kwargs, CTSolvers.AbstractNLPSolver)

    # Resolve components: use provided ones or complete via registry
    components = if _has_complete_components(discretizer, modeler, solver)
        (discretizer=discretizer, modeler=modeler, solver=solver)
    else
        _complete_components(discretizer, modeler, solver, registry)
    end

    # Single solve call with resolved components
    return CommonSolve.solve(
        ocp, initial_guess,
        components.discretizer,
        components.modeler,
        components.solver;
        display=display
    )
end
```

**Key properties**:

- `description` is received but ignored (uniform positional signature with `DescriptiveMode`)
- Extracts typed components from `kwargs` itself — Layer 1 does not pre-extract
- `initial_guess` is a **keyword** argument (changed from positional in `solve_explicit`)
- Independently testable: `_solve(ExplicitMode(), ocp, (); initial_guess=init, display=false, registry=reg, discretizer=disc, ...)`
- `_has_complete_components` and `_complete_components` reused from `kanban_explicit`

**Migration from `solve_explicit`**:

| Before (`solve_explicit`) | After (`_solve(::ExplicitMode, ...)`) |
|---|---|
| `solve_explicit(ocp, init; disc, mod, sol, display, registry)` | `_solve(ExplicitMode(), ocp, (); initial_guess=init, display=display, registry=reg, discretizer=disc, ...)` |
| `initial_guess` positional | `initial_guess` keyword |
| public function | internal dispatch via `_solve` |

Test calls in `test/suite/solve/test_explicit.jl` must be updated accordingly (see R4).

---

### `_solve` — Descriptive mode

**Objective**: Handle the descriptive mode. Initially a stub (raises `NotImplemented`) until
`solve_descriptive` is implemented.

```julia
# ============================================================================
# R2.5: _solve dispatch — Descriptive mode (STUB)
# ============================================================================

function _solve(
    ::DescriptiveMode,
    ocp::CTModels.AbstractModel,
    description::Tuple{Vararg{Symbol}};
    initial_guess::CTModels.AbstractInitialGuess,
    display::Bool,
    registry::CTSolvers.Strategies.StrategyRegistry,
    kwargs...
)::CTModels.AbstractSolution

    throw(CTBase.NotImplemented(
        "Descriptive mode is not yet implemented",
        suggestion="Use explicit mode: solve(ocp; discretizer=..., modeler=..., solver=...)",
        context="_solve(::DescriptiveMode, ...)"
    ))
end
```

**Lifecycle**:

1. **Now**: Stub that raises `NotImplemented` — allows testing the orchestration layer
   (mode detection, dispatch routing) without `solve_descriptive`
2. **Later**: Replace body with
   `return solve_descriptive(ocp, description; initial_guess=initial_guess, display=display, registry=registry, kwargs...)`
   when `solve_descriptive` is implemented

**Signature note**: `description` is received as `Tuple{Vararg{Symbol}}` (forwarded from
`CommonSolve.solve` where it was `Symbol...`). No `discretizer`/`modeler`/`solver` in
signature — those are only relevant in `ExplicitMode`. The `kwargs...` carries
strategy-specific options.

---

## R3 - Design Alternatives Considered

### Alternative A: Extraction at Layer 1 (rejected)

`CommonSolve.solve` extracts `discretizer`, `modeler`, `solver` from `kwargs` and passes
them explicitly to both `_solve` methods. `_solve(::DescriptiveMode, ...)` receives them as
`nothing`.

**Pros**: `_solve` has a uniform signature with typed kwargs

**Cons**: Layer 1 does work that belongs to Layer 2; `_solve(::DescriptiveMode, ...)` receives
irrelevant `discretizer/modeler/solver=nothing` kwargs; extraction is wasted in descriptive mode

**Decision**: Rejected — Layer 1 should be a pure orchestrator

### Alternative B: Carry `description` in `DescriptiveMode` struct

```julia
struct DescriptiveMode <: SolveMode
    description::Tuple{Vararg{Symbol}}
end
```

**Pros**: `_solve(::DescriptiveMode, ...)` has no positional `description` argument

**Cons**: `SolveMode` becomes stateful; breaks symmetry with `ExplicitMode`; mode type
carries data, which is unusual for dispatch tags

**Decision**: Rejected — keep `SolveMode` as pure tags; pass `description` as positional arg

### Alternative C: `::Type{ExplicitMode}` dispatch

**Pros**: No need to instantiate

**Cons**: Non-idiomatic Julia; `::Type{T}` is for type-level operations

**Decision**: Rejected — use instance dispatch `::ExplicitMode` (i.e., `ExplicitMode()`)

### Alternative D: Two `CommonSolve.solve` methods

```julia
function CommonSolve.solve(ocp, description::Symbol...; initial_guess, display, kwargs...)
function CommonSolve.solve(ocp; initial_guess, display, discretizer, modeler, solver)
```

**Pros**: Pure dispatch, no mode detection

**Cons**: `solve(ocp)` is ambiguous (matches both); second method needs `kwargs...` for
strategy options, which reintroduces the name collision problem

**Decision**: Rejected — use single entry point with `_explicit_or_descriptive`

### Alternative E: Keep explicit kwargs in `solve` signature

```julia
function CommonSolve.solve(
    ocp, description...;
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing}=nothing,
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing}=nothing,
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}=nothing, ...
)
```

**Pros**: Explicit, IDE-friendly

**Cons**: Name collision risk with strategy options; forces all strategies to avoid these
names; less flexible

**Decision**: Rejected — use `kwargs` extraction by type (R2.3) to avoid name collisions

---

## R4 - Migration: `solve_explicit` → `_solve(::ExplicitMode, ...)`

### Files to update

**`src/solve/solve_explicit.jl`**:

- Rename `solve_explicit` → `_solve_explicit` (keep as internal helper), or
- Remove entirely (absorb logic into `_solve(::ExplicitMode, ...)` in `solve_dispatch.jl`)

**`src/solve/solve_dispatch.jl`** (new file):

- Contains `_solve(::ExplicitMode, ...)` and `_solve(::DescriptiveMode, ...)`

**`src/OptimalControl.jl`**:

- Remove `solve_explicit` from exports if present

**`test/suite/solve/test_explicit.jl`**:

- Rename test function and testset from `"solve_explicit ..."` to `"_solve ExplicitMode ..."`
- Update all calls: `solve_explicit(ocp, init; ...)` → `_solve(ExplicitMode(), ocp, (); initial_guess=init, ...)`
- Note: `initial_guess` becomes a keyword argument

### Call site migration example

```julia
# BEFORE
OptimalControl.solve_explicit(
    pb.ocp, init;
    discretizer=CTDirect.Collocation(),
    modeler=CTSolvers.ADNLP(),
    solver=CTSolvers.Ipopt(),
    display=false,
    registry=registry
)

# AFTER
OptimalControl._solve(
    OptimalControl.ExplicitMode(),
    pb.ocp,
    ();  # description tuple (empty for explicit mode)
    initial_guess=init,
    display=false,
    registry=registry,
    discretizer=CTDirect.Collocation(),
    modeler=CTSolvers.ADNLP(),
    solver=CTSolvers.Ipopt()
)
```

---

## Summary

| Layer | Function | Responsibility |
| ----- | -------- | -------------- |
| 1 | `CommonSolve.solve` | Pure orchestrator: defaults, normalization, mode detection, dispatch |
| 1 | `_explicit_or_descriptive` | Mode detection (presence check only) + conflict validation |
| 1 | `_extract_kwarg` | Type-based kwarg extraction (used by `_solve(::ExplicitMode, ...)`) |
| 2 | `_solve(::ExplicitMode, ...)` | Extracts components, completes via registry, calls Layer 3 |
| 2 | `_solve(::DescriptiveMode, ...)` | Stub → `NotImplemented` (until `solve_descriptive` exists) |
| 2 | `solve_descriptive` | Not yet implemented |