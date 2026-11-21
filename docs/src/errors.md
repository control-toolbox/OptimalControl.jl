# [Errors](@id errors)

OptimalControl raises a few typed exceptions. Each one says what went wrong (`Got`,
`Expected`, `Reason`), where (`Context`), and how to fix it (`Hint`), so the message is the
first thing to read. This page lists them, with a real example of each.

```@setup errors
using OptimalControl
using NLPModelsIpopt
using OrdinaryDiffEqTsit5

ocp = @def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0], (start)
    x(1) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    0.5∫(u(t)^2) → min
end
```

| Exception | What it means | Usual cause |
| :--- | :--- | :--- |
| `IncorrectArgument` | an argument is invalid | a wrong value, size or name, an unknown option |
| `AmbiguousDescription` | a method description matches no known method | a misspelt or unavailable token in `solve(ocp, :token)` |
| `ParsingError` | a `@def` or `@init` block cannot be read | a syntax the macro does not know |
| `PreconditionError` | the arguments are valid, but the call is not allowed now | a value the object does not hold, a call in the wrong order |
| `ExtensionError` | a feature needs a package that is not loaded | `using NLPModelsIpopt`, `Plots`, `OrdinaryDiffEqTsit5`, … missing |
| `SolverFailure` | an integration failed | a trajectory that blows up, a stiff problem |
| `NotImplemented` | a method is missing for this type | an extension point not implemented: please report it |

All of them are subtypes of `OptimalControl.CTException`.

## IncorrectArgument

An option that no strategy of the method knows. The hint lists the closest names:

```@repl errors
solve(ocp; tolerance=1e-8)
```

## AmbiguousDescription

A token that appears in no method of the catalogue (see
[Choosing a method](@ref solve-choosing-a-method)):

```@repl errors
solve(ocp, :ipopt_solver)
```

## ParsingError

A line of `@def` that matches no syntax (see [Abstract syntax](@ref modelling-abstract-syntax)):

```@repl errors
@def begin
    t ∈ [0, 1], time
    x ∈ R, state
    u ∈ R, control
    x(0) == 0
    ẋ(t) == u(t)
    ∫(u(t)^2) → minimise
end
```

## PreconditionError

The solution of a flow carries no multiplier of the boundary conditions (see
[Constrained arcs](@ref flows-constrained-arcs)):

```@repl errors
sol = Flow(ocp, (x, p) -> p[2])((0, 1), [-1, 0], [12, 6]);
dual(sol, ocp, :start)
```

## ExtensionError

The error names the package to load: see [Installation](@ref getting-started-installation)
for an example, and for the packages each feature needs.

## SolverFailure

An integration that fails: here $\dot x = x^2$ from $x(0) = 1$, whose solution blows up at
$t = 1$:

```@repl errors
Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do # hide
Flow(VectorField(x -> x^2))(0, 1.0, 2)
end # hide
```

With `unsafe=true`, the flow returns what it computed instead of raising this error (see
[Shooting](@ref flows-shooting)).

## Catching an error

The exceptions are reached as `OptimalControl.X`, so a script can catch one by its name and
let the others through:

```@example errors
function final_state_or_nothing(x0)
    try
        return Flow(VectorField(x -> x^2))(0, x0, 2)
    catch e
        e isa OptimalControl.SolverFailure || rethrow()
        return nothing
    end
end
Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do # hide
final_state_or_nothing(-1.0), final_state_or_nothing(1.0)
end # hide
```

```@example errors
Base.CoreLogging.with_logger(Base.CoreLogging.NullLogger()) do                  # hide
@assert final_state_or_nothing(1.0) === nothing                                  # hide
@assert isapprox(final_state_or_nothing(-1.0), -1 / 3; atol=1e-6)                # hide
end                                                                              # hide
nothing                                                                          # hide
```

From $x(0) = -1$, the solution is $x(t) = -1/(1 + t)$, so $x(2) = -1/3$; from $x(0) = 1$, the
integration fails and the function returns `nothing`.

## See also

- [Exceptions](https://control-toolbox.org/CTBase.jl/stable/guide/exceptions) in the CTBase
  documentation: the fields of each exception, and how the messages are built.
- [API reference](@ref api-qualified): the exception types.
