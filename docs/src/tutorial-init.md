# Initial guess options

```@meta
CurrentModule =  OptimalControl
```

We present in this tutorial the different possibilities to provide an initial guess to solve an optimal control problem using the [`solve`](@ref) command. For the illustrations, we define the following optimal control problem.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

```@example main
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
## Default initial guess
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

Note that the three following formulations are equivalent
```@example main
sol = solve(ocp, display=false)
sol = solve(ocp, display=false, init=nothing)
sol = solve(ocp, display=false, init=())
```

To reduce the number of iterations and improve the convergence, we can give an initial guess to the solver. 
This initial guess can be built from constant values, interpolated matrices, functions, or existing solutions.
Except when initializing from a solution, the arguments are to be passed as a named tuple ```init=(state=..., control=..., variable=...)``` whose fields are optional. Missing fields will revert to default initialization (ie constant 0.1).

## Constant initial guess
We first illustrate the constant initial guess, using vectors or scalars according to the dimension.

```@example main
# solve the optimal control problem with initial guess
sol = solve(ocp, display=false, init=(state=[-0.2, 0.1], control=-0.2, variable=0.05))

# print the number of iterations
println("Number of iterations: ", sol.iterations)
nothing # hide
```

Partial initializations are also valid, such as
```@example main
sol = solve(ocp, display=false, init=(state=[-0.2, 0.1],))
sol = solve(ocp, display=false, init=(control=-0.2,))
sol = solve(ocp, display=false, init=(state=[-0.2, 0.1], variable=0.05))
```

## Functional initial guess
For the state and control, we can also provide functions of time as initial guess.

```@example main
# initial guess as functions of time
x(t) = [ -0.2t, 0.1t ]
u(t) = -0.2t

# solve the optimal control problem with initial guess
sol = solve(ocp, display=false, init=(state=x, control=u, variable=0.05))

# print the number of iterations
println("Number of iterations: ", sol.iterations)
nothing # hide
```

## Vector initial guess (interpolated)
Initialization can also be provided with vectors / matrices to be interpolated along a given time grid. 
In this case the time steps must be given through an additional argument ```time```, which can be a vector or line/column matrix.
For the values to be interpolated both matrices and vectors of vectors are allowed, but the shape should be *number of time steps x variable dimension*.
Simple vectors are also allowed for variables of dimension 1.

```@example main
time_grid = LinRange(t0,tf,4)
x_vec = [[0, 0], [1, 2], [0.5,-0.3], [5, -1]]
x_matrix = [0 0; 1 2; 0.5 -0.3; 5 -1]
u_vec = [0, 0.8,  0.3, .1]

sol = solve(ocp, display=false, init=(time=time_grid, state=x_vec, control=u_vec, variable=0.05))

println("Number of iterations: ", sol.iterations)
nothing # hide
```

Note: in the free final time case, the given time grid should be consistent with the initial guess provided for the final time (in the optimization variables).

## Mixed initial guess
The constant, functional and vector initializations can be mixed, for instance as
```@example main
sol = solve(ocp, display=false, init=(state=[-0.2, 0.1], control=u, variable=0.05))
println("Number of iterations: ", sol.iterations)
nothing # hide

sol = solve(ocp, display=false, init=(time=time_grid, state=x_matrix, control=u, variable=0.05))
println("Number of iterations: ", sol.iterations)
nothing # hide
```

## Solution as initial guess (warm start)
Finally, we can use an existing solution to provide the initial guess. 
The dimensions of the state, control and optimization variable must coincide.
This particular feature allows an easy implementation of discrete continuations.
```@example main
# generate the initial solution
sol_init = solve(ocp, display=false)

# solve the problem using solution as initial guess
sol = solve(ocp, init=sol_init, display=false)

# print the number of iterations
println("Number of iterations: ", sol.iterations)
nothing # hide
```

Note that you can also manually pick and choose which data to reuse from a solution, by recovering the functions ```sol.state```, ```sol.control``` and the values ```sol.variable```.
The two following formulations are equivalent
```@example main
sol = solve(ocp, display=false, init=sol)
sol = solve(ocp, display=false, init=(state=sol.state, control=sol.control, variable=sol.variable))
``` 


!!! warning

    For the moment we can not provide an initial guess for the costate / multipliers.

