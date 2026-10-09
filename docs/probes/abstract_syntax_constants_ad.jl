# Page: modelling/abstract-syntax.md (its former "Known issues" section)
# Claim: a constant inside a vector expression no longer breaks the ADNLP modeler
# (OptimalControl.jl#481, fixed by ADNLPModels 0.8.14). The section was removed on that basis;
# if this probe fails, the bug is back: restore a one-line note with the issue link.

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
