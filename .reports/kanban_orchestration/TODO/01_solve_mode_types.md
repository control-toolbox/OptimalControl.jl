# Task 01: Implement `SolveMode` Types

## 📋 Task Information

**Priority**: 1 (First task - no dependencies)
**Estimated Time**: 20 minutes
**Layer**: Infrastructure (types)
**Created**: 2026-02-18

## 🎯 Objective

Define the `SolveMode` abstract type and its two concrete subtypes `ExplicitMode` and
`DescriptiveMode`. These are sentinel types used for multiple dispatch on `_solve`.

## 📐 Mandatory Rules

This task MUST follow:
- 🧪 **Testing**: `.windsurf/rules/testing.md`
- 📋 **Architecture**: `.windsurf/rules/architecture.md`
- 📚 **Documentation**: `.windsurf/rules/docstrings.md`
- ⚠️ **Exceptions**: `.windsurf/rules/exceptions.md`

## 📝 Requirements

### Design Specification

Reference: `.reports/solve_orchestration.md` — R2.1: Mode types for dispatch

### Type Definitions

**File**: `src/solve/solve_mode.jl`

```julia
"""
Abstract supertype for solve mode sentinel types.

Concrete subtypes are used for multiple dispatch on `_solve` to route
resolution to the appropriate mode handler without `if/else` branching.

# Subtypes
- [`ExplicitMode`](@ref): User provided explicit components (discretizer, modeler, solver)
- [`DescriptiveMode`](@ref): User provided symbolic description (e.g., `:collocation, :adnlp, :ipopt`)

# See Also
- [`_explicit_or_descriptive`](@ref): Returns the appropriate mode instance
- [`_solve`](@ref): Dispatches on mode
"""
abstract type SolveMode end

"""
Sentinel type indicating that the user provided explicit resolution components.

An instance `ExplicitMode()` is passed to `_solve` when at least one of
`discretizer`, `modeler`, or `solver` is present in `kwargs` with the
correct abstract type.

# See Also
- [`DescriptiveMode`](@ref): The alternative mode
- [`_explicit_or_descriptive`](@ref): Mode detection logic
- [`_solve(::ExplicitMode, ...)`](@ref): Handler for this mode
"""
struct ExplicitMode <: SolveMode end

"""
Sentinel type indicating that the user provided a symbolic description.

An instance `DescriptiveMode()` is passed to `_solve` when no explicit
components are found in `kwargs`. The symbolic description (e.g.,
`:collocation, :adnlp, :ipopt`) is forwarded via `kwargs`.

# See Also
- [`ExplicitMode`](@ref): The alternative mode
- [`_explicit_or_descriptive`](@ref): Mode detection logic
- [`_solve(::DescriptiveMode, ...)`](@ref): Handler for this mode
"""
struct DescriptiveMode <: SolveMode end
```

### Design Note: Instance vs. Type Dispatch

Use **instance dispatch** (`::ExplicitMode`, pass `ExplicitMode()`), NOT type dispatch
(`::Type{ExplicitMode}`). This is the idiomatic Julia pattern for sentinel/tag dispatch
(analogous to `Val{:symbol}()`). `::Type{T}` is reserved for functions that operate on
types themselves (constructors, `sizeof`, `zero`, etc.).

### Tests Required

**File**: `test/suite/solve/test_solve_mode.jl`

```julia
module TestSolveMode

import Test
import OptimalControl

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_solve_mode()
    Test.@testset "SolveMode Types" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Type hierarchy
        # ====================================================================

        Test.@testset "Type hierarchy" begin
            Test.@test OptimalControl.ExplicitMode <: OptimalControl.SolveMode
            Test.@test OptimalControl.DescriptiveMode <: OptimalControl.SolveMode
            Test.@test OptimalControl.SolveMode isa DataType
            Test.@test isabstracttype(OptimalControl.SolveMode)
            Test.@test !isabstracttype(OptimalControl.ExplicitMode)
            Test.@test !isabstracttype(OptimalControl.DescriptiveMode)
        end

        # ====================================================================
        # UNIT TESTS - Instantiation
        # ====================================================================

        Test.@testset "Instantiation" begin
            em = OptimalControl.ExplicitMode()
            dm = OptimalControl.DescriptiveMode()
            Test.@test em isa OptimalControl.ExplicitMode
            Test.@test em isa OptimalControl.SolveMode
            Test.@test dm isa OptimalControl.DescriptiveMode
            Test.@test dm isa OptimalControl.SolveMode
        end

        # ====================================================================
        # UNIT TESTS - Dispatch
        # ====================================================================

        Test.@testset "Multiple dispatch" begin
            # Verify dispatch works correctly on instances
            function _mode_name(::OptimalControl.ExplicitMode)
                return :explicit
            end
            function _mode_name(::OptimalControl.DescriptiveMode)
                return :descriptive
            end

            Test.@test _mode_name(OptimalControl.ExplicitMode()) == :explicit
            Test.@test _mode_name(OptimalControl.DescriptiveMode()) == :descriptive
        end

        # ====================================================================
        # UNIT TESTS - Distinctness
        # ====================================================================

        Test.@testset "Distinctness" begin
            Test.@test OptimalControl.ExplicitMode != OptimalControl.DescriptiveMode
            Test.@test !(OptimalControl.ExplicitMode() isa OptimalControl.DescriptiveMode)
            Test.@test !(OptimalControl.DescriptiveMode() isa OptimalControl.ExplicitMode)
        end
    end
end

end # module

test_solve_mode() = TestSolveMode.test_solve_mode()
```

### Integration into `OptimalControl.jl`

The file `src/solve/solve_mode.jl` must be included and the types exported:

```julia
# In src/OptimalControl.jl (or appropriate include file):
include("solve/solve_mode.jl")

# Exports (internal types, may not need public export — check convention):
# SolveMode, ExplicitMode, DescriptiveMode are internal but accessible as
# OptimalControl.ExplicitMode for tests
```

Check existing `src/OptimalControl.jl` to determine the correct include location and
whether these types should be exported publicly.

## ✅ Acceptance Criteria

- [ ] File `src/solve/solve_mode.jl` created
- [ ] `SolveMode` abstract type defined with docstring
- [ ] `ExplicitMode` struct defined with docstring
- [ ] `DescriptiveMode` struct defined with docstring
- [ ] File included in `src/OptimalControl.jl`
- [ ] Test file `test/suite/solve/test_solve_mode.jl` created
- [ ] Test file wired into test runner
- [ ] All unit tests pass
- [ ] All existing project tests still pass
- [ ] No warnings or errors

## 📦 Deliverables

1. Source file: `src/solve/solve_mode.jl`
2. Test file: `test/suite/solve/test_solve_mode.jl`
3. All tests passing

## 🔗 Dependencies

**Depends on**: None (first task)
**Required by**: Tasks 03, 04, 05 (all use `SolveMode`)

## 💡 Notes

- These are pure sentinel types — no fields, no methods beyond dispatch
- Keep docstrings focused on the dispatch role
- Check `src/solve/` directory structure before creating the file
- The `ExplicitMode`/`DescriptiveMode` naming is final per design spec

---

## Status Tracking

**Current Status**: TODO
**Created**: 2026-02-18
