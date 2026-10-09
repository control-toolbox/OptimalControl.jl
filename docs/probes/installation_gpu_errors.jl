# Page: getting-started/installation.md, section "Optional: GPU"
# Claim: a missing GPU package is reported by an ExtensionError.
# Known upstream bug (CTBase.jl#565): with no GPU package at all, the error asks for
# `MadNLP` and mentions `MadNLP{CPU}`. This probe checks the current behaviour, so it fails
# once the bug is fixed: then update the installation page and this probe.

include("common.jl")
using OptimalControl
using NLPModelsIpopt

ocp = eval(ENERGY_DEF)

msg = error_text(() -> solve(ocp, :gpu; display=false))
check(occursin("ExtensionError", msg), "solve(ocp, :gpu) without GPU packages raises an ExtensionError")
check(occursin("MadNLP{CPU}", msg),
    "known bug CTBase.jl#565: the error still mentions MadNLP{CPU} (update the docs when this fails)")

using MadNLPGPU
msg = error_text(() -> solve(ocp, :gpu; display=false))
check(occursin("ExtensionError", msg) && occursin("CUDA", msg),
    "with MadNLPGPU only, the error asks for CUDA")
