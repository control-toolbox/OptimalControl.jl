"""
$(TYPEDSIGNATURES)

Create and return the strategy registry for the solve system.

The registry maps abstract strategy families to their concrete implementations
with their supported parameters:
- `CTDirect.AbstractDiscretizer` → Discretization strategies
- `CTSolvers.AbstractNLPModeler` → NLP modeling strategies (with CPU/GPU support)
- `CTSolvers.AbstractNLPSolver` → NLP solver strategies (with CPU/GPU support)

Each strategy entry specifies which parameters it supports:
- `CPU`: All strategies support CPU execution
- `GPU`: Only GPU-capable strategies support GPU execution (Exa, MadNLP, MadNCL)

# Returns
- `CTSolvers.StrategyRegistry`: Registry with all available strategies and their parameters

# Examples
```julia
julia> registry = OptimalControl.get_strategy_registry()
StrategyRegistry with 3 families

julia> CTSolvers.strategy_ids(CTSolvers.AbstractNLPModeler, registry)
(:adnlp, :exa)

julia> CTSolvers.strategy_ids(CTSolvers.AbstractNLPSolver, registry)  
(:ipopt, :madnlp, :madncl, :knitro)

julia> # Check which parameters a strategy supports
julia> CTSolvers.available_parameters(:modeler, CTSolvers.Exa, registry)
(CPU, GPU)

julia> CTSolvers.available_parameters(:solver, CTSolvers.Ipopt, registry)
(CPU,)
```

# Notes
- Returns a precomputed registry (allocation-free, type-stable)
- GPU-capable strategies (Exa, MadNLP, MadNCL) support both CPU and GPU parameters
- CPU-only strategies (ADNLP, Ipopt, Knitro) support only CPU parameter
- Parameterization is handled at the method level in `methods()`
- GPU strategies automatically get appropriate default configurations when parameterized
- Used by solve functions for component completion and strategy building

See also: [`methods`](@ref), [`_complete_components`](@ref), [`solve`](@ref)
"""
function get_strategy_registry()::CTSolvers.StrategyRegistry
    return CTSolvers.create_registry(
        CTDirect.AbstractDiscretizer => (
            CTDirect.Collocation,
            # Add other discretizers as they become available
        ),
        CTSolvers.AbstractNLPModeler => (
            (CTSolvers.ADNLP, [CTSolvers.CPU]),
            (CTSolvers.Exa, [CTSolvers.CPU, CTSolvers.GPU])
        ),
        CTSolvers.AbstractNLPSolver => (
            (CTSolvers.Ipopt, [CTSolvers.CPU]),
            (CTSolvers.MadNLP, [CTSolvers.CPU, CTSolvers.GPU]),
            (CTSolvers.MadNCL, [CTSolvers.CPU, CTSolvers.GPU]),
            (CTSolvers.Knitro, [CTSolvers.CPU]),
        ),
    )
end
