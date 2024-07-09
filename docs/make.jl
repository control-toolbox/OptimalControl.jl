using Documenter
using DocumenterMermaid
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
    format = Documenter.HTML(prettyurls = false,
                             size_threshold_ignore = ["api-ctbase.md", "application-mri-saturation.md"]),
    pages = [
        "Introduction" => "index.md",
        "Tutorials"    => [
                            "tutorial-basic-example.md", 
                            "tutorial-basic-example-f.md", 
                            "tutorial-double-integrator.md",
                            "tutorial-initial-guess.md",
                            "tutorial-continuation.md",
                            "tutorial-nlp.md",
                            "tutorial-plot.md",
                            "tutorial-lqr-basic.md",
                            "tutorial-iss.md",
                            ],
        "Applications" => [
                            "tutorial-batch.md",
                            "tutorial-goddard.md",
                            "application-mri-saturation.md",
                          ],
        "FGS 2024"     => "fgs-2024.md", 
        "API"          => "api.md", 
    ]
)

deploydocs(
    repo = "github.com/control-toolbox/OptimalControl.jl.git",
    devbranch = "main"
)
