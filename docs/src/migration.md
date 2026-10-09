# [Migrating from v2.0](@id migration)

`OptimalControl.jl` v2.1.0-beta reorganised the ecosystem so that every name has exactly one
owner. Most of the changes are mechanical: a `Lie` becomes an `ad`, a `success` becomes a
`successful`, and the old spelling fails with a message naming its replacement. A few changes
are semantic and do **not** announce themselves; they get their own warnings below.

!!! note "The messages need 2.2.0-beta or newer"

    The old spellings stopped working in v2.1.0-beta. The messages that name their
    replacements ([What you get instead of an error](@ref migration-instead-of-error)) came in
    2.2.0-beta. With exactly v2.1.0-beta, the same mistakes give a bare `UndefVarError` or
    `MethodError`.

The full record of the breaking changes, with the reasons, is
[`BREAKING.md`](https://github.com/control-toolbox/OptimalControl.jl/blob/main/BREAKING.md) in
the repository; this page says what to change in a script.

## Start here: `Flow` needs an integrator

This is the most common first failure. The ODE integrators are no longer a dependency of the
package: load one before building a flow.

```julia
using OptimalControl
using OrdinaryDiffEqTsit5   # required before any Flow(...)

f = Flow(ocp, (x, p) -> p[2])
```

Without it, `Flow` fails with an `ExtensionError` that names the package to load. The direct
method, `solve`, does not need it. See [Installation](@ref getting-started-installation) and
[Flows overview](@ref flows-overview).

## What was renamed

| v2.0 | Now | Notes |
| --- | --- | --- |
| `OptimalControl.VectorField`, `OptimalControl.Hamiltonian`, … | `VectorField`, `Hamiltonian`, … | exported; the qualified form still works |
| `Lie(X, f)` | `ad(X, f)` | `Lie` throws, naming `ad` |
| `X ⋅ f` | `ad(X, f)` | no operator; `X ⋅ f` throws, naming `ad`, when `X` is a `VectorField` |
| `HamiltonianLift` | `Lift(f)` to build; `OptimalControl.LiftedHamiltonianFunction` to name the type | renamed **and** re-parented, see [What changed meaning silently](@ref migration-silent) |
| `autonomous=`, `variable=`, `inplace=` (constructor keywords) | `is_autonomous=`, `is_variable=`, `is_inplace=` | on `VectorField`, `Hamiltonian`, `@Lie`, and the other constructors |
| `Flow(f)` with `f::Function` | `Flow(VectorField(f))`, `Flow(Hamiltonian(f))`, `Flow(HamiltonianVectorField(f))` | a function alone does not say which flow to build |
| `Flow(ocp, u, g, μ)` | `Flow(ocp, u; constraint=g, multiplier=μ)` | two keywords, given together |
| `f(t0, x0, p0, tf, λ)`, `f(t0, x0, tf, λ)` | `f(t0, x0, p0, tf; variable=λ)`, `f(t0, x0, tf; variable=λ)` | `variable=` is a keyword, required on a problem with a variable |
| `augment=true` | `variable_costate=true` | returns `(xf, pf, pvf)` |
| `CTSolvers.Modelers.ADNLP()`, `CTDirect.Collocation()` | `OptimalControl.ADNLP()`, `OptimalControl.Collocation()` | the modules `CTSolvers` and `CTDirect` are not exported |
| `time(ocp)`, `time(sol)` | `times(ocp)`, `time_grid(sol)` | `time` is `Base.time` |
| `success(sol)` | `successful(sol)` | `success` is `Base.success` |

## What changed shape

**The flow call.** The variable is passed by keyword, never by position:

```julia
f(t0, x0, p0, tf, λ)                                  # [!code --]
f(t0, x0, p0, tf; augment=true)                       # [!code --]
f(t0, x0, p0, tf; variable=λ)                         # [!code ++]
f(t0, x0, p0, tf; variable=λ, variable_costate=true)  # [!code ++]
```

On a problem with a variable, `variable=` is required: without it, the call throws, saying what
to pass. The call also accepts `unsafe=true`, which does not check the return code of the
integrator: inside a shooting function, a failed integration then shows in the residual
instead of stopping the solver (see [Shooting](@ref flows-shooting)). The integrator options
(`saveat=`, `abstol=`, `reltol=`, `alg=`, …) are no longer accepted by the call. Pass them when
the flow is built:

```julia
f = Flow(ocp, (x, p) -> p[2]; abstol=1e-8)
f(t0, x0, p0, tf)
```

**Constrained flows.** The constraint and the multiplier are keywords, given together:

```julia
fb = Flow(ocp, u, g, μ)                         # [!code --]
fb = Flow(ocp, u; constraint=g, multiplier=μ)   # [!code ++]
```

One without the other is an `IncorrectArgument`. `constraint=` accepts a function, a typed
constraint, or a `Symbol` naming a path constraint of the problem, `constraint=:vmax`. The
`Symbol` form uses the constraint function stored in the problem, without its bound: see the
caveat on [Constrained arcs](@ref flows-constrained-arcs).

**Constructor keywords take an `is_` prefix**, on `VectorField`, `Hamiltonian`, `@Lie`, and the
other constructors:

```julia
VectorField(f; autonomous=false, variable=true)        # [!code --]
@Lie [X, Y] autonomous=false                            # [!code --]
VectorField(f; is_autonomous=false, is_variable=true)   # [!code ++]
@Lie [X, Y] is_autonomous=false                         # [!code ++]
```

The old keyword on `@Lie` raises an `IncorrectArgument` that lists the accepted keywords. On
`VectorField` and `Hamiltonian`, it raises a `MethodError`, "got unsupported keyword argument".

## [What changed meaning silently](@id migration-silent)

Three changes do not raise an error.

!!! warning "`Lift(f::Function)` is no longer an `AbstractHamiltonian`"

    In v2.0, lifting a plain function and lifting a `VectorField` gave the same kind of object.
    Now, the lift of a function is a function, `OptimalControl.LiftedHamiltonianFunction`:

    ```julia
    H = Lift(f)                  # f::Function
    H isa AbstractHamiltonian    # false now, true in v2.0
    ```

    A test `isa AbstractHamiltonian` on it is now false. The lift of a `VectorField` is still a
    `Hamiltonian`. See [Lift](@ref geometry-lift).

!!! warning "`OpenLoop` checks the arity of the law when the flow runs"

    An open-loop control is a function of time, `u(t)`, or `u(t, v)` with a variable. A
    function without argument is accepted when the law is built, and fails only when the flow
    runs, with a `MethodError` far from the mistake
    ([CTBase#570](https://github.com/control-toolbox/CTBase.jl/issues/570)):

    ```julia
    bad_law = OpenLoop(() -> 1.0)                          # accepted
    Flow(ControlledVectorField(fc), bad_law)(t0, x0, tf)   # MethodError here  [!code error]
    ```

    See [Simulation](@ref flows-simulation).

!!! warning "The old state-flow call runs on a flow with a costate"

    In v2.0, a flow of the state was called `f(t0, x0, tf, λ)`, with the variable $\lambda$ in
    the 4th position. The flow of a problem without a variable is called
    `f(t0, x0, p0, tf)`, also with four arguments. Called the old way, it **runs**, with the
    arguments shifted: `tf` is taken as `p0`, and `λ` as `tf`.

    ```julia
    f(t0, x0, tf, λ)   # runs as f(t0, x0, p0=tf, tf=λ)  [!code warning]
    ```

    It fails only when the shapes do not match. Check these calls by hand.

## [What you get instead of an error](@id migration-instead-of-error)

The removed spellings throw a `PreconditionError` naming their replacement. With a problem
`ocp` with a variable, its solution `sol`, a vector field `X` and a function `f`:

```@setup migration
using OptimalControl
using OrdinaryDiffEqTsit5
using NLPModelsIpopt

ocp = @def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    tf ≥ 0
    x(0) == [-1, 0]
    x(tf) == [0, 0]
    ẋ(t) == [v(t), u(t)]
    tf → min
end
sol = solve(ocp; display=false)

X = VectorField(x -> [x[2], -x[1]])
f(x) = x[1]^2

t0, x0, p0, tf, λ = 0, [-1.0, 0.0], [1.0, 1.0], 1.0, 2.0
fh = Flow(ocp, (x, p, v) -> 1)                                 # a flow of the problem
fs = Flow(VectorField((x, v) -> -v * x; is_variable=true))     # a flow of the state, with a variable
g(x, u, v) = x[1]
μ(x, p, v) = 0
```

```@repl migration
try # hide
Lie(X, f)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
X ⋅ f
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
HamiltonianLift(f)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
time(ocp)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
time(sol)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
success(sol)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
Flow(f)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
Flow(ocp, (x, p, v) -> 0, g, μ)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

On the flow `fh` of the problem, and on the flow `fs` of a state with a variable:

```@repl migration
try # hide
fh(t0, x0, p0, tf, λ)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
fs(t0, 1.0, tf, λ)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

```@repl migration
try # hide
fh(t0, x0, p0, tf; variable=λ, augment=true)
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
```

`X ⋅ f` is caught when `X` is a `VectorField`. With a plain function `X`, as in v2.0, it raises
a `MethodError` about `iterate`.

## What raises another error

| Spelling | What happens | Write instead |
| --- | --- | --- |
| `f(t0, x0, p0, tf; saveat=…)`, and the other integrator options on a call | `MethodError`, "unsupported keyword argument" | `Flow(…; saveat=…)`, when the flow is built |
| `CTSolvers.Modelers.ADNLP()`, `CTDirect.Collocation()` | `UndefVarError` on `CTSolvers` or `CTDirect` | `OptimalControl.ADNLP()`, `OptimalControl.Collocation()` |
| `@Lie [X, Y] autonomous=false` | `IncorrectArgument`, with the accepted keywords | `@Lie [X, Y] is_autonomous=false` |
| `VectorField(f; autonomous=false)`, `Hamiltonian(h; variable=true)` | `MethodError`, "unsupported keyword argument" | `is_autonomous=`, `is_variable=` |

## Initial guesses as named tuples

[`@init`](@ref solve-initial-guess) is the recommended way to write an initial guess. The
named tuple of v2.0 still works, with the fields `state`, `control` and `variable` (see
[Initial guess](@ref solve-initial-guess)), and also with the labels of the components:

```julia
sol = solve(ocp; init=(state=[-0.2, 0.1], control=-0.2))
sol = solve(ocp; init=(q=-1.0, v=0.0, u=0.1, tf=2.0))
```

`@init` checks the labels against the problem. In both forms, the costate and the multipliers
cannot be given a guess.

## From v1.x to v2.0

For the older migration from v1.x to v2.0 (the direct-mode API, option routing, the methods),
see the second section of
[`BREAKING.md`](https://github.com/control-toolbox/OptimalControl.jl/blob/main/BREAKING.md#breaking-changes-v1x--v20).
