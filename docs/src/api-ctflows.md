# CTFlows.jl

```@meta
CollapsedDocStrings = true
```

The `CTFlows.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
O(<a href='https://control-toolbox.org/docs/optimalcontrol/stable/'>OptimalControl</a>) --> B(<a href='https://control-toolbox.org/docs/ctbase/stable/'>CTBase</a>)
O --> D(<a href='https://control-toolbox.org/docs/ctdirect/stable/'>CTDirect</a>)
O --> F(<a href='https://control-toolbox.org/docs/ctflows/stable/'>CTFlows</a>)
P(<a href='https://control-toolbox.org/docs/ctproblems/stable/'>CTProblems</a>) --> F
P --> B
F --> B
D --> B
style F fill:#FBF275
```

For the developers, here are the [private methods](@ref dev-ctflows).

## Index

```@index
Pages   = ["api-ctflows.md"]
Modules = [CTFlows]
Order   = [:module, :constant, :type, :function, :macro]
```

## Documentation

```@autodocs
Modules = [CTFlows]
Order   = [:module, :constant, :type, :function, :macro]
Private = false
```
