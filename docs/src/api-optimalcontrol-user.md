# OptimalControl.jl

```@meta
CollapsedDocStrings = false
```

[OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) is the root package of the [control-toolbox ecosystem](https://github.com/control-toolbox).

## Index

```@index
Pages   = ["api-optimalcontrol-user.md"]
Modules = [OptimalControl, CTBase, CTDirect, CTFlows, CTModels, CTParser, CommonSolve, RecipesBase]
Order   = [:module, :constant, :type, :function, :macro]
```

## Documentation

```@docs; canonical=true
Flow
@Lie
Lie
Lift
Model
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
plot(::CTModels.Solution, ::Symbol...)
plot!(::Plots.Plot, ::CTModels.Solution, ::Symbol...)
set_initial_guess
solve(::CTModels.Model, ::Symbol...)
state
state_components
state_dimension
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
```
