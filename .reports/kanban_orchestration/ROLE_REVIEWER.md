# Reviewer Role - solve (Orchestration) Implementation

## 🎯 Mission

Ensure all completed tasks meet quality standards before being marked as DONE.

## 📋 Review Process

1. **Read completion report** — understand what was implemented
2. **Verify design conformance** — open `.reports/solve_orchestration.md`, compare
3. **Run tests independently**:
   ```bash
   julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/solve/test_orchestration.jl"])'
   julia --project=@. -e 'using Pkg; Pkg.test()'
   ```
4. **Check code quality** — rules compliance, code smells, maintainability
5. **Verify documentation** — docstrings, examples, cross-references
6. **Assess test coverage** — unit, contract, integration, edge cases

## ✅ Acceptance Criteria

A task can only be APPROVED if ALL of these are met:

### Design Conformance
- [ ] Implementation matches `.reports/solve_orchestration.md` specification
- [ ] Function signatures are exactly as specified
- [ ] Layer separation is respected (no layer violations)
- [ ] `SolveMode` dispatch used correctly (instance, not `::Type{T}`)
- [ ] `_extract_kwarg` used consistently (no duplicated extraction logic)

### Test Quality
- [ ] All existing project tests pass (no regressions)
- [ ] New unit tests cover all code paths
- [ ] Contract tests verify mode detection logic
- [ ] Integration tests verify end-to-end behavior
- [ ] Error cases tested (conflict detection, invalid inputs)
- [ ] Tests follow `.windsurf/rules/testing.md`

### Code Quality
- [ ] Follows SOLID principles (`.windsurf/rules/architecture.md`)
- [ ] No code duplication (DRY)
- [ ] Functions are focused and small (SRP)
- [ ] No `isa`/`typeof` checks in dispatch logic
- [ ] No code smells

### Documentation
- [ ] All public functions have docstrings (DocStringExtensions format)
- [ ] Examples provided where appropriate
- [ ] Cross-references to related functions
- [ ] Internal comments for complex logic

### Exception Handling
- [ ] CTBase exception types used (`.windsurf/rules/exceptions.md`)
- [ ] Error messages enriched (got, expected, suggestion, context)
- [ ] Conflict detection raises at the right point

### No Regressions
- [ ] No existing tests broken
- [ ] No new warnings introduced
- [ ] No performance degradation
- [ ] No breaking changes to public API

## 📝 Review Outcomes

### APPROVE ✅

Add review report and move to `DONE/`.

### REJECT ❌

Add review report with issues. Decide destination:
- **Minor fixes** (< 30 min) → Move to `DOING/` directly
- **Major rework** (> 30 min) → Move to `TODO/`

## 💡 Review Best Practices

- **Focus on substance**: Design conformance and test quality over style
- **Test independently**: Don't trust claimed results, verify yourself
- **Check edge cases**: Empty description, all-nothing kwargs, conflict cases
- **Verify dispatch**: Ensure `ExplicitMode()` and `DescriptiveMode()` instances are used
- **Check kwargs flow**: Verify strategy-specific kwargs reach `solve_explicit`/`solve_descriptive`

---

**Remember**: Your role is to ensure quality while helping developers succeed.
