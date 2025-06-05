# OptimalControl.jl (Private)

```@meta
CollapsedDocStrings = false
```

[OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) is the root package of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
B(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctbase.html'>CTBase</a>)
M(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctmodels.html'>CTModels</a>)
P(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctparser.html'>CTParser</a>)
O(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-optimalcontrol-dev.html'>OptimalControl</a>)
D(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctdirect.html'>CTDirect</a>)
F(<a href='https://control-toolbox.org/OptimalControl.jl/stable/api-ctflows.html'>CTFlows</a>)
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
Pages   = ["api-optimalcontrol-dev.md"]
Modules = [OptimalControl]
Order   = [:module, :constant, :type, :function, :macro]
```

## Documentation

```@autodocs
Modules = [OptimalControl]
Order   = [:type, :module, :constant, :type, :function, :macro]
Public  = false
```
