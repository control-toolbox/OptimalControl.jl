# Page: results/plot.md, section "Plotting a flow".
# Claim: a flow built with `saveat` but without `dense=false` crashes when called on a time
# span (CTFlows#434, known bug: this probe checks the current behaviour, and fails when it is
# fixed); with `dense=false`, it works.

include("common.jl")

script(dense) = """
pushfirst!(LOAD_PATH, $(repr(REPO_ROOT))); pushfirst!(LOAD_PATH, $(repr(joinpath(REPO_ROOT, "docs"))))
using OptimalControl, OrdinaryDiffEqTsit5
ocp = @def begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [-1, 0]
    x(1) == [0, 0]
    ẋ(t) == [x₂(t), u(t)]
    ∫(0.5u(t)^2) → min
end
f = Flow(ocp, (x, p) -> p[2]; saveat=range(0, 1, 11)$(dense ? "" : ", dense=false"))
sol = f((0, 1), [-1, 0], [12, 6])
abs(objective(sol) - 6) < 1e-6 || error("wrong objective")
"""

run_child(code) = success(pipeline(`$(Base.julia_cmd()) --startup-file=no -e $code`; stdout=devnull, stderr=devnull))

check(!run_child(script(true)), "with saveat and the default dense, the trajectory call crashes")
check(run_child(script(false)), "with saveat and dense=false, the trajectory call works (objective 6)")
