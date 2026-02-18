# Task 02: Implement `get_strategy_registry()`

## 📋 Task Information

**Priority**: 2  
**Estimated Time**: 45 minutes  
**Layer**: Infrastructure  
**Created**: 2026-02-17

## 🎯 Objective

Implement the `get_strategy_registry()` function that creates and returns the strategy registry mapping abstract families to concrete strategy types.

## 📐 Mandatory Rules

This task MUST follow:
- 🧪 **Testing**: `.windsurf/rules/testing.md`
- 📋 **Architecture**: `.windsurf/rules/architecture.md`
- 📚 **Documentation**: `.windsurf/rules/docstrings.md`
- ⚠️ **Exceptions**: `.windsurf/rules/exceptions.md`

## 📝 Requirements

### Design Specification

Reference: `.reports/solve_explicit.md` - Registry Creation (Layer 1)

### Function Signature

```julia
function get_strategy_registry()::CTSolvers.Strategies.StrategyRegistry
```

### Implementation Details

**File**: `src/solve/helpers/registry.jl`

````julia
"""
$(TYPEDSIGNATURES)

Create and return the strategy registry for the solve system.

The registry maps abstract strategy families to their concrete implementations:
- `CTDirect.AbstractDiscretizer` → Discretization strategies
- `CTSolvers.AbstractNLPModeler` → NLP modeling strategies
- `CTSolvers.AbstractNLPSolver` → NLP solver strategies

# Returns
- `CTSolvers.Strategies.StrategyRegistry`: Registry with all available strategies

# Examples
```julia
julia> registry = get_strategy_registry()
StrategyRegistry with 3 families

julia> CTSolvers.Strategies.strategy_ids(CTDirect.AbstractDiscretizer, registry)
(:collocation,)
```

# See Also
- [`CTSolvers.Strategies.create_registry`](@ref): Creates a strategy registry
- [`CTSolvers.Strategies.StrategyRegistry`](@ref): Registry type
"""
function get_strategy_registry()::CTSolvers.Strategies.StrategyRegistry
    return CTSolvers.Strategies.create_registry(
        CTDirect.AbstractDiscretizer => (
            CTDirect.Collocation,
            # Add other discretizers as they become available
        ),
        CTSolvers.AbstractNLPModeler => (
            CTSolvers.ADNLP,
            CTSolvers.Exa,
        ),
        CTSolvers.AbstractNLPSolver => (
            CTSolvers.Ipopt,
            CTSolvers.MadNLP,
            CTSolvers.Knitro,
        )
    )
end
````

### Tests Required

**File**: `test/suite/solve/test_registry.jl`

```julia
module TestRegistry

using Test
using OptimalControl
using CTSolvers
using CTDirect
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_registry()
    @testset "Strategy Registry Tests" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ================================================================
        # UNIT TESTS
        # ================================================================
        
        @testset "Registry Creation" begin
            registry = OptimalControl.get_strategy_registry()
            @test registry isa CTSolvers.Strategies.StrategyRegistry
        end
        
        @testset "Discretizer Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.Strategies.strategy_ids(CTDirect.AbstractDiscretizer, registry)
            
            @test :collocation in ids
            @test length(ids) >= 1
        end
        
        @testset "Modeler Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.Strategies.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
            
            @test :adnlp in ids
            @test :exa in ids
            @test length(ids) == 2
        end
        
        @testset "Solver Family" begin
            registry = OptimalControl.get_strategy_registry()
            ids = CTSolvers.Strategies.strategy_ids(CTSolvers.AbstractNLPSolver, registry)
            
            @test :ipopt in ids
            @test :madnlp in ids
            @test :knitro in ids
            @test length(ids) == 3
        end
        
        @testset "Determinism" begin
            # Should create equivalent registries
            r1 = OptimalControl.get_strategy_registry()
            r2 = OptimalControl.get_strategy_registry()
            
            # Check same families
            ids1 = CTSolvers.Strategies.strategy_ids(CTSolvers.AbstractNLPSolver, r1)
            ids2 = CTSolvers.Strategies.strategy_ids(CTSolvers.AbstractNLPSolver, r2)
            @test ids1 == ids2
        end
    end
end

end # module

test_registry() = TestRegistry.test_registry()
```

## ✅ Acceptance Criteria

- [ ] File `src/solve/helpers/registry.jl` created
- [ ] Function `get_strategy_registry()` implemented
- [ ] Docstring complete with DocStringExtensions format
- [ ] Test file `test/suite/solve/test_registry.jl` created
- [ ] All unit tests pass
- [ ] All existing project tests still pass
- [ ] Code coverage 100% for new code
- [ ] Registry contains all three families
- [ ] No warnings or errors

## 📦 Deliverables

1. Source file: `src/solve/helpers/registry.jl`
2. Test file: `test/suite/solve/test_registry.jl`
3. All tests passing

## 🔗 Dependencies

**Depends on**: None  
**Required by**: Tasks 04, 06, 07 (functions that use registry)

## 💡 Notes

- Uses `CTSolvers.Strategies.create_registry()`
- Registry is created fresh each time (no caching for now)
- Can be extended later with more strategies
- Important for testability (can create custom registries in tests)

---

## Status Tracking

**Current Status**: TODO  
**Assigned To**: -  
**Started**: -  
**Completed**: -  
**Reviewed**: -

## Review Report
**Reviewed**: 2026-02-17 22:44
**Reviewer**: Cascade
**Status**: ✅ APPROVED

### Verification Results
- [x] Matches design in solve_explicit.md
- [x] Function signature correct
- [x] Docstring complete (DocStringExtensions format)
- [x] Registry contains all three families (discretizer, modeler, solver)
- [x] All project tests pass (11/11 for suite/helpers/test_registry)
- [x] No regressions observed
- [x] Rules compliance (architecture, testing, documentation)

### Strengths
- Clean registry creation using CTSolvers.Strategies.create_registry
- Comprehensive family coverage with concrete strategy mappings
- Tests verify family contents and determinism
- Well-documented with examples and cross-references

### Minor Suggestions (non-blocking)
- None for this task

### Comments
Approved as implemented; registry provides solid foundation for strategy building in downstream tasks.
