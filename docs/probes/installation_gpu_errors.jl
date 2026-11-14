# Page: getting-started/installation.md, section "Optional: GPU"
# Claim: when one of MadNLPGPU, CUDA, CUDSS is missing, `solve(ocp, :gpu)` raises an
# ExtensionError that names it (CTBase.jl#565, fixed in CTBase 0.30.6).
# Known upstream bug (CTSolvers.jl#234): with CUDA loaded but not MadNLPGPU, the first error
# asks for `MadNLP`, and only the next one for `MadNLPGPU`. This part checks the current
# behaviour, so it fails once the bug is fixed: then drop the one-line note and this part.

include("common.jl")

# One child process per set of loaded packages: an extension cannot be unloaded.
function gpu_error(pkgs::AbstractString...)
    code = """
    pushfirst!(LOAD_PATH, $(repr(REPO_ROOT))); pushfirst!(LOAD_PATH, $(repr(joinpath(REPO_ROOT, "docs"))))
    using OptimalControl, NLPModelsIpopt
    $(join(("using " * p for p in pkgs), "\n"))
    ocp = $(ENERGY_DEF)
    try
        solve(ocp, :gpu; display=false)
    catch e
        print(sprint(showerror, e))
    end
    """
    return read(
        pipeline(`$(Base.julia_cmd()) --startup-file=no -e $code`; stderr=devnull), String
    )
end
missing_pkg(msg) = match(r"Missing\s+(\w+)", msg)

msg = gpu_error()
check(
    occursin("ExtensionError", msg) && !occursin("MadNLP{CPU}", msg),
    "with no GPU package, an ExtensionError that no longer mentions MadNLP{CPU}",
)
check(missing_pkg(msg)[1] == "CUDA", "with no GPU package, the error asks for CUDA")
check(
    missing_pkg(gpu_error("MadNLPGPU"))[1] == "CUDA",
    "with MadNLPGPU only, the error asks for CUDA",
)
check(
    missing_pkg(gpu_error("MadNLPGPU", "CUDA"))[1] == "CUDSS",
    "with MadNLPGPU and CUDA, the error asks for CUDSS",
)
check(
    missing_pkg(gpu_error("CUDA", "CUDSS"))[1] == "MadNLP",
    "known bug CTSolvers.jl#234: with CUDA and CUDSS but not MadNLPGPU, the error asks for MadNLP",
)
check(
    missing_pkg(gpu_error("CUDA", "CUDSS", "MadNLP"))[1] == "MadNLPGPU",
    "then, with MadNLP loaded, it asks for MadNLPGPU",
)
