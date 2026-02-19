# Task 02: Implement `_extract_kwarg`

## 📋 Task Information

**Priority**: 2
**Estimated Time**: 20 minutes
**Layer**: Infrastructure (helper)
**Created**: 2026-02-18

## 🎯 Objective

Implement `_extract_kwarg`, a pure helper that scans `kwargs` for a value matching a given
abstract type and returns it (or `nothing`). This is the foundation of type-based mode
detection — it replaces named-kwarg detection with type-based detection.

## 📐 Mandatory Rules

This task MUST follow:
- 🧪 **Testing**: `.windsurf/rules/testing.md`
- 📋 **Architecture**: `.windsurf/rules/architecture.md`
- 📚 **Documentation**: `.windsurf/rules/docstrings.md`
- ⚠️ **Exceptions**: `.windsurf/rules/exceptions.md`

## 📝 Requirements

### Design Specification

Reference: `.reports/solve_orchestration.md` — R2.3: Type-based kwarg extraction

### Function Signature

**File**: `src/helpers/kwarg_extraction.jl`

````julia
"""
$(TYPEDSIGNATURES)

Extract the first value of abstract type `T` from `kwargs`, or return `nothing`.

This function enables type-based mode detection: explicit resolution components
(discretizer, modeler, solver) are identified by their abstract type rather than
by their keyword name. This avoids name collisions with strategy-specific options
that might share the same keyword names.

# Arguments
- `kwargs`: Keyword arguments from a `solve` call (`Base.Pairs`)
- `T`: Abstract type to search for

# Returns
- `Union{T, Nothing}`: First matching value, or `nothing` if none found

# Examples
```julia
julia> using CTDirect
julia> disc = CTDirect.Collocation()
julia> kw = pairs((; discretizer=disc, print_level=0))
julia> OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
Collocation(...)

julia> OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler)
nothing
```

# See Also
- [`_explicit_or_descriptive`](@ref): Uses this to detect explicit components
- [`_solve(::ExplicitMode, ...)`](@ref): Uses this to extract components for `solve_explicit`
"""
function _extract_kwarg(
    kwargs::Base.Pairs,
    ::Type{T}
)::Union{T, Nothing} where {T}
    for (_, v) in kwargs
        v isa T && return v
    end
    return nothing
end
````

### Tests Required

**File**: `test/suite/helpers/test_kwarg_extraction.jl`

```julia
module TestKwargExtraction

import Test
import OptimalControl
import CTDirect
import CTSolvers

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL: concrete instances for testing
const DISC = CTDirect.Collocation()
const MOD  = CTSolvers.ADNLP()
const SOL  = CTSolvers.Ipopt()

function test_kwarg_extraction()
    Test.@testset "KwargExtraction" verbose=VERBOSE showtiming=SHOWTIMING begin

        # ====================================================================
        # UNIT TESTS - Basic extraction
        # ====================================================================

        Test.@testset "Extracts matching type" begin
            kw = pairs((; discretizer=DISC, print_level=0))
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test result === DISC
        end

        Test.@testset "Returns nothing when absent" begin
            kw = pairs((; print_level=0, max_iter=100))
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test isnothing(result)
        end

        Test.@testset "Returns nothing for empty kwargs" begin
            kw = pairs(NamedTuple())
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer))
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler))
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPSolver))
        end

        # ====================================================================
        # UNIT TESTS - All three component types
        # ====================================================================

        Test.@testset "Extracts all three component types" begin
            kw = pairs((; discretizer=DISC, modeler=MOD, solver=SOL, print_level=0))
            Test.@test OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer) === DISC
            Test.@test OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler) === MOD
            Test.@test OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPSolver) === SOL
        end

        # ====================================================================
        # UNIT TESTS - Name independence (key design property)
        # ====================================================================

        Test.@testset "Name-independent extraction" begin
            # The key is found by TYPE, not by name
            kw = pairs((; my_custom_key=DISC, another_key=42))
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test result === DISC
        end

        Test.@testset "Non-matching types ignored" begin
            kw = pairs((; x=42, y="hello", z=3.14))
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer))
            Test.@test isnothing(OptimalControl._extract_kwarg(kw, CTSolvers.AbstractNLPModeler))
        end

        # ====================================================================
        # UNIT TESTS - Type safety
        # ====================================================================

        Test.@testset "Return type correctness" begin
            kw = pairs((; discretizer=DISC))
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test result isa Union{CTDirect.AbstractDiscretizer, Nothing}
        end

        Test.@testset "Nothing return type" begin
            kw = pairs(NamedTuple())
            result = OptimalControl._extract_kwarg(kw, CTDirect.AbstractDiscretizer)
            Test.@test result isa Nothing
        end
    end
end

end # module

test_kwarg_extraction() = TestKwargExtraction.test_kwarg_extraction()
```

## ✅ Acceptance Criteria

- [ ] File `src/helpers/kwarg_extraction.jl` created
- [ ] Function `_extract_kwarg` implemented with correct signature
- [ ] Docstring complete with DocStringExtensions format and examples
- [ ] File included in `src/OptimalControl.jl`
- [ ] Test file `test/suite/helpers/test_kwarg_extraction.jl` created
- [ ] Test file wired into test runner
- [ ] All unit tests pass (including name-independence test)
- [ ] All existing project tests still pass
- [ ] No warnings or errors

## 📦 Deliverables

1. Source file: `src/helpers/kwarg_extraction.jl`
2. Test file: `test/suite/helpers/test_kwarg_extraction.jl`
3. All tests passing

## 🔗 Dependencies

**Depends on**: None (pure utility, no type dependencies beyond `Base.Pairs`)
**Required by**: Tasks 03, 04 (`_explicit_or_descriptive`, `_solve(::ExplicitMode, ...)`)

## 💡 Notes

- This is a pure function — no side effects, no state
- The name-independence test is critical: it validates the core design insight
- `Base.Pairs` is the type of `kwargs` in Julia — verify with `typeof(kwargs)` if unsure
- The `where {T}` parametric form ensures type-stable return `Union{T, Nothing}`
- Do NOT add a fallback for multiple matches — first match is sufficient per design

---

## Status Tracking

**Current Status**: REVIEW
**Started**: 2026-02-19
**Completed**: 2026-02-19
**Developer**: Cascade

---

## 📋 Completion Report

### ✅ Implementation Summary

**Files Created**:
- `src/helpers/kwarg_extraction.jl` - `_extract_kwarg` function for type-based kwarg extraction
- `test/suite/helpers/test_kwarg_extraction.jl` - Comprehensive tests with mocks

**Integration**:
- Added `include("helpers/kwarg_extraction.jl")` in `src/OptimalControl.jl`
- Test file automatically discovered by test runner

### ✅ Testing Results

**New Tests**: 13/13 passed
- Basic extraction tests
- All three component types (discretizer, modeler, solver)
- Name-independent extraction (key design property)
- Type safety validation
- Empty kwargs handling

**Regression Tests**: All existing tests pass (691/691)

### ✅ Quality Checks

**Architecture**:
- ✅ Pure function with no side effects
- ✅ Type-stable return `Union{T, Nothing}`
- ✅ First-match sufficient per design
- ✅ Name-independent detection by type, not by name

**Documentation**:
- ✅ Complete docstring with DocStringExtensions
- ✅ Usage examples
- ✅ Cross-references to related functions

**Code Quality**:
- ✅ No warnings or errors
- ✅ Mock-based tests avoid external dependencies
- ✅ Consistent import pattern with other test files

### ✅ Acceptance Criteria Verification

- [x] File `src/helpers/kwarg_extraction.jl` created
- [x] Function `_extract_kwarg` implemented with correct signature
- [x] Docstring complete with DocStringExtensions format and examples
- [x] File included in `src/OptimalControl.jl`
- [x] Test file `test/suite/helpers/test_kwarg_extraction.jl` created
- [x] Test file wired into test runner
- [x] All unit tests pass (13/13)
- [x] Name-independence test passes (critical design property)
- [x] All existing project tests still pass (691/691)
- [x] No warnings or errors

### 🎯 Ready for Review

This task implements the core type-based kwarg extraction mechanism that enables
name-independent component detection. The critical "name-independent extraction" test
validates the fundamental design insight. All tests pass and the implementation
matches the specification in `.reports/solve_orchestration.md`. Ready for reviewer validation.
