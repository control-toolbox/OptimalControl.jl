# CTSolvers reexports

# DOCP
@reexport import CTSolvers:
    DiscretizedOptimalControlProblem,
    ocp_model,
    nlp_model,
    ocp_solution

# Modelers
@reexport import CTSolvers:
    AbstractOptimizationModeler,
    ADNLPModeler,
    ExaModeler

# Solvers
@reexport import CTSolvers:
    AbstractOptimizationSolver,
    IpoptSolver,
    MadNLPSolver,
    MadNCLSolver,
    KnitroSolver

# Strategies
@reexport import CTSolvers:

    # Types
    AbstractStrategy, 
    StrategyRegistry, 
    StrategyMetadata, 
    StrategyOptions, 
    OptionDefinition,
    RoutedOption,

    # Metadata
    id,
    metadata,

    # Introspection functions
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
    filter_options, 
    suggest_options, 
    options_dict,
    route_to