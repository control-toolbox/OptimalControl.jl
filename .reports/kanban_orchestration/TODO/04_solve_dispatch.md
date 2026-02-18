# Task 04: Implement `_solve` dispatch methods

## 📋 Task Information

**Priority**: 4
**Estimated Time**: 45 minutes
**Layer**: 2 (Mode-specific adapters)
**Created**: 2026-02-18

## 🎯 Objective

Implement the two `_solve` dispatch methods:

- `_solve(::ExplicitMode, ...)` — absorbs the logic of `solve_explicit` directly. Receives
  `description::Tuple` (ignored) and extracts typed components from `kwargs` itself via
  `_extract_kwarg`. Handles component completion via registry.
- `_solve(::DescriptiveMode, ...)` — **stub** that raises `CTBase.NotImplemented`. Receives
  `description::Tuple` as a positional argument (to be used when `solve_descriptive` exists).

`CommonSolve.solve` is a **pure orchestrator** — it does not extract components. Each
`_solve` method is self-contained and handles its own needs.

This task also covers the **migration of `solve_explicit`**: the existing public function
is renamed/absorbed, and `test/suite/solve/test_explicit.jl` must be updated.

## 📐 Mandatory Rules

This task MUST follow:
- 🧪 **Testing**: `.windsurf/rules/testing.md`
- 📋 **Architecture**: `.windsurf/rules/architecture.md`
- 📚 **Documentation**: `.windsurf/rules/docstrings.md`
- ⚠️ **Exceptions**: `.windsurf/rules/exceptions.md`

## 📝 Requirements

### Design Specification

Reference: `.reports/solve_orchestration.md` — R2.4 and R2.5

### Function Signatures

**File**: `src/solve/solve_dispatch.jl`

```julia
"""
$(TYPEDSIGNATURES)

Resolve an OCP in explicit mode.

Extracts typed components (`discretizer`, `modeler`, `solver`) from `kwargs` by abstract
type via [`_extract_kwarg`](@ref), then completes missing components via the registry.
The `description` argument is received but ignored (uniform positional signature).

# Arguments
- `ocp`: The optimal control problem to solve
- `description`: Symbolic description tuple — ignored in explicit mode
- `initial_guess`: Normalized initial guess (keyword, processed by Layer 1)
- `display`: Whether to display configuration information
- `registry`: Strategy registry for completing partial components
- `kwargs...`: Contains explicit components (by type) plus any remaining options

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# See Also
- [`_extract_kwarg`](@ref): Type-based extraction from kwargs
- [`_has_complete_components`](@ref): Checks if all three components are provided
- [`_complete_components`](@ref): Completes missing components via registry
- [`ExplicitMode`](@ref): The dispatch sentinel type
"""
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

"""
$(TYPEDSIGNATURES)

Stub for descriptive mode resolution.

Raises [`CTBase.NotImplemented`](@ref) until `solve_descriptive` is implemented.
This stub allows testing the orchestration layer (mode detection, dispatch routing)
before the descriptive mode handler exists.

The `description` tuple will be forwarded to `solve_descriptive` when implemented.

# Throws
- `CTBase.NotImplemented`: Always — descriptive mode is not yet implemented

# See Also
- [`DescriptiveMode`](@ref): The dispatch sentinel type
- [`CommonSolve.solve`](@ref): The entry point that dispatches here
"""
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

### Tests Required

**File**: `test/suite/solve/test_solve_dispatch.jl`

Key invariants to verify:

1. `_solve(::ExplicitMode, ...)` extracts components from `kwargs` by type (not by name)
2. `_solve(::DescriptiveMode, ...)` raises `NotImplemented`
3. Dispatch is correct (right method called for each mode)

The mock types (`MockDiscretizer`, etc.) enable testing extraction by type without real OCP
resolution. The `CommonSolve.solve(::MockOCP, ::MockInit, ...)` override returns `MockSolution`
immediately, making tests fast and isolated.

```julia
module TestSolveDispatch

import Test
import OptimalControl
import CTModels
import CTDirect
import CTSolvers
import CTBase
import CommonSolve

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Mock types for contract testing
# ============================================================================

struct MockOCP <: CTModels.AbstractModel end
struct MockInit <: CTModels.AbstractInitialGuess end
struct MockSolution <: CTModels.AbstractSolution end

struct MockDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.StrategyOptions
end
struct MockModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.StrategyOptions
end
struct MockSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.StrategyOptions
end

# Override Layer 3 solve for mocks — returns MockSolution immediately
CommonSolve.solve(
    ::MockOCP, ::MockInit,
    ::MockDiscretizer, ::MockModeler, ::MockSolver;
    display::Bool
)::MockSolution = MockSolution()

function test_solve_dispatch()
    Test.@testset "Solve Dispatch" verbose=VERBOSE showtiming=SHOWTIMING begin

        ocp      = MockOCP()
        init     = MockInit()
        disc     = MockDiscretizer(CTSolvers.StrategyOptions())
        mod      = MockModeler(CTSolvers.StrategyOptions())
        sol      = MockSolver(CTSolvers.StrategyOptions())
        registry = OptimalControl.get_strategy_registry()

        # ====================================================================
        # CONTRACT TESTS - ExplicitMode: extraction by type from kwargs
        # ====================================================================

        Test.@testset "ExplicitMode - extracts components by type" begin
            # Components passed under standard names
            result = OptimalControl._solve(
                OptimalControl.ExplicitMode(),
                ocp, ();
                initial_guess=init,
                display=false,
                registry=registry,
                discretizer=disc, modeler=mod, solver=sol
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "ExplicitMode - extracts by type, not by name" begin
            # Components passed under non-standard kwarg names
            result = OptimalControl._solve(
                OptimalControl.ExplicitMode(),
                ocp, ();
                initial_guess=init,
                display=false,
                registry=registry,
                my_disc=disc, my_mod=mod, my_sol=sol  # non-standard names!
            )
            Test.@test result isa MockSolution
        end

        Test.@testset "ExplicitMode - description tuple is ignored" begin
            # Non-empty description tuple is ignored in explicit mode
            result = OptimalControl._solve(
                OptimalControl.ExplicitMode(),
                ocp, (:collocation, :adnlp);
                initial_guess=init,
                display=false,
                registry=registry,
                discretizer=disc, modeler=mod, solver=sol
            )
            Test.@test result isa MockSolution
        end

        # ====================================================================
        # CONTRACT TESTS - DescriptiveMode: stub raises NotImplemented
        # ====================================================================

        Test.@testset "DescriptiveMode raises NotImplemented" begin
            Test.@test_throws CTBase.NotImplemented begin
                OptimalControl._solve(
                    OptimalControl.DescriptiveMode(),
                    ocp, (:collocation, :adnlp, :ipopt);
                    initial_guess=init,
                    display=false,
                    registry=registry
                )
            end
        end

        Test.@testset "DescriptiveMode raises NotImplemented (empty description)" begin
            Test.@test_throws CTBase.NotImplemented begin
                OptimalControl._solve(
                    OptimalControl.DescriptiveMode(),
                    ocp, ();
                    initial_guess=init,
                    display=false,
                    registry=registry
                )
            end
        end

        # ====================================================================
        # UNIT TESTS - Dispatch correctness (mode → method)
        # ====================================================================

        Test.@testset "ExplicitMode does NOT raise NotImplemented" begin
            Test.@test_nowarn OptimalControl._solve(
                OptimalControl.ExplicitMode(),
                ocp, ();
                initial_guess=init,
                display=false,
                registry=registry,
                discretizer=disc, modeler=mod, solver=sol
            )
        end

        Test.@testset "DescriptiveMode DOES raise NotImplemented" begin
            Test.@test_throws CTBase.NotImplemented OptimalControl._solve(
                OptimalControl.DescriptiveMode(),
                ocp, ();
                initial_guess=init,
                display=false,
                registry=registry
            )
        end
    end
end

end # module

test_solve_dispatch() = TestSolveDispatch.test_solve_dispatch()
```

**Key advantage of Option C**: The mock override of `CommonSolve.solve(::MockOCP, ...)` at
Layer 3 makes `_solve(::ExplicitMode, ...)` fully testable without a real OCP. The
`"extracts by type, not by name"` test is the critical invariant for `_extract_kwarg`.

## ✅ Acceptance Criteria

- [ ] File `src/solve/solve_dispatch.jl` created
- [ ] `_solve(::ExplicitMode, ...)` has `description::Tuple{Vararg{Symbol}}` as positional arg
- [ ] `_solve(::ExplicitMode, ...)` extracts components from `kwargs` via `_extract_kwarg`
- [ ] `_solve(::ExplicitMode, ...)` has `initial_guess` as **keyword** argument
- [ ] `_solve(::ExplicitMode, ...)` has docstring complete with DocStringExtensions
- [ ] `_solve(::DescriptiveMode, ...)` has `description::Tuple{Vararg{Symbol}}` as positional arg
- [ ] `_solve(::DescriptiveMode, ...)` is a stub raising `CTBase.NotImplemented`
- [ ] `_solve(::DescriptiveMode, ...)` has docstring noting stub lifecycle
- [ ] File included in `src/OptimalControl.jl`
- [ ] `solve_explicit` renamed/removed (see R4 in `solve_orchestration.md`)
- [ ] `test/suite/solve/test_explicit.jl` updated (calls migrated to `_solve(ExplicitMode(), ...)`)
- [ ] Test file `test/suite/solve/test_solve_dispatch.jl` created with mock-based tests
- [ ] Test file wired into test runner
- [ ] `"extracts by type, not by name"` test passes
- [ ] DescriptiveMode raises `NotImplemented`
- [ ] All existing project tests still pass
- [ ] No warnings or errors

## 📦 Deliverables

1. Source file: `src/solve/solve_dispatch.jl`
2. Test file: `test/suite/solve/test_solve_dispatch.jl`
3. All tests passing

## 🔗 Dependencies

**Depends on**: Task 01 (`SolveMode`), Task 02 (`_extract_kwarg`), helpers `_has_complete_components` + `_complete_components` (from `kanban_explicit`)
**Required by**: Task 05 (`CommonSolve.solve`)

## 💡 Notes

- `_solve(::ExplicitMode, ...)` absorbs `solve_explicit` — do NOT call `solve_explicit` from here
- `_solve(::DescriptiveMode, ...)` is intentionally a stub — `NotImplemented` is the correct behavior now
- `_has_complete_components` and `_complete_components` are already implemented (kanban_explicit)
- `description::Tuple{Vararg{Symbol}}` is the Julia type for a vararg tuple of symbols
- `initial_guess` is a **keyword** argument in `_solve` (changed from positional in `solve_explicit`)
- The mock override of `CommonSolve.solve(::MockOCP, ...)` at Layer 3 is the key to fast dispatch tests
- Check `CTBase.NotImplemented` signature in `.windsurf/rules/exceptions.md` before using it
- The `"extracts by type, not by name"` test (`my_disc=disc`) is the critical validation for `_extract_kwarg`

---

## Status Tracking

**Current Status**: TODO
**Created**: 2026-02-18
