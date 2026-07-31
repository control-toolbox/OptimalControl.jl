# CTBase reexports
#
# Since the ecosystem-wide restructuring, CTBase owns the strategy/option layer
# (previously in CTSolvers) and the `Data` type vocabulary `Flow` dispatches on
# (previously in CTFlows). Every import below points at the *owning* submodule,
# per the Handbook `modules.md` rule.

# Generated code — `@Lie` expands to `CTBase.Traits.*` prefixes, so `CTBase`
# itself must stay in scope at every call site.
@reexport import CTBase: CTBase # for generated code (prefix)

# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------
import CTBase.Core: NotProvided, NotProvidedType, ctNumber

# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------
import CTBase.Exceptions:
    CTException,
    IncorrectArgument,
    PreconditionError,
    NotImplemented,
    ParsingError,
    AmbiguousDescription,
    ExtensionError

# ---------------------------------------------------------------------------
# Traits
#
# CTModels.Models re-exports these, but CTBase.Traits owns them.
# ---------------------------------------------------------------------------
@reexport import CTBase.Traits:
    is_autonomous,
    is_nonautonomous,
    is_variable,
    is_nonvariable,
    has_variable,
    has_control,
    is_control_free

# ---------------------------------------------------------------------------
# Data — the type vocabulary the user writes against
#
# `Flow` dispatches on these, so a user building a flow explicitly needs them
# in scope. Note the two deliberate omissions: `control_law` and
# `pseudo_hamiltonian` are exported from `CTFlows.Systems` instead (they are
# siblings of `hamiltonian(sys)`); see imports/ctflows.jl.
# ---------------------------------------------------------------------------
@reexport import CTBase.Data:

    # Vector fields
    AbstractVectorField,
    VectorField,
    ControlledVectorField,
    ComposedVectorField,
    AbstractControlledVectorField,
    controlled_vector_field,

    # Hamiltonians
    AbstractHamiltonian,
    Hamiltonian,
    ComposedHamiltonian,
    AbstractHamiltonianVectorField,
    HamiltonianVectorField,

    # Pseudo-Hamiltonians
    AbstractPseudoHamiltonian,
    PseudoHamiltonian,
    AbstractPseudoHamiltonianVectorField,
    PseudoHamiltonianVectorField,

    # Control laws — semantically distinct, they select different `Flow` methods
    AbstractControlLaw,
    ControlLaw,
    OpenLoop,
    ClosedLoop,
    DynClosedLoop,

    # Path constraints
    AbstractPathConstraint,
    PathConstraint,
    StateConstraint,
    ControlConstraint,
    MixedConstraint,

    # Multipliers
    AbstractMultiplier,
    Multiplier

# ---------------------------------------------------------------------------
# Strategies
# ---------------------------------------------------------------------------
import CTBase.Strategies:

    # Types
    AbstractStrategy,
    StrategyRegistry,
    StrategyMetadata,
    StrategyOptions,
    RoutedOption,
    BypassValue,

    # Parameter types (imported only, not reexported)
    AbstractStrategyParameter

@reexport import CTBase.Strategies: CPU, GPU

@reexport import CTBase.Strategies:

    # Metadata
    id,
    metadata,

    # Display and introspection functions
    describe,
    options,
    option_names,
    option_type,
    option_description,
    option_default,
    option_defaults,
    option_value,
    option_source,
    has_option,

    # Registry
    create_registry,
    strategy_ids,
    type_from_id,
    parameter,
    default_parameter,
    available_parameters,
    force,

    # Utility functions
    route_to,
    bypass

# ---------------------------------------------------------------------------
# Options
#
# `OptionDefinition` is exported by both `Options` and `Strategies` — same
# object. Import from `Options`, the owner.
# ---------------------------------------------------------------------------
import CTBase.Options: OptionDefinition, OptionValue

@reexport import CTBase.Options: is_user, is_default, is_computed
