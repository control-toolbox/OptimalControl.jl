# Page: solve/gpu.md, section "Prerequisites"
# Claims: with MadNLPGPU and CUDA but without CUDSS, a :gpu solve fails with an
# ExtensionError reporting "Missing CUDSS" and the hint `using CUDSS`; and `using ExaModels`
# makes `objective` and `constraint` ambiguous. The docs build loads all the packages, so it
# cannot show either. Runs without a GPU: the error is raised before the device is used.

include("common.jl")
using OptimalControl
using MadNLPGPU
using CUDA

ocp = eval(ENERGY_DEF)

msg = error_text(() -> solve(ocp, :gpu; display=false))
check(
    occursin("ExtensionError", msg) &&
        occursin("CUDSS", msg) &&
        occursin("using CUDSS", msg),
    "without CUDSS, the :gpu solve reports Missing CUDSS with the hint `using CUDSS`",
)

using ExaModels
msg = error_text(() -> @eval Main objective)
check(
    occursin("UndefVarError", msg) || occursin("ambigu", msg),
    "`using ExaModels` makes `objective` ambiguous with OptimalControl's accessor",
)
