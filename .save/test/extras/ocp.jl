using Pkg
Pkg.activate(".")

using OptimalControl

# activate NLP modelers
using ADNLPModels
# + using ExaModels (in test_exa for now)

# activate NLP solvers
using NLPModelsIpopt
using MadNLP

n=2
@def ocp begin
    tf ∈ R, variable
    t ∈ [0, tf], time
    x ∈ R^n, state
    u ∈ R, control
    -1 ≤ u(t) ≤ 1
    x(0) == [0, 0]
    x(tf) == [1, 0]
    0.05 ≤ tf ≤ Inf
    ẋ(t) == [x₂(t), u(t)]
    tf → min
end true

sol = solve(ocp, :adnlp, :ipopt; print_level=5);
