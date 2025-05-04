# CTFlows.jl

```@meta
CollapsedDocStrings = false
```

The [CTFlows.jl](control-toolbox.org/CTFlows.jl) package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
B(<a href='https://control-toolbox.org/OptimalControl.jl/stable/dev-ctbase.html'>CTBase</a>)
M(<a href='https://control-toolbox.org/OptimalControl.jl/stable/dev-ctmodels.html'>CTModels</a>)
P(<a href='https://control-toolbox.org/OptimalControl.jl/stable/dev-ctparser.html'>CTParser</a>)
O(<a href='https://control-toolbox.org/OptimalControl.jl/stable/dev-optimalcontrol.html'>OptimalControl</a>)
D(<a href='https://control-toolbox.org/OptimalControl.jl/stable/dev-ctdirect.html'>CTDirect</a>)
F(<a href='https://control-toolbox.org/OptimalControl.jl/stable/dev-ctflows.html'>CTFlows</a>)
O --> D
O --> M
O --> F
O --> P
F --> M
O --> B
F --> B
D --> B
D --> M
P --> M
P --> B
M --> B
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