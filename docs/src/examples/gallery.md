# [Example gallery](@id examples-gallery)

```@meta
Draft = false
```

A guide answers *"how do I do X"*; an example answers *"what does a real problem look like"*.
Each page here is a complete, self-contained problem worked end to end — a story with a
result, not a feature demonstration.

Read them in order: each one uses something the previous introduced.

| Example | Story | Introduces |
| --- | --- | --- |
| [Energy minimisation](@ref examples-double-integrator-energy) | The double integrator, transferred at minimal energy. | `@def`, `solve`, `plot`, a Hamiltonian flow, shooting |
| [Time minimisation (bang–bang)](@ref examples-double-integrator-time) | The same wagon, transferred as fast as possible. | bang–bang control, flow concatenation, switching-time detection |
| [Parameter estimation without a control](@ref examples-control-free) | Fitting a growth rate and an oscillator's pulsation — no control anywhere. | control-free problems, `variable_costate=true` |
| [Control and variable together](@ref examples-control-and-variable) | The same two systems, now with a control input to pay for. | estimating a parameter *and* a control at once |
| [Singular control](@ref examples-singular-control) | A drift system whose optimal control has a singular arc. | `Lift`, `@Lie` Poisson brackets, the Geometry toolkit's payoff |
| [State constraint](@ref examples-state-constraint) | The double integrator again, this time with a velocity or position bound. | boundary arcs, costate jumps, `constraint=`/`multiplier=` |

## See also

- [Flows overview](@ref flows-overview) and [Geometry overview](@ref geometry-overview) — the
  tools these examples are built from.
