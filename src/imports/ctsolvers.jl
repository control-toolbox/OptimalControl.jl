# CTSolvers reexports

# For internal use
import CTSolvers

# DOCP
import CTSolvers:
    DiscretizedModel

@reexport import CTSolvers:
    ocp_model,
    nlp_model,
    ocp_solution

# Modelers
import CTSolvers:
    AbstractNLPModeler,
    ADNLP,
    Exa

# Solvers
import CTSolvers:
    AbstractNLPSolver,
    Ipopt,
    MadNLP,
    MadNCL,
    Knitro

# Strategies
import CTSolvers:

    # Types
    AbstractStrategy, 
    StrategyRegistry, 
    StrategyMetadata, 
    StrategyOptions, 
    OptionDefinition,
    RoutedOption,
    BypassValue

@reexport import CTSolvers:

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
    is_user,
    is_default,
    is_computed,

    # Utility functions
    route_to,
    bypass
