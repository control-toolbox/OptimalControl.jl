const EXCLUDE_SYMBOLS = [:include, :eval, :OptimalControl]

const NON_SYMBOLS = Set([
    "API", "PR", "Source", "Symbol", "Why", "Guide", "Note", "Status",
    "Julia", "REPL", "Pkg", "Namesof", "Names", "OptimalControl",
    "CTDirect", "CTSolvers", "CTParser", "SolverFailure", "Base",
])

function _clean_token(tok)
    tok = strip(tok, [';', ',', '.', '(', ')'])
    isempty(tok) && return nothing
    any(c -> c in ('/', ';', '.', '=', '(', ')', '{', '}', '[', ']', '<', '>', '-', ' '), tok) && return nothing
    any(c -> c in '0':'9', tok) && return nothing
    tok in NON_SYMBOLS && return nothing
    return Symbol(tok)
end

function _extract_themes(path)
    lines = readlines(path)
    section_theme = nothing
    themes = Dict{String, Vector{Symbol}}()
    push_sym(t, s) = push!(get!(themes, t, Symbol[]), s)

    section_map = Dict(
        1 => "qualified", 2 => "macros", 3 => "modelling", 4 => "problem",
        5 => "solving", 6 => "solution", 7 => "options", 8 => "flows",
        9 => "geometry", 10 => "types", 11 => "io", 12 => "qualified", 13 => "qualified",
    )

    for line in lines
        if startswith(line, "## ")
            m = match(r"^## ([0-9]+)[.] (.*)", line)
            if !isnothing(m)
                section_theme = get(section_map, parse(Int, m.captures[1]), nothing)
                continue
            end
        end

        if startswith(strip(line), "|")
            cells = split(line, '|')
            cells = [strip(c) for c in cells if !all(isspace, c)]
            length(cells) < 2 && continue
            any(c -> c == "Symbol" || c == "---" || startswith(c, "--") ||
                     c in ("Why it is exported", "Why", "Guide", "API theme", "Note",
                           "Where it belongs", "Status", "Used on"),
                cells) && continue

            firstcell = cells[1]
            theme = section_theme
            for c in Iterators.reverse(cells)
                c in ("modelling", "problem", "solving", "options", "solution",
                      "flows", "geometry", "types", "io", "qualified") || continue
                theme = c
                break
            end

            parts = split(firstcell, '`')
            for i in 2:2:length(parts)
                tok = _clean_token(parts[i])
                if !isnothing(tok) && !isnothing(theme)
                    push_sym(theme, tok)
                end
            end
            continue
        end

        if !isnothing(section_theme)
            parts = split(line, '`')
            for i in 2:2:length(parts)
                tok = _clean_token(parts[i])
                if section_theme == "macros"
                    if tok in (:def, :init)
                        push_sym("modelling", Symbol("@" * String(tok)))
                    elseif tok == :Lie
                        push_sym("geometry", Symbol("@" * String(tok)))
                    end
                elseif !isnothing(tok)
                    push_sym(section_theme, tok)
                end
            end
        end
    end

    for (k, v) in themes
        themes[k] = sort(unique(v))
    end
    return themes
end

const _THEMES_DICT = let
    path = joinpath(@__DIR__, "reports", "99-api-coverage.md")
    themes = _extract_themes(path)

    themes["problem"] = setdiff(get(themes, "problem", Symbol[]), [:objective, :variable])

    for (k, v) in themes
        themes[k] = sort(filter(s -> isdefined(OptimalControl, s), v))
    end

    exported = setdiff(names(OptimalControl), (:OptimalControl,))
    covered = Set{Symbol}()
    for syms in values(themes)
        union!(covered, syms)
    end
    qualified_set = Set(get(themes, "qualified", Symbol[]))

    missing_syms = setdiff(exported, covered)
    stale_syms = setdiff(covered, union(exported, qualified_set))

    if !isempty(missing_syms)
        error("API reference is missing exported symbols: $missing_syms")
    end
    if !isempty(stale_syms)
        error("API reference contains stale symbols: $stale_syms")
    end
    themes
end

const API_THEMES = [
    (id="modelling", title="Modelling", symbols=_THEMES_DICT["modelling"]),
    (id="problem", title="Problem", symbols=_THEMES_DICT["problem"]),
    (id="solving", title="Solving", symbols=_THEMES_DICT["solving"]),
    (id="options", title="Options and strategies", symbols=_THEMES_DICT["options"]),
    (id="solution", title="Solution", symbols=_THEMES_DICT["solution"]),
    (id="flows", title="Flows", symbols=_THEMES_DICT["flows"]),
    (id="geometry", title="Geometry", symbols=_THEMES_DICT["geometry"]),
    (id="types", title="Types", symbols=_THEMES_DICT["types"]),
    (id="io", title="Plotting and I/O", symbols=_THEMES_DICT["io"]),
    (id="qualified", title="Qualified access", symbols=_THEMES_DICT["qualified"]),
]

function _generate_theme_page(docs_src, theme)
    page = joinpath(docs_src, "api", "$(theme.id).md")
    mkpath(dirname(page))
    open(page, "w") do io
        println(io, "# [$(theme.title)](@id api-$(theme.id))")
        println(io)
        if theme.id == "qualified"
            println(io, "These names are not exported by `using OptimalControl`, but they are reachable as `OptimalControl.X`.")
            println(io)
        end
        println(io, "```@docs; canonical=true")
        for s in theme.symbols
            println(io, s)
        end
        println(io, "```")
    end
    return theme.title => "api/$(theme.id).md"
end

function generate_api_reference(src_dir::String, ext_dir::String)
    docs_src = abspath(joinpath(@__DIR__, "src"))
    src(files...) = [abspath(joinpath(src_dir, f)) for f in files]
    mkpath(joinpath(docs_src, "api"))

    pages = [_generate_theme_page(docs_src, t) for t in API_THEMES]

    helpers = src(
        joinpath("helpers", "component_checks.jl"),
        joinpath("helpers", "component_completion.jl"),
        joinpath("helpers", "descriptive_routing.jl"),
        joinpath("helpers", "describe.jl"),
        joinpath("helpers", "kwarg_extraction.jl"),
        joinpath("helpers", "methods.jl"),
        joinpath("helpers", "print.jl"),
        joinpath("helpers", "registry.jl"),
        joinpath("helpers", "strategy_builders.jl"),
        joinpath("solve", "canonical.jl"),
        joinpath("solve", "descriptive.jl"),
        joinpath("solve", "dispatch.jl"),
        joinpath("solve", "explicit.jl"),
        joinpath("solve", "mode.jl"),
        joinpath("solve", "mode_detection.jl"),
    )

    internals = CTBase.automatic_reference_documentation(;
        subdirectory="api",
        primary_modules=[OptimalControl => helpers],
        external_modules_to_document=[CTBase, CTModels, CTSolvers],
        exclude=EXCLUDE_SYMBOLS,
        public=false,
        private=true,
        title="Internals",
        title_in_menu="Internals",
        filename="internals",
    )
    push!(pages, internals)

    return pages
end

function with_api_reference(f::Function, src_dir::String, ext_dir::String)
    pages = generate_api_reference(src_dir, ext_dir)
    try
        f(pages)
    finally
        docs_src = abspath(joinpath(@__DIR__, "src"))
        _cleanup_pages(docs_src, pages)
    end
end

function _cleanup_pages(docs_src::String, pages)
    for p in pages
        val = last(p)
        if val isa AbstractString
            fname = endswith(val, ".md") ? val : val * ".md"
            full_path = joinpath(docs_src, fname)
            if isfile(full_path)
                rm(full_path)
                println("Removed temporary API doc: $full_path")
            end
        elseif val isa AbstractVector
            _cleanup_pages(docs_src, val)
        end
    end
end
