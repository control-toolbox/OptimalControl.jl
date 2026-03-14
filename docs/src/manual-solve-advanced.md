# [Solve: advanced options](@id manual-solve-advanced)

```@meta
Draft = false
```

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
using CTDirect, CTSolvers, MadNLP
describe(Collocation)
```

```@example advanced
describe(Ipopt)
```

```@example advanced
describe(MadNLP)
```

## Ambiguous options and `route_to`

Some options exist in multiple strategies. For example, `tol` is recognized by both Ipopt and MadNLP solvers. If you try to use such an option without disambiguation, you'll get an error:

```julia
# This will raise an error
solve(ocp, :madnlp; tol=1e-6)
# ERROR: IncorrectArgument: Option 'tol' is ambiguous...
```

### Using `route_to` for disambiguation

Use `route_to` to explicitly specify which strategy family should receive the option:

```@example advanced
# Explicitly route 'tol' to the solver
sol = solve(ocp, :madnlp; 
    tol=route_to(solver=1e-6),
    max_iter=500,
    print_level=MadNLP.ERROR
)
nothing # hide
```

The `route_to` function accepts keyword arguments for each strategy family:

- `route_to(discretizer=value)` — route to the discretizer
- `route_to(modeler=value)` — route to the modeler  
- `route_to(solver=value)` — route to the solver

You can combine routed and non-routed options:

```@example advanced
sol = solve(ocp, :madnlp;
    grid_size=50,                    # auto-routed to discretizer
    max_iter=route_to(solver=1000),  # explicitly routed to solver
    print_level=MadNLP.ERROR         # auto-routed to solver
)
nothing # hide
```

## The `bypass` mechanism

By default, `solve` uses **strict validation**: any option not recognized by a registered strategy raises an error. This prevents typos and ensures you're using valid options.

However, some NLP solvers accept options that aren't declared in their strategy metadata. To pass such options, wrap them with `bypass`:

```@example advanced
# Pass an undeclared option to the solver
sol = solve(ocp, :ipopt;
    max_iter=100,
    print_level=0,
    # 'mu_strategy' might not be in Ipopt's declared metadata
    mu_strategy=route_to(solver=bypass("adaptive"))
)
nothing # hide
```

!!! warning "Use bypass sparingly"

    The `bypass` mechanism skips validation entirely. Use it only when:
    
    - You need to pass an option to the underlying NLP solver that isn't declared in the strategy metadata
    - You're certain the option name and value are correct
    
    Bypassed options are passed directly to the solver without type checking or validation.

### Combining `route_to` and `bypass`

You **must** combine `bypass` with `route_to` to specify which strategy should receive the bypassed option:

```julia
# Correct: route_to + bypass
solve(ocp; custom_opt=route_to(solver=bypass(42)))

# Wrong: bypass alone (will raise an error)
solve(ocp; custom_opt=bypass(42))  # ERROR!
```

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

## Introspection tools

OptimalControl.jl provides several functions to inspect strategies and their options.

### Strategy metadata

Use `describe` to see all available options for a strategy type:

```@example advanced
describe(Collocation)
```

This shows:

- Option names
- Types
- Default values
- Descriptions

### Instance options

Once you've created a strategy instance, use `options` to see its current configuration:

```@example advanced
solver = Ipopt(max_iter=1000, tol=1e-6, print_level=0)
opts = options(solver)
```

### Option queries

Query individual option properties:

```@example advanced
# Get option names
option_names(opts)
```

```@example advanced
# Get a specific option's value
option_value(opts, :max_iter)
```

```@example advanced
# Get the default value for an option
option_default(opts, :max_iter)
```

```@example advanced
# Check the source (provenance) of an option
option_source(opts, :max_iter)  # :user (you set it)
```

```@example advanced
option_source(opts, :acceptable_tol)  # :default (not set by you)
```

### Provenance checks

Check where an option value came from:

```@example advanced
# Was this option set by the user?
is_user(opts, :max_iter)
```

```@example advanced
# Is this option using its default value?
is_default(opts, :max_iter)
```

```@example advanced
is_default(opts, :acceptable_tol)
```

```@example advanced
# Was this option computed/inferred?
is_computed(opts, :max_iter)
```

These tools are useful for:

- Debugging option routing issues
- Understanding which options are active
- Verifying that your custom options were applied

## See also

- **[Basic solve](@ref manual-solve)**: descriptive mode basics
- **[Explicit mode](@ref manual-solve-explicit)**: using typed components
- **[GPU solving](@ref manual-solve-gpu)**: GPU parameter and types
- **[CTSolvers Options System](https://control-toolbox.org/CTSolvers.jl/stable/guides/options_system.html)**: detailed options system documentation
