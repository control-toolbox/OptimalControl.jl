# CTBase.jl

```@meta
CollapsedDocStrings = false
```

The [CTBase.jl](https://github.com/control-toolbox/CTBase.jl/) package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```mermaid
flowchart TD
B(<a href='api-ctbase.html'>CTBase</a>)
M(<a href='api-ctmodels.html'>CTModels</a>)
P(<a href='api-ctparser.html'>CTParser</a>)
O(<a href='api-optimalcontrol-dev.html'>OptimalControl</a>)
D(<a href='api-ctdirect.html'>CTDirect</a>)
F(<a href='api-ctflows.html'>CTFlows</a>)
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
style B fill:#FBF275
```

OptimalControl heavily relies on CTBase. We refer to [CTBase API](@extref CTBase index) for more details.