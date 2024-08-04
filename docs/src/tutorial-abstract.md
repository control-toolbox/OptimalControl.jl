# [Abstract syntax](@id abstract)

The full grammar of OptimalControl.jl small Domain Specific Language is given below. The idea is to use a syntax that is
- pure Julia (and, as such, effortlessly analysed by the standard Julia parser),
- as close as possible to the mathematical description of an optimal control problem. 

While the syntax will be transparent to those users familiar with Julia expressions (`Expr`'s), we provide examples for every case that should be widely understandable. We rely heavily on [MLStyle.jl](https://github.com/thautwarm/MLStyle.jl) and its pattern matching abilities for the semantic pass. Abstract definitions use the macro `@def`.

## [Variable](@id variable)

```julia
   :( $v ∈ R^$q, variable            ) 
   :( $v ∈ R   , variable            ) 
```

A variable (only one is allowed) is a finite dimensional vector or reals that will be optimised along with state and control values. To define an (almost empty!) optimal control problem, named `ocp`, having a dimension two variable named `v`, do the following:

```@example main
using OptimalControl #hide
@def ocp begin
    v ∈ R², variable
end
```

Aliases `v₁` and `v₂` are automatically defined and can be used in subsequent expressions instead of `v[1]` and `v[2]`. The user can also define her own aliases for the components (one per dimension):

```@example main
@def ocp begin
    v = (a, b) ∈ R², variable
end
```

A one dimensional can be declared according to

```@example main
@def ocp begin
    v ∈ R, variable
end
```

## Time

```julia
   :( $t ∈ [$t0, $tf], time        ) 
```

The independent variable or *time* is a scalar bound to a given interval. Its name is arbitrary.

```@example main
tf = 5
@def ocp begin
    t ∈ [0, tf], time
end
```

One (or even the two bounds) can be variable, typically for minimum time problems:

```@example main
@def ocp begin
    v = (T, λ) ∈ R², variable
    t ∈ [0, T], time
end
```

## [State](@id state)

```julia
   :( $x ∈ R^$n, state               ) 
   :( $x ∈ R   , state               ) 
```

The state declaration defines the name and the dimension of the state:

```@example main
@def ocp begin
       x ∈ R⁴, state
end
```

As for the variable, there are automatic aliases (`x₁` for `x[1]`, *etc.*) and the user can define her own aliases (one per scalar component of the state):

```@example main
@def ocp begin
       x = (q₁, q₂, v₁, v₂) ∈ R⁴, state
end
```

## [Control](@id control)

```julia
   :( $u ∈ R^$m, control             ) 
   :( $u ∈ R   , control             ) 
```

The control declaration defines the name and the dimension of the control:

```@example main
@def ocp begin
    u ∈ R², control
end
```

As before, there are automatic aliases (`u₁` for `u[1]`, *etc.*) and the user can define her own aliases (one per scalar component of the state):

```@example main
@def ocp begin
    u = (α, β) ∈ R², control
end
```

## [Dynamics](@id dynamics)

```julia
   :( ∂($x)($t) == $e1               ) 
```

The dynamics is given in the standard vectorial ODE form:

```math
    \dot{x}(t) = f(x(t), u(t)) \quad \text{or} \quad f(t, x(t), u(t))
```

depending on whether it is autonomous or not (the parser will detect dependence time, which entails that time and state must be declared prior to dynamics - an error will be issued otherwise). The symbol `∂` or the dotted state name
(`ẋ` can be used):

```@example main
@def ocp begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ∂(x)(t) == [x₂(t), u(t)]
end
```

or

```@example main
@def ocp begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ẋ(t) == [x₂(t), u(t)]
end
```

Any Julia code can be used, so the following is also OK: 

```@example main
@def ocp begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    ẋ(t) == F₀(x(t)) + u(t) * F₁(x(t))
end

F₀(x) = [x[2], 0]
F₁(x) = [0, 1]
```

!!! note
    The vector fields `F₀` and `F₁` can be defined afterwards, as they only need to be available when the dynamics will be evaluated.

Currently, it is not possible to declare the dynamics component after component, but a simple workaround is to use *aliases* (check the relevant [section ](#aliases) below):

```@example main
@def damped_integrator begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    q̇ = v(t)
    v̇ = u(t) - c(t)
    ẋ(t) == [q̇, v̇]
end
```

## Constraints

```julia
   :( $e1 == $e2                     ) 
   :( $e1 ≤  $e2 ≤  $e3              ) 
   :(        $e2 ≤  $e3              ) 
   :( $e3 ≥  $e2 ≥  $e1              ) 
   :( $e2 ≥  $e1                     ) 
```

Constraints 
- can be of five types: boundary, control, state, mixed, variable,
- be linear (ranges) or nonlinear (not ranges),
- equalities or (one or two-sided) inequalities.

Boundary conditions are detected when the expression contains evaluations of the state at initial and / or final time bounds (*e.g.*, `x(0)`), and may not involve the control. Conversely control, state or mixed constraints will involve control, state or both evaluated at the declared time (*e.g.*, `x(t) + u(t)`). 
Other combinations should be detected as incorrect by the parser 🤞🏾. The variable may be involved in any of the four previous constraints. Constraints involving the variable only are variable constraints, either linear or nonlinear.
In the example below, there are
- two linear boundary constraints,
- one linear variable constraint,
- one linear state constraint,
- one (two-sided) nonlinear control constraint.

```@example main
@def ocp begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(tf) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    tf ≥ 0 
    x₂(t) ≤ 1
    u(t)^2 ≤ 1
   end
```

!!! caveat
    Write either `u(t)^2` or `(u^2)(t)`, not `u^2(t)` since in Julia the latter is means `u^(2t)`. Moreover,
    in the case of equalities or of one-sided inequalities, the control and / or the state must belong the *left-hand side*. The following will error:

```julia
julia> @def ocp begin
    t ∈ [0, 2], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(2) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    1 ≤ x₂(t)
    -1 ≤ u(t) ≤ 1
end
ERROR: ParsingError: 
Line 7: 1 ≤ x₂(t)
bad constraint declaration
```

## Mayer cost

```julia                                      
   :( $e1                      → min ) 
   :( $e1                      → max ) 
```

Mayer costs are defined in a similar way to boundary conditions and follow the same rules. The symbol `→` is used
to denote minimisation of maximisation, the latter being treated by minimising the opposite cost.

```@example main
@def ocp begin
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
   :(             ∫($e1)       → min ) 
   :(           - ∫($e1)       → min ) 
   :(       $e1 * ∫($e2)       → min ) 
   :(             ∫($e1)       → max ) 
   :(           - ∫($e1)       → max ) 
   :(       $e1 * ∫($e2)       → max ) 
```

Lagrange (integral) costs are defined used the symbol `∫`, *with parenthesis:

```@example main
@def ocp begin
    t ∈ [0, 1], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    0.5∫( q(t) + u(t)^2 ) → min
end
```

The integration range is implicitly equal to the time range, so the cost above is to be understood as
```math
\int_0^1 q(t) + u^2(t)\,\mathrm{d}t \to \min.
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

Quite readily, Mayer and Lagrange costs can be combined into genral Bolza costs. For instance as follows:

```@example main
@def ocp begin
    p = (t0, tf) ∈ R², variable
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R², control
    (tf - t0) + 0.5∫( c(t) * u(t)^2 ) → min
end
```

!!! caveat
    The expression must be the sum of two terms (plus, possibly, a scalar factor before the integral), not *more*, so mind the parentheses. For instance, the following errors:

```julia
julia> @def ocp begin
           p = (t0, tf) ∈ R², variable
           t ∈ [t0, tf], time
           x = (q, v) ∈ R², state
           u ∈ R², control
           (tf - t0) + q(tf) + 0.5∫( c(t) * u(t)^2 ) → min
       end
ERROR: ParsingError: 
Line 5: (tf - t0) + q(tf) + 0.5 * ∫(c(t) * u(t) ^ 2) → min
bad objective declaration resulting in a Mayer term with trailing ∫
```

The correct syntax is
```@example main
@def ocp begin
    p = (t0, tf) ∈ R², variable
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R², control
    ( (tf - t0) + q(tf) ) + 0.5∫( c(t) * u(t)^2 ) → min
end
```

## [Aliases](@id aliases)

```julia
        :( $a = $e1 )
```

The single `=` symbol is used to define not a constraint but an alias, that is a purely syntactic replacement. There are some automatic aliases, *e.g.* `x₁` for `x[1]` if `x` is the state, and we have also seen that the user can define her own aliases when declaring the [variable](#variable), [state](#state) and [control](#control). Arbitrary aliases can be further defined, as below (compare with previous examples in the [dynamics](#dynamics) section):

```@example main
@def ocp begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    F₀ = [x₂(t), 0]
    F₁ = [0, 1]
    ẋ(t) == F₀ + u(t) * F₁
end

```

!!! caveat Such aliases do not define any additional function and are just replaced textually by the parser. In particular, they cannot be used outside the `@def` `begin ... end` block.

!!! hint
    You can use a trace mode for the macro `@def` to look at your code after expansions of the aliases adding `true` after your `begin ... end` block:

```@example main
@def damped_integrator begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    q̇ = v(t)
    v̇ = u(t) - c(t)
    ẋ(t) == [q̇, v̇]
end
```

!!! caveat
    The dynamics of an OCP is indeed a particular constraint, be careful to use `==` and not a single `=` that would try define an alias:

```julia
julia> @def double_integrator begin
       tf ∈ R, variable
       t ∈ [0, tf], time
       x = (q, v) ∈ R², state
       u ∈ R, control
       q̇ = v
       v̇ = u
       ẋ(t) = [q̇, v̇]
       end
ERROR: ParsingError: 
Line 7: ẋ(t) = begin
        #= REPL[35]:8 =#
        [q̇, v̇]
    end
forbidden alias name: (∂(x))(t)
```

## Misc

- Declarations (variable - in any -, time, state and control) must be done first. Then, dynamics, constraints and cost can be introduced in an arbitrary order.
- It is possible to provide numbers / labels (as math equations) for the constraints to improve readability (this is mostly for future use, typically to retrieve the Lagrange multiplier associated with the discretisation of a given constraint):

```@example main
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
end
```

- Parsing errors should be explicit enough (with line number in the `@def` `begin ... end` block indicated) 🤞🏾
- Check tutorials and applications in the documentation for further use.