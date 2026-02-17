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
registry = OptimalControl.get_strategy_registry()
solution = OptimalControl.solve_explicit(ocp, init;
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
