# Design of `solve` (Canonical)

**Layer**: 3 (Pure Execution - Fully Specified)

## R0 - High-Level Description

`solve` (canonical) is the lowest-level solve function that performs the actual resolution with fully specified, concrete components. It:

1. Discretizes the optimal control problem
2. Displays the configuration (if requested)
3. Delegates to the discretized problem solver

All inputs are concrete types (no `Union{T, Nothing}`), and all normalization/validation has been done by upper layers.

## R1 - Signature and Delegation

```julia
# ============================================================================
# LAYER 3: Canonical Solve - Fully specified, NO defaults, NO normalization
# ============================================================================

function CommonSolve.solve(
    ocp::AbstractModel,
    initial_guess::AbstractInitialGuess,  # Already normalized by Layer 1
    discretizer::AbstractDiscretizer,     # Concrete type (no Nothing)
    modeler::AbstractNLPModeler,          # Concrete type (no Nothing)
    solver::AbstractNLPSolver;            # Concrete type (no Nothing)
    display::Bool                         # Explicit value (no default)
)::AbstractSolution
    
    # 1. Discretize the optimal control problem
    discrete_problem = CTDirect.discretize(ocp, discretizer)
    
    # 2. Display configuration (compact, user options only)
    if display
        OptimalControl.display_ocp_configuration(
            discretizer, modeler, solver;
            display=true, show_options=true, show_sources=false
        )
    end
    
    # 3. Solve the discretized optimal control problem
    return CommonSolve.solve(
        discrete_problem, initial_guess, modeler, solver; display=display
    )
end
```

### Functions Called (R2 candidates)

- `CTDirect.discretize(ocp, discretizer)` - Discretize the OCP
- `OptimalControl.display_ocp_configuration(...)` - Display configuration
- `CommonSolve.solve(discrete_problem, initial_guess, modeler, solver; display)` - Solve discretized problem (CTDirect layer)

### Responsibilities

1. **Discretization**: Transform continuous OCP to discrete optimization problem
2. **Display**: Show user-friendly configuration information
3. **Delegation**: Call the discretized problem solver (next layer down)

### Key Design Decisions

- **No defaults**: All parameters are explicit (passed from Layer 2)
- **No normalization**: `initial_guess` already normalized by Layer 1
- **Concrete types only**: No `Union{T, Nothing}` - all components are concrete
- **Pure execution**: No branching logic, no registry lookups, no option routing
- **Type stability**: All types are concrete, enabling compiler optimizations
- **Minimal responsibility**: Only discretization and delegation

### Type Guarantees

At this layer, we have strong type guarantees:

- `ocp::AbstractModel` - Valid OCP
- `initial_guess::AbstractInitialGuess` - Normalized and validated
- `discretizer::AbstractDiscretizer` - Concrete discretizer instance
- `modeler::AbstractNLPModeler` - Concrete modeler instance
- `solver::AbstractNLPSolver` - Concrete solver instance
- `display::Bool` - Boolean value (not `nothing`)

No `Union` types, no `nothing` values, no optional parameters.