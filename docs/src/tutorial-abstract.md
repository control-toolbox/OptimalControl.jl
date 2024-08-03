# [Abstract syntax](@id abstract)

The full grammar of OptimalControl.jl DSL[^1] is given below. The idea is to use a syntax that is
- pure Julia (and, as such, effortlessly analysed by the standard Julia parser),
- as close as possible to the mathematical description of an optimal control problem. 

While the syntax will be transparent to those users familiar with Julia expressions, we provide examples for every case that should be widely understandable. We rely heavily on [MLStyle.jl](https://github.com/thautwarm/MLStyle.jl) and its pattern matching abilities for the semantic pass. Abstract definitions use the macro `@def`.

## Variable declaration

```julia
   # variable                    
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

## Time declaration

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

## State declaration
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

## Control declaration
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

## Dynamics
```julia
   :( ∂($x)($t) == $e1               ) 
   :( ∂($x)($t) == $e1, $label       ) 
```
- add x\dot (automatic alias)
- no line to line / component declaration
- labeled or not

## Constraints
- boundary, control, state, mixed
- ranges (linear) of general (*a priori* nonlinear)
- equalities, one or two-sided inequalities
- labeled or not (future use: retrieve associated multipliers on the discretised problem)

```julia
   :( $e1 == $e2                     ) 
   :( $e1 == $e2, $label             ) 
   :( $e1 ≤  $e2 ≤  $e3              ) 
   :( $e1 ≤  $e2 ≤  $e3, $label      ) 
   :(        $e2 ≤  $e3              ) 
   :(        $e2 ≤  $e3, $label      ) 
   :( $e3 ≥  $e2 ≥  $e1              ) 
   :( $e3 ≥  $e2 ≥  $e1, $label      ) 
   :( $e2 ≥  $e1                     ) 
   :( $e2 ≥  $e1,        $label      ) 
```

# Mayer cost
 ```julia                                      
   :( $e1                      → min ) 
   :( $e1                      → max ) 
```

# Lagrange cost
```julia
   :(             ∫($e1)       → min ) 
   :(           - ∫($e1)       → min ) 
   :(       $e1 * ∫($e2)       → min ) 
                                       
   :(             ∫($e1)       → max ) 
   :(           - ∫($e1)       → max ) 
   :(       $e1 * ∫($e2)       → max ) 
```
- caveat:  ... + ... + ...

# Bolza cost
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

## Aliases

- order: declaration first, then constraint and cost (no ordering for these two)
- examples for most features
- caveat's (check isssue) (case by base)
- error should be OK (give an example)
- expressions should evaluate at run
- aliases (vars, and in general)
- link to example + API for functional syntax
- point towards examples for further use

[^1]: Domain Specific Language