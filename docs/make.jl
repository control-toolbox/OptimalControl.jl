using Documenter
using DocumenterMermaid
using OptimalControl
using CTBase
using CTDirect
using CTFlows
using CTModels
using CTParser
using Plots
using CommonSolve
using OrdinaryDiffEq
using DocumenterInterLinks
using ADNLPModels
using ExaModels
using NLPModelsIpopt
using MadNLP
using MadNLPMumps
using JSON3
using JLD2
using NLPModelsKnitro

#
links = InterLinks(
    "CTBase" => (
        "https://control-toolbox.org/CTBase.jl/stable/",
        "https://control-toolbox.org/CTBase.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "CTBase.toml"),
    ),
    "CTDirect" => (
        "https://control-toolbox.org/CTDirect.jl/stable/",
        "https://control-toolbox.org/CTDirect.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "CTDirect.toml"),
    ),
    "CTFlows" => (
        "https://control-toolbox.org/CTFlows.jl/stable/",
        "https://control-toolbox.org/CTFlows.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "CTFlows.toml"),
    ),
    "CTModels" => (
        "https://control-toolbox.org/CTModels.jl/stable/",
        "https://control-toolbox.org/CTModels.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "CTModels.toml"),
    ),
    "CTParser" => (
        "https://control-toolbox.org/CTParser.jl/stable/",
        "https://control-toolbox.org/CTParser.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "CTParser.toml"),
    ),
    "ADNLPModels" => (
        "https://jso.dev/ADNLPModels.jl/stable/",
        "https://jso.dev/ADNLPModels.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "ADNLPModels.toml"),
    ),
    "NLPModelsIpopt" => (
        "https://jso.dev/NLPModelsIpopt.jl/stable/",
        "https://jso.dev/NLPModelsIpopt.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "NLPModelsIpopt.toml"),
    ),
    "ExaModels" => (
        "https://exanauts.github.io/ExaModels.jl/stable/",
        "https://exanauts.github.io/ExaModels.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "ExaModels.toml"),
    ),
    "MadNLP" => (
        "https://madnlp.github.io/MadNLP.jl/stable/",
        "https://madnlp.github.io/MadNLP.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "MadNLP.toml"),
    ),
    "Tutorials" => (
        "https://control-toolbox.org/Tutorials.jl/stable/",
        "https://control-toolbox.org/Tutorials.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "Tutorials.toml"),
    ),
)

# to add docstrings from external packages
const CTFlowsODE = Base.get_extension(CTFlows, :CTFlowsODE)
const CTModelsPlots = Base.get_extension(CTModels, :CTModelsPlots)
const CTModelsJSON = Base.get_extension(CTModels, :CTModelsJSON)
const CTModelsJLD = Base.get_extension(CTModels, :CTModelsJLD)
const CTDirectExtIpopt = Base.get_extension(CTDirect, :CTDirectExtIpopt)
const CTDirectExtKnitro = Base.get_extension(CTDirect, :CTDirectExtKnitro)
const CTDirectExtMadNLP = Base.get_extension(CTDirect, :CTDirectExtMadNLP)
const CTDirectExtADNLP = Base.get_extension(CTDirect, :CTDirectExtADNLP)
const CTDirectExtExa = Base.get_extension(CTDirect, :CTDirectExtExa)
Modules = [
    CTBase,
    CTFlows,
    CTDirect,
    CTModels,
    CTParser,
    OptimalControl,
    CTFlowsODE,
    CTModelsPlots,
    CTModelsJSON,
    CTModelsJLD,
    CTDirectExtIpopt,
    CTDirectExtKnitro,
    CTDirectExtMadNLP,
    CTDirectExtADNLP,
    CTDirectExtExa,
]
for Module in Modules
    isnothing(DocMeta.getdocmeta(Module, :DocTestSetup)) &&
        DocMeta.setdocmeta!(Module, :DocTestSetup, :(using $Module); recursive=true)
end

# For reproducibility
mkpath(joinpath(@__DIR__, "src", "assets"))
cp(
    joinpath(@__DIR__, "Manifest.toml"),
    joinpath(@__DIR__, "src", "assets", "Manifest.toml");
    force=true,
)
cp(
    joinpath(@__DIR__, "Project.toml"),
    joinpath(@__DIR__, "src", "assets", "Project.toml");
    force=true,
)

repo_url = "github.com/control-toolbox/OptimalControl.jl"

# if draft is true, then the julia code from .md is not executed # debug
# to disable the draft mode in a specific markdown file, use the following:
#=
```@meta
Draft = false
```
=#
makedocs(;
    draft=true, # if draft is true, then the julia code from .md is not executed # debug
    # to disable the draft mode in a specific markdown file, use the following:
    # ```@meta
    # Draft = false
    # ```
    #draft=false,
    #warnonly=[:cross_references, :autodocs_block],
    sitename="OptimalControl.jl",
    format=Documenter.HTML(;
        repolink="https://" * repo_url,
        prettyurls=false,
        size_threshold_ignore=[
            "api-optimalcontrol-user.md", "example-double-integrator-energy.md"
        ],
        assets=[
            asset("https://control-toolbox.org/assets/css/documentation.css"),
            asset("https://control-toolbox.org/assets/js/documentation.js"),
        ],
    ),
    pages=[
        "Getting Started" => "index.md",
        "Basic Examples" => [
            "Energy minimisation" => "example-double-integrator-energy.md",
            "Time mininimisation" => "example-double-integrator-time.md",
        ],
        "Manual" => [
            "Define a problem" => "manual-abstract.md",
            "Use AI" => "manual-ai-ded.md",
            "Problem characteristics" => "manual-model.md",
            "Set an initial guess" => "manual-initial-guess.md",
            "Solve a problem" => "manual-solve.md",
            "Solve on GPU" => "manual-solve-gpu.md",
            "Solution characteristics" => "manual-solution.md",
            "Plot a solution" => "manual-plot.md",
            "Compute flows" => [
                "Flow API" => "manual-flow-api.md",
                "From optimal control problems" => "manual-flow-ocp.md",
                "From Hamiltonians and others" => "manual-flow-others.md",
            ],
        ],
        "API" => [
            "OptimalControl.jl - User" => "api-optimalcontrol-user.md",
            "Subpackages - Developers" => [
                "CTBase.jl" => "api-ctbase.md",
                "CTDirect.jl" => "api-ctdirect.md",
                "CTFlows.jl" => "api-ctflows.md",
                "CTModels.jl" => "api-ctmodels.md",
                "CTParser.jl" => "api-ctparser.md",
                "OptimalControl.jl" => "api-optimalcontrol-dev.md",
            ],
        ],
        "Zhejiang 2025" => "zhejiang-2025.md",
        "JLESC17" => "jlesc17.md",
    ],
    plugins=[links],
)

deploydocs(; repo=repo_url * ".git", devbranch="main", push_preview=true)
