# to run the documentation generation:
# julia --project=docs docs/make.jl
# to serve the documentation:
#   npx serve docs/build/1 --listen 5173
# Append (not prepend): docs/Manifest.toml must win for shared deps; the repo root is only
# needed to find the local OptimalControl. Prepending it lets the root environment shadow docs/ and
# breaks the precompilation of extensions on weak dependencies installed only in docs/.
push!(LOAD_PATH, joinpath(@__DIR__))
push!(LOAD_PATH, joinpath(@__DIR__, ".."))

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
using JSON
using JLD2

# plotting
using Plots
using CairoMakie: CairoMakie   # `import`, not `using`: keeps Makie's `plot`/`plot!` out of Main,
# which would collide with Plots' in the `@docs` block on results/plot.md

# DocumenterVitepress picks the highest-priority MIME type a plot object responds to
# (image/png: 4.0 over image/svg+xml: 3.0) — the opposite of Documenter.HTML, which
# prefers SVG. Both Plots.jl and CairoMakie respond to `image/png`, so PNG wins for
# every figure unless it is disabled. Set once here, before any @example block runs,
# so it covers every page present or future — not just the ones plotting today. See
# ct-conventions SITE12.
Base.showable(::MIME"image/png", ::Plots.Plot) = false
CairoMakie.activate!(; type="svg")
Base.showable(::MIME"image/png", ::CairoMakie.Makie.Figure) = false

# Thumbnails of the example gallery (src/components/ExamplesGallery.vue). Each example page
# calls `Main.gallery_thumbnail(fig, id)` in a hidden block, which saves the figure in a
# temporary staging folder (not under `build/`, whose content DocumenterVitepress moves
# into `build/.documenter/` before rendering). The `GalleryThumbnails`
# plugin hands that folder to DocumenterVitepress, which copies it into the VitePress
# `public/` at render time, after it has rebuilt that folder: the figure is served at
# `/gallery/<id>.svg`. A page built in draft mode saves nothing, and its card then shows no
# image.
const GALLERY_STAGING = mktempdir()
function gallery_thumbnail(fig, id::AbstractString)
    dir = mkpath(joinpath(GALLERY_STAGING, "gallery"))
    path = joinpath(dir, id * ".svg")
    fig isa Plots.Plot ? Plots.savefig(fig, path) : CairoMakie.save(path, fig)
    return nothing
end
struct GalleryThumbnails <: Documenter.Plugin end
DocumenterVitepress.vitepress_assets(::GalleryThumbnails) = [GALLERY_STAGING]

# The rocket animation of the guided tour: an HTML template with `@@name@@` placeholders,
# filled in with the trajectories of the page. The template is a file of its own, not a
# string in the page: JavaScript does not survive the `# hide` markers of a Literate block.
const GODDARD_TEMPLATE = joinpath(@__DIR__, "src-literate", "goddard-animation.html")
_js(x::AbstractVector) = "[" * join(round.(x; digits=6), ",") * "]"
_js(x::Real) = string(round(x; digits=6))
_js(c::Plots.Colorant) = "#" * Plots.Colors.hex(c)
goddard_animation(; kwargs...) =
    reduce((html, (k, v)) -> replace(html, "@@$k@@" => _js(v)), kwargs; init=read(GODDARD_TEMPLATE, String))

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
    is_sidebar = sidenav === Val(:sidebar)
    is_getting_started = lowercase(strip(name)) == "getting started"
    collapse = is_sidebar && !is_getting_started ? "collapsed: true," : ""
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
    CTModels => (:CTModelsJLD, :CTModelsJSON, :CTModelsPlots, :CTModelsMakie),
    CTSolvers => (:CTSolversIpopt, :CTSolversKnitro, :CTSolversMadNLP, :CTSolversMadNCL),
    CTFlows => (:CTFlowsPlots, :CTFlowsSciMLFlows, :CTFlowsSciMLIntegrator, :CTFlowsMakie),
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
# Each TOML is copied twice: into `src/assets/` so Documenter's link checker
# resolves the `assets/…` download links (no `warnonly` since #952), and into
# `src/public/assets/` so VitePress actually serves the file — it does not bundle
# `.toml`, and DocumenterVitepress's assets→public copy only handles logo/favicon.
# Creating `src/public/` also makes DVP skip that logo copy, so the logo is staged
# into `src/public/` here as well. `src/public/` is git-ignored (build output);
# `src/assets/Manifest.toml` stays tracked (the reviewable snapshot).
mkpath(joinpath(@__DIR__, "src", "assets"))
mkpath(joinpath(@__DIR__, "src", "public", "assets"))
for f in ("Manifest.toml", "Project.toml")
    cp(joinpath(@__DIR__, f), joinpath(@__DIR__, "src", "assets", f); force=true)
    cp(joinpath(@__DIR__, f), joinpath(@__DIR__, "src", "public", "assets", f); force=true)
end

# Logo: `logo.svg` is the tracked light artwork; `logo-dark.svg` is the same file with
# the white backdrop swapped for the VitePress dark surface (#1b1b1f), Julia mark colours
# unchanged — generated here (git-ignored). Both are staged into `src/public/`: the
# home-page hero reads them from there (front matter, not bundled by Vite), and the navbar
# uses `/logo.svg` (DVP fills `logo:` with it; a `.dark` filter recolours it there).
write(
    joinpath(@__DIR__, "src", "assets", "logo-dark.svg"),
    replace(
        read(joinpath(@__DIR__, "src", "assets", "logo.svg"), String),
        "#ffffff" => "#1b1b1f",
    ),
)
cp(
    joinpath(@__DIR__, "src", "assets", "logo.svg"),
    joinpath(@__DIR__, "src", "public", "logo.svg");
    force=true,
)
cp(
    joinpath(@__DIR__, "src", "assets", "logo-dark.svg"),
    joinpath(@__DIR__, "src", "public", "logo-dark.svg");
    force=true,
)

# ═══════════════════════════════════════════════════════════════════════════════
# Configuration
# ═══════════════════════════════════════════════════════════════════════════════
# `draft = false` is the committed default: every page executes its `@example` /
# `@repl` blocks, which is what a published build must do. Flip this to `true`
# locally for a fast build that skips all execution (checking navigation, links,
# `@extref`/`@ref` resolution, rendering). To keep one specific page drafted while
# the rest execute, add to its `@meta` block:
#=
```@meta
Draft = true
```
=#
draft = false

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

# ═══════════════════════════════════════════════════════════════════════════════
# Deploy decision (SITE13)
# ═══════════════════════════════════════════════════════════════════════════════
# Where the site is deployed, decided once. DocumenterVitepress builds the site for the
# base of this decision; without it, it decides with `push_preview=true` and builds a pull
# request for `previews/PR<n>`, announcing a deployment that `deploydocs` then refuses
# (#1042). A pull request deploys its preview only with the label `documentation push
# preview`, which sets `DOCUMENTER_PUSH_PREVIEW` (CTActions).
push_preview = get(ENV, "DOCUMENTER_PUSH_PREVIEW", "false") == "true"
deploy_decision = Documenter.deploy_folder(
    Documenter.auto_detect_deploy_system();
    repo=repo_url,
    devbranch="main",
    devurl="dev",
    push_preview=push_preview,
)

# Include the API reference manager
include("api_reference.jl")

# ═══════════════════════════════════════════════════════════════════════════════
# InterLinks
# ═══════════════════════════════════════════════════════════════════════════════
# Sibling inventories (SITE4): the published one, as on CI. With CT_LOCAL_INVENTORIES=true,
# the sibling's local build is read first, so that a contributor developing across
# repositories sees their in-progress docstring/@extref changes before a release:
#   CT_LOCAL_INVENTORIES=true julia --project=docs docs/make.jl
# Never by default: InterLinks takes the first source that loads for the whole package, so
# an old local build shadows the published inventory and breaks every @extref added since
# (CTModels 0.19.7 built next to this repo against 0.21.1 published; ct-conventions#69).
# A missing local file falls back to the published inventory without a warning (#950).
const LOCAL_INVENTORIES = get(ENV, "CT_LOCAL_INVENTORIES", "false") == "true"

function sibling_inventory(dir_name::AbstractString, base_url::AbstractString)
    remote = (base_url, base_url * "objects.inv")
    LOCAL_INVENTORIES || return remote
    local_inv = joinpath(
        @__DIR__, "..", "..", dir_name, "docs", "build", "1", "objects.inv"
    )
    isfile(local_inv) || return remote
    version = "?"
    for line in Iterators.take(eachline(local_inv), 4)
        startswith(line, "# Version: ") && (version = chopprefix(line, "# Version: "))
    end
    @info "InterLinks: local inventory of $dir_name (version $version)" local_inv
    return (base_url, local_inv, base_url * "objects.inv")
end

links = InterLinks(
    "CTBase" =>
        sibling_inventory("CTBase", "https://control-toolbox.org/CTBase.jl/stable/"),
    "CTDirect" =>
        sibling_inventory("CTDirect.jl", "https://control-toolbox.org/CTDirect.jl/stable/"),
    "CTFlows" =>
        sibling_inventory("CTFlows.jl", "https://control-toolbox.org/CTFlows.jl/stable/"),
    "CTLie" => sibling_inventory("CTLie", "https://control-toolbox.org/CTLie.jl/stable/"),
    "CTModels" =>
        sibling_inventory("CTModels.jl", "https://control-toolbox.org/CTModels.jl/stable/"),
    "CTParser" =>
        sibling_inventory("CTParser.jl", "https://control-toolbox.org/CTParser.jl/stable/"),
    "CTSolvers" =>
        sibling_inventory("CTSolvers", "https://control-toolbox.org/CTSolvers.jl/stable/"),
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
        "https://madsuite-org.github.io/ExaModels.jl/stable/",
        joinpath(@__DIR__, "inventories", "ExaModels.toml"),
        "https://madsuite-org.github.io/ExaModels.jl/stable/objects.inv",
    ),
    "MadNLP" => (
        "https://madsuite-org.github.io/MadNLP.jl/stable/",
        joinpath(@__DIR__, "inventories", "MadNLP.toml"),
        "https://madsuite-org.github.io/MadNLP.jl/stable/objects.inv",
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
# The notebook and the script are offered as downloads on the guided tour page, served by
# VitePress from `src/public/assets/` (git-ignored). The page links them in raw HTML, so
# Documenter's link checker does not need a copy in `src/assets/`.
DOWNLOAD_DIR = joinpath(@__DIR__, "src", "public", "assets")

for file in ["guided-tour.jl"]
    INPUT = joinpath(LITERATE_DIR, file)
    # The guided tour executes like every other real page under the global
    # `draft = false`. (It once carried an injected `Draft = false` override to run
    # under a `draft = true` default; that default is gone.)
    Literate.markdown(INPUT, MD_OUTPUT; name="guided-tour")
    Literate.notebook(INPUT, DOWNLOAD_DIR; name="guided-tour", execute=false)
    Literate.script(INPUT, DOWNLOAD_DIR; name="guided-tour")
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
        # No `warnonly`: every unresolved cross-reference fails the build. The historical
        # backlog is cleared — the `@ref`/`DOCPCache` pair (control-toolbox/CTDirect.jl#630,
        # closed) and the `@extref` set (`CTBase.Strategies.parameter` #943; CTModels'
        # extension docstrings control-toolbox/CTModels.jl#427, shipped in CTModels
        # 0.19.4-beta). With `draft = false` a broken `@example` / `@repl` also fails
        # (:example_block). Verified with the sibling inventories resolved remotely (as on
        # CI). See .reports/campaign/D-api-reference.md.
        sitename="OptimalControl.jl",
        format=DocumenterVitepress.MarkdownVitepress(;
            repo=repo_url,
            devbranch="main",
            devurl="dev",
            sidebar_drawer=true,
            deploy_decision=deploy_decision,
        ),
        pages=[
            # index.md is the VitePress root — not listed here
            "Getting started" => [
                "Installation" => "getting-started/installation.md",
                "Your first problem" => "getting-started/first-problem.md",
                "Guided tour" => "getting-started/guided-tour.md",
                # The examples are reached from the gallery, which gives their reading
                # order; each page links the previous and the next one
                # (src/components/ExampleNav.vue).
                "Examples" => "examples/gallery.md",
            ],
            "Modelling" => [
                "Formulation" => "modelling/formulation.md",
                "Abstract syntax (@def)" => "modelling/abstract-syntax.md",
                "Functional API" => "modelling/functional-api.md",
                "Control-free problems" => "modelling/without-control.md",
                "Inspect a problem" => "modelling/inspect.md",
                "With AI" => "modelling/with-ai.md",
            ],
            "Solve (direct)" => [
                "Overview" => "solve/overview.md",
                "Choosing a method" => "solve/choosing-a-method.md",
                "Options" => "solve/options.md",
                "Explicit mode" => "solve/explicit-mode.md",
                "Initial guess" => "solve/initial-guess.md",
                "GPU" => "solve/gpu.md",
            ],
            "Results" => [
                "Solution object" => "results/solution.md",
                "Plot with Plots" => "results/plot.md",
                "Plot with Makie" => "results/plot-makie.md",
                "Save & load" => "results/save-load.md",
            ],
            "Flows (indirect)" => [
                "Overview" => "flows/overview.md",
                "From an OCP" => "flows/from-ocp.md",
                "Shooting" => "flows/shooting.md",
                "Multi-phase flows" => "flows/multi-phase.md",
                "Constrained arcs" => "flows/constrained-arcs.md",
                "Simulation" => "flows/simulation.md",
                "From Hamiltonians" => "flows/from-hamiltonians.md",
                "Accessors" => "flows/accessors.md",
            ],
            "Geometry" => [
                "Overview" => "geometry/overview.md",
                "Lift" => "geometry/lift.md",
                "Lie derivative and Lie bracket" => "geometry/ad.md",
                "Poisson bracket" => "geometry/poisson.md",
                "The @Lie macro" => "geometry/lie-macro.md",
                "AD backend" => "geometry/ad-backend.md",
            ],
            "Reference" => [
                "API Reference" => api_pages_final,
                "Errors" => "errors.md",
                "Migrating from v2.0" => "migration.md",
                "About" => "about.md",
            ],
        ],
        plugins=[links, GalleryThumbnails()],
    )
end

# ═══════════════════════════════════════════════════════════════════════════════
# Deploy documentation to GitHub Pages
# ═══════════════════════════════════════════════════════════════════════════════
bases_file = joinpath(@__DIR__, "build", "bases.txt")
if !deploy_decision.all_ok
    reason = if get(ENV, "GITHUB_EVENT_NAME", "") == "pull_request" && !push_preview
        "no preview requested (label `documentation push preview` absent)"
    else
        "the deployment criteria above are not met"
    end
    @info "Skipping deployment: $(reason)."
elseif !isfile(bases_file)
    @info "Skipping deployment: no bases were built (prerelease with existing higher stable release)."
else
    DocumenterVitepress.deploydocs(;
        repo=repo_url * ".git", devbranch="main", push_preview=push_preview
    )
end
