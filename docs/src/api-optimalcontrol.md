# OptimalControl.jl

```@meta
CollapsedDocStrings = true
```

The OptimalControl.jl package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
O(<a href='https://control-toolbox.org/OptimalControl.jl/stable/'>OptimalControl</a>) --> B(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctbase.html'>CTBase</a>)
O --> D(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctdirect.html'>CTDirect</a>)
O --> F(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctflows.html'>CTFlows</a>)
F --> B
D --> B
style O fill:#FBF275
```

## Index

```@index
Pages   = ["api-optimalcontrol.md"]
Modules = [OptimalControl]
Order   = [:module, :constant, :type, :function, :macro]
```

For the developers, here are the [private methods](@ref dev-optimalcontrol).

## Available methods

```@example
using OptimalControl
available_methods()
```

## Documentation

```@autodocs
Modules = [OptimalControl]
Order   = [:module, :constant, :type, :function, :macro]
Private = false
```
