# [Functional API (macro-free)](@id manual-macro-free)

```@meta
Draft = false
```

The [`@def`](@ref manual-abstract-syntax) macro provides a concise DSL to define optimal control problems. An alternative is the **functional API**, which builds the same problem step by step using plain Julia functions. This approach is useful when:

- generating problems **programmatically** from parameters, data, or loops,
- building **library code** that must not rely on macros,
- interfacing with external tools that process problem structures directly.

The functional API uses [`OptimalControl.PreModel`](@ref CTModels.PreModel) as a mutable builder, populated by setter calls, then frozen into an immutable [`OptimalControl.Model`](@ref) by [`build`](@ref).

!!! note

    When a problem is defined with the functional API, [`definition`](@ref)`(ocp)` returns an `EmptyDefinition` — no abstract expression is stored. This contrasts with `@def`, which records the full DSL expression for display and introspection.

!!! warning "Modeler compatibility"

    Problems built with the functional API can only be solved with the `:adnlp` modeler (the default). The `:exa` modeler (ExaModels, GPU-capable) requires the abstract syntax [`@def`](@ref manual-abstract-syntax). See the [solve manual](@ref manual-solve) for modeler details.

---

**Content**

```@contents
Pages = ["manual-macro-free.md"]
Depth = 3
```

---

## Canvas

The functional API mirrors the [Mathematical formulation](@ref math-formulation). The correspondence is:

| Math | Functional API |
| :--- | :--- |
| Dynamics $f(t, x, u)$ | `dyn!` passed to [`dynamics!`](@ref) |
| Lagrange integrand $f^0(t, x, u)$ | `lag` passed to [`objective!`](@ref) |
| Mayer terminal cost $g(x_0, x_f)$ | `may` passed to [`objective!`](@ref) |
| Path constraint $c(t, x, u)$ | `p!` passed to [`constraint!`](@ref)`(pre, :path; ...)` |
| Boundary constraint $b(x_0, x_f)$ | `b!` passed to [`constraint!`](@ref)`(pre, :boundary; ...)` |
| Extra variable $v$ | [`variable!`](@ref) (extra argument to all the callbacks above) |

```julia
using OptimalControl

pre = OptimalControl.PreModel()

# ─── Optional: must come before time! when using indf/ind0 ───────────────────
variable!(pre, q)                         # q = variable dimension
# ─────────────────────────────────────────────────────────────────────────────

time!(pre; t0=..., tf=...)                # fixed times
# or: time!(pre; t0=..., indf=i)          # free final time at variable index i

state!(pre, n)                            # n = state dimension

# ─── Optional: omit entirely for control-free problems ───────────────────────
control!(pre, m)                          # m = control dimension
# ─────────────────────────────────────────────────────────────────────────────

# Dynamics — in-place, signature: dyn!(dx, t, x, u, v)
#   dx : output vector (modified in place), length n
#   t  : current time  (scalar)
#   x  : state         (vector of length n; scalar state ↦ x[1])
#   u  : control       (vector of length m; scalar control ↦ u[1]; unused if control-free)
#   v  : variable      (vector of length q; scalar variable ↦ v[1]; unused if no variable)
function dyn!(dx, t, x, u, v)
    dx[1] = ...
    dx[2] = ...
end
dynamics!(pre, dyn!)

# Lagrange integrand — out-of-place, signature: lag(t, x, u, v) → scalar
lag(t, x, u, v) = ...
# Mayer terminal cost — out-of-place, signature: may(x0, xf, v) → scalar
#   x0 : initial state (vector of length n; scalar state ↦ x0[1])
#   xf : final state   (vector of length n; scalar state ↦ xf[1])
may(x0, xf, v) = ...

objective!(pre, :min; lagrange=lag)                   # Lagrange cost
# or: objective!(pre, :min; mayer=may)                # Mayer cost
# or: objective!(pre, :min; mayer=may, lagrange=lag)  # Bolza cost

# ─── Optional: one call per constraint ───────────────────────────────────────
# Two families of constraints:
#
# (a) Box constraints on components — :state, :control, :variable
#     rg selects the component range i:j, with lb ≤ x[rg] ≤ ub (resp. u, v).
constraint!(pre, :state;    rg=i:j, lb=..., ub=..., label=:name)
constraint!(pre, :control;  rg=i:j, lb=..., ub=..., label=:name)
constraint!(pre, :variable; rg=i:j, lb=..., ub=..., label=:name)
#
# (b) Non-linear constraints defined by a function — :boundary, :path
#     The constraint reads:  lb ≤ f(...) ≤ ub  (use lb=ub for equality).
#
#     Boundary — in-place, signature: b!(val, x0, xf, v)   (same shape as Mayer)
#         val : output vector (modified in place), length = length(lb) = length(ub)
#         x0  : initial state (vector of length n; scalar state ↦ x0[1])
#         xf  : final   state (vector of length n; scalar state ↦ xf[1])
#         v   : variable (vector of length q)
function b!(val, x0, xf, v)
    val[1] = ...
end
constraint!(pre, :boundary; f=b!, lb=..., ub=..., label=:name)
#
#     Path — in-place, signature: p!(val, t, x, u, v)      (same shape as dynamics)
#         val : output vector (modified in place), length = length(lb) = length(ub)
#         t   : current time  (scalar)
#         x   : state         (vector of length n)
#         u   : control       (vector of length m)
#         v   : variable      (vector of length q)
function p!(val, t, x, u, v)
    val[1] = ...
end
constraint!(pre, :path; f=p!, lb=..., ub=..., label=:name)
# ─────────────────────────────────────────────────────────────────────────────

# autonomous=true  ⟺  time t does NOT appear explicitly in the dynamics,
#                     the Lagrange integrand, nor in any :path constraint.
# autonomous=false ⟺  at least one of them depends explicitly on t.
time_dependence!(pre; autonomous=true)

ocp = build(pre)
```

**Required:** `time!` · `state!` · `dynamics!` · `objective!` · `time_dependence!` · `build`

**Optional:** `variable!` · `control!` · `constraint!` (repeatable)

**Ordering constraints:**

- `variable!` → before `time!` when using free-time indices (`indf`, `ind0`)
- `variable!` → before `dynamics!` and `objective!`
- `dynamics!` and `objective!` → after `time!` and `state!`

## Examples

For each problem below, the [`@def`](@ref) abstract syntax is shown on the left and the equivalent functional API on the right. After `build`, both formulations produce an equivalent model and can be passed directly to [`solve`](@ref manual-solve).

### [Double integrator: energy minimisation](@id manual-macro-free-energy)

The simplest case: fixed time interval, boundary constraints, autonomous dynamics, Lagrange cost.
See the [full example](@ref example-double-integrator-energy) for solving and plotting.

```@example ex-energy
using OptimalControl
using NLPModelsIpopt
t0 = 0.0; tf = 1.0; x0 = [-1.0, 0.0]; xf = [0.0, 0.0]
nothing # hide
```

```@raw html
<div class="responsive-columns-30-70">
<div>
```

**Abstract syntax**

```@example ex-energy
ocp_macro = @def begin

t ∈ [t0, tf], time
x = (q, v) ∈ R², state
u ∈ R, control

x(t0) == x0
x(tf) == xf

ẋ(t) == [v(t), u(t)]

0.5∫( u(t)^2 ) → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-energy
pre = OptimalControl.PreModel()

time!(pre; t0=t0, tf=tf)
# state "x" with components "q" (position) and "v" (velocity)
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)

function f_energy!(dx, t, x, u, v)
    dx[1] = x[2]
    dx[2] = u[1]
    return nothing
end
dynamics!(pre, f_energy!)

function boundary_energy!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end
constraint!(pre, 
    :boundary;
    f=boundary_energy!, 
    lb=zeros(4), ub=zeros(4), 
    label=:endpoint
)

lagrange_energy(t, x, u, v) = 0.5 * u[1]^2
objective!(pre, :min; lagrange=lagrange_energy)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

Both formulations produce identical solutions. We solve both and plot them together for verification:

```@example ex-energy
sol_macro = solve(ocp_macro; display=false)
sol_func = solve(ocp_func; display=false)

println("Macro: objective = ", objective(sol_macro), ", iterations = ", iterations(sol_macro))
println("Functional API: objective = ", objective(sol_func), ", iterations = ", iterations(sol_func))
```

```@example ex-energy
plt = plot(sol_macro; label="Macro", color=1, size=(800, 600))
plot!(plt, sol_func; label="Functional API", color=2, linestyle=:dash)
```

The two models are functionally equivalent. The key difference is visible via [`definition`](@ref): the macro records the full DSL expression, whereas the functional API stores an empty definition.

```@example ex-energy
definition(ocp_macro)
```

```@example ex-energy
has_abstract_definition(ocp_func)
```

#### Scalar vs vector: a subtlety of the functional API

In the functional API definition above, the control is declared with `control!(pre, 1)` — it is of **dimension 1**. Yet, inside the callbacks `f_energy!` and `lagrange_energy`, we accessed it as `u[1]`, *not* as `u`. The same applies to the state and the variable: inside callbacks, dimension-1 components must always be indexed.

This is because the functional API callbacks always receive `x`, `u`, and `v` as **vectors**, regardless of their dimension. This keeps the callback signatures uniform and lets the same code shape work for any dimension.

However, once the problem is solved, accessing the control (or state, or variable) on the solution returns a **scalar** when the component is of dimension 1 — just like the [`@def`](@ref manual-abstract-syntax) macro convention:

```@example ex-energy
u_macro = control(sol_macro)
u_func  = control(sol_func)
# The callbacks used u[1], yet the solution returns a scalar:
u_macro(t0), u_func(t0)
```

```@example ex-energy
typeof(u_macro(t0)), typeof(u_func(t0))
```

!!! warning "Scalar vs vector conventions"

    The functional API uses two different conventions depending on where you are:

    - **Inside callbacks** (`dynamics!`, `objective!`, `constraint!`): `x`, `u`, `v` are **always vectors**. For a dimension-1 component, use `x[1]`, `u[1]`, `v[1]`.
    - **On a solution**: `state(sol)(t)`, `control(sol)(t)`, `variable(sol)` return a **scalar** when the corresponding component is of dimension 1. This matches the [`@def`](@ref manual-abstract-syntax) convention (see the [solution manual](@ref manual-solution)).

    This asymmetry is intentional: callbacks are written once for any dimension, while solutions expose the mathematical object (scalar or vector) directly.

### [Double integrator: time minimisation](@id manual-macro-free-time)

Free final time as a variable, Mayer cost, control box constraint.
See the [full example](@ref example-double-integrator-time) for solving and plotting.

```@example ex-time
using OptimalControl
using NLPModelsIpopt
t0 = 0.0; x0 = [-1.0, 0.0]; xf = [0.0, 0.0]
nothing # hide
```

```@raw html
<div class="responsive-columns-30-70">
<div>
```

**Abstract syntax**

```@example ex-time
ocp_macro = @def begin

tf ∈ R,           variable
t ∈ [t0, tf],     time
x = (q, v) ∈ R²,  state
u ∈ R,            control

-1 ≤ u(t) ≤ 1

x(t0) == x0
x(tf) == xf

ẋ(t) == [v(t), u(t)]

tf → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-time
pre = OptimalControl.PreModel()

# variable[1] = final time tf
variable!(pre, 1, "tf")
# free final time: tf = variable[1]
time!(pre; t0=t0, indf=1)
# state "x" with components "q" (position) and "v" (velocity)
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)

function f_time!(dx, t, x, u, v)
    dx[1] = x[2]
    dx[2] = u[1]
    return nothing
end
dynamics!(pre, f_time!)

# control box constraint: -1 ≤ u ≤ 1
constraint!(pre,
    :control;
    rg=1:1, lb=[-1.0], ub=[1.0],
    label=:u_bounds
)

function boundary_time!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end
constraint!(pre,
    :boundary;
    f=boundary_time!,
    lb=zeros(4), ub=zeros(4),
    label=:endpoint
)

# Mayer cost: minimise tf = variable[1]
mayer_time(x0_, xf_, v) = v[1]
objective!(pre, :min; mayer=mayer_time)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

Both formulations produce identical solutions:

```@example ex-time
sol_macro = solve(ocp_macro; display=false)
sol_func = solve(ocp_func; display=false)

println("Macro: objective = ", objective(sol_macro), ", iterations = ", iterations(sol_macro))
println("Functional API: objective = ", objective(sol_func), ", iterations = ", iterations(sol_func))
```

```@example ex-time
plt = plot(sol_macro; label="Macro", color=1, size=(800, 600))
plot!(plt, sol_func; label="Functional API", color=2, linestyle=:dash)
```

!!! note
    `variable!(pre, 1, "tf")` must be called **before** `time!(pre; indf=1)` so that the free-time index refers to a declared variable.

### [Control-free problems](@id manual-macro-free-control-free)

No control variable: `control!` is simply omitted. The dynamics and objective still receive `u` as an argument, but it is a zero-dimensional vector.
See the [full example](@ref example-control-free) for solving and plotting.

```@example ex-cf
using OptimalControl
using NLPModelsIpopt
λ_true = 0.5
model_fn(t) = 2 * exp(λ_true * t)
noise_fn(t) = 2e-1 * sin(4π * t)
data_fn(t) = model_fn(t) + noise_fn(t)
t0 = 0.0; tf = 2.0; x0_cf = 2.0
nothing # hide
```

```@raw html
<div class="responsive-columns-30-70">
<div>
```

**Abstract syntax**

```@example ex-cf
ocp_macro = @def begin

λ ∈ R, variable
t ∈ [t0, tf], time
x ∈ R, state

x(t0) == x0_cf

ẋ(t) == λ * x(t)

∫( (x(t) - data_fn(t))^2 ) → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-cf
pre = OptimalControl.PreModel()

# variable[1] = parameter λ (growth rate)
variable!(pre, 1, "λ")
time!(pre; t0=t0, tf=tf)
# scalar state x
state!(pre, 1, "x")
# no control! — control-free problem

function f_cf!(dx, t, x, u, v)
    # λ = v[1]; u is empty (control-free)
    dx[1] = v[1] * x[1]
    return nothing
end
dynamics!(pre, f_cf!)

function boundary_cf!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0_cf
    return nothing
end
constraint!(pre,
    :boundary;
    f=boundary_cf!,
    lb=[0.0], ub=[0.0],
    label=:ic
)

lagrange_cf(t, x, u, v) = (x[1] - data_fn(t))^2
objective!(pre, :min; lagrange=lagrange_cf)

# autonomous=false: data_fn(t) depends on t
time_dependence!(pre; autonomous=false)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

Both formulations produce identical solutions:

```@example ex-cf
sol_macro = solve(ocp_macro; display=false)
sol_func = solve(ocp_func; display=false)

println("Macro: objective = ", objective(sol_macro), ", iterations = ", iterations(sol_macro))
println("Functional API: objective = ", objective(sol_func), ", iterations = ", iterations(sol_func))
```

```@example ex-cf
plt = plot(sol_macro; label="Macro", color=1, size=(800, 200))
plot!(plt, sol_func; label="Functional API", color=2, linestyle=:dash)
```

!!! note
    `time_dependence!(pre; autonomous=false)` is required here because the Lagrange integrand `data_fn(t)` depends explicitly on time `t`.

### [Problems mixing control and variable](@id manual-macro-free-control-and-variable)

A variable parameter and an explicit control are used simultaneously.
See the [full example](@ref example-control-and-variable) for solving and plotting.

```@example ex-cv
using OptimalControl
using NLPModelsIpopt
λ_true = 0.5
model_fn2(t) = 2 * exp(λ_true * t)
noise_fn2(t) = 2e-1 * sin(4π * t)
data_fn2(t) = model_fn2(t) + noise_fn2(t)
t0 = 0.0; tf = 2.0; x0_cv = 2.0
nothing # hide
```

```@raw html
<div class="responsive-columns-30-70">
<div>
```

**Abstract syntax**

```@example ex-cv
ocp_macro = @def begin

λ ∈ R, variable
t ∈ [t0, tf], time
x ∈ R, state
u ∈ R, control

x(t0) == x0_cv

ẋ(t) == λ * x(t) + u(t)

∫( (x(t) - data_fn2(t))^2 + 0.5*u(t)^2 ) → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-cv
pre = OptimalControl.PreModel()

# variable[1] = parameter λ (growth rate)
variable!(pre, 1, "λ")
time!(pre; t0=t0, tf=tf)
# scalar state x
state!(pre, 1, "x")
# scalar control u
control!(pre, 1)

function f_cv!(dx, t, x, u, v)
    # λ = v[1]
    dx[1] = v[1] * x[1] + u[1]
    return nothing
end
dynamics!(pre, f_cv!)

function boundary_cv!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0_cv
    return nothing
end
constraint!(pre,
    :boundary;
    f=boundary_cv!,
    lb=[0.0], ub=[0.0],
    label=:ic
)

lagrange_cv(t, x, u, v) =
    (x[1] - data_fn2(t))^2 + 0.5 * u[1]^2
objective!(pre, :min; lagrange=lagrange_cv)

# autonomous=false: data_fn2(t) depends on t
time_dependence!(pre; autonomous=false)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

Both formulations produce identical solutions:

```@example ex-cv
sol_macro = solve(ocp_macro; display=false)
sol_func = solve(ocp_func; display=false)

println("Macro: objective = ", objective(sol_macro), ", iterations = ", iterations(sol_macro))
println("Functional API: objective = ", objective(sol_func), ", iterations = ", iterations(sol_func))
```

```@example ex-cv
plt = plot(sol_macro; label="Macro", color=1, size=(800, 400))
plot!(plt, sol_func; label="Functional API", color=2, linestyle=:dash)
```

### [Singular control](@id manual-macro-free-singular)

Three-dimensional state, free final time, state and control box constraints, Mayer cost.
See the [full example](@ref example-singular-control) for solving and plotting.

```@example ex-singular
using OptimalControl
using NLPModelsIpopt
nothing # hide
```

```@raw html
<div class="responsive-columns-30-70">
<div>
```

**Abstract syntax**

```@example ex-singular
ocp_macro = @def begin

tf ∈ R, variable
t ∈ [0, tf], time
q = (x, y, θ) ∈ R³, state
u ∈ R, control

-1 ≤ u(t) ≤ 1
-π/2 ≤ θ(t) ≤ π/2

x(0) == 0
y(0) == 0
x(tf) == 1
y(tf) == 0

∂(q)(t) == [cos(θ(t)), sin(θ(t)) + x(t), u(t)]

tf → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-singular
pre = OptimalControl.PreModel()

# variable[1] = final time tf
variable!(pre, 1, "tf")
# free final time: tf = variable[1]
time!(pre; t0=0.0, indf=1)
# state "q" with components "x", "y", "θ"
state!(pre, 3, "q", ["x", "y", "θ"])
control!(pre, 1)

function f_singular!(dq, t, q, u, v)
    dq[1] = cos(q[3])
    dq[2] = sin(q[3]) + q[1]
    dq[3] = u[1]
    return nothing
end
dynamics!(pre, f_singular!)

# control box constraint: -1 ≤ u ≤ 1
constraint!(pre,
    :control;
    rg=1:1, lb=[-1.0], ub=[1.0],
    label=:u_bounds
)
# state box constraint on θ = q[3]: -π/2 ≤ θ ≤ π/2
constraint!(pre,
    :state;
    rg=3:3, lb=[-π/2], ub=[π/2],
    label=:theta_bounds
)

function boundary_singular!(b, q0, qf, v)
    b[1] = q0[1]        # x(0) = 0
    b[2] = q0[2]        # y(0) = 0
    b[3] = qf[1] - 1.0  # x(tf) = 1
    b[4] = qf[2]        # y(tf) = 0
    return nothing
end
constraint!(pre,
    :boundary;
    f=boundary_singular!,
    lb=zeros(4), ub=zeros(4),
    label=:endpoint
)

# Mayer cost: minimise tf = variable[1]
mayer_singular(q0, qf, v) = v[1]
objective!(pre, :min; mayer=mayer_singular)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

Both formulations produce identical solutions:

```@example ex-singular
sol_macro = solve(ocp_macro; display=false)
sol_func = solve(ocp_func; display=false)

println("Macro: objective = ", objective(sol_macro), ", iterations = ", iterations(sol_macro))
println("Functional API: objective = ", objective(sol_func), ", iterations = ", iterations(sol_func))
```

```@example ex-singular
plt = plot(sol_macro; label="Macro", color=1, size=(800, 800))
plot!(plt, sol_func; label="Functional API", color=2, linestyle=:dash)
```

### [State constraint](@id manual-macro-free-state-constraint)

Same double integrator as the energy minimisation example, with an added upper bound on velocity.
See the [full example](@ref example-state-constraint) for solving and plotting.

```@example ex-state
using OptimalControl
using NLPModelsIpopt
t0 = 0.0; tf = 1.0; x0 = [-1.0, 0.0]; xf = [0.0, 0.0]
nothing # hide
```

```@raw html
<div class="responsive-columns-30-70">
<div>
```

**Abstract syntax**

```@example ex-state
ocp_macro = @def begin

t ∈ [t0, tf], time
x = (q, v) ∈ R², state
u ∈ R, control

x(t0) == x0
x(tf) == xf

v(t) ≤ 1.2

ẋ(t) == [v(t), u(t)]

0.5∫( u(t)^2 ) → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-state
pre = OptimalControl.PreModel()

time!(pre; t0=t0, tf=tf)
# state "x" with components "q" (position) and "v" (velocity)
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)

function f_state!(dx, t, x, u, v)
    dx[1] = x[2]
    dx[2] = u[1]
    return nothing
end
dynamics!(pre, f_state!)

function boundary_state!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end
constraint!(pre,
    :boundary;
    f=boundary_state!,
    lb=zeros(4), ub=zeros(4),
    label=:endpoint
)

# state box constraint: v(t) ≤ 1.2, i.e. x[2] ≤ 1.2
constraint!(pre,
    :state;
    rg=2:2, lb=[-Inf], ub=[1.2],
    label=:v_max
)

lagrange_state(t, x, u, v) = 0.5 * u[1]^2
objective!(pre, :min; lagrange=lagrange_state)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

Both formulations produce identical solutions:

```@example ex-state
sol_macro = solve(ocp_macro; display=false)
sol_func = solve(ocp_func; display=false)

println("Macro: objective = ", objective(sol_macro), ", iterations = ", iterations(sol_macro))
println("Functional API: objective = ", objective(sol_func), ", iterations = ", iterations(sol_func))
```

```@example ex-state
plt = plot(sol_macro; label="Macro", color=1, size=(800, 600))
plot!(plt, sol_func; label="Functional API", color=2, linestyle=:dash)
```

!!! note
    The state box constraint `v(t) ≤ 1.2` is expressed as `constraint!(pre, :state; rg=2:2, lb=[-Inf], ub=[1.2], ...)`, where `rg=2:2` selects the second state component `v`.

## API Reference

```@docs; canonical=false
CTModels.PreModel
```

```@docs; canonical=false
CTModels.time!
```

```@docs; canonical=false
CTModels.state!
```

```@docs; canonical=false
CTModels.control!
```

```@docs; canonical=false
CTModels.variable!
```

```@docs; canonical=false
CTModels.dynamics!
```

```@docs; canonical=false
CTModels.objective!
```

```@docs; canonical=false
CTModels.constraint!
```

```@docs; canonical=false
CTModels.time_dependence!
```

```@docs; canonical=false
CTModels.build
```

```@docs; canonical=false
CTModels.Model
```
