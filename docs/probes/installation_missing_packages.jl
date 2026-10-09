# Page: getting-started/installation.md
# Claim: without the package of an optional feature, the call raises an ExtensionError that
# names the missing package. The docs build cannot show this: its process loads them all.

include("common.jl")
using OptimalControl

ocp = eval(ENERGY_DEF)

msg = error_text(() -> solve(ocp; display=false))
check(occursin("ExtensionError", msg) && occursin("using NLPModelsIpopt", msg),
    "solve without a solver package asks for `using NLPModelsIpopt`")

msg = error_text(() -> solve(ocp, :madncl; display=false))
check(occursin("MadNCL", msg) && occursin("MadNLP", msg),
    ":madncl needs both MadNCL and MadNLP, and the error names both")

using NLPModelsIpopt
sol = solve(ocp; display=false)

msg = error_text(() -> plot(sol))
check(occursin("ExtensionError", msg) && occursin("using Plots", msg),
    "plot(sol) without Plots asks for `using Plots`")

msg = error_text(() -> export_ocp_solution(sol; filename="probe"))
check(occursin("ExtensionError", msg) && occursin("JLD2", msg),
    "export_ocp_solution without JLD2 raises an ExtensionError naming JLD2")

msg = error_text(() -> Flow(ocp, (x, p) -> p[2]))
check(occursin("ExtensionError", msg) && occursin("OrdinaryDiffEqTsit5", msg),
    "Flow without an ODE package asks for `using OrdinaryDiffEqTsit5`")
