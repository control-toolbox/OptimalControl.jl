"""
$(TYPEDSIGNATURES)

Display detailed information about a strategy identified by its symbol.

This is a convenience wrapper around `CTBase.Strategies.describe` that uses OptimalControl's
full strategy registry. It shows the strategy's available options, their types, defaults,
and descriptions.

Every strategy the package exposes is covered, on both sides of the library — the direct path
(discretizer, NLP modeler, NLP solver) and the indirect one (AD backend, ODE integrator). The
integrator and the AD backend are strategies in the control-toolbox sense like any other, so
their options are inspectable the same way.

# Arguments
- `strategy_id::Symbol`: Strategy identifier. One of

  | family | ids |
  |---|---|
  | discretizer | `:collocation` |
  | NLP modeler | `:adnlp`, `:exa` |
  | NLP solver | `:ipopt`, `:madnlp`, `:madncl`, `:uno`, `:knitro` |
  | AD backend | `:di` |
  | ODE integrator | `:sciml` |

  or a strategy *parameter*: `:cpu`, `:gpu`.

# Returns
- Nothing (prints to stdout)

# Example
```julia-repl
julia> using OptimalControl

julia> describe(:collocation)
```

# Notes
For complete option lists, see the official documentation:

- **ADNLP**: [ADNLPModels documentation](https://jso.dev/ADNLPModels.jl/stable/)
- **Exa**: [ExaModels documentation](https://exanauts.github.io/ExaModels.jl/stable/)
- **Ipopt**: [Ipopt options](https://coin-or.github.io/Ipopt/OPTIONS.html)
- **MadNLP**: [MadNLP options](https://madnlp.github.io/MadNLP.jl/stable/options/)
- **MadNCL**: [MadNCL documentation](https://github.com/MadNLP/MadNCL.jl)
- **Knitro**: [Knitro options](https://www.artelys.com/docs/knitro/3_referenceManual/userOptions.html)
- **Uno**: [Uno documentation](https://unosolver.readthedocs.io)

See also: [`methods`](@ref), [`get_strategy_registry`](@ref), [`solve`](@ref)
"""
# NOTE: this is deliberate type piracy on `::Symbol` — pre-existing, and the
# whole point of the convenience wrapper. `describe` moved from CTSolvers to
# CTBase.Strategies in v2.1.0-beta, hence the qualified path; do not "fix" it
# into a local `describe`, that would shadow the two-argument method.
function CTBase.Strategies.describe(strategy_id::Symbol)
    # The *full* registry, not the solve one: `:di` and `:sciml` are strategies too, and a
    # user should not have to know which registry a token lives in. Merging beats a
    # `try`/`catch` fallback between the two — it keeps the "unknown id" error intact
    # instead of swallowing it and reporting the second registry's failure.
    registry = get_full_strategy_registry()
    return CTBase.Strategies.describe(strategy_id, registry)
end
