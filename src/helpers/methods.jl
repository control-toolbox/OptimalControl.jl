"""
$(TYPEDSIGNATURES)

Return the tuple of available method quadruplets for solving optimal control problems.

Each quadruplet consists of `(discretizer_id, modeler_id, solver_id, parameter)` where:
- `discretizer_id::Symbol`: Discretization strategy identifier (e.g., `:collocation`)
- `modeler_id::Symbol`: NLP modeling strategy identifier (e.g., `:adnlp`, `:exa`)
- `solver_id::Symbol`: NLP solver identifier (e.g., `:ipopt`, `:madnlp`, `:madncl`, `:knitro`)
- `parameter::Symbol`: Execution parameter (`:cpu` or `:gpu`)

# Returns
- `Tuple{Vararg{Tuple{Symbol, Symbol, Symbol, Symbol}}}`: Available method combinations

# Examples
```julia
julia> m = methods()
((:collocation, :adnlp, :ipopt, :cpu), (:collocation, :adnlp, :madnlp, :cpu), ...)

julia> length(m)
11  # 9 CPU methods + 2 GPU methods

julia> # CPU methods
julia> methods()[1]
(:collocation, :adnlp, :ipopt, :cpu)

julia> # GPU methods
julia> methods()[9]
(:collocation, :exa, :madnlp, :gpu)
```

# Notes
- Returns a precomputed constant tuple (allocation-free, type-stable)
- All methods currently use `:collocation` discretization
- CPU methods (9 total): All combinations of `{adnlp, exa}` × `{ipopt, madnlp, uno, madncl, knitro}`
- GPU methods (2 total): Only GPU-capable combinations `exa` × `{madnlp, madncl}`
- GPU-capable strategies use parameterized types with automatic defaults
- Used by `CTBase.Descriptions.complete` to complete partial method descriptions

See also: [`solve`](@ref), [`CTBase.Descriptions.complete`](@extref), [`get_strategy_registry`](@ref)
"""
function Base.methods()::Tuple{Vararg{Tuple{Symbol,Symbol,Symbol,Symbol}}}
    return (
        # CPU methods (all existing methods now with :cpu parameter)
        (:collocation, :adnlp, :ipopt, :cpu),
        (:collocation, :adnlp, :madnlp, :cpu),
        (:collocation, :adnlp, :uno, :cpu),
        (:collocation, :adnlp, :madncl, :cpu),
        (:collocation, :adnlp, :knitro, :cpu),
        (:collocation, :exa, :ipopt, :cpu),
        (:collocation, :exa, :madnlp, :cpu),
        (:collocation, :exa, :madncl, :cpu),
        (:collocation, :exa, :knitro, :cpu),

        # GPU methods (only combinations that make sense)
        (:collocation, :exa, :madnlp, :gpu),
        (:collocation, :exa, :madncl, :gpu),
    )
end
