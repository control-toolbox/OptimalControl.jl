# Breaking Changes

This document describes all breaking changes introduced in CTSolvers.jl releases
and provides migration guides for users upgrading between versions.

---

## v0.3.6-beta (2026-02-19)

**Breaking change:** The routing and validation system has been refactored to simplify responsibilities and introduce a new bypass mechanism.

### Summary

- `route_all_options()` no longer accepts a `mode` parameter
- `mode=:permissive` behavior is replaced by explicit `bypass(val)` wrapper
- New `BypassValue{T}` type and `bypass(val)` function for validation bypass
- Simplified separation of concerns: routing vs validation

### Breaking Changes

#### 1. Removed `mode` parameter from `route_all_options`

**Before:**
```julia
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry;
    mode=:permissive  # or :strict
)
```

**After:**
```julia
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry
)
```

#### 2. Replaced `mode=:permissive` with explicit bypass

**Before:**
```julia
# Accept unknown options with warning
strat = MySolver(unknown_opt=42; mode=:permissive)
```

**After:**
```julia
# Explicit bypass for unknown options
strat = MySolver(unknown_opt=Strategies.bypass(42))
```

#### 3. Updated `route_to` usage for unknown options

**Before:**
```julia
# Would fail even in permissive mode for unknown options
kwargs = (custom_opt = Strategies.route_to(my_solver=42),)
```

**After:**
```julia
# Explicit bypass for unknown options
kwargs = (custom_opt = Strategies.route_to(my_solver=Strategies.bypass(42)),)
```

### Migration Guide

#### Replace `mode=:permissive` usage

**For unknown options:**
```julia
# Old
MySolver(custom_opt=42; mode=:permissive)

# New
MySolver(custom_opt=Strategies.bypass(42))
```

**For routing unknown options:**
```julia
# Old
kwargs = (opt = Strategies.route_to(strategy=42),)
routed = Orchestration.route_all_options(...; mode=:permissive)

# New
kwargs = (opt = Strategies.route_to(strategy=Strategies.bypass(42)),)
routed = Orchestration.route_all_options(...)
```

#### Remove `mode` parameter from `route_all_options`

```julia
# Old
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry;
    mode=:strict  # or :permissive
)

# New (no mode parameter)
routed = Orchestration.route_all_options(
    method, families, action_defs, kwargs, registry
)
```

#### Update error handling

`mode=:invalid_mode` now throws `MethodError` instead of `IncorrectArgument`:

```julia
# Old: Would throw IncorrectArgument
try
    Orchestration.route_all_options(...; mode=:invalid_mode)
catch e
    @test e isa Exceptions.IncorrectArgument
end

# New: Throws MethodError
try
    Orchestration.route_all_options(...; mode=:invalid_mode)
catch e
    @test e isa MethodError
end
```

### Benefits

- **Clearer API**: Explicit bypass makes intent obvious
- **Simpler architecture**: `route_all_options` only routes, `build_strategy_options` validates
- **Better error messages**: Unknown option errors now suggest `bypass()` usage
- **Type safety**: `BypassValue{T}` preserves type information through routing

---

## v0.3.3-beta (2026-02-16)

**Breaking change:** The base solver abstract type was renamed from
`AbstractOptimizationSolver` to `AbstractNLPSolver` for consistency with the
`AbstractNLPModeler` naming introduced in v0.3.0.

### Migration

Replace any references to the old abstract type:

```text
AbstractOptimizationSolver → AbstractNLPSolver
```

No other API changes are required.

---

## v0.3.2-beta (2026-02-15)

No breaking changes. This release focused on options getters/encapsulation
and documentation updates.

---

## v0.3.1-beta (2026-02-14)

No breaking changes.

---

## Breaking Changes — v0.3.0-beta

This document describes all breaking changes introduced in CTSolvers.jl v0.3.0-beta
and provides a migration guide for users upgrading from v0.2.x.

---

## Summary

All public types have been renamed to use shorter, module-qualified names.
This aligns with Julia conventions (`Module.Type`) and improves readability.

---

## Type Renaming

### Modelers

| v0.2.x                       | v0.3.0                 |
|------------------------------|------------------------|
| `ADNLPModeler`               | `Modelers.ADNLP`       |
| `ExaModeler`                 | `Modelers.Exa`         |
| `AbstractOptimizationModeler`| `AbstractNLPModeler`   |

### Solvers

| v0.2.x        | v0.3.0           |
|---------------|------------------|
| `IpoptSolver` | `Solvers.Ipopt`  |
| `MadNLPSolver`| `Solvers.MadNLP` |
| `MadNCLSolver`| `Solvers.MadNCL` |
| `KnitroSolver`| `Solvers.Knitro` |

### DOCP

| v0.2.x                             | v0.3.0             |
|------------------------------------|--------------------|
| `DiscretizedOptimalControlProblem` | `DiscretizedModel` |

---

## Migration Guide

### Search-and-replace

The simplest migration is a global search-and-replace in your codebase:

```text
ADNLPModeler                      →  Modelers.ADNLP
ExaModeler                        →  Modelers.Exa
AbstractOptimizationModeler       →  AbstractNLPModeler
IpoptSolver                       →  Solvers.Ipopt
MadNLPSolver                      →  Solvers.MadNLP
MadNCLSolver                      →  Solvers.MadNCL
KnitroSolver                      →  Solvers.Knitro
DiscretizedOptimalControlProblem  →  DiscretizedModel
```

### Code examples

**Before (v0.2.x):**

```julia
using CTSolvers

# Create modeler and solver
modeler = ADNLPModeler(backend=:sparse)
solver = IpoptSolver(max_iter=1000, tol=1e-6)

# Create DOCP
docp = DiscretizedOptimalControlProblem(ocp, builder)
```

**After (v0.3.0):**

```julia
using CTSolvers

# Create modeler and solver
modeler = Modelers.ADNLP(backend=:sparse)
solver = Solvers.Ipopt(max_iter=1000, tol=1e-6)

# Create DOCP
docp = DiscretizedModel(ocp, builder)
```

### Registry creation

**Before:**

```julia
registry = create_registry(
    AbstractOptimizationModeler => (ADNLPModeler, ExaModeler),
    AbstractNLPSolver => (IpoptSolver, MadNLPSolver)
)
```

**After:**

```julia
registry = create_registry(
    AbstractNLPModeler => (Modelers.ADNLP, Modelers.Exa),
    AbstractNLPSolver => (Solvers.Ipopt, Solvers.MadNLP)
)
```

---

## Other Changes

- **`src/Solvers/validation.jl`** has been removed. Validation is now handled
  entirely by the strategy framework (`Strategies.build_strategy_options`).
- **CTModels 0.9 compatibility** — this version requires CTModels v0.9.0-beta or later.
