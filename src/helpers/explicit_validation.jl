"""
$(TYPEDSIGNATURES)

Return keyword arguments that are not explicit component instances or canonical
component keywords.

Reuses [`_descriptive_families`](@ref) as the single source of truth for component
keyword names and abstract types, so this stays in sync with descriptive mode.
"""
function _extract_explicit_component_kwargs(kwargs::Base.Pairs)
    families = _descriptive_families()
    remaining = NamedTuple(
        key => value for (key, value) in kwargs if
        key ∉ keys(families) && !_is_explicit_component(value, families)
    )
    return Base.pairs(remaining)
end

_is_explicit_component(value, families=_descriptive_families()) =
    any(T -> value isa T, values(families))

"""
$(TYPEDSIGNATURES)

Return the names of the options accepted directly by `solve` in explicit mode:
action options (with their aliases) plus the component keywords.

Derived from [`_descriptive_action_defs`](@ref) and [`_descriptive_families`](@ref)
so the list stays in sync with descriptive mode.
"""
function _explicit_option_names()
    names = String[]
    for def in _descriptive_action_defs()
        push!(names, string(def.name))
        append!(names, string.(def.aliases))
    end
    append!(names, string.(keys(_descriptive_families())))
    return names
end

"""
$(TYPEDSIGNATURES)

Validate keyword arguments left over after explicit solve components and action
options have been extracted.
"""
function _validate_explicit_options(kwargs, components::NamedTuple)
    for (option, _) in kwargs
        owners = [
            family for (family, strategy) in pairs(components) if
            CTBase.Strategies.has_option(strategy, option)
        ]

        if isempty(owners)
            _throw_unknown_explicit_option(option)
        elseif length(owners) == 1
            _throw_strategy_explicit_option(option, only(owners), components)
        else
            _throw_ambiguous_explicit_option(option, owners)
        end
    end

    return nothing
end

function _throw_strategy_explicit_option(option, owner, components::NamedTuple)
    strategy = components[owner]
    strategy_name = nameof(typeof(strategy))
    throw(
        CTBase.IncorrectArgument(
            "Strategy option cannot be passed directly to solve in explicit mode";
            got="option `$(option)` for $(owner)",
            expected="options accepted by the solve action or explicit component instances",
            suggestion="Construct $(strategy_name) with $(option)=... and pass it as `$(owner)` to solve",
            context="solve explicit option validation",
        ),
    )
end

function _throw_ambiguous_explicit_option(option, owners)
    owner_names = join(string.(owners), ", ")
    throw(
        CTBase.IncorrectArgument(
            "Ambiguous strategy option in explicit mode";
            got="option `$(option)` for $(owner_names)",
            expected="an explicitly configured strategy instance",
            suggestion="Construct the intended strategy with $(option)=... and pass it to solve",
            context="solve explicit option validation",
        ),
    )
end

function _throw_unknown_explicit_option(option)
    action_options = join(_explicit_option_names(), ", ")
    throw(
        CTBase.IncorrectArgument(
            "Unknown option for solve in explicit mode";
            got="option `$(option)`",
            expected="one of $(action_options)",
            suggestion="Use a solve action option or configure the option when constructing a strategy",
            context="solve explicit option validation",
        ),
    )
end
