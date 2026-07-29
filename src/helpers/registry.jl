"""
$(TYPEDSIGNATURES)

Create and return the strategy registry for the solve system.

The registry maps abstract strategy families to their concrete implementations
with their supported parameters:
- `CTSolvers.DOCP.AbstractDiscretizer` → Discretization strategies
- `CTSolvers.Modelers.AbstractNLPModeler` → NLP modeling strategies (with CPU/GPU support)
- `CTSolvers.Solvers.AbstractNLPSolver` → NLP solver strategies (with CPU/GPU support)

Each strategy entry specifies which parameters it supports:
- `CPU`: All strategies support CPU execution
- `GPU`: Only GPU-capable strategies support GPU execution (Exa, MadNLP, MadNCL)

# Returns
- `CTBase.Strategies.StrategyRegistry`: Registry with all available strategies and their parameters

# Examples
```julia
julia> registry = OptimalControl.get_strategy_registry()
StrategyRegistry with 3 families

julia> CTBase.Strategies.strategy_ids(CTSolvers.Modelers.AbstractNLPModeler, registry)
(:adnlp, :exa)

julia> CTBase.Strategies.strategy_ids(CTSolvers.Solvers.AbstractNLPSolver, registry)  
(:ipopt, :madnlp, :uno, :madncl, :knitro)

julia> # Check which parameters a strategy supports
julia> CTBase.Strategies.available_parameters(:modeler, CTSolvers.Modelers.Exa, registry)
(CPU, GPU)

julia> CTBase.Strategies.available_parameters(:solver, CTSolvers.Solvers.Ipopt, registry)
(CPU,)
```

# Notes
- Returns a precomputed registry (allocation-free, type-stable)
- GPU-capable strategies (Exa, MadNLP, MadNCL) support both CPU and GPU parameters
- CPU-only strategies (ADNLP, Ipopt, Uno, Knitro) support only CPU parameter
- Parameterization is handled at the method level in `methods()`
- GPU strategies automatically get appropriate default configurations when parameterized
- Used by solve functions for component completion and strategy building

See also: [`methods`](@ref), [`_complete_components`](@ref), [`solve`](@ref)
"""
function get_strategy_registry()::CTBase.Strategies.StrategyRegistry
    return CTBase.Strategies.create_registry(
        CTSolvers.DOCP.AbstractDiscretizer => (
            CTDirect.Collocation,
            # Add other discretizers as they become available
        ),
        CTSolvers.Modelers.AbstractNLPModeler => (
            (CTSolvers.Modelers.ADNLP, [CTBase.Strategies.CPU]),
            (CTSolvers.Modelers.Exa, [CTBase.Strategies.CPU, CTBase.Strategies.GPU]),
        ),
        CTSolvers.Solvers.AbstractNLPSolver => (
            (CTSolvers.Solvers.Ipopt, [CTBase.Strategies.CPU]),
            (CTSolvers.Solvers.MadNLP, [CTBase.Strategies.CPU, CTBase.Strategies.GPU]),
            (CTSolvers.Solvers.Uno, [CTBase.Strategies.CPU]),
            (CTSolvers.Solvers.MadNCL, [CTBase.Strategies.CPU, CTBase.Strategies.GPU]),
            (CTSolvers.Solvers.Knitro, [CTBase.Strategies.CPU]),
        ),
    )
end
