# Discrete continuation

```@meta
CurrentModule =  OptimalControl
```

Using the warm start option, it is easy to implement a basic discrete continuation method, where a sequence of problems is solved using each solution as initial guess for the next problem.
This usually gives better and faster convergence than solving each problem with the same initial guess, and is a way to handle problems that require a good initial guess.


## Continuation on parametric OCP

The most compact syntax to perform a discrete continuation is to use a function that returns the OCP for a given value of the continuation parameter, and solve a sequence of these problems. We illustrate this on a very basic double integrator with increasing fixed final time.


First we load the required packages
```@example main
using OptimalControl
using NLPModelsIpopt
using Printf
using Plots
```
and write a function that returns the OCP for a given final time
```@example main
function ocp_T(T)
    @def ocp begin
        t ∈ [0, T], time
        x ∈ R², state
        u ∈ R, control
        q = x₁
        v = x₂
        q(0) == 0
        v(0) == 0
        q(T) == 1
        v(T) == 0
        ẋ(t) == [ v(t), u(t) ]
        ∫(u(t)^2) → min
    end
    return ocp
end
nothing # hide
```

Then we perform the continuation with a simple *for* loop, using each solution to initialize the next problem.

```@example main
init1 = ()
for T=1:5
    ocp1 = ocp_T(T) 
    sol1 = solve(ocp1; display=false, init=init1)
    global init1 = sol1
    @printf("T %.2f objective %9.6f iterations %d\n", T, sol1.objective, sol1.iterations)
end
```

## Continuation on global variable

As a second example, we show how to avoid redefining a new OCP each time, and modify the original one instead.
More precisely we now solve a Goddard problem for a decreasing maximal thrust. If we store the value for *Tmax* in a global variable, we can simply modify this variable and keep the same OCP problem during the continuation.

Let us first define the Goddard problem (note that the formulation below illustrates all the possible constraints types, and the problem could be defined in a more compact way).

```@example main
Cd = 310
Tmax = 3.5
β = 500
b = 2
function F0(x)
    r, v, m = x
    D = Cd * v^2 * exp(-β*(r - 1))
    return [ v, -D/m - 1/r^2, 0 ]
end
function F1(x)
    r, v, m = x
    return [ 0, Tmax/m, -b*Tmax ]
end

ocp = Model(variable=true)

r0 = 1
v0 = 0
m0 = 1
mf = 0.6
x0=[r0,v0,m0]

vmax = 0.1

state!(ocp, 3)
control!(ocp, 1)
variable!(ocp, 1)
time!(ocp; t0=0, indf=1)

constraint!(ocp, :initial; lb=x0, ub=x0)
constraint!(ocp, :final; rg=3, lb=mf, ub=Inf)
constraint!(ocp, :state; lb=[r0,v0,mf], ub=[r0+0.2,vmax,m0])
constraint!(ocp, :control; lb=0, ub=1)
constraint!(ocp, :variable; lb=0.01, ub=Inf)

objective!(ocp, :mayer, (x0, xf, v) -> xf[1], :max)

dynamics!(ocp, (x, u, v) -> F0(x) + u*F1(x) )

sol0 = solve(ocp; display=false)
@printf("Objective for reference solution %.6f\n", sol0.objective)
```

Then we perform the continuation on the maximal thrust.

```@example main
sol       = sol0
Tmax_list = []
obj_list  = []
for Tmax_local=3.5:-0.5:1
    global Tmax = Tmax_local  
    global sol = solve(ocp; display=false, init=sol)
    @printf("Tmax %.2f objective %.6f iterations %d\n", Tmax, sol.objective, sol.iterations)
    push!(Tmax_list, Tmax)
    push!(obj_list, sol.objective)
end 
```

We plot now the objective w.r.t the maximal thrust, as well as both solutions for *Tmax*=3.5 and *Tmax*=1.

```@example main
using Plots.PlotMeasures # for leftmargin

plt_obj = plot(Tmax_list, obj_list;
    seriestype=:scatter,
    title="Goddard problem",
    label="r(tf)", 
    xlabel="Maximal thrust (Tmax)",
    ylabel="Maximal altitude r(tf)")

plt_sol = plot(sol0; solution_label="(Tmax = "*string(Tmax_list[1])*")")
plot!(plt_sol, sol;  solution_label="(Tmax = "*string(Tmax_list[end])*")")

layout = grid(2, 1, heights=[0.2, 0.8])
plot(plt_obj, plt_sol; layout=layout, size=(800, 1000), leftmargin=5mm)
```
