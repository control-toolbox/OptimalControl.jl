# CTFlows reexports
#
# Almost everything this file used to import has moved: the type vocabulary to
# `CTBase.Data` (imports/ctbase.jl) and the differential geometry to `CTLie`
# (imports/ctlie.jl). What remains genuinely belongs to CTFlows.

# For internal use. The module name is not exported (#967).
using CTFlows: CTFlows

# Flows
@reexport import CTFlows.Flows: Flow

# Systems — `control_law`, `pseudo_hamiltonian` and `hamiltonian` (below) are one
# function each, owned by `CTBase.Data` and extended by CTModels (on a model:
# `pseudo_hamiltonian(ocp)`, `hamiltonian(ocp, u)`) and by `CTFlows.Systems` (on a
# system or a flow). Importing them from here or from `CTBase.Data` is the same.
@reexport import CTFlows.Systems: control_law, pseudo_hamiltonian

# Flow accessors — the system a flow integrates and its integrator.
@reexport import CTFlows.Flows: system, integrator

# Systems accessors
@reexport import CTFlows.Systems:
    hamiltonian,
    hamiltonian_vector_field,
    vector_field,
    get_hamiltonian_gradient,
    get_variable_gradient,
    get_pseudo_hamiltonian_gradient,
    get_pseudo_variable_gradient

# Output grids — the `grid` keyword of a trajectory call. `grid=n` covers the common
# case; the types are reached qualified, like the other configuration objects
# (`OptimalControl.AdaptiveGrid(50)`). `AbstractGrid` and `AutomaticGrid` (the default)
# stay in CTFlows.
import CTFlows.Configs: UniformGrid, AdaptiveGrid

# Multi-phase flows — `Base.:*` is extended by `CTFlows.MultiPhase` to
# concatenate flows, so it needs no re-export of its own.
@reexport import CTFlows.MultiPhase:
    AnyMultiPhaseFlow,
    MultiPhaseFlow,
    MultiPhaseStateFlow,
    MultiPhaseHamiltonianFlow,
    n_phases,
    get_flow,
    get_flows,
    get_jump,
    get_jumps,
    get_switching_time,
    get_switching_times
