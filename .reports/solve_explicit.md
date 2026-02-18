# Design of `solve_explicit`

**Layer**: 2 (Mode-Specific Logic - Explicit Mode)

## R0 - High-Level Description

`solve_explicit` solves an optimal control problem using resolution components explicitly provided by the user. It handles two cases:

1. **Complete components**: All three components (discretizer, modeler, solver) provided → direct resolution
2. **Partial components**: Some components missing → use registry to complete them

## R1 - Signature and Delegation

```julia
# ============================================================================
# LAYER 2: Explicit Mode - NO defaults (all values explicit from Layer 1)
# ============================================================================

function solve_explicit(
    ocp::AbstractModel,
    initial_guess::AbstractInitialGuess;  # Already normalized by Layer 1
    discretizer::Union{AbstractDiscretizer, Nothing},  # NO default
    modeler::Union{AbstractNLPModeler, Nothing},       # NO default
    solver::Union{AbstractNLPSolver, Nothing},         # NO default
    display::Bool,                                     # NO default
    registry::CTSolvers.Strategies.StrategyRegistry    # Passed from Layer 1
)::AbstractSolution
    
    # 1. Check component completeness
    if _has_complete_components(discretizer, modeler, solver)
        # Direct path - all components provided
        return CommonSolve.solve(
            ocp, initial_guess, 
            discretizer, modeler, solver;
            display=display
        )
    else
        # Completion path - use registry to fill missing components
        complete_components = _complete_components(
            discretizer, modeler, solver, registry
        )
        return CommonSolve.solve(
            ocp, initial_guess,
            complete_components.discretizer,
            complete_components.modeler,
            complete_components.solver;
            display=display
        )
    end
end
```

### Functions Called (R2 candidates)

- `_has_complete_components(discretizer, modeler, solver)` - Check if all components provided
- `_complete_components(discretizer, modeler, solver)` - Complete missing components via registry
- `CommonSolve.solve(ocp, initial_guess, discretizer, modeler, solver; display)` - Canonical solve (Layer 3)

### Responsibilities

1. **Component completeness check**: Determine if registry completion needed
2. **Registry delegation**: Use component registry to fill missing pieces
3. **Canonical solve invocation**: Call Layer 3 with complete components

### Key Design Decisions

- **No defaults**: All parameters are explicit (passed from Layer 1)
- **Type flexibility**: Accepts `Union{T, Nothing}` to support partial components
- **Registry-based completion**: Uses existing infrastructure to complete partial specifications
- **Direct bypass**: When all components provided, skips registry entirely (allows custom components)

---

## R2 - Helper Functions Refinement

### `_has_complete_components`

**Objective**: Determine if all three components are provided (not `nothing`).

```julia
# ============================================================================
# R2.1: Component completeness check
# ============================================================================

function _has_complete_components(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)::Bool
    return !isnothing(discretizer) && !isnothing(modeler) && !isnothing(solver)
end
```

**Responsibilities**:
- Pure predicate function
- No side effects
- Returns `true` if all components are concrete, `false` otherwise

**What it needs**: Nothing - pure logic on input parameters

---

### `_complete_components`

**Objective**: Complete missing components using the registry system.

```julia
# ============================================================================
# R2.2: Component completion via registry
# ============================================================================

function _complete_components(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing},
    registry::CTSolvers.Strategies.StrategyRegistry
)::NamedTuple{(:discretizer, :modeler, :solver)}
    
    # 1. Build partial description from provided components
    partial_description = _build_partial_description(discretizer, modeler, solver)
    
    # 2. Complete description using available methods registry
    complete_description = _complete_description(partial_description)
    
    # 3. Build concrete components from complete description
    #    Use provided components as overrides if present
    final_discretizer = _build_or_use_strategy(
        complete_description, discretizer, CTDirect.AbstractDiscretizer, registry
    )
    final_modeler = _build_or_use_strategy(
        complete_description, modeler, CTSolvers.AbstractNLPModeler, registry
    )
    final_solver = _build_or_use_strategy(
        complete_description, solver, CTSolvers.AbstractNLPSolver, registry
    )
    
    return (
        discretizer=final_discretizer,
        modeler=final_modeler,
        solver=final_solver
    )
end
```

**Responsibilities**:
1. Build partial symbolic description from components
2. Complete description via registry
3. Build missing components from complete description
4. Preserve provided components (no override)

**Functions Called (R3 candidates)**:
- `_build_partial_description(discretizer, modeler, solver)` - Extract symbols from components
- `_complete_description(partial_description)` - Use `CTBase.complete()` with registry
- `_build_or_use_strategy(description, provided, family_type, registry)` - Generic build or use provided

**What it needs**:
- Access to `available_methods()` registry (method triplets)
- Access to `CTSolvers.Strategies.StrategyRegistry` (strategy registry)
- Component symbol extraction via `CTSolvers.Strategies.id(Type)`
- Component builders via `CTSolvers.Strategies.build_strategy_from_method()`

---

## R3 - Sub-Helper Functions (Next Level)

### `_build_partial_description`

```julia
function _build_partial_description(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)::Tuple{Vararg{Symbol}}
    symbols = Symbol[]
    
    if !isnothing(discretizer)
        push!(symbols, CTSolvers.Strategies.id(typeof(discretizer)))
    end
    if !isnothing(modeler)
        push!(symbols, CTSolvers.Strategies.id(typeof(modeler)))
    end
    if !isnothing(solver)
        push!(symbols, CTSolvers.Strategies.id(typeof(solver)))
    end
    
    return Tuple(symbols)
end
```

**Needs**: `CTSolvers.Strategies.id(::Type)` - Type-level method that returns strategy symbol

**Note**: All strategies (discretizers, modelers, solvers) now implement the `AbstractStrategy` contract with an `id()` method.

---

### `_complete_description`

```julia
function _complete_description(
    partial_description::Tuple{Vararg{Symbol}}
)::Tuple{Symbol, Symbol, Symbol}
    return CTBase.complete(
        partial_description...; 
        descriptions=available_methods()
    )
end
```

**Needs**: 
- `CTBase.complete()` function
- `available_methods()` registry

---

### `_build_or_use_strategy`

```julia
function _build_or_use_strategy(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    provided::Union{T, Nothing} where T <: CTSolvers.Strategies.AbstractStrategy,
    family_type::Type{T},
    registry::CTSolvers.Strategies.StrategyRegistry
)::T
    if !isnothing(provided)
        return provided
    end
    
    # Build strategy from method tuple using registry and family type
    return CTSolvers.Strategies.build_strategy_from_method(
        complete_description,
        family_type,
        registry
    )
end
```

**Needs**:
- `CTSolvers.Strategies.build_strategy_from_method()` - Builds strategy from method tuple
- `CTSolvers.Strategies.StrategyRegistry` - Registry containing all strategies
- Family abstract type (e.g., `CTDirect.AbstractDiscretizer`)

**Usage Examples**:
```julia
# For discretizer
discretizer = _build_or_use_strategy(
    complete_description, provided_discretizer, 
    CTDirect.AbstractDiscretizer, registry
)

# For modeler
modeler = _build_or_use_strategy(
    complete_description, provided_modeler, 
    CTSolvers.AbstractNLPModeler, registry
)

# For solver
solver = _build_or_use_strategy(
    complete_description, provided_solver, 
    CTSolvers.AbstractNLPSolver, registry
)
```

**Benefits**:
- **DRY**: Single function instead of three nearly identical ones
- **Type-safe**: Parametric type ensures correct return type
- **Extensible**: Works with any `AbstractStrategy` family
- **Maintainable**: Changes only need to be made in one place

---

## Summary of Dependencies

### External Functions Needed (New Strategy Architecture):

1. **Strategy Introspection**:
   - `CTSolvers.Strategies.id(::Type{<:AbstractStrategy})` - Get strategy symbol from type
   - Type-level method, no instantiation needed

2. **Description Completion**:
   - `CTBase.complete(symbols...; descriptions)` - Complete partial description
   - `available_methods()` - Registry of valid method triplets (e.g., `(:collocation, :adnlp, :ipopt)`)

3. **Strategy Registry**:
   - `CTSolvers.Strategies.StrategyRegistry` - Registry mapping families to strategies
   - `CTSolvers.Strategies.build_strategy_from_method(method, family, registry; kwargs...)` - Build strategy from method tuple
   - `CTSolvers.Strategies.extract_id_from_method(method, family, registry)` - Extract ID for a family from method tuple

4. **Strategy Families** (Abstract Types):
   - `CTDirect.AbstractDiscretizer <: AbstractStrategy`
   - `CTSolvers.AbstractNLPModeler <: AbstractStrategy`
   - `CTSolvers.AbstractNLPSolver <: AbstractStrategy`

### Key Architecture Changes:

**Old approach** (deprecated):
- `get_symbol(instance)` - Extract symbol from instance
- `build_X_from_symbol(symbol)` - Build from symbol

**New approach** (current):
- `Strategies.id(Type)` - Type-level symbol extraction
- `Strategies.build_strategy_from_method(method, family, registry)` - Build from method tuple using registry
- All components are strategies implementing the `AbstractStrategy` contract

### No Longer Needed:
- ❌ `_extract_discretizer_symbol()` - Replaced by `extract_id_from_method()`
- ❌ `_extract_modeler_symbol()` - Replaced by `extract_id_from_method()`
- ❌ `_extract_solver_symbol()` - Replaced by `extract_id_from_method()`
- ❌ Individual `build_X_from_symbol()` functions - Replaced by unified `build_strategy_from_method()`

---

## Implementation Plan

### File Organization

```
src/solve/
├── solve_canonical.jl          # Layer 3 - Already implemented ✅
├── solve_explicit.jl           # Layer 2 - To implement
├── solve_descriptive.jl        # Layer 2 - Future
├── solve_orchestration.jl      # Layer 1 - Future
└── helpers/
    ├── available_methods.jl    # Registry of method triplets
    ├── component_checks.jl     # _has_complete_components
    ├── component_completion.jl # _complete_components
    └── strategy_builders.jl    # R3 helpers
```

### Functions to Implement (Priority Order)

#### **Phase 1: Core Infrastructure** (Needed by all)

1. **`available_methods()`** → `src/solve/helpers/available_methods.jl`
   ```julia
   const AVAILABLE_METHODS = (
       (:collocation, :adnlp, :ipopt),
       (:collocation, :adnlp, :madnlp),
       (:collocation, :adnlp, :knitro),
       (:collocation, :exa, :ipopt),
       (:collocation, :exa, :madnlp),
       (:collocation, :exa, :knitro),
   )
   available_methods() = AVAILABLE_METHODS
   ```
   - **Status**: Can copy from `.save/src/solve.jl`
   - **Tests**: Simple verification test

#### **Phase 2: Layer 2 - solve_explicit** (Top-down with mocks)

2. **`solve_explicit()`** → `src/solve/solve_explicit.jl`
   - **Implementation**: R1 signature with routing logic
   - **Tests**: Contract tests with **mock strategies** and **mock `CommonSolve.solve`**
   - **Verification**: Test both branches (complete vs partial components)
   - **Mock approach**:
     ```julia
     # In test file - define at module top-level
     struct MockDiscretizer <: CTDirect.AbstractDiscretizer
         options::CTSolvers.Strategies.StrategyOptions
     end
     CTSolvers.Strategies.id(::Type{<:MockDiscretizer}) = :mock_disc
     
     # Mock the canonical solve to verify routing
     function CommonSolve.solve(
         ocp::MockOCP,
         init::CTModels.AbstractInitialGuess,
         disc::MockDiscretizer,
         mod::MockModeler,
         sol::MockSolver;
         display::Bool
     )
         return MockSolution(:explicit_complete_path)
     end
     ```

#### **Phase 3: R2 Helpers** (Bottom-up, pure functions first)

3. **`_has_complete_components()`** → `src/solve/helpers/component_checks.jl`
   - **Implementation**: Pure predicate (trivial)
   - **Tests**: Unit tests with all combinations
   - **Status**: ✅ Can implement immediately (no dependencies)

4. **`_build_partial_description()`** → `src/solve/helpers/strategy_builders.jl`
   - **Implementation**: Extract symbols using `Strategies.id(typeof(...))`
   - **Tests**: Unit tests with mock strategies
   - **Dependencies**: Mock strategies with `id()` method

5. **`_complete_description()`** → `src/solve/helpers/strategy_builders.jl`
   - **Implementation**: Call `CTBase.complete()` with `available_methods()`
   - **Tests**: Unit tests with partial descriptions
   - **Dependencies**: `available_methods()`, `CTBase.complete()`

6. **`_build_or_use_strategy()`** → `src/solve/helpers/strategy_builders.jl`
   - **Implementation**: Generic builder with registry
   - **Tests**: Unit tests with mock registry
   - **Dependencies**: `CTSolvers.Strategies.build_strategy_from_method()`
   - **Note**: May need to mock `build_strategy_from_method()` initially

7. **`_complete_components()`** → `src/solve/helpers/component_completion.jl`
   - **Implementation**: Orchestrate R3 helpers
   - **Tests**: Integration tests combining R3 helpers
   - **Dependencies**: All R3 helpers above

### Testing Strategy (Top-Down with Mocks)

#### ✅ **Advantages of Top-Down Approach**:

1. **Contract Verification Early**: Test the public API contract immediately
2. **Incremental Refinement**: Replace mocks one by one as we implement
3. **Regression Safety**: Mocks stay in tests to verify routing logic
4. **Clear Interfaces**: Forces us to define clear contracts between layers

#### 📋 **Test Structure**:

```julia
# test/suite/solve/test_explicit.jl
module TestExplicit

using Test
using OptimalControl
using Main.TestOptions: VERBOSE, SHOWTIMING

# ====================================================================
# TOP-LEVEL: Mock Strategies (defined at module level)
# ====================================================================

struct MockDiscretizer <: CTDirect.AbstractDiscretizer
    options::CTSolvers.Strategies.StrategyOptions
end
CTSolvers.Strategies.id(::Type{<:MockDiscretizer}) = :mock_disc

struct MockModeler <: CTSolvers.AbstractNLPModeler
    options::CTSolvers.Strategies.StrategyOptions
end
CTSolvers.Strategies.id(::Type{<:MockModeler}) = :mock_mod

struct MockSolver <: CTSolvers.AbstractNLPSolver
    options::CTSolvers.Strategies.StrategyOptions
end
CTSolvers.Strategies.id(::Type{<:MockSolver}) = :mock_sol

struct MockOCP <: CTModels.AbstractModel end
struct MockSolution <: CTModels.AbstractSolution
    path::Symbol  # Track which path was taken
end

# Mock canonical solve to verify routing
function CommonSolve.solve(
    ocp::MockOCP,
    init::CTModels.AbstractInitialGuess,
    disc::MockDiscretizer,
    mod::MockModeler,
    sol::MockSolver;
    display::Bool
)
    return MockSolution(:complete_path)
end

function test_explicit()
    @testset "solve_explicit Tests" verbose=VERBOSE showtiming=SHOWTIMING begin
        
        # ================================================================
        # UNIT TESTS - Component Checks
        # ================================================================
        
        @testset "_has_complete_components" begin
            # Test all combinations
            @test OptimalControl._has_complete_components(disc, mod, sol) == true
            @test OptimalControl._has_complete_components(nothing, mod, sol) == false
            @test OptimalControl._has_complete_components(disc, nothing, sol) == false
            @test OptimalControl._has_complete_components(disc, mod, nothing) == false
            @test OptimalControl._has_complete_components(nothing, nothing, nothing) == false
        end
        
        # ================================================================
        # CONTRACT TESTS - solve_explicit routing
        # ================================================================
        
        @testset "solve_explicit - Complete Components Path" begin
            ocp = MockOCP()
            init = OptimalControl.build_initial_guess(ocp, nothing)
            disc = MockDiscretizer(...)
            mod = MockModeler(...)
            sol = MockSolver(...)
            
            result = OptimalControl.solve_explicit(
                ocp, init;
                discretizer=disc, modeler=mod, solver=sol,
                display=false
            )
            
            @test result isa MockSolution
            @test result.path == :complete_path
        end
        
        @testset "solve_explicit - Partial Components Path" begin
            # Test with missing components
            # This will use _complete_components
            # Initially will fail until we implement helpers
        end
        
        # ================================================================
        # INTEGRATION TESTS
        # ================================================================
        
        @testset "solve_explicit - Real Strategies" begin
            # Test with actual CTDirect/CTSolvers strategies
            # Add once helpers are implemented
        end
    end
end

end # module

test_explicit() = TestExplicit.test_explicit()
```

### Implementation Order (Recommended)

1. ✅ **Start**: `available_methods()` (trivial, no dependencies)
2. ✅ **Next**: `_has_complete_components()` (pure function, easy to test)
3. ✅ **Then**: `solve_explicit()` with mock tests (verify routing logic)
4. ⚠️ **After**: R3 helpers one by one, replacing mocks progressively
5. 🎯 **Finally**: Integration tests with real strategies

### Design Decision: Registry Parameter

**Decision**: Pass `registry` as an explicit parameter from Layer 1 down to all functions that need it.

**Rationale**:
1. **Testability**: Easy to create test registries with mock strategies
2. **Explicitness**: No hidden dependencies on global state
3. **Thread-safety**: No shared mutable state
4. **Flexibility**: Different registries can be used in different contexts

**Parameter Flow**:
```
Layer 1 (solve orchestration)
  ↓ creates/obtains registry
  ↓ passes to solve_explicit
Layer 2 (solve_explicit)
  ↓ passes to _complete_components
R2 (_complete_components)
  ↓ passes to _build_or_use_strategy (3x)
R3 (_build_or_use_strategy)
  → uses registry with build_strategy_from_method
```

**Registry Creation** (Layer 1):
```julia
# In Layer 1 orchestration (future implementation)
function CommonSolve.solve(
    ocp::AbstractModel,
    description::Symbol...;
    initial_guess=nothing,
    discretizer=nothing,
    modeler=nothing,
    solver=nothing,
    display=__display(),
    kwargs...
)::AbstractSolution
    # Create strategy registry once at top level
    registry = get_strategy_registry()
    
    # Normalize initial guess
    normalized_init = CTModels.build_initial_guess(ocp, initial_guess)
    
    # Route to explicit or descriptive mode
    if _has_explicit_components(discretizer, modeler, solver)
        return solve_explicit(
            ocp, normalized_init;
            discretizer=discretizer,
            modeler=modeler,
            solver=solver,
            display=display,
            registry=registry  # Pass registry down
        )
    else
        return solve_descriptive(
            ocp, normalized_init, description...;
            discretizer=discretizer,
            modeler=modeler,
            solver=solver,
            display=display,
            registry=registry,  # Pass registry down
            kwargs...
        )
    end
end

function get_strategy_registry()::CTSolvers.Strategies.StrategyRegistry
    # Create registry with all available strategies
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
```

### Summary: Complete Function Signatures

**All functions with final signatures including registry parameter:**

```julia
# Layer 2
function solve_explicit(
    ocp::AbstractModel,
    initial_guess::AbstractInitialGuess;
    discretizer::Union{AbstractDiscretizer, Nothing},
    modeler::Union{AbstractNLPModeler, Nothing},
    solver::Union{AbstractNLPSolver, Nothing},
    display::Bool,
    registry::CTSolvers.Strategies.StrategyRegistry
)::AbstractSolution

# R2 - Component checks (no registry needed)
function _has_complete_components(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)::Bool

# R2 - Component completion
function _complete_components(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing},
    registry::CTSolvers.Strategies.StrategyRegistry
)::NamedTuple{(:discretizer, :modeler, :solver)}

# R3 - Build partial description (no registry needed)
function _build_partial_description(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)::Tuple{Vararg{Symbol}}

# R3 - Complete description (no registry needed)
function _complete_description(
    partial_description::Tuple{Vararg{Symbol}}
)::Tuple{Symbol, Symbol, Symbol}

# R3 - Build or use strategy (uses registry)
function _build_or_use_strategy(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    provided::Union{T, Nothing} where T <: CTSolvers.Strategies.AbstractStrategy,
    family_type::Type{T},
    registry::CTSolvers.Strategies.StrategyRegistry
)::T

# Infrastructure - Available methods (no registry needed)
function available_methods()::Tuple{Vararg{Tuple{Symbol, Symbol, Symbol}}}

# Infrastructure - Get strategy registry (creates registry)
function get_strategy_registry()::CTSolvers.Strategies.StrategyRegistry
```

### Next Steps

1. Create `src/solve/helpers/` directory
2. Implement `available_methods.jl`
3. Implement `get_strategy_registry()` in `src/solve/helpers/registry.jl`
4. Implement `_has_complete_components()` in `component_checks.jl`
5. Create test file with mock strategies
6. Implement `solve_explicit()` with contract tests (including registry parameter)
7. Progressively implement and test R3 helpers

### File Organization (Final)

```
src/solve/
├── solve_canonical.jl          # Layer 3 ✅
├── solve_explicit.jl           # Layer 2 (registry parameter)
├── solve_descriptive.jl        # Layer 2 (future, registry parameter)
├── solve_orchestration.jl      # Layer 1 (future, creates registry)
└── helpers/
    ├── registry.jl             # get_strategy_registry()
    ├── available_methods.jl    # available_methods()
    ├── component_checks.jl     # _has_complete_components()
    ├── component_completion.jl # _complete_components(registry)
    └── strategy_builders.jl    # R3 helpers (_build_or_use_strategy(registry))
```

### Key Points

1. **Registry flows from top (Layer 1) to bottom (R3)**
2. **Pure functions don't need registry** (`_has_complete_components`, `_build_partial_description`, `_complete_description`)
3. **Only functions that build strategies need registry** (`_build_or_use_strategy`, `_complete_components`)
4. **Registry created once at Layer 1** via `get_strategy_registry()`
5. **All signatures are now final and consistent**
