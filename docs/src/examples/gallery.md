# [Example gallery](@id examples-gallery)

A guide answers *"how do I do X"*; an example answers *"what does a real problem look like"*.
Each page here is a complete problem worked end to end: the problem, the direct method, the
derivation of the solution from the maximum principle, the indirect method, and the
comparison of the two, checked against the exact values when they are known.

Read them in order: each one uses something the previous ones introduced.

| Example | Story | Introduces |
| --- | --- | --- |
| [Energy minimisation](@ref examples-double-integrator-energy) | A wagon on a rail, transferred with the least energy. | `@def`, `solve`, `plot`, a Hamiltonian flow, shooting from the direct solution |
| [Time minimisation (bang–bang)](@ref examples-double-integrator-time) | The same wagon, with a bounded force, transferred as fast as possible. | a free final time, bang–bang control, the switching time read off the direct solution, concatenation of flows |
| [Parameter estimation without a control](@ref examples-control-free) | A growth rate fitted to data, and the pulsation of an oscillator, with no control. | problems without a control, the costate of the variable (`variable_costate=true`) |
| [Control and variable together](@ref examples-control-and-variable) | The same two systems, with a control. | a parameter and a control optimised together, two extremals compared |
| [Turnpike (bang–singular–bang)](@ref examples-turnpike) | A scalar system whose optimal control is bang, singular, then bang. | singular arcs, switching times as shooting unknowns, three flows concatenated |
| [Singular control](@ref examples-singular-control) | A vehicle in a drift field, in minimum time. | the singular control by hand and with `Lift` and `@Lie` |
| [State constraint](@ref examples-state-constraint) | The wagon with a speed limit, then with a bound on its position (Bryson–Denham). | boundary arcs, `constraint=` and `multiplier=`, touch points and costate jumps |
| [The logo](@ref examples-logo) | A low-thrust orbit transfer, drawn three times. | an initial guess from an analytical trajectory, plotting with Makie |

## See also

- [Flows overview](@ref flows-overview) and [Geometry overview](@ref geometry-overview): the
  tools these examples are built from.
- [Notation and conventions](@ref modelling-formulation-conventions): the conventions of the
  derivations.
