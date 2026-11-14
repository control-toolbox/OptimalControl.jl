# ============================================================================
# No `import`, no dotted `using` (MOD3, MOD4)
# ============================================================================
# Regression guard for the ct-conventions rules "using, never import" (`MOD3`) and
# "qualified external imports" (`MOD4`): flags any tracked `.jl` or `.md` file that
# uses the `import` keyword, or the dotted form `using Pkg.Sub` (write `using Pkg: Sub`).
# Each violation is reported with its file, line and text (#831).

module TestNoImport

using Test: Test

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const IMPORT_RE = r"^\s*import\b"
const DOTTED_USING_RE = r"^\s*using\s+[A-Za-z_]\w*\.[A-Za-z_]"

# `src/imports/` builds the API of OptimalControl: `@reexport import Pkg: sym` for the
# exported names and `import Pkg.Sub: sym` for the names reached as `OptimalControl.X`.
# This is the one place `import` is intentional in the ecosystem (see AGENTS.md).
const IMPORT_EXEMPT_DIRS = ("src/imports/",)

# Forbidden lines of a source text, as `(line number, kind, text)`.
function _violations(text::AbstractString; check_import::Bool=true)
    found = Tuple{Int,String,String}[]
    for (n, line) in enumerate(split(text, '\n'))
        if check_import && occursin(IMPORT_RE, line)
            push!(found, (n, "`import`", strip(line)))
        end
        if occursin(DOTTED_USING_RE, line)
            push!(found, (n, "dotted `using`", strip(line)))
        end
    end
    return found
end

function _report(violations)
    println(stderr, "Found forbidden import syntax (MOD3, MOD4):")
    for v in violations
        println(stderr, "  ", v)
    end
    return false
end

function test_no_import()
    Test.@testset "No `import`, no dotted `using` (MOD3, MOD4)" verbose = VERBOSE showtiming =
        SHOWTIMING begin
        Test.@testset "the patterns" begin
            Test.@test length(_violations("import Pkg")) == 1
            Test.@test length(_violations("    import Pkg: f")) == 1
            Test.@test length(_violations("using Pkg.Sub")) == 1
            Test.@test length(_violations("using Pkg.Sub: f")) == 1
            Test.@test isempty(_violations("using Pkg: Pkg"))
            Test.@test isempty(_violations("using Pkg: Sub"))
            Test.@test isempty(_violations("using .TestProblems: TestProblems"))
            Test.@test isempty(_violations("using ..Sibling: f"))
            Test.@test isempty(_violations("# import is fine in a comment"))
            Test.@test isempty(_violations("import Pkg: f"; check_import=false))
        end

        Test.@testset "tracked files" begin
            repo_root = normpath(joinpath(@__DIR__, "..", "..", ".."))
            tracked = filter(
                f -> endswith(f, ".jl") || endswith(f, ".md"),
                readlines(Cmd(`git ls-files`; dir=repo_root)),
            )
            Test.@test !isempty(tracked)
            violations = String[]
            for relpath in tracked
                check_import = !any(startswith(relpath, d) for d in IMPORT_EXEMPT_DIRS)
                text = read(joinpath(repo_root, relpath), String)
                for (n, kind, line) in _violations(text; check_import=check_import)
                    push!(violations, "$relpath:$n: $kind: $line")
                end
            end
            Test.@test isempty(violations) || _report(violations)
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_no_import() = TestNoImport.test_no_import()
