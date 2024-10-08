# CTBase.jl

```@meta
CollapsedDocStrings = true
```

The [CTBase.jl](control-toolbox.org/CTBase.jl/) package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
O(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-optimalcontrol.html'>OptimalControl</a>) --> B(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctbase.html'>CTBase</a>)
O --> D(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctdirect.html'>CTDirect</a>)
O --> F(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctflows.html'>CTFlows</a>)
F --> B
D --> B
style B fill:#FBF275
```

You may find in this package:

- [Description](@ref api-ctbase-description): tools to manipulate tuples.
- [Differential geometry](@ref api-ctbase-differential-geometry): tools to compute [Lie brackets](https://en.wikipedia.org/w/index.php?title=Lie_bracket_of_vector_fields&oldid=1163591634), [Poisson brackets](https://en.wikipedia.org/w/index.php?title=Poisson_manifold&oldid=1163991099#Formal_definition)...
- [Exceptions](@ref api-ctbase-exceptions).
- [Initial guess](@ref api-ctbase-init): tools to define an initial guess.
- [Model](@ref api-ctbase-model): tools to model an optimal control problem in a functional manner.
- [Parser](@ref api-ctbase-parser): tools to model an optimal control problem in an abstract manner.
- [Print](@ref api-ctbase-print): check how an optimal control problem is displayed.
- [Repl](@ref api-ctbase-repl): control-toolbox repl.
- [Solution](@ref api-ctbase-solution): optimal control solution.
- [Types](@ref api-ctbase-types): the common types and associated methods if any.
- [Utils](@ref api-ctbase-utils): auxiliary methods.

Here is the list of imported packages and exported functions.

```@autodocs
Modules = [CTBase, Base]
Order = [:module]
Pages = ["CTBase.jl"]
Private = false
```

For the developers, here are the [private methods](@ref dev-ctbase).