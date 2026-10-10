# Page: modelling/abstract-syntax.md
# Claim: a constant inside the expressions of a problem no longer breaks the ADNLP modeler
# (OptimalControl.jl#481): neither in a vector expression of a boundary constraint (fixed by
# ADNLPModels 0.8.14), nor as a component of the dynamics (fixed by ADNLPModels 0.8.15). The
# page used to warn about the second case ("A constant component"), and the warning is gone.
# This probe guards against a regression with an older ADNLPModels.

include("common.jl")
using OptimalControl
using NLPModelsIpopt

for (name, ocp) in [
    "x(0) - [-1, v] == [0, 0]" => @def(begin
        v ∈ R, variable
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ v ≤ 1
        x(0) - [-1, v] == [0, 0]
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(0.5u(t)^2) → min
    end),
    "x(0) - [-one(v), v] == [0, 0]" => @def(begin
        v ∈ R, variable
        t ∈ [0, 1], time
        x ∈ R², state
        u ∈ R, control
        -1 ≤ v ≤ 1
        x(0) - [-one(v), v] == [0, 0]
        x(1) == [0, 0]
        ẋ(t) == [x₂(t), u(t)]
        ∫(0.5u(t)^2) → min
    end),
]
    sol = solve(ocp; display=false)
    check(successful(sol), "a constant component in `$name` solves with :adnlp")
end

constant = @def begin
    t ∈ [0, 1], time
    x ∈ R³, state
    u ∈ R, control
    x(0) == [-1, 0, 2]
    x₁(1) == 0
    x₂(1) == 0
    ẋ(t) == [x₂(t), u(t), 0]
    0.5∫(u(t)^2) → min
end

sol = solve(constant; display=false)
check(successful(sol), "a constant component of the dynamics, ẋ(t) == [x₂(t), u(t), 0], solves with :adnlp")
check(isapprox(objective(sol), 6; rtol=1e-3), "its cost is the one of the double integrator, 6")
check(successful(solve(constant, :exa; display=false)), "and with :exa")
