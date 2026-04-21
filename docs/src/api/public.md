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
@Lie
Lie
Lift
Poisson
boundary_constraints_dual
boundary_constraints_nl
bypass
components
constraints
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
expression
describe
dim_boundary_constraints_nl
dim_control_constraints_box
dim_dual_control_constraints_box
dim_dual_state_constraints_box
dim_dual_variable_constraints_box
dim_path_constraints_nl
dim_state_constraints_box
dim_variable_constraints_box
dimension
discretize
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
has_option
has_variable
is_variable
has_control
is_control_free
has_abstract_definition
id
import_ocp_solution
index
infos
@init
initial_time
initial_time_name
is_autonomous
is_computed
is_default
is_abstractly_defined
is_nonautonomous
is_nonvariable
is_empty
is_empty_time_grid
is_final_time_fixed
is_final_time_free
is_initial_time_fixed
is_initial_time_free
is_lagrange_cost_defined
is_mayer_cost_defined
is_user
iterations
lagrange
mayer
message
metadata
methods
model
name
nlp_model
ocp_model
ocp_solution
option_default
option_defaults
option_description
option_names
option_source
option_type
option_value
options
path_constraints_dual
path_constraints_nl
plot
plot!
route_to
solve(::CTSolvers.Optimization.AbstractOptimizationProblem, ::Any, ::CTSolvers.Modelers.AbstractNLPModeler, ::CTSolvers.Solvers.AbstractNLPSolver)
solve(::CTModels.OCP.AbstractModel, ::Symbol...)
solve(::CTModels.OCP.AbstractModel, ::CTModels.Init.AbstractInitialGuess, ::CTDirect.AbstractDiscretizer, ::CTSolvers.Modelers.AbstractNLPModeler, ::CTSolvers.Solvers.AbstractNLPSolver)
state
state_components
state_constraints_box
state_constraints_lb_dual
state_constraints_ub_dual
state_dimension
state_name
status
success
successful
time
time_grid
time_name
times
variable_components
variable_constraints_box
variable_constraints_lb_dual
variable_constraints_ub_dual
variable_dimension
variable_name
⋅
```
