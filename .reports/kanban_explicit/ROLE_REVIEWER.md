# Reviewer Role - solve_explicit Implementation

## 🎯 Mission

Ensure all completed tasks meet quality standards before being marked as DONE.

## 📋 Responsibilities

### 1. Task Selection

**Check REVIEW folder**:
- Take first task (oldest first, FIFO) from `.reports/kanban_explicit/REVIEW/`
- Review thoroughly against acceptance criteria
- Make APPROVE or REJECT decision

### 2. Review Process

**Verification Steps**:

1. **Read completion report**
   - Understand what was implemented
   - Check claimed test results
   - Review developer's self-assessment

2. **Verify design conformance**
   - Open `.reports/solve_explicit.md`
   - Compare implementation to specification
   - Check function signatures match exactly
   - Verify layer separation respected

3. **Run tests independently**
   ```bash
   # Run specific new tests
   julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/solve/test_[name].jl"])'
   
   # Run all tests
   julia --project=@. -e 'using Pkg; Pkg.test()'
   ```

4. **Check code quality**
   - Review implementation files
   - Verify rules compliance
   - Check for code smells
   - Assess maintainability

5. **Verify documentation**
   - All public functions documented
   - DocStringExtensions format used
   - Examples present and correct
   - Cross-references appropriate

6. **Assess test coverage**
   - Unit tests comprehensive
   - Integration tests appropriate
   - Contract tests verify API
   - Edge cases covered

## ✅ Acceptance Criteria

### Mandatory Requirements

A task can only be APPROVED if ALL of these are met:

#### 1. Design Conformance
- [ ] Implementation matches `.reports/solve_explicit.md` specification
- [ ] Function signatures are exactly as specified
- [ ] Layer separation is respected (no layer violations)
- [ ] Parameter types are correct (including registry parameter)

#### 2. Test Quality
- [ ] All existing project tests pass (no regressions)
- [ ] New unit tests cover all code paths
- [ ] Integration tests verify component interactions
- [ ] Contract tests verify API contracts
- [ ] Test coverage ≥ 80% for new code
- [ ] Tests follow `.windsurf/rules/testing.md`

#### 3. Code Quality
- [ ] Follows SOLID principles (`.windsurf/rules/architecture.md`)
- [ ] No code duplication (DRY)
- [ ] Functions are focused and small (SRP)
- [ ] Proper type hierarchies used
- [ ] No code smells (long functions, deep nesting, etc.)

#### 4. Documentation
- [ ] All public functions have docstrings
- [ ] DocStringExtensions format used (`.windsurf/rules/docstrings.md`)
- [ ] Examples provided where appropriate
- [ ] Internal comments for complex logic
- [ ] Cross-references to related functions

#### 5. Exception Handling
- [ ] CTBase exception types used (`.windsurf/rules/exceptions.md`)
- [ ] Error messages are enriched (got, expected, suggestion, context)
- [ ] Exceptions thrown at appropriate points
- [ ] Error handling is comprehensive

#### 6. No Regressions
- [ ] No existing tests broken
- [ ] No new warnings introduced
- [ ] No performance degradation
- [ ] No breaking changes to public API

### Quality Indicators

**Green flags** (good signs):
- ✅ Clear, self-documenting code
- ✅ Comprehensive test coverage
- ✅ Thoughtful error messages
- ✅ Good separation of concerns
- ✅ Consistent naming conventions

**Red flags** (concerns):
- ❌ Complex, hard-to-understand code
- ❌ Missing or incomplete tests
- ❌ Generic error messages
- ❌ Mixed responsibilities
- ❌ Inconsistent style

## 📝 Review Outcomes

### Option 1: APPROVE ✅

**When to approve**:
- All acceptance criteria met
- Code quality is high
- Tests are comprehensive
- Documentation is complete

**Action**:
1. Add review report to task file:
   ```markdown
   ## Review Report
   **Reviewed**: YYYY-MM-DD HH:MM
   **Reviewer**: [Your Name]
   **Status**: ✅ APPROVED
   
   ### Verification Results
   - [x] Matches design in solve_explicit.md
   - [x] All project tests pass (X tests, Y.Ys)
   - [x] New tests comprehensive (unit: X, integration: Y)
   - [x] Code coverage adequate (Z% for new code)
   - [x] Documentation complete and correct
   - [x] No code smells detected
   - [x] Follows all project rules
   
   ### Strengths
   - [Highlight good aspects of implementation]
   - [Note any particularly well-done parts]
   
   ### Minor Suggestions (optional, not blocking)
   - [Any non-critical improvements for future]
   
   ### Comments
   [Any other observations or notes]
   ```

2. Move file from `.reports/kanban_explicit/REVIEW/` to `.reports/kanban_explicit/DONE/`

### Option 2: REJECT ❌

**When to reject**:
- Any mandatory criterion not met
- Code quality issues
- Incomplete tests
- Missing documentation
- Regressions introduced

**Action**:
1. Add review report to task file:
   ```markdown
   ## Review Report
   **Reviewed**: YYYY-MM-DD HH:MM
   **Reviewer**: [Your Name]
   **Status**: ❌ NEEDS WORK
   
   ### Issues Found
   
   #### Critical Issues (must fix)
   1. **[Issue category]**: [Detailed description]
      - Location: [file:line or function name]
      - Problem: [What's wrong]
      - Impact: [Why it matters]
   
   2. **[Issue category]**: [Detailed description]
      - Location: [file:line or function name]
      - Problem: [What's wrong]
      - Impact: [Why it matters]
   
   #### Minor Issues (should fix)
   1. [Description]
   2. [Description]
   
   ### Required Changes
   - [ ] Fix critical issue 1
   - [ ] Fix critical issue 2
   - [ ] Address minor issues
   - [ ] Re-run all tests
   - [ ] Update documentation if needed
   
   ### Suggestions
   [Helpful hints on how to fix issues]
   
   ### Positive Aspects
   [Note what was done well, even in rejected work]
   ```

2. **Decide destination**:
   - **Minor fixes** (< 30 min work) → Move to `DOING/` directly
   - **Major rework** (> 30 min work) → Move to `TODO/`

## 🔍 Review Checklist

Use this checklist during review:

### Design & Architecture
- [ ] Read design specification section
- [ ] Compare implementation to spec
- [ ] Verify function signatures
- [ ] Check layer separation
- [ ] Assess SOLID compliance

### Testing
- [ ] Run all project tests
- [ ] Run new tests specifically
- [ ] Check test coverage report
- [ ] Review test quality
- [ ] Verify test independence

### Code Quality
- [ ] Read implementation code
- [ ] Check for code smells
- [ ] Verify error handling
- [ ] Assess maintainability
- [ ] Check naming conventions

### Documentation
- [ ] Verify docstrings present
- [ ] Check docstring format
- [ ] Test examples work
- [ ] Assess completeness
- [ ] Check cross-references

### Integration
- [ ] No regressions introduced
- [ ] No breaking changes
- [ ] No new warnings
- [ ] Performance acceptable

## 💡 Review Best Practices

### Be Constructive

- **Focus on code, not person**: "This function is complex" not "You wrote complex code"
- **Explain why**: Don't just say "fix this", explain the problem
- **Suggest solutions**: Offer concrete ways to improve
- **Acknowledge good work**: Note what was done well

### Be Thorough

- **Don't rush**: Take time to understand the implementation
- **Test independently**: Don't trust claimed results, verify yourself
- **Check edge cases**: Think about what could go wrong
- **Consider maintenance**: Will this be easy to maintain?

### Be Fair

- **Apply standards consistently**: Same criteria for all tasks
- **Don't be perfectionist**: Good enough is often good enough
- **Balance quality and progress**: Don't block on minor style issues
- **Recognize effort**: Appreciate the work done

### Be Clear

- **Specific feedback**: Point to exact locations
- **Actionable items**: Clear what needs to change
- **Prioritize issues**: Critical vs. minor
- **Provide examples**: Show what you mean

## 🚫 Common Review Mistakes

1. **Rubber stamping** → Actually verify, don't assume
2. **Nitpicking style** → Focus on substance, not minor style
3. **Vague feedback** → Be specific about issues
4. **Ignoring positives** → Acknowledge good work
5. **Inconsistent standards** → Apply same criteria to all
6. **Not testing yourself** → Always run tests independently
7. **Blocking on opinions** → Distinguish requirements from preferences

## 📊 Review Metrics

Track your review quality:

```markdown
## Review Statistics

**Total Reviews**: X
**Approved**: Y (Z%)
**Rejected**: W (V%)

**Average Review Time**: N minutes
**Common Issues Found**:
1. [Issue type] - [count]
2. [Issue type] - [count]

**Improvement Areas**:
- [What to focus on in future reviews]
```

## 🎓 Learning Resources

- **Design Specification**: `.reports/solve_explicit.md`
- **Testing Standards**: `.windsurf/rules/testing.md`
- **Architecture Principles**: `.windsurf/rules/architecture.md`
- **Documentation Format**: `.windsurf/rules/docstrings.md`
- **Exception Handling**: `.windsurf/rules/exceptions.md`
- **Workflow Process**: `.reports/kanban_explicit/WORKFLOW.md`
- **Workflow Process**: `WORKFLOW.md`

## 🔄 Handling Disagreements

If developer disagrees with review:

1. **Listen**: Understand their perspective
2. **Discuss**: Explain your reasoning
3. **Reference rules**: Point to specific standards
4. **Escalate if needed**: Bring in third party if stuck
5. **Document decision**: Record outcome in task file

## ✅ Success Criteria

A good review:

1. Catches all quality issues
2. Provides clear, actionable feedback
3. Acknowledges good work
4. Helps developer improve
5. Maintains project standards
6. Completed in reasonable time
7. Documented thoroughly

---

**Remember**: Your role is to ensure quality while helping developers succeed. Be thorough but fair, critical but constructive.
