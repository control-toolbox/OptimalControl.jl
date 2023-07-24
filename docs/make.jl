using Documenter
using OptimalControl
using CTBase
using CTFlows
using CTDirect

# https://stackoverflow.com/questions/70137119/how-to-include-the-docstring-for-a-function-from-another-package-in-my-julia-doc
DocMeta.setdocmeta!(CTBase, :DocTestSetup, :(using CTBase); recursive = true)
DocMeta.setdocmeta!(CTFlows, :DocTestSetup, :(using CTFlows); recursive = true)
DocMeta.setdocmeta!(CTDirect, :DocTestSetup, :(using CTDirect); recursive = true)
DocMeta.setdocmeta!(OptimalControl, :DocTestSetup, :(using OptimalControl); recursive = true)

makedocs(
    sitename = "OptimalControl.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction"  => "index.md",
        "Tutorials"     => ["tutorial-basic-example.md", 
                            "tutorial-goddard.md",
                            "tutorial-model.md",
                            "tutorial-solvers.md",
                            "tutorial-init.md",
                            "tutorial-plot.md",
                            "tutorial-iss.md",
                            "tutorial-ctrepl.md"],
        "API"           => ["api.md", 
                            "api-ctbase.md", 
                            "api-ctflows.md", 
                            "api-ctdirect.md"], 
    ]
)

deploydocs(
    repo = "github.com/control-toolbox/OptimalControl.jl.git",
    devbranch = "main"
)
