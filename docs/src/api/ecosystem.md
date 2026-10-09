# [Ecosystem](@id api-ecosystem)

Everything documented in this API reference is reachable from `using OptimalControl`.
OptimalControl is the user-facing entry point of the control-toolbox ecosystem; it
re-exports and wires together the lower-level packages below.

| Package | Role |
| --- | --- |
| [CTBase](@extref CTBase index) | the foundation: shared types (vector fields, Hamiltonians), exceptions, strategies |
| [CTModels](@extref CTModels index) | the optimal control problem and its solution, with their accessors |
| [CTParser](@extref CTParser index) | the abstract syntax, `@def` |
| [CTDirect](@extref CTDirect index) | the direct method: the discretisation of the problem |
| [CTSolvers](@extref CTSolvers index) | the modelers and the solvers of the discretised problem |
| [CTFlows](@extref CTFlows index) | flows of vector fields and Hamiltonians, for the indirect method |
| [CTLie](@extref CTLie index) | Lie derivatives, Lie and Poisson brackets, lifts |
