# Task 05: Implement `CommonSolve.solve` (Orchestration Entry Point)

## 📋 Task Information

**Priority**: 5
**Estimated Time**: 60 minutes
**Layer**: 1 (Public API - Entry Point)
**Created**: 2026-02-18

## 🎯 Objective

Implement the main `CommonSolve.solve` entry point that orchestrates resolution by:
1. Detecting the mode via `_explicit_or_descriptive` (raises on conflict)
2. Normalizing the initial guess
3. Creating the registry
4. Dispatching to `_solve(mode, ocp, description; initial_guess=..., display=..., registry=..., kwargs...)` via `SolveMode`

**`CommonSolve.solve` is a pure orchestrator** — it does NOT extract components from
`kwargs`. Each `_solve` method handles its own needs:

- `_solve(::ExplicitMode, ...)` extracts typed components from `kwargs` itself
- `_solve(::DescriptiveMode, ...)` uses `description` directly

`description` is forwarded as a `Tuple` (positional argument to `_solve`).

Check the current state of `src/solve/solve.jl` before implementing.

## 📐 Mandatory Rules

This task MUST follow:
- 🧪 **Testing**: `.windsurf/rules/testing.md`
- 📋 **Architecture**: `.windsurf/rules/architecture.md`
- 📚 **Documentation**: `.windsurf/rules/docstrings.md`
- ⚠️ **Exceptions**: `.windsurf/rules/exceptions.md`

## 📝 Requirements

### Design Specification

Reference: `.reports/solve_orchestration.md` — R1: Signature and Delegation

### Function Signature

**File**: `src/solve/solve.jl` (check if it exists; modify or create as needed)

````julia
"""
$(TYPEDSIGNATURES)

Solve an optimal control problem.

This is the main entry point for optimal control problem resolution. It supports
two resolution modes:

- **Explicit mode**: Provide resolution components directly as keyword arguments.
  Components are identified by their abstract type, not their keyword name:
  - A value of type `CTDirect.AbstractDiscretizer` → discretizer
  - A value of type `CTSolvers.AbstractNLPModeler` → modeler
  - A value of type `CTSolvers.AbstractNLPSolver` → solver

- **Descriptive mode**: Provide a symbolic description as positional arguments
  (e.g., `:collocation, :adnlp, :ipopt`). Strategy-specific options can be
  passed as keyword arguments. Currently raises `NotImplemented`.

The two modes cannot be mixed: providing both explicit components and a symbolic
description raises an error.

# Arguments
- `ocp`: The optimal control problem to solve
- `description`: Optional symbolic description tokens (e.g., `:collocation, :adnlp, :ipopt`)
- `initial_guess`: Initial guess for the solution (normalized internally)
- `display`: Whether to display resolution configuration (default: `__display()`)
- `kwargs...`: Explicit components (by type) and/or strategy-specific options

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# Throws
- `CTBase.IncorrectArgument`: If explicit components and symbolic description are mixed
- `CTBase.NotImplemented`: If descriptive mode is used (not yet implemented)

# Examples
```julia
# Explicit mode - all components
sol = solve(ocp;
    discretizer=CTDirect.Collocation(grid_size=100),
    modeler=CTSolvers.ADNLP(),
    solver=CTSolvers.Ipopt(print_level=5))

# Explicit mode - partial (registry completes missing)
sol = solve(ocp; discretizer=CTDirect.Collocation(grid_size=100))

# Default mode (no description, no components) — uses registry defaults
sol = solve(ocp)
```

# See Also
- [`_explicit_or_descriptive`](@ref): Mode detection
- [`_solve(::ExplicitMode, ...)`](@ref): Explicit mode handler (Layer 2)
- [`_solve(::DescriptiveMode, ...)`](@ref): Descriptive mode stub (Layer 2)
"""
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

    # 4. Dispatch — description forwarded as Tuple, kwargs forwarded as-is
    #    Each _solve method handles its own needs (no extraction here)
    return _solve(
        mode, ocp, description;
        initial_guess=normalized_init,
        display=display,
        registry=registry,
        kwargs...
    )
end
````

### Tests Required

**File**: `test/suite/solve/test_orchestration.jl`

The testing strategy focuses on **the orchestration layer** — not resolution quality.
Key invariants:

1. **Mode detection** routes correctly
2. **Conflict detection** raises `CTBase.IncorrectArgument`
3. **`description` forwarded** correctly to `_solve` (DescriptiveMode stub confirms it)
4. **`initial_guess` normalization** works for both `nothing` and `AbstractInitialGuess`

Note: the name-independence test (`my_custom_disc=disc`) belongs to `test_solve_dispatch.jl`
(Task 04) since it tests `_extract_kwarg` inside `_solve(::ExplicitMode, ...)`, not Layer 1.

```julia
module TestOrchestration

import Test
import OptimalControl
import CTModels
import CTDirect
import CTSolvers
import CTBase
import CommonSolve

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_orchestration()
    Test.@testset "Orchestration - CommonSolve.solve" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Mode detection (via helpers)
        # ====================================================================

        Test.@testset "ExplicitMode detection" begin
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            kw   = pairs((; discretizer=disc))
            Test.@test OptimalControl._explicit_or_descriptive((), kw) isa OptimalControl.ExplicitMode
        end

        Test.@testset "DescriptiveMode detection" begin
            kw = pairs(NamedTuple())
            Test.@test OptimalControl._explicit_or_descriptive((:collocation,), kw) isa OptimalControl.DescriptiveMode
        end

        # ====================================================================
        # UNIT TESTS - Conflict validation
        # ====================================================================

        Test.@testset "Conflict: explicit + description raises IncorrectArgument" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)

            Test.@test_throws CTBase.IncorrectArgument begin
                CommonSolve.solve(pb.ocp, :adnlp, :ipopt; discretizer=disc, display=false)
            end
        end

        # ====================================================================
        # CONTRACT TESTS - ExplicitMode path
        # ====================================================================

        Test.@testset "ExplicitMode - complete components" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)
            mod  = CTSolvers.ADNLP()
            sol  = CTSolvers.Ipopt(print_level=0, max_iter=0)

            result = CommonSolve.solve(pb.ocp;
                initial_guess=pb.init,
                discretizer=disc, modeler=mod, solver=sol,
                display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "ExplicitMode - partial components (registry completes)" begin
            pb   = TestProblems.Beam()
            disc = CTDirect.Collocation(grid_size=10, scheme=:midpoint)

            result = CommonSolve.solve(pb.ocp;
                initial_guess=pb.init, discretizer=disc, display=false
            )
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "ExplicitMode - no components (registry provides all)" begin
            pb = TestProblems.Beam()
            result = CommonSolve.solve(pb.ocp; initial_guess=pb.init, display=false)
            Test.@test result isa CTModels.AbstractSolution
        end

        # ====================================================================
        # CONTRACT TESTS - DescriptiveMode path (stub)
        # ====================================================================

        Test.@testset "DescriptiveMode raises NotImplemented" begin
            pb = TestProblems.Beam()

            Test.@test_throws CTBase.NotImplemented begin
                CommonSolve.solve(pb.ocp, :collocation, :adnlp, :ipopt;
                    initial_guess=pb.init, display=false
                )
            end
        end

        # ====================================================================
        # UNIT TESTS - initial_guess normalization
        # ====================================================================

        Test.@testset "initial_guess=nothing is accepted" begin
            pb = TestProblems.Beam()
            result = CommonSolve.solve(pb.ocp; initial_guess=nothing, display=false)
            Test.@test result isa CTModels.AbstractSolution
        end

        Test.@testset "initial_guess as AbstractInitialGuess is accepted" begin
            pb   = TestProblems.Beam()
            init = CTModels.build_initial_guess(pb.ocp, pb.init)
            result = CommonSolve.solve(pb.ocp; initial_guess=init, display=false)
            Test.@test result isa CTModels.AbstractSolution
        end
    end
end

end # module

test_orchestration() = TestOrchestration.test_orchestration()
```

**Note on DescriptiveMode**: The `NotImplemented` test is intentional — it verifies the stub
is in place and that `description` is correctly forwarded to `_solve(::DescriptiveMode, ...)`.
When `solve_descriptive` is implemented, this test will be updated.

## ✅ Acceptance Criteria

- [ ] `CommonSolve.solve` implemented with correct signature in `src/solve/solve.jl`
- [ ] Docstring complete with DocStringExtensions format, examples, `@throws`
- [ ] Mode detection via `_explicit_or_descriptive` (not inline `if/else`)
- [ ] Initial guess normalized via `CTModels.build_initial_guess`
- [ ] Registry created via `get_strategy_registry`
- [ ] Dispatch via `_solve(mode, ocp, description; initial_guess=..., display=..., registry=..., kwargs...)`
- [ ] **No extraction** in `CommonSolve.solve` (pure orchestrator)
- [ ] Test file `test/suite/solve/test_orchestration.jl` created
- [ ] Test file wired into test runner
- [ ] Conflict test passes (explicit + description → `IncorrectArgument`)
- [ ] ExplicitMode path test passes (complete + partial + no components)
- [ ] DescriptiveMode path test passes (raises `NotImplemented`)
- [ ] `initial_guess=nothing` test passes
- [ ] All existing project tests still pass
- [ ] No warnings or errors

## 📦 Deliverables

1. Source file: `src/solve/solve.jl` (modified or created)
2. Test file: `test/suite/solve/test_orchestration.jl`
3. All tests passing

## 🔗 Dependencies

**Depends on**: Tasks 01, 02, 03, 04 (all helpers), existing `solve_explicit`
**Required by**: Task 06 (integration tests)

## 💡 Notes

- Check the current `src/solve/solve.jl` — it may already have a `CommonSolve.solve`
  implementation that needs to be replaced or refactored
- `__display()` is an existing helper — verify its location before using
- `TestProblems.Beam()` is used in `test_explicit.jl` — reuse the same pattern
- `initial_guess` is a **keyword** argument in `CommonSolve.solve` (with default `nothing`)
- `description` is forwarded as a `Tuple` to `_solve` (Julia captures `Symbol...` as a tuple)
- The name-independence test belongs to Task 04 (`test_solve_dispatch.jl`), not here
- The DescriptiveMode `NotImplemented` test is **intentional** — it validates stub + forwarding
- `kwargs...` is forwarded to `_solve` as-is — `_solve(::ExplicitMode, ...)` will extract from it

---

## Status Tracking

**Current Status**: DOING
**Started**: 2026-02-19
**Developer**: Cascade
