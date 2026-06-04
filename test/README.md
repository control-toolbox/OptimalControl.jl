# Testing Guide for OptimalControl

This directory contains the test suite for `OptimalControl.jl`. It follows the testing conventions and infrastructure provided by [CTBase.jl](https://github.com/control-toolbox/CTBase.jl).

For detailed guidelines on testing and coverage, please refer to:

- [CTBase Test Coverage Guide](https://control-toolbox.org/CTBase.jl/stable/test-coverage-guide.html)
- [CTBase TestRunner Extension](https://github.com/control-toolbox/CTBase.jl/blob/main/ext/TestRunner.jl)
- [CTBase CoveragePostprocessing](https://github.com/control-toolbox/CTBase.jl/blob/main/ext/CoveragePostprocessing.jl)

---

## 1. Running Tests

Tests are executed using the standard Julia Test interface, enhanced by `CTBase.TestRunner`.

### Convenience Command: `jtest`

If the `jtest` command is available (custom script), you can use it for quick test execution:

```bash
# Run all tests
jtest

# Run specific test file(s)
jtest test_ctbase test_ctmodels

# Run test directory
jtest reexport
```

If `jtest` is not available, use the manual commands below.

### Default Run (All Enabled Tests)

```bash
julia --project=@. -e 'using Pkg; Pkg.test()' 2>&1 | tee /tmp/test_output.txt
```

**Note:** Always use `tee` to capture output to `/tmp/test_output.txt` for later inspection with `grep`.

### Running Specific Test Groups

To run only specific test groups (e.g., `reexport`):

```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/reexport/*"])' 2>&1 | tee /tmp/test_output.txt
```

Multiple groups can be specified:

```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/reexport/*", "suite/other/*"])' 2>&1 | tee /tmp/test_output.txt
```

### Running All Tests (Including Optional/Long Tests)

```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["all"])' 2>&1 | tee /tmp/test_output.txt
```

---

## 2. Coverage

To run tests with coverage and generate a report:

```bash
julia --project=@. -e 'using Pkg; Pkg.test("OptimalControl"; coverage=true); include("test/coverage.jl")' 2>&1 | tee /tmp/test_coverage_output.txt
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
# File: test/suite/reexport/test_ctbase.jl
module TestCtbase

using Test
using OptimalControl
const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

function test_ctbase()
    @testset "CTBase reexports" verbose=VERBOSE showtiming=SHOWTIMING begin
        # Tests here
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_ctbase() = TestCtbase.test_ctbase()
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
- Each test must be independent and deterministic

### Directory Structure

Tests are organized under `test/suite/` by **functionality**:

- `suite/reexport/` - Reexport verification tests

---

For more detailed testing standards, see the [CTBase Test Coverage Guide](https://control-toolbox.org/CTBase.jl/stable/test-coverage-guide.html).
