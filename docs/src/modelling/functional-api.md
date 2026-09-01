# [Functional API](@id modelling-functional-api)

```@meta
Draft = false
```

The [`@def`](@ref) macro provides a concise DSL to define optimal control problems. An alternative is the **functional API**, which builds the same problem step by step using plain Julia functions.

The functional API uses `OptimalControl.PreModel` as a mutable builder, populated by setter calls, then frozen into an immutable `OptimalControl.Model` by [`build`](@ref). Both `PreModel` and `Model` are imported, not exported — write `OptimalControl.PreModel()`.

!!! note

    When a problem is defined with the functional API, [`definition`](@ref)`(ocp)` returns an `EmptyDefinition` — no abstract expression is stored. This contrasts with `@def`, which records the full DSL expression for display and introspection.

!!! warning "Modeler compatibility"

    Problems built with the functional API can only be solved with the `:adnlp` modeler (the default). The `:exa` modeler (ExaModels, GPU-capable) requires the abstract syntax [`@def`](@ref modelling-abstract-syntax). See [Solve overview](@ref solve-overview) for modeler details.

## When you want this

- generating problems **programmatically** from parameters, data, or loops,
- building **library code** that must not rely on macros,
- interfacing with external tools that process problem structures directly.

## The canvas

The functional API mirrors the [Formulation](@ref modelling-formulation). The correspondence is:

| Math | Functional API |
| :--- | :--- |
| Dynamics $f(t, x, u)$ | `dyn!` passed to [`dynamics!`](@ref) |
| Lagrange integrand $f^0(t, x, u)$ | `lag` passed to [`objective!`](@ref) |
| Mayer terminal cost $g(x_0, x_f)$ | `may` passed to [`objective!`](@ref) |
| Path constraint $c(t, x, u)$ | `p!` passed to [`constraint!`](@ref CTModels.Building.constraint!)`(pre, :path; ...)` |
| Boundary constraint $b(x_0, x_f)$ | `b!` passed to [`constraint!`](@ref CTModels.Building.constraint!)`(pre, :boundary; ...)` |
| Extra variable $v$ | [`variable!`](@ref) (extra argument to all the callbacks above) |

```julia
using OptimalControl

pre = OptimalControl.PreModel()

# ─── Optional: before time! when using indf/ind0 ───────────────
variable!(pre, q)                         # q = variable dimension
# ───────────────────────────────────────────────────────────────

time!(pre; t0=..., tf=...)                # fixed times
# or: time!(pre; t0=..., indf=i)   # free final time at var index i

state!(pre, n)                            # n = state dimension

# ─── Optional: omit for control-free problems ──────────────────
control!(pre, m)                          # m = control dimension
# ───────────────────────────────────────────────────────────────

# Dynamics — in-place, signature: dyn!(dx, t, x, u, v)
#   dx : output vector (modified in place), length n (vector even for n=1)
#   t  : current time  (scalar)
#   x  : state         (scalar if n=1, vector of length n otherwise)
#   u  : control    (scalar if m=1 else vector; `nothing` if control-free)
#   v  : variable   (scalar if q=1 else vector; `nothing` if none)
function dyn!(dx, t, x, u, v)
    dx[1] = ...
    dx[2] = ...
end
dynamics!(pre, dyn!)

# Lagrange integrand — out-of-place, signature: lag(t, x, u, v) → scalar
lag(t, x, u, v) = ...
# Mayer terminal cost — out-of-place, signature: may(x0, xf, v) → scalar
#   x0 : initial state (scalar if n=1, vector of length n otherwise)
#   xf : final state   (scalar if n=1, vector of length n otherwise)
may(x0, xf, v) = ...

objective!(pre, :min; lagrange=lag)                   # Lagrange cost
# or: objective!(pre, :min; mayer=may)                # Mayer cost
# or: objective!(pre, :min; mayer=may, lagrange=lag)  # Bolza cost

# ─── Optional: one call per constraint ─────────────────────────
# Two families of constraints:
#
# (a) Box constraints on components — :state, :control, :variable
#     rg selects the range i:j, with lb ≤ x[rg] ≤ ub (resp. u, v).
constraint!(pre, :state;    rg=i:j, lb=..., ub=..., label=:name)
constraint!(pre, :control;  rg=i:j, lb=..., ub=..., label=:name)
constraint!(pre, :variable; rg=i:j, lb=..., ub=..., label=:name)
#
# (b) Non-linear constraints defined by a function — :boundary, :path
#     The constraint reads:  lb ≤ f(...) ≤ ub  (use lb=ub for equality).
#
#     Boundary — in-place: b!(val, x0, xf, v)   (same shape as Mayer)
#         val : vector (in place), length = length(lb) = length(ub)
#     Path — in-place: p!(val, t, x, u, v)      (same shape as dynamics)
#         val : vector (in place), length = length(lb) = length(ub)
function b!(val, x0, xf, v)
    val[1] = ...
end
constraint!(pre, :boundary; f=b!, lb=..., ub=..., label=:name)

function p!(val, t, x, u, v)
    val[1] = ...
end
constraint!(pre, :path; f=p!, lb=..., ub=..., label=:name)
# ───────────────────────────────────────────────────────────────

# autonomous=true  ⟺  time t does NOT appear explicitly in the dynamics,
#                     the Lagrange integrand, nor in any :path constraint.
# autonomous=false ⟺  at least one of them depends explicitly on t.
time_dependence!(pre; autonomous=true)

ocp = build(pre)
```

**Required:** `time!` · `state!` · `dynamics!` · `objective!` · `time_dependence!` · `build`

**Optional:** `variable!` · `control!` · `constraint!` (repeatable)

## Worked problems

Seven problems, each shown as [`@def`](@ref) (left) and the equivalent functional API (right). Every one has a full worked story — direct *and* indirect solution — on its [example gallery](@ref examples-gallery) page; here the focus is the model, built both ways and solved once to check the two agree. The callbacks follow the scalar convention of [Shapes in callbacks](@ref modelling-functional-api-shapes): a dimension-1 `x`, `u` or `v` is a `Real`, only the in-place output buffers (`dx`, `val`) are written by index.

### 1. Double integrator — energy minimisation

The simplest case: fixed time interval, boundary constraints, autonomous dynamics, Lagrange cost.

```@example ex-energy
using OptimalControl
using NLPModelsIpopt
t0 = 0.0; tf = 1.0; x0 = [-1.0, 0.0]; xf = [0.0, 0.0]
nothing # hide
```

```@raw html
<div class="responsive-columns-40-60">
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
    dx[2] = u
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

lagrange_energy(t, x, u, v) = 0.5 * u^2
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

println(
    "Macro: objective = ", objective(sol_macro),
    ", iterations = ", iterations(sol_macro),
)
println(
    "Functional API: objective = ", objective(sol_func),
    ", iterations = ", iterations(sol_func),
)
```

```@example ex-energy
plt = plot(
    sol_macro, :state, :control; label="Macro", color=1, size=(800, 600)
)
plot!(
    plt, sol_func, :state, :control;
    label="Functional API", color=2, linestyle=:dash,
)
```

The two models are functionally equivalent. The key difference is visible via [`definition`](@ref): the macro records the full DSL expression, whereas the functional API stores an empty definition.

```@example ex-energy
definition(ocp_macro)
```

```@example ex-energy
has_abstract_definition(ocp_func)
```

Full worked story (direct + indirect): [Energy minimisation](@ref examples-double-integrator-energy) · [example gallery](@ref examples-gallery).

### 2. Double integrator — time minimisation

The same wagon, transferred as fast as possible: the control is box-bounded and the final time `tf` is a free **variable** (`variable!` before `time!`, then `indf=1`). The cost is a Mayer term (`tf`), not a Lagrange integral.

```@example ex-time
using OptimalControl
using NLPModelsIpopt
t0 = 0.0; x0 = [-1.0, 0.0]; xf = [0.0, 0.0]
nothing # hide
```

```@raw html
<div class="responsive-columns-40-60">
<div>
```

**Abstract syntax**

```@example ex-time
ocp_macro = @def begin

    tf ∈ R, variable
    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

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

variable!(pre, 1, "tf")            # free final time — before time!
time!(pre; t0=t0, indf=1)          # tf is variable 1
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)

function f_time!(dx, t, x, u, v)
    dx[1] = x[2]
    dx[2] = u
    return nothing
end
dynamics!(pre, f_time!)

function boundary_time!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end
constraint!(pre,
    :boundary; f=boundary_time!, lb=zeros(4), ub=zeros(4), label=:endpoint
)

constraint!(pre, :control; rg=1:1, lb=[-1.0], ub=[1.0], label=:u_box)

objective!(pre, :min; mayer=(x0_, xf_, v) -> v)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

```@example ex-time
sol_macro = solve(ocp_macro; grid_size=20, display=false)
sol_func = solve(ocp_func; grid_size=20, display=false)
println(
    "objective: macro = ", objective(sol_macro),
    ", functional = ", objective(sol_func),
)
```

Full worked story (direct + indirect): [Time minimisation](@ref examples-double-integrator-time) · [example gallery](@ref examples-gallery).

### 3. Parameter estimation — no control

No control anywhere: `control!` is simply never called (see [No control](@ref modelling-without-control)). Only a **variable** — the growth rate `λ` — is optimised, fitting the state to data. The Lagrange integrand reads `t` through `data(t)`, so the problem is **non-autonomous**.

```@example ex-control-free
using OptimalControl
using NLPModelsIpopt

λ_true = 0.5
x_true(t) = 2 * exp(λ_true * t)
data(t) = x_true(t) + 0.2 * sin(4π * t)

t0 = 0.0; tf = 2.0; x0 = 2.0
nothing # hide
```

```@raw html
<div class="responsive-columns-40-60">
<div>
```

**Abstract syntax**

```@example ex-control-free
ocp_macro = @def begin

    λ ∈ R, variable
    t ∈ [t0, tf], time
    x ∈ R, state

    x(t0) == x0

    ẋ(t) == λ * x(t)

    ∫( (x(t) - data(t))^2 ) → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-control-free
pre = OptimalControl.PreModel()

variable!(pre, 1, "λ")
time!(pre; t0=t0, tf=tf)
state!(pre, 1, "x")
# no control! — this problem is control-free

function f_cf!(dx, t, x, u, v)
    dx[1] = v * x          # v: the scalar variable λ; x: the scalar state
    return nothing
end
dynamics!(pre, f_cf!)

objective!(pre, :min; lagrange=(t, x, u, v) -> (x - data(t))^2)

function boundary_cf!(b, x0_, xf_, v)
    b[1] = x0_ - x0        # 1-D state ⇒ x0_ is a scalar
    return nothing
end
constraint!(pre,
    :boundary; f=boundary_cf!, lb=[0.0], ub=[0.0], label=:ic
)

time_dependence!(pre; autonomous=false)   # data(t) depends on t

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

```@example ex-control-free
sol_macro = solve(ocp_macro; grid_size=20, display=false)
sol_func = solve(ocp_func; grid_size=20, display=false)
println(
    "estimated λ: macro = ", variable(sol_macro),
    ", functional = ", variable(sol_func),
)
```

Full worked story (direct + indirect): [Parameter estimation without a control](@ref examples-control-free), [No control](@ref modelling-without-control) · [example gallery](@ref examples-gallery).

### 4. Control and variable together

The growth problem again, now with a control input and a quadratic control cost — a **variable** (`λ`) and a **control** (`u`) estimated at once.

```@example ex-control-variable
using OptimalControl
using NLPModelsIpopt

λ_true = 0.5
x_true(t) = 2 * exp(λ_true * t)
data(t) = x_true(t) + 0.2 * sin(4π * t)

t0 = 0.0; tf = 2.0; x0 = 2.0
nothing # hide
```

```@raw html
<div class="responsive-columns-40-60">
<div>
```

**Abstract syntax**

```@example ex-control-variable
ocp_macro = @def begin

    λ ∈ R, variable
    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    x(t0) == x0

    ẋ(t) == λ * x(t) + u(t)

    ∫( (x(t) - data(t))^2 + 0.5u(t)^2 ) → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-control-variable
pre = OptimalControl.PreModel()

variable!(pre, 1, "λ")
time!(pre; t0=t0, tf=tf)
state!(pre, 1, "x")
control!(pre, 1)

function f_cv!(dx, t, x, u, v)
    dx[1] = v * x + u
    return nothing
end
dynamics!(pre, f_cv!)

objective!(pre, :min;
    lagrange=(t, x, u, v) -> (x - data(t))^2 + 0.5 * u^2,
)

function boundary_cv!(b, x0_, xf_, v)
    b[1] = x0_ - x0
    return nothing
end
constraint!(pre,
    :boundary; f=boundary_cv!, lb=[0.0], ub=[0.0], label=:ic
)

time_dependence!(pre; autonomous=false)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

```@example ex-control-variable
sol_macro = solve(ocp_macro; grid_size=20, display=false)
sol_func = solve(ocp_func; grid_size=20, display=false)
println(
    "objective: macro = ", objective(sol_macro),
    ", functional = ", objective(sol_func),
)
```

Full worked story (direct + indirect): [Control and variable together](@ref examples-control-and-variable) · [example gallery](@ref examples-gallery).

### 5. Turnpike — bang–singular–bang

The smallest problem with a singular arc: a scalar state *and* a scalar control, fixed horizon, one control box, a Lagrange cost. Nothing here is a length-1 vector — the callbacks are pure scalar arithmetic.

```@example ex-turnpike
using OptimalControl
using NLPModelsIpopt
t0 = 0.0; tf = 2.0; x0 = 1.0; xf = 0.5
nothing # hide
```

```@raw html
<div class="responsive-columns-40-60">
<div>
```

**Abstract syntax**

```@example ex-turnpike
ocp_macro = @def begin

    t ∈ [t0, tf], time
    x ∈ R, state
    u ∈ R, control

    -1 ≤ u(t) ≤ 1

    x(t0) == x0
    x(tf) == xf

    ẋ(t) == u(t)

    ∫( x(t)^2 ) → min

end
nothing # hide
```

```@raw html
</div>
<div>
```

**Functional API**

```@example ex-turnpike
pre = OptimalControl.PreModel()

time!(pre; t0=t0, tf=tf)
state!(pre, 1, "x")
control!(pre, 1)

function f_turnpike!(dx, t, x, u, v)
    dx[1] = u             # x, u both scalars
    return nothing
end
dynamics!(pre, f_turnpike!)

function boundary_turnpike!(b, x0_, xf_, v)
    b[1] = x0_ - x0       # 1-D state ⇒ x0_, xf_ are scalars
    b[2] = xf_ - xf
    return nothing
end
constraint!(pre,
    :boundary; f=boundary_turnpike!, lb=zeros(2), ub=zeros(2), label=:endpoint
)

constraint!(pre, :control; rg=1:1, lb=[-1.0], ub=[1.0], label=:u_box)

objective!(pre, :min; lagrange=(t, x, u, v) -> x^2)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

```@example ex-turnpike
sol_macro = solve(ocp_macro; grid_size=100, display=false)
sol_func = solve(ocp_func; grid_size=100, display=false)
println(
    "objective: macro = ", objective(sol_macro),
    ", functional = ", objective(sol_func),
)
```

Full worked story (direct + indirect): [Turnpike (bang–singular–bang)](@ref examples-turnpike) · [example gallery](@ref examples-gallery).

### 6. Singular control

A planar vehicle with drift, time-optimal: three-dimensional state, free final time, and box bounds on both the control and one state component. The optimal control has a singular arc — the example page computes it with the Geometry toolkit.

```@example ex-singular
using OptimalControl
using NLPModelsIpopt
nothing # hide
```

```@raw html
<div class="responsive-columns-40-60">
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
    -π / 2 ≤ θ(t) ≤ π / 2

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

variable!(pre, 1, "tf")
time!(pre; t0=0.0, indf=1)
state!(pre, 3, "q", ["x", "y", "θ"])
control!(pre, 1)

function f_singular!(dq, t, q, u, v)
    dq[1] = cos(q[3])
    dq[2] = sin(q[3]) + q[1]
    dq[3] = u
    return nothing
end
dynamics!(pre, f_singular!)

function boundary_singular!(b, q0, qf, v)
    b[1] = q0[1]          # x(0) = 0
    b[2] = q0[2]          # y(0) = 0
    b[3] = qf[1] - 1.0    # x(tf) = 1
    b[4] = qf[2]          # y(tf) = 0
    return nothing
end
constraint!(pre,
    :boundary; f=boundary_singular!, lb=zeros(4), ub=zeros(4), label=:endpoint
)

constraint!(pre, :control; rg=1:1, lb=[-1.0], ub=[1.0], label=:u_box)
constraint!(pre, :state; rg=3:3, lb=[-π / 2], ub=[π / 2], label=:θ_box)

objective!(pre, :min; mayer=(q0, qf, v) -> v)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

```@example ex-singular
sol_macro = solve(ocp_macro; grid_size=50, display=false)
sol_func = solve(ocp_func; grid_size=50, display=false)
println(
    "objective: macro = ", objective(sol_macro),
    ", functional = ", objective(sol_func),
)
```

Full worked story (direct + indirect): [Singular control](@ref examples-singular-control) · [example gallery](@ref examples-gallery).

### 7. State constraint

The energy-minimal transfer of problem 1, now with an upper bound on the velocity written as a nonlinear **path** constraint — so it carries a dual, reachable by its label — rather than a box on the state component.

```@example ex-state-constraint
using OptimalControl
using NLPModelsIpopt
t0 = 0.0; tf = 1.0; x0 = [-1.0, 0.0]; xf = [0.0, 0.0]; VMAX = 1.2
nothing # hide
```

```@raw html
<div class="responsive-columns-40-60">
<div>
```

**Abstract syntax**

```@example ex-state-constraint
ocp_macro = @def begin

    t ∈ [t0, tf], time
    x = (q, v) ∈ R², state
    u ∈ R, control

    x(t0) == x0
    x(tf) == xf

    v(t) + 0.0 ≤ VMAX, (vmax)

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

```@example ex-state-constraint
pre = OptimalControl.PreModel()

time!(pre; t0=t0, tf=tf)
state!(pre, 2, "x", ["q", "v"])
control!(pre, 1)

function f_sc!(dx, t, x, u, v)
    dx[1] = x[2]
    dx[2] = u
    return nothing
end
dynamics!(pre, f_sc!)

function boundary_sc!(b, x0_, xf_, v)
    b[1] = x0_[1] - x0[1]
    b[2] = x0_[2] - x0[2]
    b[3] = xf_[1] - xf[1]
    b[4] = xf_[2] - xf[2]
    return nothing
end
constraint!(pre,
    :boundary; f=boundary_sc!, lb=zeros(4), ub=zeros(4), label=:endpoint
)

function path_sc!(c, t, x, u, v)
    c[1] = x[2]          # v(t) ≤ VMAX
    return nothing
end
constraint!(pre,
    :path; f=path_sc!, lb=[-Inf], ub=[VMAX], label=:vmax
)

objective!(pre, :min; lagrange=(t, x, u, v) -> 0.5 * u^2)

time_dependence!(pre; autonomous=true)

ocp_func = build(pre)
nothing # hide
```

```@raw html
</div>
</div>
```

```@example ex-state-constraint
sol_macro = solve(ocp_macro; grid_size=50, display=false)
sol_func = solve(ocp_func; grid_size=50, display=false)
println(
    "objective: macro = ", objective(sol_macro),
    ", functional = ", objective(sol_func),
)
```

Full worked story (direct + indirect): [State constraint](@ref examples-state-constraint) · [example gallery](@ref examples-gallery).

## [Shapes in callbacks](@id modelling-functional-api-shapes)

The control above is declared with `control!(pre, 1)` — dimension 1 — and inside the callbacks `f_energy!` and `lagrange_energy` it is used as a bare `u`, not `u[1]`. This is not a special case: **1-D state, control and variable components arrive as scalars in every functional-API callback** (`dynamics!`, `objective!`, `constraint!`), exactly as on a solution and exactly as the `@def` convention (see the note on [Control](@ref modelling-abstract-syntax-control)). There is no asymmetry between "inside a callback" and "on a solution" — a dimension-1 quantity is a `Real` everywhere:

```@example ex-energy
u_macro = control(sol_macro)
u_func  = control(sol_func)
u_macro(t0), u_func(t0)
```

```@example ex-energy
typeof(u_macro(t0)), typeof(u_func(t0))
```

The **in-place output buffer is the one exception**: `dx` (dynamics), `val` (boundary/path constraints) is always a vector of its declared length, written by index, even when that length is 1 — a scalar cannot be mutated in place:

```julia
f!(r, t, x, u, v) = (r[1] = -x + u; nothing)  # r vector; x,u scalars
```

This is the one place on the site where this is spelled out; every other page just follows it.

## Order and preconditions

- `variable!` → before `time!` when using free-time indices (`indf`, `ind0`)
- `variable!` → before `dynamics!` and `objective!`
- `dynamics!` and `objective!` → after `time!` and `state!`
- `control!` is optional and, when used, has no ordering constraint of its own beyond needing `state!` first (component-count validation) — see [No control](@ref modelling-without-control) for what omitting it means.

## Equivalence

The abstract and functional forms are not just "meant to agree" — it's a tested contract. `test/suite/problems/test_forms_equivalent.jl` builds both forms for every problem in the shared test library and asserts they agree on dimensions, traits (`is_autonomous`, `is_variable`, `is_control_free`), time-horizon status, cost, dynamics, and constraint-dimension accessors. The one deliberate difference the test itself asserts: `has_abstract_definition` is `true` only for the `@def` form, as shown above.

## See also

- [Formulation](@ref modelling-formulation) — the mathematics this API builds.
- [Abstract syntax (`@def`)](@ref modelling-abstract-syntax) — the macro alternative.
- [No control](@ref modelling-without-control) — omitting `control!` entirely.
- [Inspect a problem](@ref modelling-inspect) — read a built model back.
