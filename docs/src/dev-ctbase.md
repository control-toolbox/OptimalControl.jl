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

## Index

```@index
Pages   = ["dev-ctbase.md"]
Modules = [CTBase]
Order   = [:module, :constant, :type, :function, :macro]
```

## Documentation

### Public

```@autodocs
Modules = [CTBase]
Order   = [:module, :constant, :type, :function, :macro]
Private = false
```

### Private

```@autodocs
Modules = [CTBase]
Order   = [:type, :module, :constant, :type, :function, :macro]
Public  = false
```