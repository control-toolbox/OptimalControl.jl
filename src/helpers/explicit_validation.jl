"""
$(TYPEDSIGNATURES)

Return keyword arguments that are not explicit component instances or canonical
component keywords.
"""
function _extract_explicit_component_kwargs(kwargs::Base.Pairs)
    component_names = (:discretizer, :modeler, :solver)
    remaining = NamedTuple(
        key => value for (key, value) in kwargs if
        key ∉ component_names && !_is_explicit_component(value)
    )
    return Base.pairs(remaining)
end

_is_explicit_component(value) =
    value isa CTSolvers.DOCP.AbstractDiscretizer ||
    value isa CTSolvers.Modelers.AbstractNLPModeler ||
    value isa CTSolvers.Solvers.AbstractNLPSolver

"""
$(TYPEDSIGNATURES)

Validate keyword arguments left over after explicit solve components and action
options have been extracted.
"""
function _validate_explicit_options(kwargs, discretizer, modeler, solver)
    strategies = (
        (:discretizer, discretizer),
        (:modeler, modeler),
        (:solver, solver),
    )

    for (option, _) in kwargs
        owners = [
            family for (family, strategy) in strategies if
            CTBase.Strategies.has_option(strategy, option)
        ]

        if isempty(owners)
            _throw_unknown_explicit_option(option)
        elseif length(owners) == 1
            _throw_strategy_explicit_option(option, only(owners), strategies)
        else
            _throw_ambiguous_explicit_option(option, owners)
        end
    end

    return nothing
end

function _throw_strategy_explicit_option(option, owner, strategies)
    strategy = only(strategy for (family, strategy) in strategies if family === owner)
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
    action_options = "initial_guess, init, display, discretizer, modeler, solver"
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
