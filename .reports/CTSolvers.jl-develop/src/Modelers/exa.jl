# Exa Modeler
#
# Implementation of Modelers.Exa using the AbstractStrategy contract.
# This modeler converts discretized optimal control problems to ExaModels.
#
# Author: CTSolvers Development Team
# Date: 2026-01-25

# Default option values
"""
$(TYPEDSIGNATURES)

Return the default floating-point type for [`Modelers.Exa`](@ref).

Default is `Float64`.
"""
__exa_model_base_type() = Float64

"""
$(TYPEDSIGNATURES)

Return the default execution backend for [`Modelers.Exa`](@ref).

Default is `nothing` (CPU).
"""
__exa_model_backend() = nothing

# NOTE: GPU options removed - not relevant for current implementation
# __exa_model_auto_detect_gpu() = true
# __exa_model_gpu_preference() = :cuda
# __exa_model_precision_mode() = :standard

"""
$(TYPEDEF)

Modeler for building ExaModels from discretized optimal control problems.

This modeler uses the ExaModels.jl package to create NLP models with
support for various execution backends (CPU, GPU) and floating-point types.

# Constructor

```julia
Modelers.Exa(; mode::Symbol=:strict, kwargs...)
```

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see Options section)

# Options

## Basic Options
- `base_type::Type{<:AbstractFloat}`: Floating-point type (default: `Float64`)
- `backend`: Execution backend (default: `nothing` for CPU)

# Examples

## Basic Usage
```julia
# Default modeler (Float64, CPU)
modeler = Modelers.Exa()
```

## Type Specification
```julia
# Single precision
modeler = Modelers.Exa(base_type=Float32)

# Double precision (default)
modeler = Modelers.Exa(base_type=Float64)
```

## Backend Configuration
```julia
# CPU backend (default)
modeler = Modelers.Exa(backend=nothing)

# GPU backend (if available)
using KernelAbstractions
modeler = Modelers.Exa(backend=CUDABackend())
```

## Validation Modes
```julia
# Strict mode (default) - rejects unknown options
modeler = Modelers.Exa(base_type=Float64)

# Permissive mode - accepts unknown options with warning
modeler = Modelers.Exa(
    base_type=Float64,
    custom_option=123;
    mode=:permissive
)
```

## Complete Configuration
```julia
# Full configuration with type and backend
modeler = Modelers.Exa(
    base_type=Float32,
    backend=CUDABackend();
    mode=:permissive
)
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If option validation fails
- `CTBase.Exceptions.IncorrectArgument`: If invalid mode is provided

# See also

- [`Modelers.ADNLP`](@ref): Alternative modeler using ADNLPModels
- [`build_model`](@ref): Build model from problem and modeler
- [`solve!`](@ref): Solve optimization problem

# Notes

- The `base_type` option affects the precision of all computations
- GPU backends require appropriate packages to be loaded
- CPU backend (`backend=nothing`) is always available
- ExaModels.jl provides efficient GPU acceleration for large problems

# References

- ExaModels.jl: [https://github.com/JuliaSmoothOptimizers/ExaModels.jl](https://github.com/JuliaSmoothOptimizers/ExaModels.jl)
- KernelAbstractions.jl: [https://github.com/JuliaGPU/KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)
"""
struct Exa <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end

# Strategy identification
Strategies.id(::Type{<:Modelers.Exa}) = :exa

# Strategy metadata with option definitions
function Strategies.metadata(::Type{<:Modelers.Exa})
    return Strategies.StrategyMetadata(
        # === Existing Options (enhanced) ===
        Strategies.OptionDefinition(;
            name=:base_type,
            type=DataType,
            default=__exa_model_base_type(),
            description="Base floating-point type used by ExaModels",
            validator=validate_exa_base_type
        ),
        # NOTE: minimize option is commented out as it will be automatically set
        # when building the model based on the problem structure
        # Strategies.OptionDefinition(;
        #     name=:minimize,
        #     type=Bool,
        #     default=Options.NotProvided,
        #     description="Whether to minimize (true) or maximize (false) the objective"
        # ),
        Strategies.OptionDefinition(;
            name=:backend,
            type=Union{Nothing, KernelAbstractions.Backend},  # More permissive for various backend types
            default=__exa_model_backend(),
            description="Execution backend for ExaModels (CPU, GPU, etc.)",
            aliases=(:exa_backend,)
        )
    )
end

# Simple constructor
"""
$(TYPEDSIGNATURES)

Create an Modelers.Exa with validated options.

# Arguments
- `mode::Symbol=:strict`: Validation mode (`:strict` or `:permissive`)
  - `:strict` (default): Rejects unknown options with detailed error message
  - `:permissive`: Accepts unknown options with warning, stores with `:user` source
- `kwargs...`: Modeler options (see [`Modelers.Exa`](@ref) documentation)

# Returns
- `Modelers.Exa`: Configured modeler instance

# Examples
```julia
# Default modeler
modeler = Modelers.Exa()

# With custom options
modeler = Modelers.Exa(base_type=Float32, backend=nothing)

# With permissive mode
modeler = Modelers.Exa(base_type=Float64, custom_option=123; mode=:permissive)
```

# Throws

- `CTBase.Exceptions.IncorrectArgument`: If option validation fails
- `CTBase.Exceptions.IncorrectArgument`: If invalid mode is provided

# See also

- [`Modelers.Exa`](@ref): Type documentation
- [`Strategies.build_strategy_options`](@ref): Option validation function
"""
function Modelers.Exa(; mode::Symbol=:strict, kwargs...)
    # Check for deprecated aliases
    if haskey(kwargs, :exa_backend)
        @warn "exa_backend is deprecated, use backend instead" maxlog=1
    end
    
    opts = Strategies.build_strategy_options(
        Modelers.Exa; mode=mode, kwargs...
    )
    return Modelers.Exa(opts)
end

# Access to strategy options
Strategies.options(m::Modelers.Exa) = m.options

# Model building interface
"""
$(TYPEDSIGNATURES)

Build an ExaModel from a discretized optimal control problem.

# Arguments
- `modeler::Modelers.Exa`: Configured modeler instance
- `prob::AbstractOptimizationProblem`: Discretized optimal control problem
- `initial_guess`: Initial guess for optimization variables

# Returns
- `ExaModels.ExaModel`: Built NLP model

# Examples
```julia
# Create modeler
modeler = Modelers.Exa(base_type=Float64)

# Build model from problem
nlp = modeler(problem, initial_guess)

# Solve the model
stats = solve(nlp, solver)
```

# See also

- [`Modelers.Exa`](@ref): Type documentation
- [`build_model`](@ref): Generic model building interface
- [`ExaModels.ExaModel`](@ref): NLP model type
"""
function (modeler::Modelers.Exa)(
    prob::AbstractOptimizationProblem,
    initial_guess
)::ExaModels.ExaModel
    # Get the appropriate builder for this problem type
    builder = get_exa_model_builder(prob)
    
    # Extract options as Dict
    options = Strategies.options_dict(modeler)
    
    # Extract BaseType and remove it from options to avoid passing it as named argument
    BaseType = options[:base_type]
    delete!(options, :base_type)
    
    # Build the ExaModel passing BaseType as first argument and remaining options as named arguments
    return builder(BaseType, initial_guess; options...)
end

# Solution building interface
"""
$(TYPEDSIGNATURES)

Build a solution object from NLP solver statistics.

# Arguments
- `modeler::Modelers.Exa`: Configured modeler instance
- `prob::AbstractOptimizationProblem`: Original optimization problem
- `nlp_solution::SolverCore.AbstractExecutionStats`: NLP solver statistics

# Returns
- Solution object appropriate for the problem type

# Examples
```julia
# Create modeler and solve
modeler = Modelers.Exa()
nlp = modeler(problem, initial_guess)
stats = solve(nlp, solver)

# Build solution object
solution = modeler(problem, stats)
```

# See also

- [`Modelers.Exa`](@ref): Type documentation
- [`SolverCore.AbstractExecutionStats`](@ref): Solver statistics type
- [`solve`](@ref): Generic solve interface
"""
function (modeler::Modelers.Exa)(
    prob::AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats
)
    # Get the appropriate solution builder for this problem type
    builder = get_exa_solution_builder(prob)
    return builder(nlp_solution)
end
