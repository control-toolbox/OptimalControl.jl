using Documenter
using DocumenterMermaid
using OptimalControl
using CTBase
using CTFlows
using CTDirect

# to add docstrings from external packages
Modules = [CTBase, CTFlows, CTDirect, OptimalControl]
for Module ∈ Modules
    isnothing( DocMeta.getdocmeta(Module, :DocTestSetup) ) && 
    DocMeta.setdocmeta!(Module, :DocTestSetup, :(using $Module); recursive = true)
end

#
makedocs(
    warnonly = [:cross_references, :autodocs_block],
    sitename = "OptimalControl.jl",
    format = Documenter.HTML(
        prettyurls = false,
        size_threshold_ignore = [
            "api-ctbase/types.md",
            "tutorial-plot.md",
        ],
        assets = [
            asset("https://control-toolbox.org/assets/css/documentation.css"),
            asset("https://control-toolbox.org/assets/js/documentation.js"),
        ],
    ),
    pages = [
        "Introduction" => "index.md",
        "Basic examples" => [
            "Energy minimisation" => "tutorial-basic-example.md", 
            "Time mininimisation" => "tutorial-double-integrator.md",
        ],
        "Manual" => [
            "Abstract syntax"   => "tutorial-abstract.md",
            "Initial guess"     => "tutorial-initial-guess.md",
            "Solve"             => "tutorial-solve.md",
            "Plot a solution"   => "tutorial-plot.md",
            "Flow"              => "tutorial-flow.md",
            "Functional syntax" => "tutorial-functional.md",
        ],
        "Tutorials" => [
            "tutorial-continuation.md",
            "Goddard: direct, indirect"  => "tutorial-goddard.md",
            "tutorial-iss.md",
            "Linear–quadratic regulator" => "tutorial-lqr-basic.md",
            "tutorial-nlp.md",
        ],
        "API" => [
            "api-optimalcontrol.md",
            "Subpackages" => [
                "api-ctbase.md",
                "api-ctdirect.md",
                "api-ctflows.md",
            ],
        ],
        "Developers" => [
            "OptimalControl.jl" => "dev-optimalcontrol.md",
            "Subpackages" => [
                "CTBase.jl"   => "dev-ctbase.md",
                "CTDirect.jl" => "dev-ctdirect.md",
                "CTFlows.jl"  => "dev-ctflows.md",
            ],
        ],
        "JuliaCon 2024"=> "juliacon2024.md",
    ]
)

#
deploydocs(
    repo = "github.com/control-toolbox/OptimalControl.jl.git",
    devbranch = "main"
)
