"""
$(TYPEDSIGNATURES)

Create and return the strategy registry for the solve system.

The registry maps abstract strategy families to their concrete implementations:
- `CTDirect.AbstractDiscretizer` → Discretization strategies
- `CTSolvers.AbstractNLPModeler` → NLP modeling strategies
- `CTSolvers.AbstractNLPSolver` → NLP solver strategies

# Returns
- `CTSolvers.StrategyRegistry`: Registry with all available strategies

# Examples
```julia
julia> registry = OptimalControl.get_strategy_registry()
StrategyRegistry with 3 families
```
"""
function get_strategy_registry()::CTSolvers.StrategyRegistry
    return CTSolvers.create_registry(
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
            CTSolvers.MadNCL,
            CTSolvers.Knitro,
        )
    )
end
