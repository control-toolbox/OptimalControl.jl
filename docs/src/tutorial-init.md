# Initial guess

We define the following optimal control problem.

```@example main
using OptimalControl

t0 = 0
tf = 10
α  = 5

@def ocp begin
    t ∈ [ t0, tf ], time
    v ∈ R, variable
    x ∈ R², state
    u ∈ R, control
    x(t0) == [ -1, 0 ]
    x(tf) - [ 0, v ] == [0, 0]
    ẋ(t) == [ x₂(t), x₁(t) + α*x₁(t)^2 + u(t) ]
    v^2 + ∫( 0.5u(t)^2 ) → min
end
nothing # hide
```

We first solve the problem without giving an initial guess.

```@example main
# solve the optimal control problem without initial guess
sol = solve(ocp, display=false)

# print the number of iterations 
println("Number of iterations: ", sol.iterations)
nothing # hide
```

Let us plot the solution of the optimal control problem.

```@example main
plot(sol, size=(600, 450))
```

To reduce the number of iterations and improve the convergence, we can give an initial guess to the solver. We define the following initial guess.

```@example main
# constant initial guess
initial_guess = (state=[-0.2, 0.1], control=-0.2, variable=0.05)

# solve the optimal control problem with initial guess
sol = solve(ocp, display=false, init=initial_guess)

# print the number of iterations
println("Number of iterations: ", sol.iterations)
nothing # hide
```

We can also provide functions of time as initial guess for the state and the control.

```@example main
# initial guess as functions of time
x(t) = [ -0.2 * t, 0.1 * t ]
u(t) = -0.2 * t
initial_guess = (state=x, control=u, variable=0.05)

# solve the optimal control problem with initial guess
sol = solve(ocp, display=false, init=initial_guess)

# print the number of iterations
println("Number of iterations: ", sol.iterations)
nothing # hide
```

!!! warning

    For the moment we can not provide an initial guess for the costate.
    Besides, there is neither cold nor warm start implemented yet. That is, we can not use the solution of a previous optimal control problem as initial guess.
