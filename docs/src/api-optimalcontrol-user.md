# OptimalControl.jl

```@meta
CollapsedDocStrings = false
```

[OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) is the core package of the [control-toolbox ecosystem](https://github.com/control-toolbox). Below, we group together the documentation of all the functions and types exported by OptimalControl.

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

## Exported functions and types

```@autodocs
Modules = [OptimalControl]
Order   = [:module]
Private = false
```

## Index

```@index
Pages   = ["api-optimalcontrol-user.md"]
Modules = [
    OptimalControl,
    CommonSolve, 
    RecipesBase,
    CTBase, 
    CTDirect, 
    CTFlows, 
    CTModels, 
    CTParser, 
    CTFlowsODE, 
    CTModelsPlots, 
    CTModelsJSON, 
    CTModelsJLD,
    CTSolveExtIpopt,
    CTSolveExtKnitro,
    CTSolveExtMadNLP,
]

Order = [:module, :constant, :type, :function, :macro]
```

## Documentation

```@docs; canonical=true
*(::CTFlowsODE.AbstractFlow)
Flow
Hamiltonian
HamiltonianLift
HamiltonianVectorField
@Lie
Lie
Lift
Model
ParsingError
Poisson
Solution
VectorField
available_methods
boundary_constraints_dual
build_OCP_solution
constraint
constraints_violation
control
control_components
control_constraints_box
control_constraints_lb_dual
control_constraints_ub_dual
control_dimension
control_name
costate
criterion
@def
definition
direct_transcription
dual
dynamics
export_ocp_solution
final_time
final_time_name
has_fixed_final_time
has_fixed_initial_time
has_free_final_time
has_free_initial_time
has_lagrange_cost
has_mayer_cost
import_ocp_solution
infos
initial_time
initial_time_name
is_autonomous(::Model{CTModels.Autonomous, <:CTModels.TimesModel})
iterations
lagrange
mayer
message
objective
path_constraints_dual
plot(::Solution, ::Symbol...)
plot!(::Plots.Plot, ::Solution, ::Symbol...)
set_initial_guess
solve(::Model, ::Symbol...)
state
state_components
state_constraints_box
state_constraints_lb_dual
state_constraints_ub_dual
state_dimension
state_name
stopping
time_grid
time_name
variable
variable_components
variable_constraints_box
variable_constraints_lb_dual
variable_constraints_ub_dual
variable_dimension
variable_name
⋅
```
