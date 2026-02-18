# Design of `solve_descriptive`

**Layer**: 2 (Mode-Specific Logic - Descriptive Mode)

## R0 - High-Level Description

`solve_descriptive` solves an optimal control problem using symbolic method descriptions (e.g., `:collocation`, `:adnlp`, `:ipopt`). It:

1. Completes partial descriptions using the available methods registry
2. Builds components from the complete description
3. Handles component options and routing

## R1 - Signature and Delegation

```julia
# ============================================================================
# LAYER 2: Descriptive Mode - NO defaults (all values explicit from Layer 1)
# ============================================================================

function solve_descriptive(
    ocp::AbstractModel,
    initial_guess::AbstractInitialGuess;  # Already normalized by Layer 1
    description::Symbol...,                # Symbolic description (may be partial)
    discretizer::Union{AbstractDiscretizer, Nothing},  # Optional override
    modeler::Union{AbstractNLPModeler, Nothing},       # Optional override
    solver::Union{AbstractNLPSolver, Nothing},         # Optional override
    display::Bool,                                     # NO default
    kwargs...                                          # Component options
)::AbstractSolution
    
    # 1. Complete the description using available methods registry
    complete_description = CTBase.complete(
        description...; 
        descriptions=available_methods()
    )
    
    # 2. Validate and route component options
    _validate_component_options(complete_description, kwargs)
    
    # 3. Build components from complete description
    #    Use provided components as overrides if present
    components = _build_components_from_description(
        complete_description;
        discretizer_override=discretizer,
        modeler_override=modeler,
        solver_override=solver,
        kwargs...
    )
    
    # 4. Call canonical solve with complete components
    return CommonSolve.solve(
        ocp, initial_guess,
        components.discretizer,
        components.modeler,
        components.solver;
        display=display
    )
end
```

### Functions Called (R2 candidates)

- `CTBase.complete(description...; descriptions=available_methods())` - Complete partial description
- `_validate_component_options(complete_description, kwargs)` - Validate option routing
- `_build_components_from_description(...)` - Build components from symbols
- `CommonSolve.solve(ocp, initial_guess, discretizer, modeler, solver; display)` - Canonical solve (Layer 3)

### Responsibilities

1. **Description completion**: Transform partial symbolic description to complete triplet
2. **Option routing**: Route kwargs to appropriate components (discretizer/modeler/solver)
3. **Component construction**: Build concrete components from symbolic description
4. **Override handling**: Allow explicit components to override description-based ones
5. **Canonical solve invocation**: Call Layer 3 with complete components

### Key Design Decisions

- **No defaults**: All parameters are explicit (passed from Layer 1)
- **Registry-based**: Uses `available_methods()` registry for completion
- **Flexible description**: Accepts empty, partial, or complete symbolic descriptions
- **Component overrides**: Explicit components take precedence over description
- **Option validation**: Ensures kwargs are routed to correct components