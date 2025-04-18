# CTModels.jl

```@meta
CollapsedDocStrings = false
```

The [CTModels.jl](control-toolbox.org/CTModels.jl) package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

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
P --> B
M --> B
style M fill:#FBF275
```

## Index

```@index
Pages   = ["dev-ctmodels.md"]
Modules = [CTModels]
Order   = [:module, :constant, :type, :function, :macro]
```

## Documentation

### Public

```@autodocs
Modules = [CTModels]
Order   = [:module, :constant, :type, :function, :macro]
Private = false
```

### Private

```@autodocs
Modules = [CTModels]
Order   = [:type, :module, :constant, :type, :function, :macro]
Public  = false
```