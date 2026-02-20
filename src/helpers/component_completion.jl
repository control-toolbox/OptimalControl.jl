"""
$(TYPEDSIGNATURES)

Complete missing resolution components using the registry and R3 helpers.

This function orchestrates the component completion workflow:
1. Extract symbols from provided components using `_build_partial_description()`
2. Complete the method description using `_complete_description()`
3. Build or use strategies for each family using `_build_or_use_strategy()`

# Arguments
- `discretizer`: Discretization strategy or `nothing`
- `modeler`: NLP modeling strategy or `nothing`
- `solver`: NLP solver strategy or `nothing`
- `registry`: Strategy registry for building missing components

# Returns
- `NamedTuple{(:discretizer, :modeler, :solver)}`: Complete component triplet

# Examples
```julia
# Complete from scratch
result = OptimalControl._complete_components(nothing, nothing, nothing, registry)
@test result.discretizer isa CTDirect.AbstractDiscretizer
@test result.modeler isa CTSolvers.AbstractNLPModeler
@test result.solver isa CTSolvers.AbstractNLPSolver

# Partial completion
disc = CTDirect.Collocation()
result = OptimalControl._complete_components(disc, nothing, nothing, registry)
@test result.discretizer === disc
@test result.modeler isa CTSolvers.AbstractNLPModeler
@test result.solver isa CTSolvers.AbstractNLPSolver
```

# See Also
- [`_build_partial_description`](@ref): Extracts symbols from provided components
- [`_complete_description`](@ref): Completes method description via CTBase
- [`_build_or_use_strategy`](@ref): Builds or uses strategy instances
- [`get_strategy_registry`](@ref): Creates the strategy registry
"""
function _complete_components(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing},
    registry::CTSolvers.StrategyRegistry
)::NamedTuple{(:discretizer, :modeler, :solver)}

    # Step 1: Extract symbols from provided components
    partial_description = _build_partial_description(discretizer, modeler, solver)
    
    # Step 2: Complete the method description
    complete_description = _complete_description(partial_description)
    
    # Step 3: Build or use strategies for each family
    final_discretizer = _build_or_use_strategy(
        complete_description, discretizer, CTDirect.AbstractDiscretizer, registry
    )
    final_modeler = _build_or_use_strategy(
        complete_description, modeler, CTSolvers.AbstractNLPModeler, registry
    )
    final_solver = _build_or_use_strategy(
        complete_description, solver, CTSolvers.AbstractNLPSolver, registry
    )
    
    return (discretizer=final_discretizer, modeler=final_modeler, solver=final_solver)
end
