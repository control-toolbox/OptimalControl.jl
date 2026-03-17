# [Solve: advanced options](@id manual-solve-advanced)

This manual covers advanced option management for the [`solve`](@ref) function: how option routing works, how to disambiguate shared options with `route_to`, how to pass unknown options with `bypass`, and how to use introspection tools.

For basic usage, see [Solve a problem](@ref manual-solve).

## Option routing system

When you call `solve` with keyword arguments, OptimalControl.jl automatically routes each option to the appropriate strategy (discretizer, modeler, or solver).

```@example advanced
using OptimalControl
using NLPModelsIpopt

t0 = 0
tf = 1
x0 = [-1, 0]

ocp = @def begin
    t ∈ [ t0, tf ], time
    x = (q, v) ∈ R², state
    u ∈ R, control
    x(t0) == x0
    x(tf) == [0, 0]
    ẋ(t)  == [v(t), u(t)]
    0.5∫( u(t)^2 ) → min
end

# Options are automatically routed
sol = solve(ocp; 
    grid_size=100,    # → Collocation (discretizer)
    show_time=true,   # → ADNLP (modeler)
    max_iter=500,     # → Ipopt (solver)
    print_level=0     # → Ipopt (solver)
)
nothing # hide
```

### How routing works

Each strategy declares its available options via metadata. When you pass an option:

1. **Lookup**: The system checks which strategies recognize this option name
2. **Route**: If exactly one strategy family (discretizer/modeler/solver) recognizes it, the option is routed there
3. **Validate**: The option value is validated against the declared type and constraints
4. **Error**: If no strategy recognizes the option, or if multiple families claim it, an error is raised

You can inspect a strategy's declared options using `describe`:

```@example advanced
using CUDA
describe(:exa)
```

The output shows:

- **Strategy ID**: The symbol used to reference this strategy (`:exa`)
- **Family**: The abstract type family (`AbstractNLPModeler`)
- **Default parameter**: Default execution backend (`CPU`)
- **Parameters**: Available execution backends (`CPU`, `GPU`)
- **Common options**: Options shared across all parameters
  - Option name and type
  - Default value
  - Description
- **Computed options**: Options that vary by parameter
  - Parameter-specific defaults
  - Whether the value is computed automatically

## Ambiguous options and `route_to`

Ambiguity occurs when an option name exists in multiple strategies **within the same method**. Since a method always has exactly one discretizer, one modeler, and one solver, ambiguity only happens when strategies from different families share an option name.

For example, suppose `:exa` (modeler) and `:madnlp` (solver) both have an option called `common_option_name`. If you try to use it without disambiguation, you'll get an error:

```julia
# This will raise an error
solve(ocp, :exa, :madnlp; common_option_name=12)
# ERROR: IncorrectArgument: Option 'common_option_name' is ambiguous...
```

### Using `route_to` for disambiguation

Use `route_to` to explicitly specify which **strategy** should receive the option:

```julia
# Explicitly route to the :exa strategy
sol = solve(ocp, :exa, :madnlp; 
    common_option_name=route_to(exa=12),
    max_iter=500,
    print_level=MadNLP.ERROR
)
```

The `route_to` function accepts keyword arguments with **strategy names**:

- `route_to(collocation=value)` — route to the Collocation discretizer
- `route_to(adnlp=value)` — route to the ADNLP modeler
- `route_to(exa=value)` — route to the Exa modeler
- `route_to(ipopt=value)` — route to the Ipopt solver
- `route_to(madnlp=value)` — route to the MadNLP solver
- `route_to(uno=value)` — route to the Uno solver
- `route_to(madncl=value)` — route to the MadNCL solver
- `route_to(knitro=value)` — route to the Knitro solver

You can use `route_to` even for non-ambiguous options, and combine routed and non-routed options:

```@example advanced
using MadNLP
sol = solve(ocp, :madnlp;
    grid_size=50,                      # auto-routed to discretizer
    max_iter=route_to(madnlp=1000),    # explicitly routed to solver
    print_level=MadNLP.ERROR           # auto-routed to solver
)
nothing # hide
```

## The `bypass` mechanism

By default, `solve` uses **strict validation**: any option not recognized by a registered strategy raises an error. This prevents typos and ensures you're using valid options.

However, NLP solvers have many options, and not all of them are declared in OptimalControl's strategy metadata. For example, Ipopt has an option `mumps_print_level` for controlling MUMPS debug output:

> `mumps_print_level`: Debug printing level for the linear solver MUMPS  
>
> 0: no printing; 1: Error messages only; 2: Error, warning, and main statistic messages; 3: Error and warning messages and terse diagnostics; ≥4: All information.

This option is not in the Ipopt strategy metadata. If you try to use it directly, you'll get an error:

```@repl advanced
sol = solve(ocp, :ipopt;
    max_iter=100,
    mumps_print_level=1)
```

To pass undeclared options, combine `route_to` with `bypass`:

```@repl advanced
sol = solve(ocp, :ipopt;
    max_iter=100,
    mumps_print_level=route_to(ipopt=bypass(1)))
```

You **must** combine `bypass` with `route_to` because:

- If the option is unknown, the system needs to know which strategy should receive it
- `bypass` forces the option through without validation

!!! note "Alias: force = bypass"
    You can use `force` as an alias for `bypass`: `route_to(ipopt=force(1))`

!!! warning "Use bypass sparingly"

    The `bypass` mechanism skips validation entirely. Use it only when:
    
    - You need to pass an option to the underlying solver that isn't declared in the strategy metadata
    - You're certain the option name and value are correct
    
    Bypassed options are passed directly to the solver without type checking or validation.

## Parameter token (CPU/GPU)

The 4th token in a method description specifies the execution backend: `:cpu` (default) or `:gpu`.

```@example advanced
# Explicitly request CPU execution (this is the default)
sol = solve(ocp, :collocation, :adnlp, :ipopt, :cpu; 
    grid_size=50, 
    print_level=0
)
nothing # hide
```

The parameter token automatically changes default options for GPU-capable strategies. For example:

- `Exa{GPU}` uses a CUDA backend by default
- `MadNLP{GPU}` uses `CUDSSSolver` as the linear solver by default

For full GPU usage details, see [Solve on GPU](@ref manual-solve-gpu).

## See also

- **[Basic solve](@ref manual-solve)**: descriptive mode basics
- **[Explicit mode](@ref manual-solve-explicit)**: using typed components
- **[GPU solving](@ref manual-solve-gpu)**: GPU parameter and types
