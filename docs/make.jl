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

# to add docstrings from external packages
const CTFlowsODE = Base.get_extension(CTFlows, :CTFlowsODE)
Modules = [CTBase, CTFlows, CTDirect, CTModels, CTParser, OptimalControl, CTFlowsODE]
for Module in Modules
    isnothing(DocMeta.getdocmeta(Module, :DocTestSetup)) &&
        DocMeta.setdocmeta!(Module, :DocTestSetup, :(using $Module); recursive=true)
end

mkpath("./docs/src/assets")
cp("./docs/Manifest.toml", "./docs/src/assets/Manifest.toml"; force=true)
cp("./docs/Project.toml", "./docs/src/assets/Project.toml"; force=true)

repo_url = "github.com/control-toolbox/OptimalControl.jl"

makedocs(;
    draft=true, # if draft is true, then the julia code from .md is not executed
    # to disable the draft mode in a specific markdown file, use the following:
    # ```@meta
    # Draft = false
    # ```
    warnonly=[:cross_references, :autodocs_block],
    sitename="OptimalControl.jl",
    format=Documenter.HTML(;
        repolink="https://" * repo_url,
        prettyurls=false,
        size_threshold_ignore=["api-optimalcontrol-user.md"],
        assets=[
            asset("https://control-toolbox.org/assets/css/documentation.css"),
            asset("https://control-toolbox.org/assets/js/documentation.js"),
        ],
    ),
    pages=[
        "Getting Started" => "index.md",
        "Basic Examples" => [
            "Energy minimisation" => "tutorial-double-integrator-energy.md",
            "Time mininimisation" => "tutorial-double-integrator-time.md",
        ],
        "Manual" => [
            "Define a problem" => "tutorial-abstract.md",
            "Set an initial guess" => "tutorial-initial-guess.md",
            "Solve a problem" => "tutorial-solve.md",
            "Plot a solution" => "tutorial-plot.md",
            "Compute flows" => "tutorial-flow.md",
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
)

deploydocs(; repo=repo_url * ".git", devbranch="main")
