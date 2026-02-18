# Kanban Workflow - solve_explicit Implementation

## 📋 Overview

This Kanban system organizes the implementation of `solve_explicit` and its helper functions following a structured workflow with quality gates.

## 🔄 Workflow States

```
TODO → DOING → REVIEW → DONE
```

### **TODO** - Backlog
Tasks waiting to be started, ordered by priority (numbered).

### **DOING** - In Progress
Currently active task (only ONE task at a time).

### **REVIEW** - Quality Gate
Completed tasks awaiting verification before being marked as done.

### **DONE** - Completed
Verified and validated tasks.

## 📐 Mandatory Rules

All tasks MUST follow these project rules:

1. **🧪 Testing Standards**: `@[.windsurf/rules/testing.md]`
   - Contract-first testing
   - Module isolation with top-level structs
   - Unit/Integration/Contract test separation
   - Test independence and determinism

2. **📋 Architecture Principles**: `@[.windsurf/rules/architecture.md]`
   - SOLID principles
   - Type hierarchies and multiple dispatch
   - Module organization
   - DRY, KISS, YAGNI

3. **📚 Documentation Standards**: `@[.windsurf/rules/docstrings.md]`
   - DocStringExtensions.jl format
   - Complete API documentation
   - Examples and cross-references

4. **⚠️ Exception Handling**: `@[.windsurf/rules/exceptions.md]`
   - CTBase exception types
   - Enriched error messages
   - Proper error context

## 🎯 Task Lifecycle

### 1. TODO → DOING

**Developer Action**:
1. Check if DOING is empty (only one task at a time)
2. Take the **first numbered task** from `.reports/kanban_explicit/TODO/`
3. Move file to `.reports/kanban_explicit/DOING/`
4. Add to file:
   ```markdown
   ## Status: DOING
   **Started**: YYYY-MM-DD HH:MM
   **Developer**: [Your Name]
   ```
5. Begin implementation

### 2. DOING → REVIEW

**Developer Action**:
1. Complete implementation
2. Run specific tests first, then all tests:
   ```bash
   # Run specific new tests
   julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/solve/test_[name].jl"])'
   
   # Run all tests
   julia --project=@. -e 'using Pkg; Pkg.test()'
   ```
3. Add completion report to file:
   ```markdown
   ## Completion Report
   **Completed**: YYYY-MM-DD HH:MM
   
   ### Implementation Summary
   - Files created/modified: [list]
   - Functions implemented: [list]
   - Tests added: [list]
   
   ### Test Results
   - All project tests: ✅ PASS / ❌ FAIL
   - New unit tests: [X/Y passed]
   - New integration tests: [X/Y passed]
   - Code coverage: [X%]
   
   ### Verification Checklist
   - [ ] All rules followed (testing, architecture, docstrings, exceptions)
   - [ ] All tests pass
   - [ ] Documentation complete
   - [ ] No regressions introduced
   ```
4. Move file to `.reports/kanban_explicit/REVIEW/`

### 3. REVIEW → DONE (or back to TODO)

**Reviewer Action**:
1. Take first task from `.reports/kanban_explicit/REVIEW/`
2. Verify against acceptance criteria (see below)
3. Run tests independently
4. Check code quality

**If APPROVED**:
1. Add review report:
   ```markdown
   ## Review Report
   **Reviewed**: YYYY-MM-DD HH:MM
   **Reviewer**: [Your Name]
   **Status**: ✅ APPROVED
   
   ### Verification Results
   - [ ] Matches design in solve_explicit.md
   - [ ] All project tests pass
   - [ ] New tests comprehensive
   - [ ] Code coverage adequate (>80% for new code)
   - [ ] Documentation complete
   - [ ] No code smells
   - [ ] Follows all project rules
   
   ### Comments
   [Any observations or suggestions]
   ```
2. Move file to `DONE/`

**If REJECTED**:
1. Add review report with issues:
   ```markdown
   ## Review Report
   **Reviewed**: YYYY-MM-DD HH:MM
   **Reviewer**: [Your Name]
   **Status**: ❌ NEEDS WORK
   
   ### Issues Found
   1. [Issue description]
   2. [Issue description]
   
   ### Required Changes
   - [ ] [Change 1]
   - [ ] [Change 2]
   ```
2. Move file back to `.reports/kanban_explicit/TODO/` (or directly to `.reports/kanban_explicit/DOING/` if minor fixes)

## ✅ Acceptance Criteria (for REVIEW → DONE)

### Mandatory Checks

1. **Design Conformance**
   - Implementation matches specifications in `.reports/solve_explicit.md`
   - Function signatures are correct
   - Layer separation is respected

2. **Test Quality**
   - All existing project tests pass
   - New unit tests cover all code paths
   - Integration tests verify component interactions
   - Contract tests verify API contracts
   - Test coverage ≥ 80% for new code

3. **Code Quality**
   - Follows SOLID principles
   - No code duplication
   - Clear, self-documenting code
   - Proper error handling with CTBase exceptions

4. **Documentation**
   - All public functions have docstrings
   - DocStringExtensions format used
   - Examples provided where appropriate
   - Internal comments for complex logic

5. **No Regressions**
   - No existing tests broken
   - No performance degradation
   - No new warnings or errors

## 📊 Progress Tracking

Track overall progress by counting tasks in each state:

```
TODO: [X tasks]
DOING: [0 or 1 task]
REVIEW: [Y tasks]
DONE: [Z tasks]

Progress: Z / (X + Y + Z + 1) = [%]
```

## 🎭 Roles

See separate role documents:
- `ROLE_DEVELOPER.md` - Developer responsibilities
- `ROLE_REVIEWER.md` - Reviewer responsibilities

## 📝 Task Naming Convention

Tasks are numbered for sequential execution:

```
01_task_name.md
02_task_name.md
03_task_name.md
...
```

This ensures clear ordering and prevents confusion about what to work on next.

## 📁 Directory Structure

```
.reports/kanban_explicit/
├── WORKFLOW.md              # Documentation du processus
├── ROLE_DEVELOPER.md        # Guide du développeur
├── ROLE_REVIEWER.md         # Guide du reviewer
├── TODO/                    # Backlog (tâches numérotées)
├── DOING/                   # En cours (1 seule tâche)
├── REVIEW/                  # En attente de review
└── DONE/                    # Terminées et validées
```

## 🔍 Reference Documents

- **Design Specification**: `.reports/solve_explicit.md`
- **Testing Rules**: `.windsurf/rules/testing.md`
- **Architecture Rules**: `.windsurf/rules/architecture.md`
- **Documentation Rules**: `.windsurf/rules/docstrings.md`
- **Exception Rules**: `.windsurf/rules/exceptions.md`
- **Kanban System**: `.reports/kanban_explicit/` (this directory)

## 💡 Tips

- **One task at a time**: Focus on completing before starting new work
- **Small commits**: Commit after each task completion
- **Test early**: Write tests alongside implementation
- **Ask for help**: If stuck, document the blocker in the task file
- **Update design**: If design needs changes, update `.reports/solve_explicit.md` first
