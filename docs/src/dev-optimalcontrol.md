# OptimalControl.jl

```@meta
CollapsedDocStrings = false
```

The [OptimalControl.jl](https://control-toolbox.org/OptimalControl.jl) package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

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
style O fill:#FBF275
```

## Index

```@index
Pages   = ["dev-optimalcontrol.md"]
Modules = [OptimalControl]
Order   = [:module, :constant, :type, :function, :macro]
```

## Available methods

```@example
using OptimalControl
available_methods()
```

## Documentation

### Public

```@autodocs
Modules = [OptimalControl]
Order   = [:module, :constant, :type, :function, :macro]
Private = false
```

### Private

```@autodocs
Modules = [OptimalControl]
Order   = [:type, :module, :constant, :type, :function, :macro]
Public  = false
```
