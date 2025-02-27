# [Initial guess (or iterate) for the resolution](@id tutorial-initial-guess)

```@meta
CurrentModule =  OptimalControl
```

We present in this tutorial the different possibilities to provide an initial guess to solve an 
optimal control problem with the [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package. 

First, we need to import the OptimalControl.jl package to define the 
optimal control problem and [NLPModelsIpopt.jl](jso.dev/NLPModelsIpopt.jl) to solve it. 
We also need to import the [Plots.jl](https://docs.juliaplots.org) package to plot the solution.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

For the illustrations, we define the following optimal control problem.

```@example main
t0 = 0
tf = 10
α  = 5

ocp = @def begin
    t ∈ [t0, tf], time
    v ∈ R, variable
    x ∈ R², state
    u ∈ R, control
    x(t0) == [ -1, 0 ]
    x₁(tf) == 0
    ẋ(t) == [ x₂(t), x₁(t) + α*x₁(t)^2 + u(t) ]
    x₂(tf)^2 + ∫( 0.5u(t)^2 ) → min
end
nothing # hide
```

## Default initial guess

We first solve the problem without giving an initial guess.
This will default to initialize all variables to 0.1.

```@example main
# solve the optimal control problem without initial guess
sol = solve(ocp; display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

Let us plot the solution of the optimal control problem.

```@example main
plot(sol; size=(600, 450))
```

Note that the following formulations are equivalent to not giving an initial guess.

```@example main
sol = solve(ocp; init=nothing, display=false)
println("Number of iterations: ", iterations(sol))

sol = solve(ocp; init=(), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```
!!! tip "Interactions with an optimal control solution"

    To get the number of iterations of the solver, check the [`iterations`](@ref) function.

To reduce the number of iterations and improve the convergence, we can give an initial guess to the solver. 
This initial guess can be built from constant values, interpolated vectors, functions, or existing solutions.
Except when initializing from a solution, the arguments are to be passed as a named tuple ```init=(state=..., control=..., variable=...)``` whose fields are optional. Missing fields will revert to default initialization (ie constant 0.1).

## Constant initial guess

We first illustrate the constant initial guess, using vectors or scalars according to the dimension.

```@example main
# solve the optimal control problem with initial guess with constant values
sol = solve(ocp; init=(state=[-0.2, 0.1], control=-0.2, variable=0.05), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

Partial initializations are also valid, as shown below. Note the ending comma when a single argument is passed, since it must be a tuple.
```@example main
# initialisation only on the state
sol = solve(ocp; init=(state=[-0.2, 0.1],), display=false)
println("Number of iterations: ", iterations(sol))

# initialisation only on the control
sol = solve(ocp; init=(control=-0.2,), display=false)
println("Number of iterations: ", iterations(sol))

# initialisation only on the state and the variable
sol = solve(ocp; init=(state=[-0.2, 0.1], variable=0.05), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

## Functional initial guess
For the state and control, we can also provide functions of time as initial guess.

```@example main
# initial guess as functions of time
x(t) = [ -0.2t, 0.1t ]
u(t) = -0.2t

sol = solve(ocp; init=(state=x, control=u, variable=0.05), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

## Vector initial guess (interpolated)
Initialization can also be provided with vectors / matrices to be interpolated along a given time grid. 
In this case the time steps must be given through an additional argument ```time```, which can be a vector or line/column matrix.
For the values to be interpolated both matrices and vectors of vectors are allowed, but the shape should be *number of time steps x variable dimension*.
Simple vectors are also allowed for variables of dimension 1.

```@example main
# initial guess as vector of points
t_vec = LinRange(t0,tf,4)
x_vec = [[0, 0], [-0.1, 0.3], [-0.15,0.4], [-0.3, 0.5]]
u_vec = [0, -0.8,  -0.3, 0]

sol = solve(ocp; init=(time=t_vec, state=x_vec, control=u_vec, variable=0.05), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

Note: in the free final time case, the given time grid should be consistent with the initial guess provided for the final time (in the optimization variables).

## Mixed initial guess

The constant, functional and vector initializations can be mixed, for instance as

```@example main
# we can mix constant values with functions of time
sol = solve(ocp; init=(state=[-0.2, 0.1], control=u, variable=0.05), display=false)
println("Number of iterations: ", iterations(sol))

# wa can mix every possibility
sol = solve(ocp; init=(time=t_vec, state=x_vec, control=u, variable=0.05), display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

## Solution as initial guess (warm start)

Finally, we can use an existing solution to provide the initial guess. 
The dimensions of the state, control and optimization variable must coincide.
This particular feature allows an easy implementation of discrete continuations.

```@example main
# generate the initial solution
sol_init = solve(ocp; display=false)

# solve the problem using solution as initial guess
sol = solve(ocp; init=sol_init, display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
```

Note that you can also manually pick and choose which data to reuse from a solution, by recovering the 
functions ```state(sol)```, ```control(sol)``` and the values ```variable(sol)```.
For instance the following formulation is equivalent to the ```init=sol``` one.

```@example main
# use a previous solution to initialise picking data
sol = solve(ocp; 
    init = (
        state    = state(sol), 
        control  = control(sol), 
        variable = variable(sol)
    ), 
    display=false)
println("Number of iterations: ", iterations(sol))
nothing # hide
``` 

!!! tip "Interactions with an optimal control solution"

    Please check [`state`](@ref), [`costate`](@ref), [`control`](@ref) and [`variable`](@ref) to get data from the solution. The functions `state`, `costate` and `control` return functions of time and `variable` returns a vector.

## Costate / multipliers

For the moment there is no option to provide an initial guess for the costate / multipliers.

