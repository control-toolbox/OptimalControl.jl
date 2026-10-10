# Page: modelling/abstract-syntax.md
# Claims:
# - a constant inside a vector expression of a boundary constraint no longer breaks the ADNLP
#   modeler (OptimalControl.jl#481, fixed for this case by ADNLPModels 0.8.14);
# - known bug (OptimalControl.jl#481, still open): a constant component of the dynamics breaks
#   it, `0 * u(t)` works around it, and `:exa` is not affected (warning "A constant component").
#   This part checks the current behaviour, so it fails once the bug is fixed: then drop the
#   warning and this part.

include("common.jl")
using OptimalControl
using NLPModelsIpopt

for (name, ocp) in [
    "x(0) - [-1, v] == [0, 0]" => @def(
        begin
            v ∈ R, variable
            t ∈ [0, 1], time
            x ∈ R², state
            u ∈ R, control
            -1 ≤ v ≤ 1
            x(0) - [-1, v] == [0, 0]
            x(1) == [0, 0]
            ẋ(t) == [x₂(t), u(t)]
            ∫(0.5u(t)^2) → min
        end
    ),
    "x(0) - [-one(v), v] == [0, 0]" => @def(
        begin
            v ∈ R, variable
            t ∈ [0, 1], time
            x ∈ R², state
            u ∈ R, control
            -1 ≤ v ≤ 1
            x(0) - [-one(v), v] == [0, 0]
            x(1) == [0, 0]
            ẋ(t) == [x₂(t), u(t)]
            ∫(0.5u(t)^2) → min
        end
    ),
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
workaround = @def begin
    t ∈ [0, 1], time
    x ∈ R³, state
    u ∈ R, control
    x(0) == [-1, 0, 2]
    x₁(1) == 0
    x₂(1) == 0
    ẋ(t) == [x₂(t), u(t), 0 * u(t)]
    0.5∫(u(t)^2) → min
end

msg = error_text(() -> solve(constant; display=false))
check(
    occursin("ordering of Dual tags", msg),
    "known bug OptimalControl.jl#481: ẋ(t) == [x₂(t), u(t), 0] fails with :adnlp",
)
check(successful(solve(workaround; display=false)), "with 0 * u(t), it solves with :adnlp")
check(
    successful(solve(constant, :exa; display=false)),
    "with :exa, the constant component solves",
)
