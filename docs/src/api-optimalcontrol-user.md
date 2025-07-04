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
build_OCP_solution
constraint(::Model, ::Symbol)
constraints
constraints_violation
control
control_components
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
get_build_examodel
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
model
objective(::Model)
objective(::Solution)
plot(::Solution, ::Symbol...)
plot!(::Plots.Plot, ::Solution, ::Symbol...)
set_initial_guess
solve(::Model, ::Symbol...)
state
state_components
state_dimension
state_name
status
successful
time_grid
time_name
times
variable(::Model)
variable(::Solution)
variable_components
variable_dimension
variable_name
⋅
```
