# to run the documentation generation:
# julia --project=. docs/make.jl
# to serve the documentation:
#   npx serve docs/build/1 --listen 5173
pushfirst!(LOAD_PATH, joinpath(@__DIR__, ".."))
pushfirst!(LOAD_PATH, joinpath(@__DIR__))

# control-toolbox packages
using OptimalControl
using CTBase
using CTDirect
using CTFlows
using CTLie
using CTModels
using CTParser
using CTSolvers

# modelers
using ADNLPModels
using ExaModels

# solvers
using CommonSolve
using MadNLP
using MadNCL
using NLPModelsIpopt
using NLPModelsKnitro
using OrdinaryDiffEq

# documentation
using DocumenterInterLinks
using Documenter
using DocumenterVitepress
using Markdown
using MarkdownAST: MarkdownAST

# data serialization
using JSON3
using JLD2

# plotting
using Plots
import CairoMakie   # `import`, not `using`: keeps Makie's `plot`/`plot!` out of Main,
# which would collide with Plots' in the `@docs` block on results/plot.md

# DocumenterVitepress picks the highest-priority MIME type a plot object responds to
# (image/png: 4.0 over image/svg+xml: 3.0) — the opposite of Documenter.HTML, which
# prefers SVG. Both Plots.jl and CairoMakie respond to `image/png`, so PNG wins for
# every figure unless it is disabled. Set once here, before any @example block runs,
# so it covers every page present or future — not just the ones plotting today. See
# Handbook/VITEPRESS-DOC.md "Plot image format — SVG vs PNG".
Base.showable(::MIME"image/png", ::Plots.Plot) = false
CairoMakie.activate!(; type="svg")
Base.showable(::MIME"image/png", ::CairoMakie.Makie.Figure) = false

# DocumenterVitepress (0.3.5) hard-codes `collapsed: false` on every sidebar group
# (`vitepress_config.jl`'s `pagelist2str` for a nested `name => children` entry), so the
# whole navigation tree renders fully expanded and there is no `MarkdownVitepress` option
# to change it. Override that one method to emit `collapsed: true` for the sidebar: each
# group starts folded, and VitePress still auto-expands the group containing the current
# page. The navbar branch (`sidenav === Val(:navbar)`) is left untouched.
@eval DocumenterVitepress function pagelist2str(
    doc, name_contents::Pair{<:AbstractString,<:AbstractArray}, sidenav::Val
)
    name, contents = name_contents
    rendered_contents = String[]
    for content in contents
        str = pagelist2str(doc, content, sidenav)
        isempty(str) || push!(rendered_contents, "{" * str * "}")
    end
    final_contents = join(rendered_contents, ",\n")
    collapse = sidenav === Val(:sidebar) ? "collapsed: true," : ""
    return "text: '$(replace(name, "'" => "\\'"))', $collapse items: [\n$(final_contents)\n]"
end

#
function _ext(pkg, sym)
    m = Base.get_extension(pkg, sym)
    isnothing(m) && @warn "Extension $sym of $pkg is not loaded"
    return m
end

# to add docstrings from external packages
const CTModelsJLD = Base.get_extension(CTModels, :CTModelsJLD)
const CTModelsJSON = Base.get_extension(CTModels, :CTModelsJSON)
const CTModelsPlots = Base.get_extension(CTModels, :CTModelsPlots)
const CTSolversIpopt = Base.get_extension(CTSolvers, :CTSolversIpopt)
const CTSolversKnitro = Base.get_extension(CTSolvers, :CTSolversKnitro)
const CTSolversMadNLP = Base.get_extension(CTSolvers, :CTSolversMadNLP)
const CTSolversMadNCL = Base.get_extension(CTSolvers, :CTSolversMadNCL)

Modules = Any[
    CTBase, CTLie, CTFlows, CTDirect, CTModels, CTSolvers, CTParser, OptimalControl
]

for (pkg, syms) in [
    CTModels => (:CTModelsJLD, :CTModelsJSON, :CTModelsPlots),
    CTSolvers => (:CTSolversIpopt, :CTSolversKnitro, :CTSolversMadNLP, :CTSolversMadNCL),
    CTFlows => (:CTFlowsPlots, :CTFlowsSciMLFlows, :CTFlowsSciMLIntegrator),
]
    for s in syms
        m = _ext(pkg, s)
        isnothing(m) || push!(Modules, m)
    end
end

for Module in Modules
    isnothing(DocMeta.getdocmeta(Module, :DocTestSetup)) &&
        DocMeta.setdocmeta!(Module, :DocTestSetup, :(using $Module); recursive=true)
end

# ═══════════════════════════════════════════════════════════════════════════════
# Assets for reproducibility
# ═══════════════════════════════════════════════════════════════════════════════
mkpath(joinpath(@__DIR__, "src", "assets"))
cp(
    joinpath(@__DIR__, "Manifest.toml"),
    joinpath(@__DIR__, "src", "assets", "Manifest.toml");
    force=true,
)
cp(
    joinpath(@__DIR__, "Project.toml"),
    joinpath(@__DIR__, "src", "assets", "Project.toml");
    force=true,
)

# ═══════════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# if draft is true, then the julia code from .md is not executed
# to disable the draft mode in a specific markdown file, use the following:
#=
```@meta
Draft = false
```
=#
draft = true  # Draft mode: skip @example execution globally; guided tour overrides below

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
repo_url = "github.com/control-toolbox/OptimalControl.jl"
src_dir = abspath(joinpath(@__DIR__, "..", "src"))
ext_dir = abspath(joinpath(@__DIR__, "..", "ext"))

# Include the API reference manager
include("api_reference.jl")

# ═══════════════════════════════════════════════════════════════════════════════
# InterLinks
# ═══════════════════════════════════════════════════════════════════════════════
links = InterLinks(
    "CTBase" => (
        "https://control-toolbox.org/CTBase.jl/stable/",
        joinpath(@__DIR__, "..", "..", "CTBase", "docs", "build", "1", "objects.inv"),
        "https://control-toolbox.org/CTBase.jl/stable/objects.inv",
    ),
    "CTDirect" => (
        "https://control-toolbox.org/CTDirect.jl/stable/",
        joinpath(@__DIR__, "..", "..", "CTDirect.jl", "docs", "build", "1", "objects.inv"),
        "https://control-toolbox.org/CTDirect.jl/stable/objects.inv",
    ),
    "CTFlows" => (
        "https://control-toolbox.org/CTFlows.jl/stable/",
        joinpath(@__DIR__, "..", "..", "CTFlows.jl", "docs", "build", "1", "objects.inv"),
        "https://control-toolbox.org/CTFlows.jl/stable/objects.inv",
    ),
    "CTLie" => (
        "https://control-toolbox.org/CTLie.jl/stable/",
        joinpath(@__DIR__, "..", "..", "CTLie", "docs", "build", "1", "objects.inv"),
        "https://control-toolbox.org/CTLie.jl/stable/objects.inv",
    ),
    "CTModels" => (
        "https://control-toolbox.org/CTModels.jl/stable/",
        joinpath(@__DIR__, "..", "..", "CTModels.jl", "docs", "build", "1", "objects.inv"),
        "https://control-toolbox.org/CTModels.jl/stable/objects.inv",
    ),
    "CTParser" => (
        "https://control-toolbox.org/CTParser.jl/stable/",
        joinpath(@__DIR__, "..", "..", "CTParser.jl", "docs", "build", "1", "objects.inv"),
        "https://control-toolbox.org/CTParser.jl/stable/objects.inv",
    ),
    "CTSolvers" => (
        "https://control-toolbox.org/CTSolvers.jl/stable/",
        joinpath(@__DIR__, "..", "..", "CTSolvers", "docs", "build", "1", "objects.inv"),
        "https://control-toolbox.org/CTSolvers.jl/stable/objects.inv",
    ),
    "ADNLPModels" => (
        "https://jso.dev/ADNLPModels.jl/stable/",
        joinpath(@__DIR__, "inventories", "ADNLPModels.toml"),
        "https://jso.dev/ADNLPModels.jl/stable/objects.inv",
    ),
    "NLPModelsIpopt" => (
        "https://jso.dev/NLPModelsIpopt.jl/stable/",
        joinpath(@__DIR__, "inventories", "NLPModelsIpopt.toml"),
        "https://jso.dev/NLPModelsIpopt.jl/stable/objects.inv",
    ),
    "ExaModels" => (
        "https://exanauts.github.io/ExaModels.jl/stable/",
        joinpath(@__DIR__, "inventories", "ExaModels.toml"),
        "https://exanauts.github.io/ExaModels.jl/stable/objects.inv",
    ),
    "MadNLP" => (
        "https://madnlp.github.io/MadNLP.jl/stable/",
        joinpath(@__DIR__, "inventories", "MadNLP.toml"),
        "https://madnlp.github.io/MadNLP.jl/stable/objects.inv",
    ),
    "Tutorials" => (
        "https://control-toolbox.org/Tutorials.jl/stable/",
        joinpath(@__DIR__, "inventories", "Tutorials.toml"),
        "https://control-toolbox.org/Tutorials.jl/stable/objects.inv",
    ),
)

# ═══════════════════════════════════════════════════════════════════════════════
# Literate: generate getting-started/guided-tour.md and sidecar files
# ═══════════════════════════════════════════════════════════════════════════════
using Literate

LITERATE_DIR = joinpath(@__DIR__, "src-literate")
MD_OUTPUT = joinpath(@__DIR__, "src", "getting-started")
NB_OUTPUT = joinpath(@__DIR__, "src", "notebooks")
JL_OUTPUT = joinpath(@__DIR__, "src", "scripts")
mkpath(NB_OUTPUT)
mkpath(JL_OUTPUT)

for file in ["guided-tour.jl"]
    INPUT = joinpath(LITERATE_DIR, file)
    # The guided tour executes like every other real page: inject `Draft = false`
    # into the generated page's `@meta` block so its code runs under the global
    # `draft = true` (Phase E5). The PR-2-era comment here claimed executing it
    # "surfaced several unrelated runtime bugs" — those were upstream and have
    # since been fixed; the tour now builds clean.
    add_draft_false =
        content -> replace(
            content,
            "EditURL = \"../../src-literate/$file\"\n" => "EditURL = \"../../src-literate/$file\"\nDraft = false\n",
        )
    Literate.markdown(INPUT, MD_OUTPUT; name="guided-tour", postprocess=add_draft_false)
    Literate.notebook(INPUT, NB_OUTPUT; name="guided-tour", execute=false)
    Literate.script(INPUT, JL_OUTPUT; name="guided-tour")
end

# ═══════════════════════════════════════════════════════════════════════════════
# Build documentation
# ═══════════════════════════════════════════════════════════════════════════════
with_api_reference(src_dir, ext_dir) do api_pages

    # add api/ecosystem.md to the generated API pages
    api_pages_final = copy(api_pages)
    push!(api_pages_final, "Ecosystem" => "api/ecosystem.md")

    # build documentation
    return makedocs(;
        draft=draft,
        remotes=nothing, # Disable remote links. Needed for DocumenterReference
        # Not fully zero: 2 unresolved @ref (DOCPCache, category :cross_references) and 6
        # unresolved @extref (CTModels.Solution / CTBase.Strategies.parameter — a *separate*
        # category, :external_cross_references, registered by DocumenterInterLinks, not
        # Documenter itself) are upstream defects, tracked at control-toolbox/CTDirect.jl#630,
        # control-toolbox/CTModels.jl#416 and control-toolbox/CTBase.jl#543 respectively. Drop
        # this exclusion once those land — see .reports/campaign/D-api-reference.md.
        #
        # :example_block is deliberately *not* here: the one remaining un-expanded @example
        # (CTParser's @def docstring, control-toolbox/CTParser.jl#341, transcluded onto
        # api/modelling.md) is a side effect of `draft` mode skipping execution and is never
        # added to `doc.internal.errors` — confirmed by testing that a genuinely broken
        # @example block on a Draft=false page (this file rewritten to error) still fails the
        # build with :example_block even with this exact warnonly list, while the CTParser one
        # stays silent either way. Excluding :example_block would have hidden real breakage for
        # no benefit.
        warnonly=[:cross_references, :external_cross_references],
        sitename="OptimalControl.jl",
        format=DocumenterVitepress.MarkdownVitepress(;
            repo=repo_url, devbranch="main", devurl="dev", sidebar_drawer=true
        ),
        pages=[
            # index.md is the VitePress root — not listed here
            "Getting started" => [
                "Installation" => "getting-started/installation.md",
                "Your first problem" => "getting-started/first-problem.md",
                "Guided tour" => "getting-started/guided-tour.md",
            ],
            "Modelling" => [
                "Formulation" => "modelling/formulation.md",
                "Abstract syntax (@def)" => "modelling/abstract-syntax.md",
                "Functional API" => "modelling/functional-api.md",
                "No control" => "modelling/without-control.md",
                "Inspect a problem" => "modelling/inspect.md",
                "With AI" => "modelling/with-ai.md",
            ],
            "Solve (direct)" => [
                "Overview" => "solve/overview.md",
                "Initial guess" => "solve/initial-guess.md",
                "Choosing a method" => "solve/choosing-a-method.md",
                "Options" => "solve/options.md",
                "Explicit mode" => "solve/explicit-mode.md",
                "GPU" => "solve/gpu.md",
            ],
            "Results" => [
                "Solution object" => "results/solution.md",
                "Plot" => "results/plot.md",
                "Save & load" => "results/save-load.md",
            ],
            "Flows (indirect)" => [
                "Overview" => "flows/overview.md",
                "From an OCP" => "flows/from-ocp.md",
                "From Hamiltonians" => "flows/from-hamiltonians.md",
                "Simulation" => "flows/simulation.md",
                "Accessors" => "flows/accessors.md",
                "Multi-phase flows" => "flows/multi-phase.md",
                "Constrained arcs" => "flows/constrained-arcs.md",
                "Shooting" => "flows/shooting.md",
            ],
            "Geometry" => [
                "Overview" => "geometry/overview.md",
                "Lift" => "geometry/lift.md",
                "Lie derivative and Lie bracket" => "geometry/ad.md",
                "Poisson bracket" => "geometry/poisson.md",
                "The @Lie macro" => "geometry/lie-macro.md",
                "AD backend" => "geometry/ad-backend.md",
            ],
            "Examples" => [
                "Example gallery" => "examples/gallery.md",
                "Energy minimisation" => "examples/double-integrator-energy.md",
                "Time minimisation (bang–bang)" => "examples/double-integrator-time.md",
                "Parameter estimation without a control" => "examples/control-free.md",
                "Control and variable together" => "examples/control-and-variable.md",
                "Singular control" => "examples/singular-control.md",
                "State constraint" => "examples/state-constraint.md",
                "The logo" => "examples/logo.md",
            ],
            "API Reference" => api_pages_final,
            "Migrating to v2.1" => "migration.md",
        ],
        plugins=[links],
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
# Deploy documentation to GitHub Pages
# ═══════════════════════════════════════════════════════════════════════════════
bases_file = joinpath(@__DIR__, "build", "bases.txt")
if isfile(bases_file)
    DocumenterVitepress.deploydocs(;
        repo=repo_url * ".git", devbranch="main", push_preview=true
    )
else
    @info "Skipping deployment: no bases were built (prerelease with existing higher stable release)."
end
