# CTFlows.jl

```@meta
CollapsedDocStrings = true
```

The [CTFlows.jl](control-toolbox.org/CTFlows.jl) package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
O(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-optimalcontrol.html'>OptimalControl</a>) --> B(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctbase.html'>CTBase</a>)
O --> D(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctdirect.html'>CTDirect</a>)
O --> F(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctflows.html'>CTFlows</a>)
F --> B
D --> B
style F fill:#FBF275
```

## Index

```@index
Pages   = ["dev-ctflows.md"]
Modules = [CTFlows]
Order   = [:module, :constant, :type, :function, :macro]
```

## Documentation

### Public

```@autodocs
Modules = [CTFlows]
Order   = [:module, :constant, :type, :function, :macro]
Private = false
```

### Private

```@autodocs
Modules = [CTFlows]
Order   = [:type, :module, :constant, :type, :function, :macro]
Public  = false
```