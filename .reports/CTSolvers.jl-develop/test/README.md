# Testing Guide for CTSolvers

This directory contains the test suite for `CTSolvers.jl`. It follows the testing conventions and infrastructure provided by [CTBase.jl](https://github.com/control-toolbox/CTBase.jl).

For detailed guidelines on testing and coverage, please refer to:

- [CTBase Test Coverage Guide](https://control-toolbox.org/CTBase.jl/stable/test-coverage-guide.html)
- [CTBase TestRunner Extension](https://github.com/control-toolbox/CTBase.jl/blob/main/ext/TestRunner.jl)
- [CTBase CoveragePostprocessing](https://github.com/control-toolbox/CTBase.jl/blob/main/ext/CoveragePostprocessing.jl)

---

## 1. Running Tests

Tests are executed using the standard Julia Test interface, enhanced by `CTBase.TestRunner`.

### Default Run (All Enabled Tests)

```bash
julia --project=@. -e 'using Pkg; Pkg.test()'
```

### Running Specific Test Groups

To run only specific test groups (e.g., `options`):

```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/options/*"])'
```

Multiple groups can be specified:

```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/options/*", "suite/optimization/*"])'
```

### Running All Tests (Including Optional/Long Tests)

```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["all"])'
```

---

## 2. Coverage

To run tests with coverage and generate a report:

```bash
julia --project=@. -e 'using Pkg; Pkg.test("CTSolvers"; coverage=true); include("test/coverage.jl")'
```

This will:

1. Run all tests with coverage tracking
2. Process `.cov` files
3. Move them to `coverage/` directory
4. Generate an HTML report in `coverage/html/`

---

## 3. Adding New Tests

### File and Function Naming

All test files must follow this pattern:

- **File name**: `test_<name>.jl`
- **Entry function**: `test_<name>()` (matching the filename exactly)

Example:

```julia
# File: test/suite/options/test_extraction.jl
module TestExtraction

using Test
using CTSolvers
using Main.TestOptions: VERBOSE, SHOWTIMING

function test_extraction()
    @testset "Options Extraction" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Tests here
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_extraction() = TestExtraction.test_extraction()
```

### Registering the Test

Tests are automatically discovered by the `CTBase.TestRunner` extension using the pattern `suite/*/test_*`.

---

## 4. Best Practices & Rules

### ⚠️ Crucial: Struct Definitions

**NEVER define `struct`s inside test functions.** All helper types, mocks, and fakes must be defined at the **module top-level**.

```julia
# ❌ WRONG
function test_something()
    @testset "Test" begin
        struct FakeType end  # WRONG! Causes world-age issues
    end
end

# ✅ CORRECT
module TestSomething

# TOP-LEVEL: Define all structs here
struct FakeType end

function test_something()
    @testset "Test" begin
        obj = FakeType()  # Correct
    end
end

end # module
```

### Test Structure

- Use module isolation for each test file
- Separate unit and integration tests with clear comments
- Use qualified method calls (e.g., `CTSolvers.Options.extract_options()`)
- Each test must be independent and deterministic

### Directory Structure

Tests are organized under `test/suite/` by **functionality**, not by source file structure:

- `suite/options/` - Options system tests
- `suite/optimization/` - Optimization module tests
- `suite/modelers/` - Modeler implementations tests
- `suite/strategies/` - Strategy framework tests
- `suite/orchestration/` - Orchestration layer tests
- `suite/docp/` - DOCP module tests
- `suite/extensions/` - Extension tests (Ipopt, MadNLP, etc.)
- `suite/integration/` - End-to-end integration tests

---

For more detailed testing standards, see `.windsurf/rules/testing.md` in the project root.
