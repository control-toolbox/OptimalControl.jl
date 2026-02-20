# Implementing a Modeler

```@meta
CurrentModule = CTSolvers
```

This guide explains how to implement an optimization modeler in CTSolvers. Modelers are strategies that convert `AbstractOptimizationProblem` instances into NLP backend models and convert NLP solver results back into problem-specific solutions. We use **Modelers.ADNLP** and **Modelers.Exa** as reference examples.

!!! tip "Prerequisites"
    Read [Architecture](@ref) and [Implementing a Strategy](@ref) first. A modeler is a strategy with two additional **callable contracts**.

## The AbstractNLPModeler Contract

A modeler must satisfy **three contracts**:

1. **Strategy contract** — `id`, `metadata`, `options` (inherited from `AbstractStrategy`)
2. **Model building callable** — `(modeler)(prob, initial_guess) → NLP model`
3. **Solution building callable** — `(modeler)(prob, nlp_stats) → Solution`

```mermaid
classDiagram
    class AbstractStrategy {
        <<abstract>>
        id(::Type)::Symbol
        metadata(::Type)::StrategyMetadata
        options(instance)::StrategyOptions
    }

    class AbstractNLPModeler {
        <<abstract>>
        (modeler)(prob, x0) → NLP
        (modeler)(prob, stats) → Solution
    }

    AbstractStrategy <|-- AbstractNLPModeler
    AbstractNLPModeler <|-- Modelers.ADNLP
    AbstractNLPModeler <|-- Modelers.Exa
```

Both callables have default implementations that throw `NotImplemented`.

```@example modeler
using CTSolvers
nothing # hide
```

The `id` is available directly:

```@example modeler
CTSolvers.Strategies.id(CTSolvers.Modelers.ADNLP)
```

```@example modeler
CTSolvers.Strategies.id(CTSolvers.Modelers.Exa)
```

## Step-by-Step Implementation

We walk through the Modelers.ADNLP implementation as a reference.

### Step 1 — Define the struct

```julia
struct Modelers.ADNLP <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end
```

### Step 2 — Implement `id`

```@example modeler
CTSolvers.Strategies.id(CTSolvers.Modelers.ADNLP)
```

### Step 3 — Define defaults and metadata

The metadata defines all configurable options with types, defaults, and validators:

```@example modeler
CTSolvers.Strategies.metadata(CTSolvers.Modelers.ADNLP)
```

### Step 4 — Constructor and options accessor

The constructor validates options and stores them:

```@example modeler
modeler = CTSolvers.Modelers.ADNLP(backend = :optimized)
```

```@example modeler
CTSolvers.Strategies.options(modeler)
```

### Step 5 — Model building callable

This is the core of the modeler. It retrieves the appropriate **builder** from the problem and invokes it:

```julia
function (modeler::Modelers.ADNLP)(
    prob::AbstractOptimizationProblem,
    initial_guess,
)::ADNLPModels.ADNLPModel
    # Get the builder registered for this problem type
    builder = get_adnlp_model_builder(prob)

    # Extract modeler options as a Dict
    options = Strategies.options_dict(modeler)

    # Build the NLP model, passing all options to the builder
    return builder(initial_guess; options...)
end
```

The key interaction is with the **Builder pattern**: the modeler doesn't know how to build the model itself — it asks the problem for a builder, then calls it. See [Implementing an Optimization Problem](@ref) for how builders work.

### Step 6 — Solution building callable

Same pattern, but for converting NLP results back into a problem-specific solution:

```julia
function (modeler::Modelers.ADNLP)(
    prob::AbstractOptimizationProblem,
    nlp_solution::SolverCore.AbstractExecutionStats,
)
    builder = get_adnlp_solution_builder(prob)
    return builder(nlp_solution)
end
```

## Modelers.Exa: A Second Example

Modelers.Exa follows the same pattern with different options and a slightly different callable signature:

```julia
struct Modelers.Exa <: AbstractNLPModeler
    options::Strategies.StrategyOptions
end

Strategies.id(::Type{<:Modelers.Exa}) = :exa

function Strategies.metadata(::Type{<:Modelers.Exa})
    return Strategies.StrategyMetadata(
        Options.OptionDefinition(
            name = :base_type,
            type = DataType,
            default = Float64,
            description = "Base floating-point type used by ExaModels",
            validator = validate_exa_base_type,
        ),
        Options.OptionDefinition(
            name = :backend,
            type = Union{Nothing, KernelAbstractions.Backend},
            default = nothing,
            description = "Execution backend for ExaModels (CPU, GPU, etc.)",
        ),
    )
end
```

The model building callable extracts `base_type` as a positional argument:

```julia
function (modeler::Modelers.Exa)(
    prob::AbstractOptimizationProblem,
    initial_guess,
)::ExaModels.ExaModel
    builder = get_exa_model_builder(prob)
    options = Strategies.options_dict(modeler)

    # ExaModels requires BaseType as first positional argument
    BaseType = options[:base_type]
    delete!(options, :base_type)

    return builder(BaseType, initial_guess; options...)
end
```

!!! note "Different builder signatures"
    `ADNLPModelBuilder` takes `(initial_guess; kwargs...)` while `ExaModelBuilder` takes `(BaseType, initial_guess; kwargs...)`. Each modeler adapts the call to its builder's expected signature.

## Integration with build_model / build_solution

The `Optimization` module provides two generic functions that delegate to the modeler's callables:

```julia
# In src/Optimization/building.jl

function build_model(prob, initial_guess, modeler)
    return modeler(prob, initial_guess)
end

function build_solution(prob, model_solution, modeler)
    return modeler(prob, model_solution)
end
```

These are used by the high-level `CommonSolve.solve`:

```mermaid
sequenceDiagram
    participant User
    participant Solve as CommonSolve.solve
    participant BuildModel as build_model
    participant Modeler as Modelers.ADNLP
    participant Problem as AbstractOptimizationProblem
    participant Builder as ADNLPModelBuilder

    User->>Solve: solve(problem, x0, modeler, solver)
    Solve->>BuildModel: build_model(problem, x0, modeler)
    BuildModel->>Modeler: modeler(problem, x0)
    Modeler->>Problem: get_adnlp_model_builder(problem)
    Problem-->>Modeler: ADNLPModelBuilder
    Modeler->>Builder: builder(x0; show_time, backend, ...)
    Builder-->>Modeler: ADNLPModel
    Modeler-->>Solve: ADNLPModel
```

## Validation

Use `validate_strategy_contract` to verify the strategy contract (but not the callables — those require a real problem):

```julia
julia> Strategies.validate_strategy_contract(Modelers.ADNLP)
true

julia> Strategies.validate_strategy_contract(Modelers.Exa)
true
```

!!! note
    `validate_strategy_contract` requires that the default constructor produces options matching the metadata exactly. For modelers with `NotProvided` defaults or advanced option handling, run validation after loading all required extensions.

For the callables, test with a fake or real problem:

```julia
# Create a fake problem with builders
prob = FakeOptimizationProblem(adnlp_builder, adnlp_solution_builder)

# Test model building
modeler = Modelers.ADNLP(backend = :optimized)
nlp = modeler(prob, x0)
@test nlp isa ADNLPModels.ADNLPModel

# Test solution building
stats = solve(nlp, solver)
solution = modeler(prob, stats)
@test solution isa ExpectedSolutionType
```

## Summary: Adding a New Modeler

To add a new modeler (e.g., `MyModeler` for a new NLP backend):

1. Define `MyModeler <: AbstractNLPModeler` with `options::StrategyOptions`
2. Implement `Strategies.id(::Type{<:MyModeler}) = :my_backend`
3. Implement `Strategies.metadata(::Type{<:MyModeler})` with option definitions
4. Write constructor: `MyModeler(; mode, kwargs...)`
5. Implement `Strategies.options(m::MyModeler) = m.options`
6. Implement model building callable: `(modeler::MyModeler)(prob, x0) → NLP`
7. Implement solution building callable: `(modeler::MyModeler)(prob, stats) → Solution`
8. Add corresponding builder types in `Optimization` if needed (`MyModelBuilder`, `MySolutionBuilder`)
9. Add contract methods in `Optimization`: `get_my_model_builder`, `get_my_solution_builder`
