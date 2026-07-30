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

"""
$(TYPEDSIGNATURES)

Return the union of every strategy registry OptimalControl exposes: the solve registry
(discretizers, modelers, NLP solvers) and CTFlows' flow registry (`:di`, `:sciml`).

This is what backs the single-argument [`describe`](@ref), so that one entry point covers both
sides of the library — `describe(:ipopt)` and `describe(:sciml)` alike — instead of asking the
user to know which registry a strategy lives in.

# Returns
- `CTBase.Strategies.StrategyRegistry`: 5 families, `:cpu`/`:gpu` parameters.

# Notes
`Base.merge(a::StrategyRegistry, bs::StrategyRegistry...)` (CTBase ≥ 0.28.8-beta) runs the
same cross-registry checks `create_registry` performs within a single registry — global
strategy-ID uniqueness, parameter-ID/type agreement, and strategy/parameter-ID disjointness —
rather than a raw merge of the two structs' internal `Dict`s, which is what this function did
before that release ([CTBase#517](https://github.com/control-toolbox/CTBase.jl/issues/517)).
The two registries are measurably disjoint (no shared id, no shared family, `:cpu`/`:gpu`
bound to the same types on both sides), which is why the merge succeeds rather than throwing —
asserted in `test/suite/helpers/test_describe.jl`, not assumed silently.

See also: [`get_strategy_registry`](@ref), [`describe`](@ref)
"""
function get_full_strategy_registry()::CTBase.Strategies.StrategyRegistry
    return merge(get_strategy_registry(), CTFlows.Flows.flow_registry())
end
