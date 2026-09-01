"""
$(TYPEDSIGNATURES)

Complete missing resolution components using the registry.

This function orchestrates the component completion workflow:
- Extract symbols from provided components using `_build_partial_description`
- Complete the method description using `_complete_description`
- Resolve method with parameter information using `CTBase.Orchestration.resolve_method`
- Build or use strategies for each family using `_build_or_use_strategy`

# Arguments
- `discretizer::Union{CTSolvers.DOCP.AbstractDiscretizer, Nothing}`: Discretization strategy or `nothing`
- `modeler::Union{CTSolvers.Modelers.AbstractNLPModeler, Nothing}`: NLP modeling strategy or `nothing`
- `solver::Union{CTSolvers.Solvers.AbstractNLPSolver, Nothing}`: NLP solver strategy or `nothing`
- `registry::CTBase.Strategies.StrategyRegistry`: Strategy registry for building missing components

# Returns
- `NamedTuple{(:discretizer, :modeler, :solver)}`: Complete component triplet

# Examples
```julia
# Complete from scratch
result = OptimalControl._complete_components(nothing, nothing, nothing, registry)
@test result.discretizer isa CTSolvers.DOCP.AbstractDiscretizer
@test result.modeler isa CTSolvers.Modelers.AbstractNLPModeler
@test result.solver isa CTSolvers.Solvers.AbstractNLPSolver

# Partial completion
disc = CTDirect.Collocation()
result = OptimalControl._complete_components(disc, nothing, nothing, registry)
@test result.discretizer === disc
@test result.modeler isa CTSolvers.Modelers.AbstractNLPModeler
@test result.solver isa CTSolvers.Solvers.AbstractNLPSolver
```

# Notes
- Provided components are preserved (returned as-is)
- Missing components are instantiated using the first available strategy from the registry
- Supports both CPU and GPU parameterized strategies
- Used by `solve_explicit` when components are partially specified

See also: [`_build_partial_description`](@ref), [`_complete_description`](@ref), [`_build_or_use_strategy`](@ref), [`get_strategy_registry`](@ref), [`solve_explicit`](@ref)
"""
function _complete_components(
    discretizer::Union{CTSolvers.DOCP.AbstractDiscretizer,Nothing},
    modeler::Union{CTSolvers.Modelers.AbstractNLPModeler,Nothing},
    solver::Union{CTSolvers.Solvers.AbstractNLPSolver,Nothing},
    registry::CTBase.Strategies.StrategyRegistry,
)::NamedTuple{(:discretizer, :modeler, :solver)}

    # Step 1: Extract symbols from provided components
    partial_description = _build_partial_description(discretizer, modeler, solver)

    # Step 2: Complete the method description
    complete_description = _complete_description(partial_description)

    # Step 3: Resolve method with parameter information
    families = _descriptive_families()
    resolved = CTBase.Orchestration.resolve_method(complete_description, families, registry)

    # Step 4: Build or use strategies for each family
    final_discretizer = _build_or_use_strategy(
        resolved, discretizer, :discretizer, families, registry
    )
    final_modeler = _build_or_use_strategy(resolved, modeler, :modeler, families, registry)
    final_solver = _build_or_use_strategy(resolved, solver, :solver, families, registry)

    return (discretizer=final_discretizer, modeler=final_modeler, solver=final_solver)
end
