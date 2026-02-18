# Developer Role - solve_explicit Implementation

## 🎯 Mission

Implement tasks from the TODO backlog following strict quality standards and project rules.

## 📋 Responsibilities

### 1. Task Selection

**Check DOING folder**:
- If empty → Take first numbered task from `.reports/kanban_explicit/TODO/`
- If occupied → Complete that task first (only ONE task at a time)

**Process**:
1. Move task file from `.reports/kanban_explicit/TODO/` to `.reports/kanban_explicit/DOING/`
2. Update task file with start information:
   ```markdown
   ## Status: DOING
   **Started**: YYYY-MM-DD HH:MM
   **Developer**: [Your Name]
   
   ## Work Log
   [Document your progress here as you work]
   ```

### 2. Implementation

**Follow ALL project rules**:
- 🧪 **Testing**: `.windsurf/rules/testing.md`
  - Write tests FIRST (TDD approach recommended)
  - Define structs at module top-level
  - Separate unit/integration/contract tests
  - Ensure test independence
  
- 📋 **Architecture**: `.windsurf/rules/architecture.md`
  - Apply SOLID principles
  - Use proper type hierarchies
  - Follow module organization
  - Keep functions focused (SRP)
  
- 📚 **Documentation**: `.windsurf/rules/docstrings.md`
  - Use DocStringExtensions format
  - Document all public functions
  - Include examples
  - Add cross-references
  
- ⚠️ **Exceptions**: `.windsurf/rules/exceptions.md`
  - Use CTBase exception types
  - Provide enriched error messages
  - Include context and suggestions

**Reference design**:
- Always check `.reports/solve_explicit.md` for specifications
- Match function signatures exactly
- Respect layer separation

### 3. Testing

**Run tests frequently**:
```bash
# Run specific new tests first
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/solve/test_[name].jl"])'

# Then run all tests
julia --project=@. -e 'using Pkg; Pkg.test()'
```

**Test requirements**:
- All existing tests must pass
- New unit tests for all code paths
- Integration tests for workflows
- Contract tests for API contracts
- Coverage ≥ 80% for new code

### 4. Completion

**Before moving to REVIEW**:

1. **Self-review checklist**:
   - [ ] All project tests pass
   - [ ] New tests comprehensive
   - [ ] Documentation complete
   - [ ] Code follows all rules
   - [ ] No warnings or errors
   - [ ] Design matches specification

2. **Add completion report** to task file:
   ```markdown
   ## Completion Report
   **Completed**: YYYY-MM-DD HH:MM
   
   ### Implementation Summary
   - **Files created**:
     - `src/solve/helpers/available_methods.jl`
   - **Files modified**:
     - None
   - **Functions implemented**:
     - `available_methods()::Tuple{Vararg{Tuple{Symbol, Symbol, Symbol}}}`
   - **Tests added**:
     - `test/suite/solve/test_available_methods.jl`
   
   ### Test Results
   - **All project tests**: ✅ PASS (X tests, Y.Ys)
   - **New unit tests**: 5/5 passed
   - **New integration tests**: N/A
   - **Code coverage**: 100% (new code)
   
   ### Verification Checklist
   - [x] Testing rules followed
   - [x] Architecture rules followed
   - [x] Documentation rules followed
   - [x] Exception rules followed
   - [x] All tests pass
   - [x] Documentation complete
   - [x] No regressions introduced
   - [x] Matches design specification
   
   ### Notes
   [Any additional comments or observations]
   ```

3. **Move file** from `.reports/kanban_explicit/DOING/` to `.reports/kanban_explicit/REVIEW/`

## 🔧 Development Workflow

### Typical Task Flow

```
1. Select task from TODO
   ↓
2. Move to DOING, update status
   ↓
3. Read task requirements carefully
   ↓
4. Check design specification (.reports/solve_explicit.md)
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

## 💡 Best Practices

### Code Quality

- **Small commits**: Commit logical units of work
- **Clear names**: Use descriptive variable/function names
- **DRY**: Don't repeat yourself
- **KISS**: Keep it simple
- **YAGNI**: You aren't gonna need it

### Testing

- **Test early**: Write tests alongside implementation
- **Test thoroughly**: Cover edge cases
- **Test independently**: Each test should be self-contained
- **Test clearly**: Test names should describe what's being tested

### Documentation

- **Document why**: Explain non-obvious decisions
- **Document contracts**: Specify expected inputs/outputs
- **Document examples**: Show typical usage
- **Document errors**: Explain when exceptions are thrown

### Communication

- **Update work log**: Document progress in task file
- **Ask questions**: If stuck, document the blocker
- **Share insights**: Note any design discoveries
- **Be honest**: Report actual status, not desired status

## 🚫 Common Pitfalls to Avoid

1. **Defining structs inside functions** → Define at module top-level
2. **Skipping tests** → Tests are mandatory
3. **Incomplete documentation** → All public functions need docstrings
4. **Ignoring rules** → All 4 rule files must be followed
5. **Working on multiple tasks** → One task at a time
6. **Not running all tests** → Must verify no regressions
7. **Rushing to REVIEW** → Self-review thoroughly first

## 📊 Progress Tracking

Update your work log in the task file as you progress:

```markdown
## Work Log

**2026-02-17 14:30** - Started implementation
- Created file structure
- Defined function signature

**2026-02-17 15:00** - Tests written
- Added unit tests for all cases
- Tests currently failing (expected)

**2026-02-17 15:30** - Implementation complete
- All tests passing
- Added documentation

**2026-02-17 16:00** - Self-review complete
- All checklist items verified
- Ready for REVIEW
```

## 🎓 Learning Resources

- **Design Specification**: `.reports/solve_explicit.md`
- **Testing Standards**: `.windsurf/rules/testing.md`
- **Architecture Principles**: `.windsurf/rules/architecture.md`
- **Documentation Format**: `.windsurf/rules/docstrings.md`
- **Exception Handling**: `.windsurf/rules/exceptions.md`
- **Workflow Process**: `.reports/kanban_explicit/WORKFLOW.md`

## ✅ Success Criteria

A task is ready for REVIEW when:

1. All project tests pass
2. New tests are comprehensive
3. Code coverage ≥ 80% for new code
4. Documentation is complete
5. All 4 project rules followed
6. Design specification matched
7. Completion report filled out
8. No warnings or errors

## 🔄 If Task Returns from REVIEW

If reviewer sends task back to TODO/DOING:

1. Read review report carefully
2. Address all issues listed
3. Update work log with fixes
4. Re-verify all checklist items
5. Add response to review:
   ```markdown
   ## Response to Review
   **Date**: YYYY-MM-DD HH:MM
   
   ### Issues Addressed
   1. [Issue 1] - Fixed by [explanation]
   2. [Issue 2] - Fixed by [explanation]
   
   ### Verification
   - [x] All review issues resolved
   - [x] Tests still passing
   - [x] No new issues introduced
   ```
6. Move back to `.reports/kanban_explicit/REVIEW/`

---

**Remember**: Quality over speed. Take time to do it right the first time.
