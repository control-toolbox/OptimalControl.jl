using Documenter
using OptimalControl
using CTBase
using CTFlows
using CTDirect
using CTProblems

# https://stackoverflow.com/questions/70137119/how-to-include-the-docstring-for-a-function-from-another-package-in-my-julia-doc
DocMeta.setdocmeta!(CTBase, :DocTestSetup, :(using CTBase); recursive = true)
DocMeta.setdocmeta!(CTFlows, :DocTestSetup, :(using CTFlows); recursive = true)
DocMeta.setdocmeta!(CTDirect, :DocTestSetup, :(using CTDirect); recursive = true)
DocMeta.setdocmeta!(CTProblems, :DocTestSetup, :(using CTProblems); recursive = true)
DocMeta.setdocmeta!(OptimalControl, :DocTestSetup, :(using OptimalControl); recursive = true)

makedocs(
    warnonly = :cross_references,
    sitename = "OptimalControl.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction"  => "index.md",
        "Tutorials"     => ["tutorial-basic-example.md", 
                            "tutorial-basic-example-f.md", 
                            "tutorial-double-integrator.md",
                            "tutorial-lqr-basic.md",
                            "tutorial-goddard.md",
                            #"tutorial-model.md",
                            #"tutorial-solvers.md",
                            "tutorial-init.md",
                            "tutorial-plot.md",
                            #"tutorial-iss.md",
                            #"tutorial-flows.md",
                            #"tutorial-ct_repl.md",
                            ],
        "API"           => "api.md", 
        "JuliaCon2023"  => "juliacon2023.md", 
    ]
)

deploydocs(
    repo = "github.com/control-toolbox/OptimalControl.jl.git",
    devbranch = "main"
)
