# Kanban Workflow - solve (Orchestration) Implementation

## 📋 Overview

This Kanban system organizes the implementation of the `solve` orchestration layer and its
helper functions following a structured workflow with quality gates.

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

1. **🧪 Testing Standards**: `.windsurf/rules/testing.md`
   - Contract-first testing
   - Module isolation with top-level structs
   - Unit/Integration/Contract test separation
   - Test independence and determinism

2. **📋 Architecture Principles**: `.windsurf/rules/architecture.md`
   - SOLID principles
   - Type hierarchies and multiple dispatch
   - Module organization
   - DRY, KISS, YAGNI

3. **📚 Documentation Standards**: `.windsurf/rules/docstrings.md`
   - DocStringExtensions.jl format
   - Complete API documentation
   - Examples and cross-references

4. **⚠️ Exception Handling**: `.windsurf/rules/exceptions.md`
   - CTBase exception types
   - Enriched error messages
   - Proper error context

5. **⚡ Performance**: `.windsurf/rules/performance.md` and `.windsurf/rules/type-stability.md`
   - Type-stable functions
   - No unnecessary allocations in hot paths

## 🎯 Task Lifecycle

### 1. TODO → DOING

**Developer Action**:
1. Check if DOING is empty (only one task at a time)
2. Take the **first numbered task** from `.reports/kanban_orchestration/TODO/`
3. Move file to `.reports/kanban_orchestration/DOING/`
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
   julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/solve/test_orchestration.jl"])'

   # Run all tests
   julia --project=@. -e 'using Pkg; Pkg.test()'
   ```
3. Add completion report to file
4. Move file to `.reports/kanban_orchestration/REVIEW/`

### 3. REVIEW → DONE (or back to TODO)

**Reviewer Action**:
1. Take first task from `.reports/kanban_orchestration/REVIEW/`
2. Verify against acceptance criteria
3. Run tests independently
4. APPROVE → move to `DONE/` or REJECT → move back to `TODO/`

## ✅ Acceptance Criteria (for REVIEW → DONE)

### Mandatory Checks

1. **Design Conformance**
   - Implementation matches specifications in `.reports/solve_orchestration.md`
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

5. **No Regressions**
   - No existing tests broken
   - No performance degradation
   - No new warnings or errors

## 📊 Progress Tracking

```
TODO: 6 tasks
DOING: 0 tasks
REVIEW: 0 tasks
DONE: 0 tasks

Progress: 0 / 6 = 0%
```

## 🎭 Roles

See separate role documents:
- `ROLE_DEVELOPER.md` - Developer responsibilities
- `ROLE_REVIEWER.md` - Reviewer responsibilities

## 📝 Task Naming Convention

Tasks are numbered for sequential execution:

```
01_solve_mode_types.md
02_extract_kwarg.md
03_explicit_or_descriptive.md
04_solve_dispatch.md
05_commonsolve_solve.md
06_integration_tests.md
```

## 📁 Directory Structure

```
.reports/kanban_orchestration/
├── WORKFLOW.md              # Documentation du processus
├── ROLE_DEVELOPER.md        # Guide du développeur
├── ROLE_REVIEWER.md         # Guide du reviewer
├── TODO/                    # Backlog (tâches numérotées)
├── DOING/                   # En cours (1 seule tâche)
├── REVIEW/                  # En attente de review
└── DONE/                    # Terminées et validées
```

## 🔍 Reference Documents

- **Design Specification**: `.reports/solve_orchestration.md`
- **Existing Layer 2**: `.reports/solve_explicit.md` (already implemented)
- **Testing Rules**: `.windsurf/rules/testing.md`
- **Architecture Rules**: `.windsurf/rules/architecture.md`
- **Documentation Rules**: `.windsurf/rules/docstrings.md`
- **Exception Rules**: `.windsurf/rules/exceptions.md`
- **Performance Rules**: `.windsurf/rules/performance.md`
- **Type Stability Rules**: `.windsurf/rules/type-stability.md`

## 💡 Tips

- **One task at a time**: Focus on completing before starting new work
- **Small commits**: Commit after each task completion
- **Test early**: Write tests alongside implementation
- **Reuse existing infrastructure**: `get_strategy_registry`, `solve_explicit` already exist
- **Update design**: If design needs changes, update `.reports/solve_orchestration.md` first
