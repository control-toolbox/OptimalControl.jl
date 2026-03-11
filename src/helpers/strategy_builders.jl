"""
$(TYPEDSIGNATURES)

Extract strategy symbols from provided components to build a partial method description.

This function extracts the symbolic IDs from concrete strategy instances using
`CTSolvers.id(typeof(component))`. It returns a tuple containing
the symbols of all non-`nothing` components in the order: discretizer, modeler, solver.

# Arguments
- `discretizer::Union{CTDirect.AbstractDiscretizer, Nothing}`: Discretization strategy or `nothing`
- `modeler::Union{CTSolvers.AbstractNLPModeler, Nothing}`: NLP modeling strategy or `nothing`
- `solver::Union{CTSolvers.AbstractNLPSolver, Nothing}`: NLP solver strategy or `nothing`

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple of strategy symbols (empty if all `nothing`)

# Examples
```julia
julia> disc = CTDirect.Collocation()
julia> _build_partial_description(disc, nothing, nothing)
(:collocation,)

julia> mod = CTSolvers.ADNLP()
julia> sol = CTSolvers.Ipopt()
julia> _build_partial_description(nothing, mod, sol)
(:adnlp, :ipopt)

julia> _build_partial_description(nothing, nothing, nothing)
()
```

# See Also
- [`CTSolvers.Strategies.id`](@extref): Extracts symbolic ID from strategy types
- [`_complete_description`](@ref): Completes partial description via registry
"""
function _build_partial_description(
    discretizer::Union{CTDirect.AbstractDiscretizer, Nothing},
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)::Tuple{Vararg{Symbol}}
    return _build_partial_tuple(discretizer, modeler, solver)
end

# Recursive tuple building with multiple dispatch

"""
$(TYPEDSIGNATURES)

Base case for recursive tuple building.

Returns an empty tuple when no components are provided.
This function serves as the terminal case for the recursive
tuple building algorithm.

# Returns
- `()`: Empty tuple

# Notes
- This is the base case for the recursive tuple building algorithm
- Used internally by `_build_partial_description`
- Allocation-free implementation
"""
_build_partial_tuple() = ()

"""
$(TYPEDSIGNATURES)

Build partial tuple starting with a discretizer component.

This method handles the case where a discretizer is provided,
extracts its symbolic ID, and recursively processes the remaining
modeler and solver components.

# Arguments
- `discretizer::CTDirect.AbstractDiscretizer`: Concrete discretization strategy
- `modeler::Union{CTSolvers.AbstractNLPModeler, Nothing}`: NLP modeling strategy or `nothing`
- `solver::Union{CTSolvers.AbstractNLPSolver, Nothing}`: NLP solver strategy or `nothing`

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple containing discretizer symbol followed by remaining symbols

# Notes
- Uses `CTSolvers.id` to extract symbolic ID
- Recursive call to process remaining components
- Allocation-free implementation through tuple concatenation
"""
function _build_partial_tuple(
    discretizer::CTDirect.AbstractDiscretizer,
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)
    disc_symbol = (CTSolvers.id(typeof(discretizer)),)
    rest_symbols = _build_partial_tuple(modeler, solver)
    return (disc_symbol..., rest_symbols...)
end

"""
$(TYPEDSIGNATURES)

Skip discretizer and continue with remaining components.

This method handles the case where no discretizer is provided,
skipping directly to processing the modeler and solver components.

# Arguments
- `::Nothing`: Indicates no discretizer provided
- `modeler`: NLP modeling strategy or `nothing`
- `solver`: NLP solver strategy or `nothing`

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple containing symbols from modeler and/or solver

# Notes
- Delegates to recursive processing of remaining components
- Maintains order: modeler then solver
"""
function _build_partial_tuple(
    ::Nothing,
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)
    return _build_partial_tuple(modeler, solver)
end

"""
$(TYPEDSIGNATURES)

Build partial tuple starting with a modeler component.

This method handles the case where a modeler is provided,
extracts its symbolic ID, and recursively processes the solver.

# Arguments
- `modeler::CTSolvers.AbstractNLPModeler`: Concrete NLP modeling strategy
- `solver::Union{CTSolvers.AbstractNLPSolver, Nothing}`: NLP solver strategy or `nothing`

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple containing modeler symbol followed by solver symbol (if any)

# Notes
- Uses `CTSolvers.id` to extract symbolic ID
- Recursive call to process solver component
- Allocation-free implementation
"""
function _build_partial_tuple(
    modeler::CTSolvers.AbstractNLPModeler,
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)
    mod_symbol = (CTSolvers.id(typeof(modeler)),)
    rest_symbols = _build_partial_tuple(solver)
    return (mod_symbol..., rest_symbols...)
end

"""
$(TYPEDSIGNATURES)

Skip modeler and continue with solver component.

This method handles the case where no modeler is provided,
skipping directly to processing the solver component.

# Arguments
- `::Nothing`: Indicates no modeler provided
- `solver`: NLP solver strategy or `nothing`

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple containing solver symbol (if any)

# Notes
- Delegates to solver processing
- Terminal case in the recursion chain
"""
function _build_partial_tuple(
    ::Nothing,
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)
    return _build_partial_tuple(solver)
end

"""
$(TYPEDSIGNATURES)

Terminal case: extract solver symbol.

This method handles the case where a solver is provided,
extracts its symbolic ID, and returns it as a single-element tuple.

# Arguments
- `solver::CTSolvers.AbstractNLPSolver`: Concrete NLP solver strategy

# Returns
- `Tuple{Symbol}`: Single-element tuple containing solver symbol

# Notes
- Uses `CTSolvers.id` to extract symbolic ID
- Terminal case in the recursion
- Allocation-free implementation
"""
function _build_partial_tuple(solver::CTSolvers.AbstractNLPSolver)
    return (CTSolvers.id(typeof(solver)),)
end

"""
$(TYPEDSIGNATURES)

Terminal case: no solver provided.

This method handles the case where no solver is provided,
returning an empty tuple to complete the recursion.

# Arguments
- `::Nothing`: Indicates no solver provided

# Returns
- `()`: Empty tuple

# Notes
- Terminal case in the recursion
- Represents the case where all components are `nothing`
"""
function _build_partial_tuple(::Nothing)
    return ()
end

"""
$(TYPEDSIGNATURES)

Complete a partial method description into a full triplet using CTBase.complete().

This function takes a partial description (tuple of strategy symbols) and
completes it to a full (discretizer, modeler, solver) triplet using the
available methods as the completion set.

# Arguments
- `partial_description::Tuple{Vararg{Symbol}}`: Tuple of strategy symbols (may be empty or partial)

# Returns
- `Tuple{Symbol, Symbol, Symbol, Symbol}`: Complete method triplet

# Examples
```julia
julia> _complete_description((:collocation,))
(:collocation, :adnlp, :ipopt, :cpu)

julia> _complete_description(())
(:collocation, :adnlp, :ipopt, :cpu)  # First available method

julia> _complete_description((:collocation, :exa))
(:collocation, :exa, :ipopt, :cpu)
```

# See Also
- [`CTBase.Descriptions.complete`](@extref): Generic completion function
- [`methods`](@ref): Available method triplets
- [`_build_partial_description`](@ref): Builds partial description
"""
function _complete_description(
    partial_description::Tuple{Vararg{Symbol}}
)::Tuple{Symbol, Symbol, Symbol, Symbol}
    return CTBase.complete(partial_description...; descriptions=OptimalControl.methods())
end

"""
$(TYPEDSIGNATURES)

Generic strategy builder that returns a provided strategy or builds one from a resolved method.

This function works for any strategy family (discretizer, modeler, or solver) using
multiple dispatch to handle the two cases: provided strategy vs. building from registry.

# Arguments
- `resolved::CTSolvers.ResolvedMethod`: Resolved method information with parameter data
- `provided`: Strategy instance or `nothing`
- `family_name::Symbol`: Family name (e.g., `:discretizer`, `:modeler`, `:solver`)
- `families::NamedTuple`: NamedTuple mapping family names to abstract types
- `registry::CTSolvers.StrategyRegistry`: Strategy registry for building new strategies

# Returns
- `T`: Strategy instance (provided or built)

# Notes
- Fast path: strategy already provided by user
- Build path: when strategy is `nothing`, constructs from resolved method using registry
- Type-safe through Julia's multiple dispatch system
- Allocation-free implementation
- Uses ResolvedMethod for parameter-aware validation and construction

See also: [`CTSolvers.Orchestration.build_strategy_from_resolved`](@extref), [`get_strategy_registry`](@ref), [`_complete_description`](@ref)
"""
function _build_or_use_strategy(
    resolved::CTSolvers.ResolvedMethod,
    provided::T,
    family_name::Symbol,
    families::NamedTuple,
    registry::CTSolvers.StrategyRegistry
)::T where {T <: CTSolvers.AbstractStrategy}
    # Fast path: strategy already provided
    return provided
end

"""
$(TYPEDSIGNATURES)

Build strategy from registry when no strategy is provided.

This method handles the case where no strategy is provided (`nothing`),
building a new strategy from the complete method description using the registry.

# Arguments
- `resolved::CTSolvers.ResolvedMethod`: Resolved method information
- `::Nothing`: Indicates no strategy provided
- `family_name::Symbol`: Family name (e.g., `:discretizer`, `:modeler`, `:solver`)
- `families::NamedTuple`: NamedTuple mapping family names to abstract types
- `registry::CTSolvers.StrategyRegistry`: Strategy registry for building new strategies

# Returns
- `T`: Newly built strategy instance

# Notes
- Uses `CTSolvers.build_strategy_from_resolved` for construction
- Registry lookup determines the concrete strategy type
- Type-safe through Julia's dispatch system
- Allocation-free when possible (depends on registry implementation)

See also: [`CTSolvers.Orchestration.build_strategy_from_resolved`](@extref), [`get_strategy_registry`](@ref)
"""
function _build_or_use_strategy(
    resolved::CTSolvers.ResolvedMethod,
    ::Nothing,
    family_name::Symbol,
    families::NamedTuple,
    registry::CTSolvers.StrategyRegistry
)
    # Build path: construct from resolved method
    return CTSolvers.build_strategy_from_resolved(
        resolved, family_name, families, registry
    )
end
