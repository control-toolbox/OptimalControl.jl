# Task 06: Integration Tests for Orchestration Layer

## 📋 Task Information

**Priority**: 6 (Final task)
**Estimated Time**: 60 minutes
**Layer**: Integration
**Created**: 2026-02-18

## 🎯 Objective

Add comprehensive integration tests to `test/suite/solve/test_orchestration.jl` that
validate the full orchestration chain end-to-end with real strategies and real OCP problems.
This mirrors the role of Task 09 in `kanban_explicit`.

## 📐 Mandatory Rules

This task MUST follow:
- 🧪 **Testing**: `.windsurf/rules/testing.md`
- 📋 **Architecture**: `.windsurf/rules/architecture.md`
- 📚 **Documentation**: `.windsurf/rules/docstrings.md`
- ⚠️ **Exceptions**: `.windsurf/rules/exceptions.md`

## 📝 Requirements

### Test Coverage

Extend `test/suite/solve/test_orchestration.jl` with:

**1. All explicit mode combinations**

Test that `CommonSolve.solve` with explicit components works for all method combinations
from `OptimalControl.methods()`. Use `max_iter=0` to keep tests fast.

```julia
Test.@testset "Explicit mode - all method combinations" begin
    pb = TestProblems.Beam()

    discretizers = [
        ("Collocation/midpoint", CTDirect.Collocation(grid_size=20, scheme=:midpoint)),
    ]
    modelers = [
        ("ADNLP", CTSolvers.ADNLP()),
        ("Exa",   CTSolvers.Exa()),
    ]
    solvers = [
        ("Ipopt",  CTSolvers.Ipopt(print_level=0, max_iter=0)),
        ("MadNLP", CTSolvers.MadNLP(print_level=MadNLP.ERROR, max_iter=0)),
        ("MadNCL", CTSolvers.MadNCL(print_level=MadNLP.ERROR, max_iter=0)),
    ]

    for (dname, disc) in discretizers
        for (mname, mod) in modelers
            for (sname, sol) in solvers
                Test.@testset "$dname + $mname + $sname" begin
                    result = CommonSolve.solve(pb.ocp;
                        initial_guess=pb.init,
                        discretizer=disc,
                        modeler=mod,
                        solver=sol,
                        display=false
                    )
                    Test.@test result isa CTModels.AbstractSolution
                    Test.@test OptimalControl.successful(result)
                end
            end
        end
    end
end
```

**2. All descriptive mode combinations**

Test that `CommonSolve.solve` with symbolic description works for all method combinations.

```julia
Test.@testset "Descriptive mode - all method combinations" begin
    pb = TestProblems.Beam()

    for (disc_sym, mod_sym, sol_sym) in OptimalControl.methods()
        Test.@testset ":$disc_sym + :$mod_sym + :$sol_sym" begin
            result = CommonSolve.solve(pb.ocp, disc_sym, mod_sym, sol_sym;
                initial_guess=pb.init,
                display=false,
                print_level=0,
                max_iter=0
            )
            Test.@test result isa CTModels.AbstractSolution
        end
    end
end
```

**3. Partial explicit components (registry completion)**

```julia
Test.@testset "Partial explicit - discretizer only" begin
    pb   = TestProblems.Beam()
    disc = CTDirect.Collocation(grid_size=20, scheme=:midpoint)

    result = CommonSolve.solve(pb.ocp;
        initial_guess=pb.init,
        discretizer=disc,
        display=false
    )
    Test.@test result isa CTModels.AbstractSolution
end

Test.@testset "Partial explicit - solver only" begin
    pb  = TestProblems.Beam()
    sol = CTSolvers.Ipopt(print_level=0, max_iter=0)

    result = CommonSolve.solve(pb.ocp;
        initial_guess=pb.init,
        solver=sol,
        display=false
    )
    Test.@test result isa CTModels.AbstractSolution
end
```

**4. Strategy-specific kwargs pass-through**

Verify that strategy-specific kwargs (e.g., `print_level`, `max_iter`) are correctly
forwarded to the underlying solver and do not cause errors.

```julia
Test.@testset "Strategy kwargs pass-through" begin
    pb = TestProblems.Beam()

    # print_level and max_iter are Ipopt-specific options
    result = CommonSolve.solve(pb.ocp, :collocation, :adnlp, :ipopt;
        initial_guess=pb.init,
        display=false,
        print_level=0,
        max_iter=0
    )
    Test.@test result isa CTModels.AbstractSolution
end
```

**5. Error cases**

```julia
Test.@testset "Error: explicit + description conflict" begin
    pb   = TestProblems.Beam()
    disc = CTDirect.Collocation(grid_size=20, scheme=:midpoint)

    Test.@test_throws CTBase.IncorrectArgument begin
        CommonSolve.solve(pb.ocp, :adnlp, :ipopt;
            initial_guess=pb.init,
            discretizer=disc,
            display=false
        )
    end
end
```

**6. Solution quality check (one reference problem)**

```julia
Test.@testset "Solution quality - Beam problem" begin
    pb = TestProblems.Beam()

    result = CommonSolve.solve(pb.ocp;
        initial_guess=pb.init,
        display=false
    )
    Test.@test result isa CTModels.AbstractSolution
    Test.@test OptimalControl.successful(result)
    # Verify objective is in expected range (from known solution)
    Test.@test isapprox(OptimalControl.objective(result), pb.obj; rtol=1e-2)
end
```

### Test File Structure

Extend `test/suite/solve/test_orchestration.jl` (created in Task 05) with a dedicated
integration test section:

```julia
# ====================================================================
# INTEGRATION TESTS - Full orchestration chain
# ====================================================================

Test.@testset "INTEGRATION TESTS" verbose=VERBOSE showtiming=SHOWTIMING begin
    # ... all integration tests above
end
```

## ✅ Acceptance Criteria

- [ ] Integration tests added to `test/suite/solve/test_orchestration.jl`
- [ ] All explicit mode combinations tested (all from `methods()`)
- [ ] All descriptive mode combinations tested
- [ ] Partial component completion tested
- [ ] Strategy kwargs pass-through tested
- [ ] Error cases tested
- [ ] Solution quality verified for at least one reference problem
- [ ] All tests pass
- [ ] No regressions in existing tests
- [ ] Test execution time documented in completion report

## 📦 Deliverables

1. Updated `test/suite/solve/test_orchestration.jl` with integration tests
2. All tests passing
3. Verification that the full orchestration chain works end-to-end

## 🔗 Dependencies

**Depends on**: All previous tasks (01-05)
**Required by**: None (final task)

## 💡 Notes

- Reuse the `TestProblems.Beam()` pattern from `test_explicit.jl`
- Use `max_iter=0` for speed in combination tests
- The descriptive mode test uses `methods()` to stay in sync with available strategies
- Knitro is excluded (not available in CI) — follow the same pattern as `test_explicit.jl`
- Check `pb.obj` field availability in `TestProblems.Beam()` before using it

---

## Status Tracking

**Current Status**: TODO
**Created**: 2026-02-18
