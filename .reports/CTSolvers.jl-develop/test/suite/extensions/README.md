# Extension Tests

These tests verify the functionality of solver extensions. They require optional packages to be installed.

## Requirements

Each extension test requires specific packages:

### Ipopt Extension (`test_ipopt_extension.jl`)
```julia
using Pkg
Pkg.add("NLPModelsIpopt")
```

### Knitro Extension (`test_knitro_extension.jl`) - COMMENTED OUT
```julia
# using Pkg
# Pkg.add("NLPModelsKnitro")
```
**Note**: Knitro is a commercial solver requiring a license - NOT AVAILABLE

### MadNLP Extension (`test_madnlp_extension.jl`)
```julia
using Pkg
Pkg.add(["MadNLP", "MadNLPMumps"])
```

### MadNCL Extension (`test_madncl_extension.jl`)
```julia
using Pkg
Pkg.add(["MadNCL", "MadNLP", "MadNLPMumps"])
```

## Running Extension Tests

If the required packages are not installed, the tests will be skipped with a helpful message.

To run all extension tests (with packages installed):
```bash
julia --project=@. test/runtests.jl suite/extensions/test_ipopt_extension
# julia --project=@. test/runtests.jl suite/extensions/test_knitro_extension  # COMMENTED OUT - no license
julia --project=@. test/runtests.jl suite/extensions/test_madnlp_extension
julia --project=@. test/runtests.jl suite/extensions/test_madncl_extension
```

## Test Structure

Each extension test follows the same pattern:

1. **Check package availability** at runtime
2. **Skip tests** if packages are not available
3. **Unit tests**: Metadata, constructor, options extraction
4. **Integration tests**: Solve real problems (Rosenbrock, Elec, Max1MinusX2)

All tests follow the testing rules in `.windsurf/rules/testing.md` with:
- Module wrapper for isolation
- Qualified calls (e.g., `Solvers.Ipopt`, `Strategies.metadata()`)
- Fake types at top-level when needed
- Clear separation between unit and integration tests
