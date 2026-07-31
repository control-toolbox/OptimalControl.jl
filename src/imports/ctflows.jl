# CTFlows reexports
#
# Almost everything this file used to import has moved: the type vocabulary to
# `CTBase.Data` (imports/ctbase.jl) and the differential geometry to `CTLie`
# (imports/ctlie.jl). What remains genuinely belongs to CTFlows.

# Generated code
@reexport import CTFlows: CTFlows # for generated code (prefix)

# Flows
@reexport import CTFlows.Flows: Flow

# Systems — the `control_law` / `pseudo_hamiltonian` exported here are the
# CTFlows ones (siblings of `hamiltonian(sys)`), not the `CTBase.Data` ones,
# which act on a bare `ComposedHamiltonian`.
@reexport import CTFlows.Systems: control_law, pseudo_hamiltonian

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
