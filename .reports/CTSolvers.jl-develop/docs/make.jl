using Documenter
using DocumenterMermaid
using CTSolvers
using CTBase
using Markdown
using MarkdownAST: MarkdownAST

# ═══════════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════════
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
repo_url = "github.com/control-toolbox/CTSolvers.jl"
src_dir = abspath(joinpath(@__DIR__, "..", "src"))
ext_dir = abspath(joinpath(@__DIR__, "..", "ext"))

# Include the API reference manager
include("api_reference.jl")

# ═══════════════════════════════════════════════════════════════════════════════
# Build documentation
# ═══════════════════════════════════════════════════════════════════════════════
with_api_reference(src_dir, ext_dir) do api_pages
    makedocs(;
        draft=draft,
        remotes=nothing, # Disable remote links. Needed for DocumenterReference
        warnonly=true,
        sitename="CTSolvers.jl",
        format=Documenter.HTML(;
            repolink="https://" * repo_url,
            prettyurls=false,
            assets=[
                asset("https://control-toolbox.org/assets/css/documentation.css"),
                asset("https://control-toolbox.org/assets/js/documentation.js"),
            ],
        ),
        pages=[
            "Introduction" => "index.md",
            "Architecture" => "architecture.md",
            "Developer Guides" => [
                "Options System" => "guides/options_system.md",
                "Implementing a Strategy" => "guides/implementing_a_strategy.md",
                "Implementing a Solver" => "guides/implementing_a_solver.md",
                "Implementing a Modeler" => "guides/implementing_a_modeler.md",
                "Implementing an Optimization Problem" => "guides/implementing_an_optimization_problem.md",
                "Orchestration & Routing" => "guides/orchestration_and_routing.md",
                "Error Messages Reference" => "guides/error_messages.md",
            ],
            "API Reference" => api_pages,
        ],
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
deploydocs(; repo=repo_url * ".git", devbranch="main")