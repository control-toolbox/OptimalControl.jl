# Page: getting-started/installation.md, section "Optional: GPU"
# Claim: when one of MadNLPGPU, CUDA, CUDSS is missing, `solve(ocp, :gpu)` raises an
# ExtensionError that names it (CTBase.jl#565, fixed in CTBase 0.30.6; CTSolvers.jl#234,
# fixed in CTSolvers 0.6.0, for MadNLPGPU).

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
    missing_pkg(gpu_error("CUDA", "CUDSS"))[1] == "MadNLPGPU",
    "with CUDA and CUDSS, the error asks for MadNLPGPU",
)
