# Page: getting-started/installation.md, table "You will also need a solver"
# Claim: `:madncl` needs both MadNCL and MadNLP, and without them the error names both.
# The other errors of the page (no solver package, no Plots, no JLD2, no ODE package) are
# shown by the docs build itself, in a fresh process (CTBase.DevTools.repl_without_extensions).

include("common.jl")
using OptimalControl

ocp = eval(ENERGY_DEF)

msg = error_text(() -> solve(ocp, :madncl; display=false))
check(
    occursin("MadNCL", msg) && occursin("MadNLP", msg),
    ":madncl needs both MadNCL and MadNLP, and the error names both",
)
