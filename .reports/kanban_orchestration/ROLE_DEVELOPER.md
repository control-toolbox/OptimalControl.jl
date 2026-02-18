# Developer Role - solve (Orchestration) Implementation

## 🎯 Mission

Implement tasks from the TODO backlog following strict quality standards and project rules.

## 📋 Responsibilities

### 1. Task Selection

**Check DOING folder**:
- If empty → Take first numbered task from `.reports/kanban_orchestration/TODO/`
- If occupied → Complete that task first (only ONE task at a time)

**Process**:
1. Move task file from `TODO/` to `DOING/`
2. Update task file with start information

### 2. Implementation

**Follow ALL project rules**:
- 🧪 **Testing**: `.windsurf/rules/testing.md` — TDD, top-level structs, test independence
- 📋 **Architecture**: `.windsurf/rules/architecture.md` — SOLID, multiple dispatch, DRY/KISS/YAGNI
- 📚 **Documentation**: `.windsurf/rules/docstrings.md` — DocStringExtensions, examples, cross-refs
- ⚠️ **Exceptions**: `.windsurf/rules/exceptions.md` — CTBase types, enriched messages
- ⚡ **Performance**: `.windsurf/rules/performance.md` + `.windsurf/rules/type-stability.md`

**Reference design**: Always check `.reports/solve_orchestration.md` for specifications.

### 3. Testing

```bash
# Run specific new tests
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/solve/test_orchestration.jl"])'

# Run all tests
julia --project=@. -e 'using Pkg; Pkg.test()'
```

### 4. Completion

**Self-review checklist before moving to REVIEW**:
- [ ] All project tests pass
- [ ] New tests comprehensive (unit + contract + integration)
- [ ] Documentation complete (docstrings + examples)
- [ ] Code follows all rules
- [ ] No warnings or errors
- [ ] Design matches specification

**Add completion report** and move to `REVIEW/`.

## 🔧 Development Workflow

```
1. Select task from TODO
   ↓
2. Move to DOING, update status
   ↓
3. Read task requirements carefully
   ↓
4. Check design specification (.reports/solve_orchestration.md)
   ↓
5. Write tests FIRST (TDD)
   ↓
6. Implement functionality
   ↓
7. Run tests, iterate until green
   ↓
8. Add documentation
   ↓
9. Self-review against checklist
   ↓
10. Add completion report
   ↓
11. Move to REVIEW
```

## 🚫 Common Pitfalls to Avoid

1. **Defining structs inside functions** → Define at module top-level
2. **Skipping tests** → Tests are mandatory
3. **Incomplete documentation** → All public functions need docstrings
4. **Ignoring rules** → All rule files must be followed
5. **Working on multiple tasks** → One task at a time
6. **Not running all tests** → Must verify no regressions
7. **Rushing to REVIEW** → Self-review thoroughly first
8. **Forgetting `_extract_kwarg` is reused** → Don't duplicate extraction logic

## ✅ Success Criteria

A task is ready for REVIEW when:

1. All project tests pass
2. New tests are comprehensive
3. Code coverage ≥ 80% for new code
4. Documentation is complete
5. All project rules followed
6. Design specification matched
7. Completion report filled out
8. No warnings or errors

---

**Remember**: Quality over speed. Take time to do it right the first time.
