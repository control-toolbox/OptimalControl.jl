"""
$(TYPEDSIGNATURES)

Return the tuple of available method triplets for solving optimal control problems.

Each triplet consists of `(discretizer_id, modeler_id, solver_id)` where:
- `discretizer_id`: Symbol identifying the discretization strategy
- `modeler_id`: Symbol identifying the NLP modeling strategy
- `solver_id`: Symbol identifying the NLP solver

# Returns
- `Tuple{Vararg{Tuple{Symbol, Symbol, Symbol}}}`: Available method combinations

# Examples
```julia
julia> m = methods()
((:collocation, :adnlp, :ipopt), (:collocation, :adnlp, :madnlp), ...)

julia> length(m)
6
```

# See Also
- [`solve`](@ref): Main solve function that uses these methods
- [`CTBase.complete`](@ref): Completes partial method descriptions
"""
function Base.methods()::Tuple{Vararg{Tuple{Symbol, Symbol, Symbol}}}
    return (
        (:collocation, :adnlp, :ipopt ),
        (:collocation, :adnlp, :madnlp),
        (:collocation, :exa,   :ipopt ),
        (:collocation, :exa,   :madnlp),
        (:collocation, :adnlp, :knitro),
        (:collocation, :exa,   :knitro),
    )
end
