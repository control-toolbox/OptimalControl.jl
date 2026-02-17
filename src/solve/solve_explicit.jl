using CTBase

"""
$(TYPEDSIGNATURES)

Solve an optimal control problem using explicitly provided resolution components.

This function handles two cases:
1. **Complete components**: All three components provided → direct resolution
2. **Partial components**: Some components missing → use registry to complete them

# Arguments
- `ocp`: The optimal control problem to solve
- `initial_guess`: Normalized initial guess (already processed by Layer 1)
- `discretizer`: Discretization strategy or `nothing`
- `modeler`: NLP modeling strategy or `nothing`
- `solver`: NLP solver strategy or `nothing`
- `display`: Whether to display configuration information
- `registry`: Strategy registry for completing partial components

# Returns
- `CTModels.AbstractSolution`: Solution to the optimal control problem

# Examples
```julia
# Complete components (direct path)
disc = CTDirect.Collocation()
mod = CTSolvers.ADNLP()
sol = CTSolvers.Ipopt()
registry = get_strategy_registry()
solution = solve_explicit(ocp, init;
    discretizer=disc, modeler=mod, solver=sol,
    display=false, registry=registry)
```
"""
function solve_explicit(
    ocp::CTModels.AbstractModel,
    initial_guess::CTModels.AbstractInitialGuess;
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing},
    display::Bool,
    registry::CTSolvers.Strategies.StrategyRegistry
)::CTModels.AbstractSolution

    if _has_complete_components(discretizer, modeler, solver)
        return CommonSolve.solve(
            ocp, initial_guess,
            discretizer, modeler, solver;
            display=display
        )
    end

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

"""
$(TYPEDSIGNATURES)

Placeholder for component completion. Implemented in Task 08.
"""
function _complete_components(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing},
    registry::CTSolvers.Strategies.StrategyRegistry
)::NamedTuple{(:discretizer, :modeler, :solver)}
    throw(CTBase.Exceptions.NotImplemented(
        "Component completion not implemented",
        required_method="_complete_components",
        suggestion="Implement _complete_components (Task 08)",
        context="solve_explicit partial component path"
    ))
end