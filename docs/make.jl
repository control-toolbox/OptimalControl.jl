using Documenter
using OptimalControl

makedocs(
    sitename = "OptimalControl.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction" => "index.md",
        "Tutorials" => ["basic-example.md", "goddard.md"],
        "API" => "api.md",
        "Developpers" => "dev-api.md"
    ]
)

deploydocs(
    repo = "github.com/control-toolbox/OptimalControl.jl.git",
    devbranch = "main"
)
