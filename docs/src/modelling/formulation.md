# [Formulation](@id modelling-formulation)

An optimal control problem (OCP) with fixed initial and final times can be described as minimising the cost functional (in Bolza form)

```math
J(x, u) = g(x(t_0), x(t_f)) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t))\,\mathrm{d}t
```

where the state $x$ and the control $u$ are functions of time $t$, subject for $t \in [t_0, t_f]$ to the differential constraint

```math
\dot{x}(t) = f(t, x(t), u(t))
```

and other constraints such as

```math
\begin{array}{llcll}
x_{\mathrm{lower}} & \le & x(t)              & \le & x_{\mathrm{upper}}, \\
u_{\mathrm{lower}} & \le & u(t)              & \le & u_{\mathrm{upper}}, \\
c_{\mathrm{lower}} & \le & c(t, x(t), u(t))  & \le & c_{\mathrm{upper}}, \\
b_{\mathrm{lower}} & \le & b(x(t_0), x(t_f)) & \le & b_{\mathrm{upper}}.
\end{array}
```

If $g = 0$, the cost is said to be in **Lagrange form**; if $f^0 = 0$, it is in **Mayer form**.

## Free times and extra variables

The initial time $t_0$ and the final time $t_f$ may also be free, that is part of the optimisation variables:

```math
J(x, u, t_0, t_f) \to \min.
```

More generally, a vector $v \in \mathbb{R}^k$ of $k$ additional variables can be introduced (it may contain $t_0$, $t_f$, or any other free parameter). The cost, dynamics, and constraints then all depend on $v$:

```math
J(x, u, v) = g(x(t_0), x(t_f), v) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t), v)\,\mathrm{d}t \to \min,
```

```math
\dot{x}(t) = f(t, x(t), u(t), v),
```

with, in addition, box constraints on $v$:

```math
v_{\mathrm{lower}} \le v \le v_{\mathrm{upper}}.
```

## The control-free case

Nothing above requires a control to be present: taking $m = 0$ (no $u$) is a legitimate degenerate case, used to fit or optimise parameters of a dynamical system rather than to steer it. See [No control](@ref modelling-without-control) for how to declare and solve such problems.

## See also

- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — write this formulation directly as Julia code.
- [Functional API](@ref modelling-functional-api) — build the same model without the macro.
- [No control](@ref modelling-without-control) — the $m = 0$ case.
