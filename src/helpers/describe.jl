"""
$(TYPEDSIGNATURES)

Display detailed information about a strategy identified by its symbol.

This is a convenience wrapper around `CTSolvers.describe` that uses OptimalControl's
strategy registry. It shows the strategy's available options, their types, defaults,
and descriptions.

# Arguments
- `strategy_id::Symbol`: Strategy identifier (e.g., `:collocation`, `:adnlp`, `:ipopt`, `:madnlp`)

# Returns
- Nothing (prints to stdout)

# Example
```julia-repl
julia> using OptimalControl

julia> describe(:collocation)
```

# Notes
- For the complete list of options for each strategy, refer to:
  - **Collocation**: [CTDirect documentation](https://control-toolbox.org/CTDirect.jl/stable/)
  - **ADNLP**: [CTSolvers documentation](https://control-toolbox.org/CTSolvers.jl/stable/)
  - **Exa**: [ExaModels documentation](https://exanauts.github.io/ExaModels.jl/stable/)
  - **Ipopt**: [Ipopt options](https://coin-or.github.io/Ipopt/OPTIONS.html)
  - **MadNLP**: [MadNLP options](https://madnlp.github.io/MadNLP.jl/stable/options/)
  - **MadNCL**: [MadNCL documentation](https://github.com/MadNLP/MadNCL.jl)
  - **Knitro**: [Knitro options](https://www.artelys.com/docs/knitro/3_referenceManual/userOptions.html)

See also: [`methods`](@ref), [`get_strategy_registry`](@ref), [`solve`](@ref)
"""
function CTSolvers.describe(strategy_id::Symbol)
    registry = get_strategy_registry()
    CTSolvers.describe(strategy_id, registry)
end
