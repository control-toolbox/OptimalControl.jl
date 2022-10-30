using Documenter
using ControlToolbox

makedocs(
    sitename = "ControlToolbox.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction" => "index.md",
        "API" => "api.md"
    ]
)

deploydocs(
    repo = "github.com/control-toolbox/ControlToolbox.jl.git",
    devbranch = "main"
)
