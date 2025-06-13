# OptimalControl.jl

```@meta
CollapsedDocStrings = false
```

[OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) is the core package of the [control-toolbox ecosystem](https://github.com/control-toolbox). Below, we group together all the functions exported by OptimalControl.

!!! tip "Beware!"

    Even if the following functions are prefixed by another package, such as `CTFlows.Lift`, they can all be used with OptimalControl. In fact, all functions prefixed with another package are simply reexported. For example, `Lift` is defined in CTFlows but accessible from OptimalControl.

    ```julia-repl
    julia> using OptimalControl
    julia> F(x) = 2x
    julia> H = Lift(F)
    julia> x = 1
    julia> p = 2
    julia> H(x, p)
    4
    ```

## Index

```@index
Pages   = ["api-optimalcontrol-user.md"]
Modules = [
    OptimalControl, 
    CTBase, 
    CTDirect, 
    CTFlows, 
    CTModels, 
    CTParser, 
    CommonSolve, 
    RecipesBase, 
    CTFlowsODE, 
    CTModelsPlots, 
    CTModelsJSON, 
    CTModelsJLD,
    CTSolveExtIpopt,
    CTSolveExtKnitro,
    CTSolveExtMadNLP,
]
Order   = [:module, :constant, :type, :function, :macro]
```

## Documentation

```@docs; canonical=true
Flow
@Lie
Lie
Lift
Model
Solution
ParsingError
Poisson
available_methods
build_OCP_solution
constraint
control
control_components
control_dimension
control_name
costate
criterion
@def
direct_transcription
dual
dynamics
export_ocp_solution
final_time
import_ocp_solution
infos
initial_time
iterations
lagrange
mayer
message
objective
plot(::Solution, ::Symbol...)
plot!(::Plots.Plot, ::Solution, ::Symbol...)
set_initial_guess
solve(::Model, ::Symbol...)
state
state_components
state_dimension(::Model)
state_dimension(::Solution)
state_name
stopping
time_grid
time_name
variable
variable_components
variable_dimension
variable_name
⋅
*(::CTFlowsODE.AbstractFlow)
boundary_constraints_dual
constraints_violation
control_constraints_box
control_constraints_lb_dual
control_constraints_ub_dual
final_time_name
has_fixed_initial_time
has_fixed_final_time
has_free_final_time
has_free_initial_time
has_lagrange_cost
has_mayer_cost
initial_time_name
is_autonomous(::Model{CTModels.Autonomous, <:CTModels.TimesModel})
path_constraints_dual
state_constraints_box
state_constraints_lb_dual
state_constraints_ub_dual
variable_constraints_box
variable_constraints_lb_dual
variable_constraints_ub_dual
```