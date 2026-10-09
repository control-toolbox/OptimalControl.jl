# [The `@Lie` macro](@id geometry-lie-macro)

`@Lie` writes brackets as on paper: square brackets for a Lie bracket of vector fields,
`@Lie [X, Y]`, which calls [`ad`](@ref geometry-ad), and curly braces for a Poisson bracket of
Hamiltonians, `@Lie {H, G}`, which calls [`Poisson`](@ref geometry-poisson).

```@example main
using OptimalControl
```

## Lie brackets

The fields $F_1(x) = (0, -x_3, x_2)$ and $F_2(x) = (x_3, 0, -x_1)$ generate the rotations
about the first two axes. Their bracket is $[F_1, F_2](x) = (x_2, -x_1, 0)$, a rotation about
the third axis:

```@example main
F1 = VectorField(x -> [0, -x[3], x[2]])
F2 = VectorField(x -> [x[3], 0, -x[1]])

F12 = @Lie [F1, F2]
F12([1.0, 2.0, 3.0])
```

Brackets nest. A linear vector field commutes with the radial field
$F_3(x) = x$, so $[[F_1, F_2], F_3] = 0$:

```@example main
F3 = VectorField(x -> x)

F123 = @Lie [[F1, F2], F3]
F123([1.0, 2.0, 3.0])
```

```@example main
@assert F12([1.0, 2.0, 3.0]) ≈ [2, -1, 0] && F123([1.0, 2.0, 3.0]) ≈ [0, 0, 0]   # hide
nothing                                                                         # hide
```

## Poisson brackets

With $H_0(x, p) = p_1 x_2 - p_2 x_1$ and $H_1(x, p) = p_2$, $\{H_0, H_1\} = -p_1$ and
$\{H_0, \{H_0, H_1\}\} = -p_2$:

```@example main
H0(x, p) = p[1] * x[2] - p[2] * x[1]
H1(x, p) = p[2]

H01 = @Lie {H0, H1}
H001 = @Lie {H0, {H0, H1}}

x, p = [1.0, 2.0], [3.0, 4.0]
H01(x, p), H001(x, p)
```

```@example main
@assert H01(x, p) ≈ -3 && H001(x, p) ≈ -4   # hide
nothing                                    # hide
```

These iterated brackets give the control on a singular arc (see
[Poisson bracket](@ref geometry-poisson-singular)).

## Keywords

On plain functions, give the dependence on time and on the variable with the keywords
`is_autonomous=` and `is_variable=`, after the brackets. On typed operands, the traits are
read from the operands. With $X(t, x) = (t + x_2, -x_1)$ and $Y(t, x) = (x_1, t x_2)$,
$[X, Y] = (t + x_2 - t x_2,\ x_1 - t x_1)$, which is $(1, 0)$ at $t = 1$, $x = (1, 2)$:

```@example main
X(t, x) = [t + x[2], -x[1]]
Y(t, x) = [x[1], t * x[2]]

Z = @Lie [X, Y] is_autonomous=false
Z(1.0, [1.0, 2.0])
```

```@example main
@assert Z(1.0, [1.0, 2.0]) ≈ [1, 0]   # hide
nothing                              # hide
```

The keyword `ad_backend=` chooses the AD backend (see [AD backend](@ref geometry-ad-backend)).
Any other keyword, such as `autonomous=false`, raises an `IncorrectArgument` that lists the
accepted ones.

```@example main
err = try eval(:(@Lie [F1, F2] autonomous=false)); nothing catch e; e end   # hide
@assert err isa CTBase.Exceptions.IncorrectArgument                       # hide
nothing                                                                   # hide
```

## Evaluating a bracket in an expression

Inside a bracket expression, `[F1, F2](x)` evaluates the bracket at `x`, and the result
combines with ordinary arithmetic:

```@example main
y = [1.0, 2.0, 3.0]
@Lie [F1, F2](y) + 4 * [F1, F2](y)
```

The macro takes everything that follows it as its argument, commas included. Inside a function
call, put it in parentheses: `isapprox((@Lie [F1, F2])(y), [2, -1, 0])`. Without them,
`isapprox(@Lie [F1, F2](y), [2, -1, 0])` passes both arguments to the macro, and returns a
function instead of a Boolean, without an error.

```@example main
@assert (@Lie [F1, F2](y) + 4 * [F1, F2](y)) ≈ [10, -5, 0]          # hide
@assert isapprox((@Lie [F1, F2])(y), [2, -1, 0])                   # hide
@assert !(isapprox(@Lie [F1, F2](y), [2, -1, 0]) isa Bool)         # hide
nothing                                                           # hide
```

## `using OptimalControl` is needed

The expansion of `@Lie` refers to the modules `CTLie` and `CTBase` by name, which
`using OptimalControl` brings into scope. With `import OptimalControl` or
`using OptimalControl: @Lie` only, the expanded code fails with an `UndefVarError`
([CTLie#40](https://github.com/control-toolbox/CTLie.jl/issues/40)).

```@example main
m = Module()                                                                  # hide
Core.eval(m, :(import OptimalControl))                                        # hide
err = try                                                                     # hide
    Core.eval(m, :((OptimalControl.@Lie [x -> [x[2], -x[1]], x -> x])([1.0, 2.0])))   # hide
    nothing                                                                   # hide
catch e                                                                       # hide
    e                                                                         # hide
end                                                                           # hide
@assert err isa UndefVarError                                                 # hide
nothing                                                                       # hide
```

## See also

- [Lie derivative and Lie bracket](@ref geometry-ad): `ad`, called by `@Lie [X, Y]`.
- [Poisson bracket](@ref geometry-poisson): `Poisson`, called by `@Lie {H, G}`.
- [Singular control](@ref examples-singular-control): iterated Poisson brackets on a complete
  problem.
