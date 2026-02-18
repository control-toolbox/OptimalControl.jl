"""
$(TYPEDSIGNATURES)

Extract strategy symbols from provided components to build a partial method description.

This function extracts the symbolic IDs from concrete strategy instances using
`CTSolvers.Strategies.id(typeof(component))`. It returns a tuple containing
the symbols of all non-`nothing` components in the order: discretizer, modeler, solver.

# Arguments
- `discretizer`: Discretization strategy or `nothing`
- `modeler`: NLP modeling strategy or `nothing`
- `solver`: NLP solver strategy or `nothing`

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
- [`CTSolvers.Strategies.id`](@ref): Extracts symbolic ID from strategy types
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
- `discretizer`: Concrete discretization strategy
- `modeler`: NLP modeling strategy or `nothing`
- `solver`: NLP solver strategy or `nothing`

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple containing discretizer symbol followed by remaining symbols

# Notes
- Uses `CTSolvers.Strategies.id` to extract symbolic ID
- Recursive call to process remaining components
- Allocation-free implementation through tuple concatenation
"""
function _build_partial_tuple(
    discretizer::CTDirect.AbstractDiscretizer,
    modeler::Union{CTSolvers.AbstractNLPModeler, Nothing},
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)
    disc_symbol = (CTSolvers.Strategies.id(typeof(discretizer)),)
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
- `modeler`: Concrete NLP modeling strategy
- `solver`: NLP solver strategy or `nothing`

# Returns
- `Tuple{Vararg{Symbol}}`: Tuple containing modeler symbol followed by solver symbol (if any)

# Notes
- Uses `CTSolvers.Strategies.id` to extract symbolic ID
- Recursive call to process solver component
- Allocation-free implementation
"""
function _build_partial_tuple(
    modeler::CTSolvers.AbstractNLPModeler,
    solver::Union{CTSolvers.AbstractNLPSolver, Nothing}
)
    mod_symbol = (CTSolvers.Strategies.id(typeof(modeler)),)
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
- `solver`: Concrete NLP solver strategy

# Returns
- `Tuple{Symbol}`: Single-element tuple containing solver symbol

# Notes
- Uses `CTSolvers.Strategies.id` to extract symbolic ID
- Terminal case in the recursion
- Allocation-free implementation
"""
function _build_partial_tuple(solver::CTSolvers.AbstractNLPSolver)
    return (CTSolvers.Strategies.id(typeof(solver)),)
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
- `partial_description`: Tuple of strategy symbols (may be empty or partial)

# Returns
- `Tuple{Symbol, Symbol, Symbol}`: Complete method triplet

# Examples
```julia
julia> _complete_description((:collocation,))
(:collocation, :adnlp, :ipopt)

julia> _complete_description(())
(:collocation, :adnlp, :ipopt)  # First available method

julia> _complete_description((:collocation, :exa))
(:collocation, :exa, :ipopt)
```

# See Also
- [`CTBase.complete`](@ref): Generic completion function
- [`methods`](@ref): Available method triplets
- [`_build_partial_description`](@ref): Builds partial description
"""
function _complete_description(
    partial_description::Tuple{Vararg{Symbol}}
)::Tuple{Symbol, Symbol, Symbol}
    return CTBase.complete(partial_description...; descriptions=OptimalControl.methods())
end

"""
$(TYPEDSIGNATURES)

Generic strategy builder that returns a provided strategy or builds one from a method description.

This function works for any strategy family (discretizer, modeler, or solver) using
multiple dispatch to handle the two cases: provided strategy vs. building from registry.

# Arguments
- `complete_description`: Complete method triplet (discretizer, modeler, solver)
- `provided`: Strategy instance or `nothing`
- `family_type`: Abstract strategy type (e.g., `CTDirect.AbstractDiscretizer`)
- `registry`: Strategy registry for building new strategies

# Returns
- `T`: Strategy instance of the specified family type

# Examples
```julia
# Use provided strategy
disc = CTDirect.Collocation()
result = _build_or_use_strategy((:collocation, :adnlp, :ipopt), disc, CTDirect.AbstractDiscretizer, registry)
@test result === disc

# Build from registry
result = _build_or_use_strategy((:collocation, :adnlp, :ipopt), nothing, CTDirect.AbstractDiscretizer, registry)
@test result isa CTDirect.AbstractDiscretizer
```

# Notes
- Fast path: when strategy is provided, returns it directly without registry lookup
- Build path: when strategy is `nothing`, constructs from method description using registry
- Type-safe through Julia's multiple dispatch system
- Allocation-free implementation

See also: [`CTSolvers.Strategies.build_strategy_from_method`](@ref), [`get_strategy_registry`](@ref), [`_complete_description`](@ref)
"""
function _build_or_use_strategy(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    provided::T,
    family_type::Type{T},
    registry::CTSolvers.Strategies.StrategyRegistry
)::T where {T <: CTSolvers.Strategies.AbstractStrategy}
    # Fast path: strategy already provided
    return provided
end

"""
$(TYPEDSIGNATURES)

Build strategy from registry when no strategy is provided.

This method handles the case where no strategy is provided (`nothing`),
building a new strategy from the complete method description using the registry.

# Arguments
- `complete_description`: Complete method triplet for strategy building
- `::Nothing`: Indicates no strategy provided
- `family_type`: Strategy family type to build
- `registry`: Strategy registry for building new strategies

# Returns
- `T`: Newly built strategy instance

# Notes
- Uses `CTSolvers.Strategies.build_strategy_from_method` for construction
- Registry lookup determines the concrete strategy type
- Type-safe through Julia's dispatch system
- Allocation-free when possible (depends on registry implementation)

See also: [`CTSolvers.Strategies.build_strategy_from_method`](@ref), [`get_strategy_registry`](@ref)
"""
function _build_or_use_strategy(
    complete_description::Tuple{Symbol, Symbol, Symbol},
    ::Nothing,
    family_type::Type{T},
    registry::CTSolvers.Strategies.StrategyRegistry
)::T where {T <: CTSolvers.Strategies.AbstractStrategy}
    # Build path: construct from registry
    return CTSolvers.Strategies.build_strategy_from_method(
        complete_description, family_type, registry
    )
end
