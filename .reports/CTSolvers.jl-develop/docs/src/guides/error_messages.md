# Error Messages Reference

```@meta
CurrentModule = CTSolvers
```

This page catalogues all exception types used in CTSolvers, with live examples and recommended fixes. CTSolvers uses enriched exceptions from `CTBase.Exceptions` that carry structured fields (`got`, `expected`, `suggestion`, `context`) for actionable error messages.

## Exception Types

CTSolvers uses three exception types from `CTBase.Exceptions`:

| Type | Purpose |
|------|---------|
| `NotImplemented` | Contract method not implemented by a concrete type |
| `IncorrectArgument` | Invalid argument value, type, or routing |
| `ExtensionError` | Required package extension not loaded |

All three accept keyword arguments for structured messages:

```@example errors
using CTSolvers
using CTBase: CTBase
const Exceptions = CTBase.Exceptions
nothing # hide
```

## NotImplemented — Contract Not Implemented

Thrown when a concrete type doesn't implement a required contract method.

### Strategy contract — missing `id`

```@example errors
abstract type IncompleteStrategy <: CTSolvers.Strategies.AbstractStrategy end
nothing # hide
```

```@repl errors
CTSolvers.Strategies.id(IncompleteStrategy)
```

**Fix**: Implement the missing method:

```julia
Strategies.id(::Type{<:IncompleteStrategy}) = :my_strategy
```

### Strategy contract — missing `metadata`

```@repl errors
CTSolvers.Strategies.metadata(IncompleteStrategy)
```

### Optimization problem contract — missing builder

```@example errors
struct MinimalProblem <: CTSolvers.Optimization.AbstractOptimizationProblem end
nothing # hide
```

```@repl errors
CTSolvers.Optimization.get_adnlp_model_builder(MinimalProblem())
```

```@repl errors
CTSolvers.Optimization.get_exa_model_builder(MinimalProblem())
```

### Where it's thrown

| Method | Context |
|--------|---------|
| `Strategies.id(::Type{T})` | Strategy type missing `id` |
| `Strategies.metadata(::Type{T})` | Strategy type missing `metadata` |
| `Strategies.options(strategy)` | Strategy instance has no `options` field and no custom getter |
| `get_adnlp_model_builder(prob)` | Problem doesn't support ADNLPModels |
| `get_exa_model_builder(prob)` | Problem doesn't support ExaModels |
| `get_adnlp_solution_builder(prob)` | Problem doesn't support ADNLP solutions |
| `get_exa_solution_builder(prob)` | Problem doesn't support Exa solutions |

## IncorrectArgument — Invalid Arguments

Thrown for invalid values, types, or routing errors. This is the most common exception in CTSolvers.

### Type mismatch in extraction

When `extract_option` receives a value of the wrong type:

```@repl errors
def = CTSolvers.Options.OptionDefinition(
    name = :max_iter, type = Integer, default = 100,
    description = "Maximum iterations",
)
CTSolvers.Options.extract_option((max_iter = "hello",), def)
```

**Fix**: Provide a value of the correct type.

### Validator failure

When a value doesn't satisfy the validator constraint:

```@example errors
bad_def = CTSolvers.Options.OptionDefinition(
    name = :tol, type = Real, default = 1e-8,
    description = "Tolerance",
    validator = x -> x > 0 || throw(Exceptions.IncorrectArgument(
        "Invalid tolerance value",
        got = "tol=$x",
        expected = "positive real number (> 0)",
        suggestion = "Provide a positive tolerance value (e.g., 1e-6, 1e-8)",
        context = "tol validation",
    )),
)
nothing # hide
```

```@repl errors
CTSolvers.Options.extract_option((tol = -1.0,), bad_def)
```

**Fix**: Provide a value that satisfies the validator constraint.

### Type mismatch in OptionDefinition constructor

When the default value doesn't match the declared type:

```@repl errors
CTSolvers.Options.OptionDefinition(
    name = :count, type = Integer, default = "hello",
    description = "A count",
)
```

**Fix**: Ensure the default value matches the declared type.

### Invalid OptionValue source

```@repl errors
CTSolvers.Options.OptionValue(42, :invalid_source)
```

**Fix**: Use `:default`, `:user`, or `:computed`.

## ExtensionError — Extension Not Loaded

Thrown when a solver requires a package extension that hasn't been loaded.

```@repl errors
CTSolvers.Solvers.Ipopt()
```

**Fix**: Load the required package before using the solver:

```julia
using NLPModelsIpopt  # loads the CTSolversIpopt extension
solver = Solvers.Ipopt(max_iter = 1000)
```

### Where it's thrown

| Solver | Required package |
|--------|-----------------|
| `Solvers.Ipopt` | `NLPModelsIpopt` |
| `Solvers.MadNLP` | `MadNLP` |
| `Solvers.Knitro` | `KNITRO` |
| `Solvers.MadNCL` | `MadNCL` |

## Display Examples

### OptionDefinition display

```@example errors
CTSolvers.Options.OptionDefinition(
    name = :max_iter, type = Integer, default = 1000,
    description = "Maximum number of iterations",
    aliases = (:maxiter,),
)
```

### OptionValue display

```@example errors
CTSolvers.Options.OptionValue(1000, :user)
```

```@example errors
CTSolvers.Options.OptionValue(1e-8, :default)
```

### NotProvided display

```@example errors
CTSolvers.Options.NotProvided
```

### Option extraction — successful

```@example errors
def = CTSolvers.Options.OptionDefinition(
    name = :grid_size, type = Int, default = 100,
    description = "Grid size", aliases = (:n,),
)
opt_value, remaining = CTSolvers.Options.extract_option((n = 200, tol = 1e-6), def)
println("Extracted: ", opt_value)
println("Remaining: ", remaining)
```

### Multiple option extraction

```@example errors
defs = [
    CTSolvers.Options.OptionDefinition(
        name = :grid_size, type = Int, default = 100, description = "Grid size",
    ),
    CTSolvers.Options.OptionDefinition(
        name = :tol, type = Float64, default = 1e-6, description = "Tolerance",
    ),
]
extracted, remaining = CTSolvers.Options.extract_options((grid_size = 200, max_iter = 1000), defs)
println("Extracted: ", extracted)
println("Remaining: ", remaining)
```

## Best Practices for Error Messages

When implementing new validators or error paths, follow the CTSolvers convention:

```julia
throw(Exceptions.IncorrectArgument(
    "Short, clear description of the problem",
    got        = "what the user actually provided",
    expected   = "what was expected instead",
    suggestion = "actionable fix the user can apply",
    context    = "ModuleName.function_name - specific validation step",
))
```

- **`got`**: Show the actual value, including its type if relevant
- **`expected`**: Be specific about valid values or ranges
- **`suggestion`**: Provide a concrete example the user can copy
- **`context`**: Include the module and function name for traceability
