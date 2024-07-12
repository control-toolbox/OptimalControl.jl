# OptimalControl.jl

```@meta
CurrentModule =  OptimalControl
```

The `OptimalControl.jl` package aims to provide tools to solve optimal control problems by direct and indirect methods.
It is part of the [control-toolbox ecosystem](https://github.com/control-toolbox):

```mermaid
flowchart TD
O(<a href='https://control-toolbox.org/OptimalControl.jl/stable/'>OptimalControl</a>) --> B(<a href='https://control-toolbox.org/CTBase.jl/stable/'>CTBase</a>)
O --> D(<a href='https://control-toolbox.org/CTDirect.jl/stable/'>CTDirect</a>)
O --> F(<a href='https://control-toolbox.org/CTFlows.jl/stable/'>CTFlows</a>)
P(<a href='https://control-toolbox.org/CTProblems.jl/stable/'>CTProblems</a>) --> F
P --> B
F --> B
D --> B
style O fill:#FBF275
```

!!! note "Install and documentation"

    To install a package from the control-toolbox ecosystem, 
    please visit the [installation page](https://github.com/control-toolbox#installation).
    The documentation is accessible from the main menu.

An optimal control problem with fixed initial and final times can be described as minimising the cost functional

```math
g(x(t_0), x(t_f)) + \int_{t_0}^{t_f} f^{0}(t, x(t), u(t))~\mathrm{d}t
```

where the state $x$ and the control $u$ are functions subject, for $t \in [t_0, t_f]$,
to the differential constraint

```math
   \dot{x}(t) = f(t, x(t), u(t))
```

and other constraints such as

```math
\begin{array}{llcll}
~\xi_l  &\le& \xi(t, u(t))        &\le& \xi_u, \\
\eta_l &\le& \eta(t, x(t))       &\le& \eta_u, \\
\psi_l &\le& \psi(t, x(t), u(t)) &\le& \psi_u, \\
\phi_l &\le& \phi(t_0, x(t_0), t_f, x(t_f)) &\le& \phi_u.
\end{array}
```

See our tutorials to get started solving optimal control problems.
