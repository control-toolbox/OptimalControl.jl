using Documenter
using DocumenterMermaid
using OptimalControl
using CTBase
using CTDirect
using CTFlows
using CTModels
using CTParser

# to add docstrings from external packages
Modules = [CTBase, CTFlows, CTDirect, CTModels, CTParser, OptimalControl]
for Module in Modules
    isnothing(DocMeta.getdocmeta(Module, :DocTestSetup)) &&
        DocMeta.setdocmeta!(Module, :DocTestSetup, :(using $Module); recursive=true)
end

repo_url = "github.com/control-toolbox/OptimalControl.jl"

makedocs(;
    warnonly=[:cross_references, :autodocs_block],
    sitename="OptimalControl.jl",
    format=Documenter.HTML(;
        repolink="https://" * repo_url,
        prettyurls=false,
        size_threshold_ignore=[
            "api-ctbase/types.md", "dev-ctmodels.md", "tutorial-plot.md"
        ],
        assets=[
            asset("https://control-toolbox.org/assets/css/documentation.css"),
            asset("https://control-toolbox.org/assets/js/documentation.js"),
        ],
    ),
    pages=[
        "Introduction" => "index.md",
        "Basic examples" => [
            "Energy minimisation" => "tutorial-double-integrator-energy.md",
            "Time mininimisation" => "tutorial-double-integrator-time.md",
        ],
        "Manual" => [
            "Abstract syntax" => "tutorial-abstract.md",
            "Initial guess" => "tutorial-initial-guess.md",
            "Solve" => "tutorial-solve.md",
            "Plot a solution" => "tutorial-plot.md",
            "Flow" => "tutorial-flow.md",
        ],
        "Tutorials" => [
            "Discretisation options" => "tutorial-discretisation.md",
            "Discrete continuation" => "tutorial-continuation.md",
            "NLP options" => "tutorial-nlp.md",
            "Goddard: direct, indirect" => "tutorial-goddard.md",
            "Indirect simple shooting" => "tutorial-iss.md",
            "Linear–quadratic regulator" => "tutorial-lqr-basic.md",
            "Minimal action" => "tutorial-mam.md",
        ],
        "Developers" => [
            "OptimalControl.jl" => "dev-optimalcontrol.md",
            "Subpackages" => [
                "CTBase.jl" => "dev-ctbase.md",
                "CTDirect.jl" => "dev-ctdirect.md",
                "CTFlows.jl" => "dev-ctflows.md",
                "CTModels.jl" => "dev-ctmodels.md",
                "CTParser.jl" => "dev-ctparser.md",
            ],
        ],
        "Zhejiang 2025" => "zhejiang-2025.md",
    ],
)

deploydocs(; repo=repo_url * ".git", devbranch="main")
