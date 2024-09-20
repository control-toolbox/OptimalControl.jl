
using OptimalControl
using Plots

@def ocp begin
    t ∈ [0, 1], time
    x ∈ R², state
    u ∈ R, control

    x(0) == [-1, 0]
    x(1) == [0, 0]

    ẋ(t) == [x₂(t), u(t)]

    ∫(0.5u(t)^2) → min
end

docp, nlp = direct_transcription(ocp)
#println(nlp.meta.x0)

using NLPModelsIpopt
nlp_sol = ipopt(nlp; print_level=5, mu_strategy="adaptive", tol=1e-8, sb="yes")
sol = OptimalControlSolution(docp; primal=nlp_sol.solution, dual=nlp_sol.multipliers)
plot(sol)

using MadNLP
mad_nlp_sol = madnlp(nlp)

set_initial_guess(docp, nlp, sol)
#println(nlp.meta.x0)
mad_nlp_sol = madnlp(nlp)

docp, nlp = direct_transcription(ocp; init=sol)
mad_nlp_sol = madnlp(nlp)

mad_sol = OptimalControlSolution(
    docp; primal=madnlp_sol.solution, dual=madnlp_sol.multipliers
)
plot(mad_sol)

#=
using Percival
per_nlp_sol = percival(nlp, verbose = 1)
per_sol = OptimalControlSolution(docp, primal=per_nlp_sol.solution, dual=per_nlp_sol.multipliers)
plot(per_sol)
=#
