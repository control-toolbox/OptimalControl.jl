# Page: solve/choosing-a-method.md, section "Partial descriptions"
# Claims: a partial description is completed with the first method of `methods()` that
# contains all its tokens; the examples given in a non-executed block. Also: `describe`
# accepts the indirect-method strategies `:sciml` and `:di`.

include("common.jl")
using OptimalControl

complete(tokens...) = OptimalControl._complete_description(tokens)   # internal: probe only

check(complete() == methods()[1] == (:collocation, :adnlp, :ipopt, :cpu),
    "solve(ocp) uses methods()[1] = (:collocation, :adnlp, :ipopt, :cpu)")
check(complete(:madnlp) == (:collocation, :adnlp, :madnlp, :cpu), ":madnlp → (:collocation, :adnlp, :madnlp, :cpu)")
check(complete(:exa) == (:collocation, :exa, :ipopt, :cpu), ":exa → (:collocation, :exa, :ipopt, :cpu)")
check(complete(:gpu) == (:collocation, :exa, :madnlp, :gpu), ":gpu → (:collocation, :exa, :madnlp, :gpu)")
for tokens in [(:collocation,), (:adnlp,), (:ipopt,), (:cpu,), (:collocation, :adnlp),
               (:collocation, :adnlp, :ipopt, :cpu)]
    check(complete(tokens...) == methods()[1], "$(tokens) completes to the default")
end

# describe prints its description
function printed(f)
    path, io = mktemp()
    redirect_stdout(() -> f(), io)
    close(io)
    return read(path, String)
end
check(occursin("id: :sciml", printed(() -> describe(:sciml))), "describe(:sciml) describes the ODE integrator")
check(occursin("id: :di", printed(() -> describe(:di))), "describe(:di) describes the AD backend")
