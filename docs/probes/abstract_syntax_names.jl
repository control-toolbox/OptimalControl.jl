# Page: modelling/abstract-syntax.md, section "Structure of a definition"
# Claims: constants used in declarations or constraint bounds must be defined before the
# block; functions called in the dynamics may be defined after it; the variable must come
# before the time when the time bounds use it, while the other declarations may come in any
# order. Each statement below is evaluated at top level, in order, as in a user session.

include("common.jl")
using OptimalControl
using NLPModelsIpopt

msg = error_text(() -> @eval @def begin
    t ∈ [0, T_not_yet_defined], time
    x ∈ R, state
    u ∈ R, control
    ẋ(t) == u(t)
    ∫(u(t)^2) → min
end)
check(occursin("UndefVarError", msg), "a constant in the time bounds must be defined before the block")

msg = error_text(() -> @eval @def begin
    t ∈ [0, 1], time
    x ∈ R, state
    u ∈ R, control
    x(0) == x0_not_yet_defined
    ẋ(t) == u(t)
    ∫(u(t)^2) → min
end)
check(occursin("UndefVarError", msg), "a constant in a boundary condition must be defined before the block")

ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R, state
    u ∈ R, control
    x(0) == 1
    ẋ(t) == G_defined_after(x(t)) + u(t)
    ∫(u(t)^2 + x(t)^2) → min
end
G_defined_after(x) = -x
sol = solve(ocp; display=false)
check(successful(sol), "a function called in the dynamics may be defined after the block")

msg = error_text(() -> @eval @def begin
    t ∈ [0, tf], time
    tf ∈ R, variable
    x ∈ R, state
    u ∈ R, control
    ẋ(t) == u(t)
    tf → min
end)
check(occursin("UndefVarError", msg), "the variable must come before the time when the time bounds use it")

ocp = @def begin
    x ∈ R, state
    t ∈ [0, 1], time
    u ∈ R, control
    ẋ(t) == u(t)
    ∫(u(t)^2) → min
end
check(state_dimension(ocp) == 1, "other declarations may come in any order (state before time)")

ocp = @def begin
    t in [0, 1], time
    x in R^2, state
    u in R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    derivative(x)(t) == [x[2](t), u(t)]
    u(t) <= 10
    0.5integral(u(t)^2) => min
end
check(state_dimension(ocp) == 2, "the ASCII alternatives (in, R^2, derivative, <=, integral, =>) are accepted")
