using Documenter
using DocumenterMermaid
using OptimalControl
using CTBase
using CTFlows
using CTDirect
using CTProblems
using Plots

# https://stackoverflow.com/questions/70137119/how-to-include-the-docstring-for-a-function-from-another-package-in-my-julia-doc
DocMeta.setdocmeta!(CTBase, :DocTestSetup, :(using CTBase); recursive = true)
DocMeta.setdocmeta!(CTFlows, :DocTestSetup, :(using CTFlows); recursive = true)
DocMeta.setdocmeta!(CTDirect, :DocTestSetup, :(using CTDirect); recursive = true)
DocMeta.setdocmeta!(CTProblems, :DocTestSetup, :(using CTProblems); recursive = true)
DocMeta.setdocmeta!(OptimalControl, :DocTestSetup, :(using OptimalControl); recursive = true)

Base.showable(::MIME"text/html", ::Plots.Plot) = false

makedocs(
    warnonly = :cross_references,
    sitename = "OptimalControl.jl",
    format = Documenter.HTML(prettyurls = false,
                             size_threshold_ignore = [  "api-ctbase.md", 
                                                        "application-mri-saturation.md"
                                                     ]),
    pages = [
        "Introduction" => "index.md",
        "Applications" => [
                            "application-mri-saturation.md",
                          ],
    ]
)

deploydocs(
    repo = "github.com/control-toolbox/OptimalControl.jl.git",
    devbranch = "main"
)
