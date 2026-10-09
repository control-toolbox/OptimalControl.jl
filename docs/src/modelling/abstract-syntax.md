# [Abstract syntax (`@def`)](@id modelling-abstract-syntax)

The full grammar of OptimalControl.jl's small *Domain Specific Language* is given below. The idea is to use a syntax that is

- pure Julia (and, as such, effortlessly analysed by the standard Julia parser),
- as close as possible to the mathematical description of an optimal control problem (see [Formulation](@ref modelling-formulation)).

While the syntax will be transparent to those users familiar with Julia expressions (`Expr`s), we provide examples for every case that should be widely understandable. Abstract definitions use the macro [`@def`](@ref).

!!! note "About the code blocks on this page"
    Blocks written `:( … )` — such as the state pattern `:( $x ∈ R^$n, state )` — are
    **grammar patterns**: the shape of the Julia expression the parser accepts, with the
    `$`-prefixed names standing for the parts you supply. They are notation, not runnable
    code, and are shown inert on purpose.

    Every other block is executed when the documentation is built. A problem definition must
    include at least time, state, dynamics and cost (the control declaration is optional —
    see [Problems without a control](@ref modelling-abstract-syntax-control-free)); in the
    blocks that illustrate a single clause, the other required clauses are present but hidden
    so that the block still builds a complete model.

```@setup abs
using OptimalControl
using Logging: with_logger, ConsoleLogger
# show warnings without the source location (a local package path)
quiet_location(f) = with_logger(f, ConsoleLogger(stderr; meta_formatter=(level, args...) -> (:yellow, "Warning:", "")))
data(t) = 2exp(0.5t)   # observed-data stub (parameter estimation)
c(t) = 1.0             # damping coefficient (damped integrator)
```

## [Structure of a definition](@id modelling-abstract-syntax-structure)

A definition is a `begin … end` block passed to `@def`:

- **Declarations come first:** the variable (if any), the time, the state, and the control (if
  any), preferably in this order. The variable must come before the time when the time bounds
  use it, as in `t ∈ [0, tf], time`.
- **Then, in any order:** the dynamics, the constraints and the cost.
- **Two equivalent forms:** `ocp = @def begin … end` and `@def ocp begin … end` both bind the
  model to `ocp`. The second form also accepts a trailing `true` that turns on the
  [trace mode](@ref modelling-abstract-syntax-aliases).
- **When names are read:** constants used in the declarations or in the bounds of a
  constraint (`t0`, `tf`, `x0`, …) are read when the model is built, so they must be defined
  *before* the block. Functions called in the dynamics, the constraints or the cost are only
  called when these are evaluated (during `solve`), so they may be defined after the block.

The symbols have plain ASCII alternatives:

| Unicode | ASCII |
| --- | --- |
| `t ∈ [0, 1]` | `t in [0, 1]` |
| `R²` | `R^2` |
| `ẋ(t)`, `∂(x)(t)` | `derivative(x)(t)` |
| `∫(…)` | `integral(…)` |
| `≤`, `≥` | `<=`, `>=` |
| `→ min` | `=> min` |

## [Variable](@id modelling-abstract-syntax-variable)

```julia
:( $v ∈ R^$q, variable )
:( $v ∈ R   , variable )
```

A variable (only one is allowed) is a finite dimensional vector of reals that will be *optimised* along with state and control values. To define an optimal control problem with a dimension-two variable named `v`:

```@example abs
@def begin
    t ∈ [0, 1], time            # hide
    x ∈ R, state                # hide
    v ∈ R², variable
    ẋ(t) == v₁ * x(t) + v₂      # hide
    ∫(x(t)^2) → min             # hide
end
nothing # hide
```

Aliases `v₁`, `v₂` (and `v1`, `v2`) are automatically defined and can be used in subsequent expressions instead of `v[1]` and `v[2]`. You can also define your own aliases for the components (one alias per dimension):

```@example abs
@def begin
    t ∈ [0, 1], time            # hide
    x ∈ R, state                # hide
    v = (a, b) ∈ R², variable
    ẋ(t) == a * x(t) + b        # hide
    ∫(x(t)^2) → min             # hide
end
nothing # hide
```

A one dimensional variable can be declared according to

```@example abs
@def begin
    t ∈ [0, 1], time            # hide
    x ∈ R, state                # hide
    v ∈ R, variable
    ẋ(t) == v * x(t)            # hide
    ∫(x(t)^2) → min             # hide
end
nothing # hide
```

!!! warning
    Aliases during definition of variable, state or control are only allowed for multidimensional (dimension two or more) cases. Something like `u = T ∈ R, control` is not allowed... and useless (directly write `T ∈ R, control`).

## Time

```julia
:( $t ∈ [$t0, $tf], time )
```

The independent variable or *time* is a scalar bound to a given interval. Its name is arbitrary.

```@example abs
t0 = 1
tf = 5
@def begin
    t ∈ [t0, tf], time
    x ∈ R, state                # hide
    u ∈ R, control              # hide
    ẋ(t) == u(t)                # hide
    ∫(x(t)^2 + u(t)^2) → min    # hide
end
nothing # hide
```

One bound (or both) can be variable, typically for minimum time problems (see [Mayer cost](@ref modelling-abstract-syntax-mayer) section):

```@example abs
@def begin
    v = (T, λ) ∈ R², variable
    t ∈ [0, T], time
    x ∈ R, state                # hide
    ẋ(t) == λ * x(t)            # hide
    T → min                     # hide
end
nothing # hide
```

## [State](@id modelling-abstract-syntax-state)

```julia
:( $x ∈ R^$n, state )
:( $x ∈ R   , state )
```

The state declaration defines the name and the dimension of the state:

```@example abs
@def begin
    t ∈ [0, 1], time                       # hide
    x ∈ R⁴, state
    u ∈ R, control                         # hide
    ẋ(t) == [x₂(t), x₃(t), x₄(t), u(t)]    # hide
    ∫(u(t)^2) → min                        # hide
end
nothing # hide
```

As for the variable, there are automatic aliases (`x₁` and `x1` for `x[1]`, *etc.*) and you can define your own aliases (one per scalar component of the state):

```@example abs
@def begin
    t ∈ [0, 1], time                        # hide
    x = (q₁, q₂, v₁, v₂) ∈ R⁴, state
    u ∈ R², control                         # hide
    ẋ(t) == [v₁(t), v₂(t), u₁(t), u₂(t)]    # hide
    ∫(u₁(t)^2 + u₂(t)^2) → min              # hide
end
nothing # hide
```

## [Control](@id modelling-abstract-syntax-control)

```julia
:( $u ∈ R^$m, control )
:( $u ∈ R   , control )
```

The control declaration defines the name and the dimension of the control:

```@example abs
@def begin
    t ∈ [0, 1], time                # hide
    x ∈ R², state                   # hide
    u ∈ R², control
    ẋ(t) == u(t)                    # hide
    ∫(u₁(t)^2 + u₂(t)^2) → min      # hide
end
nothing # hide
```

As before, there are automatic aliases (`u₁` and `u1` for `u[1]`, *etc.*) and you can define your own aliases (one per scalar component of the control):

```@example abs
@def begin
    t ∈ [0, 1], time                # hide
    x ∈ R², state                   # hide
    u = (α, β) ∈ R², control
    ẋ(t) == [α(t), β(t)]            # hide
    ∫(α(t)^2 + β(t)^2) → min        # hide
end
nothing # hide
```

!!! note "1-D is a scalar"
    A one-dimensional variable, state or control is treated as a scalar (`Real`), not a vector (`Vector`). In Julia, for `x::Real`, it is possible to write `x[1]` (and `x[1][1]`...) so it is OK (though useless) to write `x₁`, `x1` or `x[1]` instead of simply `x` to access the corresponding value. Conversely it is *not* OK to use such an `x` as a vector, for instance as in `...f(x)...` where `f(x::Vector{T}) where {T <: Real}`. This same convention applies on the [functional API](@ref modelling-functional-api): a dimension-1 quantity is a scalar, not a length-1 vector — see [Shapes in callbacks](@ref modelling-functional-api-shapes).

## [Problems without a control](@id modelling-abstract-syntax-control-free)

The control declaration is **optional**. You can define problems without control for:

- **Parameter estimation**: identify unknown parameters in the dynamics from observed data,
- **Dynamic optimisation**: optimise constant parameters subject to ODE constraints.

For example, to estimate a growth rate parameter (here `data` is the observed signal, a
function defined beforehand):

```@example abs
@def begin
    p ∈ R, variable                 # parameter to estimate
    t ∈ [0, 10], time
    x ∈ R, state
    x(0) == 2.0
    ẋ(t) == p * x(t)                # dynamics depends on p
    ∫((x(t) - data(t))^2) → min     # fit to observed data
end
nothing # hide
```

Or to optimise the pulsation of a harmonic oscillator:

```@example abs
@def begin
    ω ∈ R, variable                 # pulsation to optimise
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    q(0) == 1.0
    v(0) == 0.0
    q(1) == 0.0                     # final condition
    ẋ(t) == [v(t), -ω^2 * q(t)]     # harmonic oscillator
    ω^2 → min                       # minimise pulsation
end
nothing # hide
```

There is no dedicated syntax for "no control": omitting the control declaration entirely *is*
the syntax — do not declare a dummy `u ∈ R, control` with `u(t) == 0`, and never write
`control!(pre, 0)` on the [functional API](@ref modelling-functional-api), which is rejected
as an error. See [No control](@ref modelling-without-control) for the full
worked examples above, solved both directly and indirectly.

## [Dynamics](@id modelling-abstract-syntax-dynamics)

```julia
:( ∂($x)($t) == $e1 )
```

The dynamics is given in the standard vectorial ODE form:

```math
    \dot{x}(t) = f([t, ]x(t)[, u(t)][, v])
```

depending on whether it is autonomous / with a variable or not (the parser will detect time and variable dependences,
which entails that time, state and variable must be declared prior to dynamics - an error will be issued otherwise). The symbol `∂`, or the dotted state name
(`ẋ`), or the keyword `derivative` can be used:

```@example abs
@def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ∂(x)(t) == [x₂(t), u(t)]
    ∫(u(t)^2) → min
end
nothing # hide
```

or

```@example abs
@def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ẋ(t) == [x₂(t), u(t)]
    ∫(u(t)^2) → min
end
nothing # hide
```

or

```@example abs
@def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    derivative(x)(t) == [x₂(t), u(t)]
    ∫(u(t)^2) → min
end
nothing # hide
```

Any Julia code can be used, so the following is also OK:

```@example abs
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ẋ(t) == F₀(x(t)) + u(t) * F₁(x(t))
    ∫(u(t)^2) → min
end

F₀(x) = [x[2], 0]
F₁(x) = [0, 1]
nothing # hide
```

!!! note
    The vector fields `F₀` and `F₁` are defined after the block: functions are only called when the dynamics is evaluated, during `solve` (see [Structure of a definition](@ref modelling-abstract-syntax-structure)).

!!! warning "A constant component"
    With the default modeler `:adnlp`, a component of the dynamics that is a constant, such as the `0` in `ẋ(t) == [x₂(t), u(t), 0]`, makes `solve` fail with "Cannot determine ordering of Dual tags" ([OptimalControl#481](https://github.com/control-toolbox/OptimalControl.jl/issues/481)). Write `0 * u(t)` instead, or solve with `:exa`.

While it is also possible to declare the dynamics component after component (see below), one may equivalently use *aliases* (check the relevant [aliases](@ref modelling-abstract-syntax-aliases) section below):

```@example abs
@def damped_integrator begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    q̇ = v(t)
    v̇ = u(t) - c(t) * v(t)
    ẋ(t) == [q̇, v̇]
    ∫(u(t)^2) → min
end
nothing # hide
```

## [Dynamics (coordinatewise)](@id modelling-abstract-syntax-dynamics-coord)

```julia
:( ∂($x[$i])($t) == $e1 )
```

The dynamics can also be declared coordinate by coordinate. The previous example can be written as

```@example abs
@def damped_integrator begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    ∂(q)(t) == v(t)
    ∂(v)(t) == u(t) - c(t) * v(t)
    ∫(u(t)^2) → min
end
nothing # hide
```

## [Constraints](@id modelling-abstract-syntax-constraints)

```julia
:( $e1 == $e2        )
:( $e1 ≤  $e2 ≤  $e3 )
:(        $e2 ≤  $e3 )
:( $e3 ≥  $e2 ≥  $e1 )
:( $e2 ≥  $e1        )
```

Admissible constraints can be

- of five types: boundary, variable, control, state, mixed (the last three are *path* constraints, that is, constraints evaluated at all times);
- box constraints (a range on a single component, such as `x₂(t) ≤ 1`) or general ones (any expression, such as `u(t)^2`);
- equalities or (one- or two-sided) inequalities.

Boundary conditions are detected when the expression contains evaluations of the state at initial and / or final time bounds (*e.g.*, `x(0)`), and may not involve the control. Conversely control, state or mixed constraints will involve control, state or both evaluated at the declared time (*e.g.*, `x(t) + u(t)`).
Other combinations should be detected as incorrect by the parser. The variable may be involved in any of the four previous constraints. Constraints involving the variable only are variable constraints, either linear or nonlinear.
In the example below, there are

- two boundary constraints,
- one box constraint on the variable,
- one box constraint on the state,
- one (two-sided) general control constraint.

```@example abs
@def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(tf) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    tf ≥ 0
    x₂(t) ≤ 1
    0.1 ≤ u(t)^2 ≤ 1
    tf → min
end
nothing # hide
```

!!! note "Duplicate box constraints"
    If the same scalar component of the state, control or variable appears in several **box** constraints (linear range constraints), the effective bounds are the **intersection** of all declared bounds: the effective lower bound is the maximum of declared lower bounds, and the effective upper bound is the minimum of declared upper bounds. A warning is emitted, and an error is thrown if the resulting interval is empty. See [Duplicate box constraints](@ref modelling-abstract-syntax-box-dedup) below.

!!! note
    Symbols like `<=` or `>=` are also authorised:

    ```@example abs
    @def begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [-1, 0]
        x(tf) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        tf >= 0
        x₂(t) <= 1
        0.1 ≤ u(t)^2 <= 1
        tf → min
    end
    nothing # hide
    ```

!!! warning
    Write either `u(t)^2` or `(u^2)(t)`, not `u^2(t)` since in Julia the latter means `u^(2t)`. Moreover,
    in the case of equalities or of one-sided inequalities, the control and / or the state must belong to the *left-hand side*. The following errors (the example quoted in the message is generic, see [CTParser#352](https://github.com/control-toolbox/CTParser.jl/issues/352); here, write `x₂(t) ≥ 1`):

    ```@repl abs
    try # hide
    @def begin
        t ∈ [0, 2], time
        x ∈ R², state
        u ∈ R, control
        x(0) == [-1, 0]
        x(2) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        1 ≤ x₂(t)
        -1 ≤ u(t) ≤ 1
    end
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

!!! warning
    A constraint *bound* must be constant — it may not depend on the variable, the state, the control or the time. The following is rejected, with a message naming the cause:

    ```@repl abs
    try # hide
    @def begin
        v ∈ R, variable
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ v ≤ 1
        x₁(0) == -1
        x₂(0) == v # wrong: the bound v depends on the variable
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(0.5u(t)^2) → min
    end
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

    Write instead a boundary constraint, moving the term to the constrained side — that side *may* involve the variable:

    ```@example abs
    @def begin
        v ∈ R, variable
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ v ≤ 1
        x₁(0) == -1
        x₂(0) - v == 0 # OK: this side may involve the variable
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(0.5u(t)^2) → min
    end
    nothing # hide
    ```

### [Duplicate box constraints](@id modelling-abstract-syntax-box-dedup)

**Box constraints** are linear range constraints on a single scalar component of the state, control or variable — that is, constraints of the form `lb ≤ x_i(t) ≤ ub`, `u_i(t) ≤ ub`, `v_i ≥ lb`, etc. (nonlinear path constraints are *not* concerned by this section).

When the **same scalar component** is targeted by several box-constraint declarations, OptimalControl does **not** keep them as separate constraints. Instead, it merges them by taking the **intersection** of all declared bounds:

- the effective lower bound is `max` of all declared lower bounds,
- the effective upper bound is `min` of all declared upper bounds,
- a single `@warn` is emitted per duplicated component, listing every contributing label,
- all labels that declared the component are preserved as **aliases** (accessible via the `aliases` field of [`state_constraints_box`](@ref), [`control_constraints_box`](@ref) and [`variable_constraints_box`](@ref); see [Inspect a problem](@ref modelling-inspect)),
- if the intersection is empty (`max(lbs) > min(ubs)`), an `IncorrectArgument` exception is thrown.

For instance,

```@example abs
quiet_location() do # hide
@def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    0 ≤ q(t) ≤ 2, (q_wide)
    1 ≤ q(t) ≤ 3, (q_tight)
    ẋ(t) == [v(t), u(t)]
    ∫(u(t)^2) → min
end
end # hide
nothing # hide
```

yields the effective constraint `1 ≤ q(t) ≤ 2`, with `aliases = [:q_wide, :q_tight]` for that component, and a warning reporting both labels.

Conversely, the following declares an empty feasible set and raises an error at build time:

```@repl abs
quiet_location() do # hide
try # hide
@def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    0 ≤ q(t) ≤ 1, (low)
    2 ≤ q(t) ≤ 3, (high) # max(lbs)=2 > min(ubs)=1 ⇒ IncorrectArgument
    ẋ(t) == [v(t), u(t)]
    ∫(u(t)^2) → min
end
catch e # hide
showerror(IOContext(stdout, :color => false), e) # hide
end # hide
end # hide
```

## [Mayer cost](@id modelling-abstract-syntax-mayer)

```julia
:( $e1 → min )
:( $e1 → max )
```

Mayer costs are defined in a similar way to boundary conditions and follow the same rules. The symbol `→` is used
to denote minimisation or maximisation, the latter being treated by minimising the opposite cost. (The symbol `=>` can also be used.)

```@repl abs
@def begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0
    -1 ≤ u(t) ≤ 1
    q(0) == 1
    v(0) == 2
    q(tf) == 0
    v(tf) == 0
    0 ≤ q(t) ≤ 5
   -2 ≤ v(t) ≤ 3
    ẋ(t) == [v(t), u(t)]
    tf → min
end
```

## Lagrange cost

```julia
:(       ∫($e1) → min )
:(     - ∫($e1) → min )
:( $e1 * ∫($e2) → min )
:(       ∫($e1) → max )
:(     - ∫($e1) → max )
:( $e1 * ∫($e2) → max )
```

Lagrange (integral) costs are defined using the symbol `∫`, *with parentheses*. The keyword `integral` can also be used:

```@example abs
@def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    ẋ(t) == [v(t), u(t)]           # hide
    0.5∫(q(t) + u(t)^2) → min
end
nothing # hide
```

or

```@example abs
@def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    ẋ(t) == [v(t), u(t)]                  # hide
    0.5integral(q(t) + u(t)^2) → min
end
nothing # hide
```

The integration range is implicitly equal to the time range, so the cost above is to be understood as

```math
\frac{1}{2} \int_0^1 \left( q(t) + u^2(t) \right) \mathrm{d}t \to \min.
```

As for the dynamics, the parser will detect whether the integrand depends or not on time (autonomous / non-autonomous case).

## Bolza cost

```julia
:( $e1 +       ∫($e2)       → min )
:( $e1 + $e2 * ∫($e3)       → min )
:( $e1 -       ∫($e2)       → min )
:( $e1 - $e2 * ∫($e3)       → min )
:( $e1 +       ∫($e2)       → max )
:( $e1 + $e2 * ∫($e3)       → max )
:( $e1 -       ∫($e2)       → max )
:( $e1 - $e2 * ∫($e3)       → max )
:(             ∫($e2) + $e1 → min )
:(       $e2 * ∫($e3) + $e1 → min )
:(             ∫($e2) - $e1 → min )
:(       $e2 * ∫($e3) - $e1 → min )
:(             ∫($e2) + $e1 → max )
:(       $e2 * ∫($e3) + $e1 → max )
:(             ∫($e2) - $e1 → max )
:(       $e2 * ∫($e3) - $e1 → max )
```

Quite readily, Mayer and Lagrange costs can be combined into general Bolza costs. For instance as follows:

```@example abs
@def begin
    p = (t0, tf) ∈ R², variable
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    ẋ(t) == [v(t), u(t)]                    # hide
    (tf - t0) + 0.5∫(c(t) * u(t)^2) → min
end
nothing # hide
```

!!! warning
    The expression must be the sum of two terms (plus, possibly, a scalar factor before the integral), not *more*, so mind the parentheses. For instance, the following errors:

    ```@repl abs
    try # hide
    @def begin
        p = (t0, tf) ∈ R², variable
        t ∈ [t0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        ẋ(t) == [v(t), u(t)]
        (tf - t0) + q(tf) + 0.5∫(c(t) * u(t)^2) → min
    end
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

    The correct syntax is

    ```@example abs
    @def begin
        p = (t0, tf) ∈ R², variable
        t ∈ [t0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        ẋ(t) == [v(t), u(t)]
        ((tf - t0) + q(tf)) + 0.5∫(c(t) * u(t)^2) → min
    end
    nothing # hide
    ```

## [Aliases](@id modelling-abstract-syntax-aliases)

```julia
:( $a = $e1 )
```

The single `=` symbol is used to define not a constraint but an alias, that is, a purely syntactic replacement. There are some automatic aliases, *e.g.* `x₁` and `x1` for `x[1]` if `x` is the state (same for variable and control, for indices between 1 and 9), and we have also seen that you can define your own aliases when declaring the [variable](@ref modelling-abstract-syntax-variable), [state](@ref modelling-abstract-syntax-state) and [control](@ref modelling-abstract-syntax-control). Arbitrary aliases can be further defined, as below (compare with previous examples in the [dynamics](@ref modelling-abstract-syntax-dynamics) section):

```@example abs
@def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    F₀ = [x₂(t), 0]
    F₁ = [0, 1]
    ẋ(t) == F₀ + u(t) * F₁
    ∫(u(t)^2) → min
end
nothing # hide
```

!!! warning
    Such aliases do *not* define any additional function and are just replaced textually by the parser. In particular, they cannot be used outside the `@def` `begin ... end` block. Conversely, the constants and functions used within the block are ordinary Julia names, defined outside it (see [Structure of a definition](@ref modelling-abstract-syntax-structure) for when).

!!! hint
    You can rely on a trace mode for the macro `@def` to look at your code after expansions of the aliases using the `@def ocp ...` syntax and adding `true` after your `begin ... end` block. The trace still shows some internal names, such as `var"u##…"[1]` for `u` ([CTParser#354](https://github.com/control-toolbox/CTParser.jl/issues/354)):

    ```@repl abs
    @def damped_integrator begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        q̇ = v(t)
        v̇ = u(t) - c(t) * v(t)
        ẋ(t) == [q̇, v̇]
        ∫(u(t)^2) → min
    end true;
    ```

!!! warning
    The dynamics of an OCP is a constraint: use `==`, not a single `=`, which would try to define an alias. The error does not say so explicitly yet ([CTParser#353](https://github.com/control-toolbox/CTParser.jl/issues/353)):

    ```@repl abs
    try # hide
    double_integrator = @def begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        q̇ = v
        v̇ = u
        ẋ(t) = [q̇, v̇]
    end
    catch e # hide
    showerror(IOContext(stdout, :color => false), e) # hide
    end # hide
    ```

## [Labels](@id modelling-abstract-syntax-labels)

A constraint can carry a label, written after a comma, as in a numbered equation. A label
names the constraint, for instance to retrieve its multiplier with
[`dual(sol, ocp, :label)`](@ref results-solution-duals). A number `(1)` is stored as the
label `:eq1`:

```@example abs
@def damped_integrator begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0, (1)
    q(0) == 2, (♡)
    q̇ = v(t)
    v̇ = u(t) - c(t) * v(t)
    ẋ(t) == [q̇, v̇]
    x(t).^2  ≤ [1, 2], (state_con)
    ∫(u(t)^2) → min
end
nothing # hide
```

Here the labels are `:eq1`, `:♡` and `:state_con`.

Parsing errors report the line of the `begin … end` block where they occur. For complete
problems written with this syntax, see the [example gallery](@ref examples-gallery).

## See also

- [Formulation](@ref modelling-formulation) — the mathematics this syntax encodes.
- [Functional API](@ref modelling-functional-api) — build the same model without the macro.
- [No control](@ref modelling-without-control) — the control-free case, worked in full.
- [Inspect a problem](@ref modelling-inspect) — read a built model back.
