# to run the documentation generation:
# julia --project=. docs/make.jl
pushfirst!(LOAD_PATH, joinpath(@__DIR__, ".."))
pushfirst!(LOAD_PATH, joinpath(@__DIR__))

# control-toolbox packages
using OptimalControl
using CTBase
using CTDirect
using CTFlows
using CTModels
using CTParser
using CTSolvers

# modelers
using ADNLPModels
using ExaModels

# solvers
using CommonSolve
using MadNLP
using MadNCL
using NLPModelsIpopt
using NLPModelsKnitro
using OrdinaryDiffEq

# documentation
using DocumenterInterLinks
using Documenter
using DocumenterMermaid
using Markdown
using MarkdownAST: MarkdownAST

# data serialization
using JSON3
using JLD2

# plotting
using Plots

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
    "CTSolvers" => (
        "https://control-toolbox.org/CTSolvers.jl/stable/",
        "https://control-toolbox.org/CTSolvers.jl/stable/objects.inv",
        joinpath(@__DIR__, "inventories", "CTSolvers.toml"),
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
const CTModelsJLD = Base.get_extension(CTModels, :CTModelsJLD)
const CTModelsJSON = Base.get_extension(CTModels, :CTModelsJSON)
const CTModelsPlots = Base.get_extension(CTModels, :CTModelsPlots)
const CTSolversIpopt = Base.get_extension(CTSolvers, :CTSolversIpopt)
const CTSolversKnitro = Base.get_extension(CTSolvers, :CTSolversKnitro)
const CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)
const CTSolversMadNCL = Base.get_extension(CTSolvers, :CTSolversMadNCL)
const CTFlowsODE = Base.get_extension(CTFlows, :CTFlowsODE)
Modules = [
    CTBase,
    CTFlows,
    CTDirect,
    CTModels,
    CTSolvers,
    CTParser,
    OptimalControl,
    CTModelsJLD,
    CTModelsJSON,
    CTModelsPlots,
    CTSolversIpopt,
    CTSolversKnitro,
    CTSolversMadNLP,
    CTSolversMadNCL,
    CTFlowsODE,
]
for Module in Modules
    isnothing(DocMeta.getdocmeta(Module, :DocTestSetup)) &&
        DocMeta.setdocmeta!(Module, :DocTestSetup, :(using $Module); recursive=true)
end

# ═══════════════════════════════════════════════════════════════════════════════
# Assets for reproducibility
# ═══════════════════════════════════════════════════════════════════════════════
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

# ═══════════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# if draft is true, then the julia code from .md is not executed
# to disable the draft mode in a specific markdown file, use the following:
#=
```@meta
Draft = false
```
=#
draft = false  # Draft mode: if true, @example blocks in markdown are not executed

# ═══════════════════════════════════════════════════════════════════════════════
# Load extensions
# ═══════════════════════════════════════════════════════════════════════════════
const DocumenterReference = Base.get_extension(CTBase, :DocumenterReference)

if !isnothing(DocumenterReference)
    DocumenterReference.reset_config!()
end

# ═══════════════════════════════════════════════════════════════════════════════
# Paths
# ═══════════════════════════════════════════════════════════════════════════════
repo_url = "github.com/control-toolbox/OptimalControl.jl"
src_dir = abspath(joinpath(@__DIR__, "..", "src"))
ext_dir = abspath(joinpath(@__DIR__, "..", "ext"))

# Include the API reference manager
include("api_reference.jl")

# ═══════════════════════════════════════════════════════════════════════════════
# Build documentation
# ═══════════════════════════════════════════════════════════════════════════════
with_api_reference(src_dir, ext_dir) do api_pages

    # add api/public.md
    api_pages_final = copy(api_pages)
    pushfirst!(api_pages_final, "Public" => joinpath("api", "public.md"))
    push!(api_pages_final, "Subpackages" => joinpath("api", "subpackages.md"))

    # build documentation
    makedocs(;
        draft=draft,
        remotes=nothing, # Disable remote links. Needed for DocumenterReference
        warnonly=true,
        sitename="OptimalControl.jl",
        format=Documenter.HTML(;
            repolink="https://" * repo_url,
            prettyurls=false,
            assets=[
                asset("https://control-toolbox.org/assets/css/documentation.css"),
                asset("https://control-toolbox.org/assets/js/documentation.js"),
                "assets/custom.css",
            ],
            size_threshold_ignore=[
                joinpath("api", "private.md"), joinpath("api", "public.md")
            ],
        ),
        pages=[
            "Introduction" => "index.md",
            "Basic Examples" => [
                "Energy minimisation" => "example-double-integrator-energy.md",
                "Time mininimisation" => "example-double-integrator-time.md",
                "Control-free problems" => "example-control-free.md",
                "Control and variable" => "example-control-and-variable.md",
                "Singular control" => "example-singular-control.md",
                "State constraint" => "example-state-constraint.md",
            ],
            "Manual" => [
                "Define a problem" => [
                    "Abstract syntax (@def)" => "manual-abstract.md",
                    "Functional API (macro-free)" => "manual-macro-free.md",
                ],
                "Use AI" => "manual-ai-llm.md",
                "Problem characteristics" => "manual-model.md",
                "Set an initial guess" => "manual-initial-guess.md",
                "Solve a problem" => [
                    "Basic usage" => "manual-solve.md",
                    "Advanced options" => "manual-solve-advanced.md",
                    "Explicit mode" => "manual-solve-explicit.md",
                    "GPU solving" => "manual-solve-gpu.md",
                ],
                "Solution characteristics" => "manual-solution.md",
                "Plot a solution" => "manual-plot.md",
                "Differential geometry tools" => "manual-differential-geometry.md",
                "Compute flows" => [
                    "From optimal control problems" => "manual-flow-ocp.md",
                    "From Hamiltonians and others" => "manual-flow-others.md",
                ],
            ],
            "API Reference" => api_pages_final,
        ],
        plugins=[links],
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
deploydocs(; repo=repo_url * ".git", devbranch="main", push_preview=true)
