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
