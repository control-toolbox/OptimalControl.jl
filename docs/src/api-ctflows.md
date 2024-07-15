# CTFlows.jl

```@meta
CollapsedDocStrings = true
```

The `CTFlows.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
O(<a href='https://control-toolbox.org/OptimalControl.jl/stable/'>OptimalControl</a>) --> B(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctbase.html'>CTBase</a>)
O --> D(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctdirect.html'>CTDirect</a>)
O --> F(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctflows.html'>CTFlows</a>)
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
