"""
$(TYPEDSIGNATURES)

Return the tuple of available method quadruplets for solving optimal control problems.

Each quadruplet consists of `(discretizer_id, modeler_id, solver_id, parameter)` where:
- `discretizer_id`: Symbol identifying the discretization strategy
- `modeler_id`: Symbol identifying the NLP modeling strategy  
- `solver_id`: Symbol identifying the NLP solver
- `parameter`: Symbol identifying the parameter (`:cpu` or `:gpu`)

GPU-capable methods use parameterized strategies that automatically get appropriate defaults:
- `Exa{GPU}` gets `CUDA.CUDABackend()` by default
- `MadNLP{GPU}` gets `MadNLPGPU.CUDSSSolver` by default
- `MadNCL{GPU}` gets `MadNLPGPU.CUDSSSolver` by default

# Returns
- `Tuple{Vararg{Tuple{Symbol, Symbol, Symbol, Symbol}}}`: Available method combinations

# Examples
```julia
julia> m = methods()
((:collocation, :adnlp, :ipopt, :cpu), (:collocation, :adnlp, :madnlp, :cpu), ...)

julia> length(m)
10  # CPU methods + GPU methods

julia> # CPU methods (existing behavior maintained)
julia> methods()[1]
(:collocation, :adnlp, :ipopt, :cpu)

julia> # GPU methods (new functionality)  
julia> methods()[9]  # First GPU method
(:collocation, :exa, :madnlp, :gpu)
```

# Notes
- All existing methods are now explicitly marked with `:cpu` parameter
- GPU methods are available when CUDA.jl is loaded
- Parameterized strategies provide smart defaults automatically

# See Also
- [`solve`](@ref): Main solve function that uses these methods
- [`CTBase.complete`](@ref): Completes partial method descriptions
- [`get_strategy_registry`](@ref): Registry with parameterized strategies
"""
function Base.methods()::Tuple{Vararg{Tuple{Symbol, Symbol, Symbol, Symbol}}}
    return (
        # CPU methods (all existing methods now with :cpu parameter)
        (:collocation, :adnlp, :ipopt,  :cpu),
        (:collocation, :adnlp, :madnlp, :cpu),
        (:collocation, :exa,   :ipopt,  :cpu),
        (:collocation, :exa,   :madnlp, :cpu),
        (:collocation, :adnlp, :madncl, :cpu),
        (:collocation, :exa,   :madncl, :cpu),
        (:collocation, :adnlp, :knitro, :cpu),
        (:collocation, :exa,   :knitro, :cpu),
        
        # GPU methods (only combinations that make sense)
        (:collocation, :exa,   :madnlp, :gpu),
        (:collocation, :exa,   :madncl, :gpu),
    )
end
