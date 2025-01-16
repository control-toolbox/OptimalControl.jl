# Minimal Action Method using Optimal Control

The Minimal Action Method (MAM) is used to find the maximum likelihood transition paths between stable states in dynamical systems. 
The Minimal Action Method is a numerical technique for finding the most probable transition pathway between stable states in stochastic dynamical systems. It achieves this by minimizing an action functional that represents the path's deviation from the deterministic dynamics, effectively identifying the path of least resistance through the system's landscape.
This tutorial demonstrates how to implement MAM as an optimal control problem.

## Required Packages

```@example oc_mam
using OptimalControl
using NLPModelsIpopt
using Plots, Printf
```

## Problem Setup

We'll consider a 2D system with a double-well flow, called the Maier-Stein model. It is a famous benchmark problem as it exhibits non-gradient dynamics with two stable equilibrium points at (-1,0) and (1,0), connected by a non-trivial transition path.
The system's deterministic dynamics are given by:

```@example oc_mam
# Define the vector field
f(u, v) = [u - u^3 - 10*u*v^2,  -(1 - u^2)*v]
f(x) = f(x...)
```

## Optimal Control Formulation

The minimal action path minimizes the deviation from the deterministic dynamics:

```@example oc_mam
mysqrt(x) = sqrt(x + 1e-1)
function ocp(T)
  action = @def begin
      t ∈ [0, T], time
      x ∈ R², state
      u ∈ R², control
      x(0) == [-1, 0]    # Starting point (left well)
      x(T) == [1, 0]     # End point (right well)
      ẋ(t) == u(t)       # Path dynamics
      ∫( sum((u(t) - f(x(t))).^2) ) → min  # Minimize deviation from deterministic flow
  end
  return action
end
```

## Initial Guess

We provide an initial guess for the path using a simple interpolation:

```@example oc_mam
# Time horizon
T = 50

# Linear interpolation for x₁
x1(t) = -(1 - t/T) + t/T

# Parabolic guess for x₂
x2(t) = 0.3(-x1(t)^2 + 1)
x(t) = [x1(t), x2(t)]
u(t) = f(x(t))

# Initial guess
init = (state=x, control=u)
```

## Solving the Problem

We solve the problem in two steps for better accuracy:

```@example oc_mam
# First solve with coarse grid
sol = solve(ocp(T); init=init, grid_size=50)

# Refine solution with finer grid
sol = solve(ocp(T); init=sol, grid_size=1000)

# Objective value
sol.objective
```

## Visualizing Results

Let's plot the solution trajectory and phase space:

```@example oc_mam
plot(sol)
```

```@example oc_mam
# Phase space plot
MLP = sol.state.(sol.time_grid)
scatter(first.(MLP), last.(MLP), 
        title="Minimal Action Path",
        xlabel="u",
        ylabel="v",
        label="Transition path")
```

The resulting path shows the most likely transition between the two stable states given a transient time $T=50$, minimizing the action functional while respecting the system's dynamics.

## Minimize with respect to T

To find the maximum likelihood path, we also need to minimize the transient time `T`. Hence, we perform a discrete continuation over the parameter `T` by solving the optimal control problem over a continuous range of final times `T`, using each solution to initialize the next problem.

```@example oc_mam
objectives = []
Ts = range(1,100,100)
sol = solve(ocp(Ts[1]); init=init, grid_size=50)
println(" Time   Objective     Iterations")
for T=Ts
    global sol = solve(ocp(T); display=false, init=sol, grid_size=1000)
    @printf("%6.2f  %9.6e  %d\n", T, sol.objective, sol.iterations)
    push!(objectives, sol.objective)
end
```

```@example oc_mam
@show Ts[argmin(objectives)]
plt1 = scatter(Ts, log10.(objectives))
plt2 = scatter(Ts[20:100], log10.(objectives[20:100]))
plot(plt1,plt2)
```
