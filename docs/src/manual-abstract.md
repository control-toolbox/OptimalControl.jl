# [The syntax to define an optimal control problem](@id manual-abstract-syntax)

The full grammar of [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) small *Domain Specific Language* is given below. The idea is to use a syntax that is

- pure Julia (and, as such, effortlessly analysed by the standard Julia parser),
- as close as possible to the mathematical description of an optimal control problem. 

While the syntax will be transparent to those users familiar with Julia expressions (`Expr`'s), we provide examples for every case that should be widely understandable. We rely heavily on [MLStyle.jl](https://thautwarm.github.io/MLStyle.jl) and its pattern matching abilities 👍🏽 both for the syntactic and semantic pass. Abstract definitions use the macro [`@def`](@ref).

## [Variable](@id manual-abstract-variable)

```julia
:( $v ∈ R^$q, variable ) 
:( $v ∈ R   , variable ) 
```

A variable (only one is allowed) is a finite dimensional vector or reals that will be *optimised* along with state and control values. To define an (almost empty!) optimal control problem, named `ocp`, having a dimension two variable named `v`, do the following:

```julia
@def begin
    v ∈ R², variable
    ...
end
```

!!! warning
    - Note that the full code of the definition above is not provided (hence the `...`) The same is true for most examples below (only those without `...` are indeed complete).
    - Also note that problem definitions must at least include definitions for time, state, dynamics and cost. The control declaration is optional (see [Control-free problems](@ref manual-abstract-control-free)).

Aliases `v₁`, `v₂` (and `v1`, `v2`) are automatically defined and can be used in subsequent expressions instead of `v[1]` and `v[2]`. The user can also define her own aliases for the components (one alias per dimension):

```julia
@def begin
    v = (a, b) ∈ R², variable
    ...
end
```

A one dimensional variable can be declared according to

```julia
@def begin
    v ∈ R, variable
    ...
end
```

!!! warning
    Aliases during definition of variable, state or control are only allowed for multidimensional (dimension two or more) cases. Something like `u = T ∈ R, control` is not allowed... and useless (directly write `T ∈ R, control`).

## Time

```julia
:( $t ∈ [$t0, $tf], time ) 
```

The independent variable or *time* is a scalar bound to a given interval. Its name is arbitrary.

```julia
t0 = 1
tf = 5
@def begin
    t ∈ [t0, tf], time
    ...
end
```

One (or even the two bounds) can be variable, typically for minimum time problems (see [Mayer cost](@ref manual-abstract-mayer) section):

```julia
@def begin
    v = (T, λ) ∈ R², variable
    t ∈ [0, T], time
    ...
end
```

## [State](@id manual-abstract-state)

```julia
:( $x ∈ R^$n, state ) 
:( $x ∈ R   , state ) 
```

The state declaration defines the name and the dimension of the state:

```julia
@def begin
    x ∈ R⁴, state
    ...
end
```

As for the variable, there are automatic aliases (`x₁` and `x1` for `x[1]`, *etc.*) and the user can define her own aliases (one per scalar component of the state):

```julia
@def begin
    x = (q₁, q₂, v₁, v₂) ∈ R⁴, state
    ...
end
```

## [Control](@id manual-abstract-control)

```julia
:( $u ∈ R^$m, control ) 
:( $u ∈ R   , control ) 
```

The control declaration defines the name and the dimension of the control:

```julia
@def begin
    u ∈ R², control
    ...
end
```

As before, there are automatic aliases (`u₁` and `u1` for `u[1]`, *etc.*) and the user can define her own aliases (one per scalar component of the state):

```julia
@def begin
    u = (α, β) ∈ R², control
    ...
end
```

!!! note
    One dimensional variable, state or control are treated as scalars (`Real`), not vectors (`Vector`). In Julia, for `x::Real`, it is possible to write `x[1]` (and `x[1][1]`...) so it is OK (though useless) to write `x₁`, `x1` or `x[1]` instead of simply `x` to access the corresponding value. Conversely it is *not* OK to use such an `x` as a vector, for instance as in `...f(x)...` where `f(x::Vector{T}) where {T <: Real}`.

## [Control-free problems](@id manual-abstract-control-free)

The control declaration is **optional**. You can define problems without control for:

- **Parameter estimation**: Identify unknown parameters in the dynamics from observed data
- **Dynamic optimization**: Optimize constant parameters subject to ODE constraints

For example, to estimate a growth rate parameter:

```julia
@def begin
    p ∈ R, variable              # parameter to estimate
    t ∈ [0, 10], time
    x ∈ R, state
    x(0) == 2.0
    ẋ(t) == p * x(t)             # dynamics depends on p
    ∫(x(t) - data(t))² → min     # fit to observed data
end
```

Or to optimize the pulsation of a harmonic oscillator:

```julia
@def begin
    ω ∈ R, variable              # pulsation to optimize
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    q(0) == 1.0
    v(0) == 0.0
    q(1) == 0.0                  # final condition
    ẋ(t) == [v(t), -ω²*q(t)]    # harmonic oscillator
    ω² → min                     # minimize pulsation
end
```

!!! compat "Upcoming feature"

    Control-free problem syntax (omitting the control declaration) is currently being implemented. For now, use a dummy control with `u ∈ R, control` and `u(t) == 0` as a workaround. See the [Control-free problems example](@ref example-control-free) for executable examples.

## [Dynamics](@id manual-abstract-dynamics)

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

```julia
@def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ∂(x)(t) == [x₂(t), u(t)]
    ...
end
```

or

```julia
@def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ẋ(t) == [x₂(t), u(t)]
    ...
end
```

or

```julia
@def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    derivative(x)(t) == [x₂(t), u(t)]
    ...
end
```

Any Julia code can be used, so the following is also OK:

```julia
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ẋ(t) == F₀(x(t)) + u(t) * F₁(x(t))
    ...
end

F₀(x) = [x[2], 0]
F₁(x) = [0, 1]
```

!!! note
    The vector fields `F₀` and `F₁` can be defined afterwards, as they only need to be available when the dynamics will be evaluated.

While it is also possible to declare the dynamics component after component (see below), one may equivalently use *aliases* (check the relevant [aliases](@ref manual-abstract-aliases) section below):

```julia
@def damped_integrator begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    q̇ = v(t)
    v̇ = u(t) - c(t)
    ẋ(t) == [q̇, v̇]
    ...
end
```

## [Dynamics (coordinatewise)](@id manual-abstract-dynamics-coord)

```julia
:( ∂($x[$i])($t) == $e1 ) 
```

The dynamics can also be declared coordinate by coordinate. The previous example can be written as

```julia
@def damped_integrator begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    ∂(q)(t) == v(t)
    ∂(v)(t) == u(t) - c(t)
    ...
end
```

## [Constraints](@id manual-abstract-constraints)

```julia
:( $e1 == $e2        ) 
:( $e1 ≤  $e2 ≤  $e3 ) 
:(        $e2 ≤  $e3 ) 
:( $e3 ≥  $e2 ≥  $e1 ) 
:( $e2 ≥  $e1        ) 
```

Admissible constraints can be

- of five types: boundary, variable, control, state, mixed (the last three ones are *path* constraints, that is constraints evaluated all times)
- linear (ranges) or nonlinear (not ranges),
- equalities or (one or two-sided) inequalities.

Boundary conditions are detected when the expression contains evaluations of the state at initial and / or final time bounds (*e.g.*, `x(0)`), and may not involve the control. Conversely control, state or mixed constraints will involve control, state or both evaluated at the declared time (*e.g.*, `x(t) + u(t)`).
Other combinations should be detected as incorrect by the parser 🤞🏾. The variable may be involved in any of the four previous constraints. Constraints involving the variable only are variable constraints, either linear or nonlinear.
In the example below, there are

- two linear boundary constraints,
- one linear variable constraint,
- one linear state constraint,
- one (two-sided) nonlinear control constraint.

```julia
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
    ...
end
```

!!! note
    Symbols like `<=` or `>=` are also authorised:

```julia
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
    ...
end
```

!!! warning
    Write either `u(t)^2` or `(u^2)(t)`, not `u^2(t)` since in Julia the latter means `u^(2t)`. Moreover,
    in the case of equalities or of one-sided inequalities, the control and / or the state must belong to the *left-hand side*. The following will error:

    ```@setup main-repl
    using OptimalControl
    ```

    ```@repl main-repl
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
    ```

!!! warning
    Constraint bounds must be *effective*, that is must not depend on a variable. For instance, instead of

    ```julia
    o = @def begin
        v ∈ R, variable
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ v ≤ 1
        x₁(0) == -1
        x₂(0) == v # wrong: the bound is not effective (as it depends on the variable)
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫( 0.5u(t)^2 ) → min
    end
    ```

    write

    ```julia
    o = @def begin
        v ∈ R, variable
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ v ≤ 1
        x₁(0) == -1
        x₂(0) - v == 0 # OK: the boundary constraint may involve the variable
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫( 0.5u(t)^2 ) → min
    end
    ```

## [Mayer cost](@id manual-abstract-mayer)

```julia
:( $e1 → min ) 
:( $e1 → max ) 
```

Mayer costs are defined in a similar way to boundary conditions and follow the same rules. The symbol `→` is used
to denote minimisation or maximisation, the latter being treated by minimising the opposite cost. (The symbol `=>` can also be used.)

```@repl main-repl
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

Lagrange (integral) costs are defined used the symbol `∫`, *with parentheses*. The keyword `integral` can also be used:

```julia
@def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    0.5∫(q(t) + u(t)^2) → min
    ...
end
```

or

```julia
@def begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    0.5integral(q(t) + u(t)^2) → min
    ...
end
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

```julia
@def begin
    p = (t0, tf) ∈ R², variable
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R², control
    (tf - t0) + 0.5∫(c(t) * u(t)^2) → min
    ...
end
```

!!! warning
    The expression must be the sum of two terms (plus, possibly, a scalar factor before the integral), not *more*, so mind the parentheses. For instance, the following errors:

    ```julia
    @def begin
        p = (t0, tf) ∈ R², variable
        t ∈ [t0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R², control
        (tf - t0) + q(tf) + 0.5∫( c(t) * u(t)^2 ) → min
        ...
    end
    ```

    The correct syntax is

    ```julia
    @def begin
        p = (t0, tf) ∈ R², variable
        t ∈ [t0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R², control
        ((tf - t0) + q(tf)) + 0.5∫( c(t) * u(t)^2 ) → min
        ...
    end
    ```

## [Aliases](@id manual-abstract-aliases)

```julia
:( $a = $e1 )
```

The single `=` symbol is used to define not a constraint but an alias, that is a purely syntactic replacement. There are some automatic aliases, *e.g.* `x₁` and `x1` for `x[1]` if `x` is the state (same for variable and control, for indices comprised between 1 and 9), and we have also seen that the user can define her own aliases when declaring the [variable](@ref manual-abstract-variable), [state](@ref manual-abstract-state) and [control](@ref manual-abstract-control). Arbitrary aliases can be further defined, as below (compare with previous examples in the [dynamics](@ref manual-abstract-dynamics) section):

```julia
@def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    F₀ = [x₂(t), 0]
    F₁ = [0, 1]
    ẋ(t) == F₀ + u(t) * F₁
    ...
end
```

!!! warning
    Such aliases do *not* define any additional function and are just replaced textually by the parser. In particular, they cannot be used outside the `@def` `begin ... end` block. Conversely, constants and functions used within the `@def` block must be defined outside and before this block.

!!! hint
    You can rely on a trace mode for the macro `@def` to look at your code after expansions of the aliases using the `@def ocp ...` syntax and adding `true` after your `begin ... end` block:

    ```@repl main-repl
    @def damped_integrator begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        q̇ = v(t)
        v̇ = u(t) - c(t)
        ẋ(t) == [q̇, v̇]
    end true;
    ```

!!! warning
    The dynamics of an OCP is indeed a particular constraint, be careful to use `==` and not a single `=` that would try to define an alias:

    ```@repl main-repl
    double_integrator = @def begin
        tf ∈ R, variable
        t ∈ [0, tf], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        q̇ = v
        v̇ = u
        ẋ(t) = [q̇, v̇]
    end
    ```

## Misc

- Declarations (of variable - if any -, time, state and control - if any -) must be done first. Then, dynamics, constraints and cost can be introduced in an arbitrary order.
- It is possible to provide numbers / labels (as in math equations) for the constraints to improve readability (this is mostly for future use, typically to retrieve the Lagrange multiplier associated with the discretisation of a given constraint):

```julia
@def damped_integrator begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    tf ≥ 0, (1)
    q(0) == 2, (♡)
    q̇ = v(t)
    v̇ = u(t) - c(t)
    ẋ(t) == [q̇, v̇]
    x(t).^2  ≤ [1, 2], (state_con) 
    ...
end
```

- Parsing errors should be explicit enough (with line number in the `@def` `begin ... end` block indicated) 🤞🏾
- Check tutorials and applications in the documentation for further use.

## [Known issues](@id manual-abstract-known-issues)

- [Reverse over forward AD issues with ADNLP](https://github.com/control-toolbox/OptimalControl.jl/issues/481#issuecomment-3471352183)
