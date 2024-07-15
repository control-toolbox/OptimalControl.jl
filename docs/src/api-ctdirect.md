# CTDirect.jl

```@meta
CollapsedDocStrings = true
```

The `CTDirect.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
O(<a href='https://control-toolbox.org/OptimalControl.jl/stable/'>OptimalControl</a>) --> B(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctbase.html'>CTBase</a>)
O --> D(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctdirect.html'>CTDirect</a>)
O --> F(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctflows.html'>CTFlows</a>)
F --> B
D --> B
style D fill:#FBF275
```

For the developers, here are the [private methods](@ref dev-ctdirect).

## Index

```@index
Pages   = ["api-ctdirect.md"]
Modules = [CTDirect]
Order   = [:module, :constant, :type, :function, :macro]
```

## Documentation

```@autodocs
Modules = [CTDirect]
Order   = [:module, :constant, :type, :function, :macro]
Private = false
```
