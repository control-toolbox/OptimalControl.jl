# Shared helpers for the documentation probes. Each probe `include`s this file first.
#
# A probe checks a claim of the documentation that the docs build cannot execute (see
# README.md). It throws on failure; `run.jl` runs every probe in a fresh Julia process.

# Same load path as docs/make.jl: the docs environment first (its Manifest decides every
# version), then this repository for OptimalControl itself.
const REPO_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
pushfirst!(LOAD_PATH, REPO_ROOT)
pushfirst!(LOAD_PATH, joinpath(REPO_ROOT, "docs"))

"""
    error_text(f) -> String

Call `f()` and return the text of the exception it throws, without colours. Throw if `f()`
does not throw.
"""
function error_text(f)
    try
        f()
    catch e
        return sprint(showerror, e)
    end
    error("expected an exception, got none")
end

"""
    check(cond, claim)

Throw with the documented `claim` when `cond` is false; print it when true.
"""
function check(cond::Bool, claim::AbstractString)
    cond || error("claim does not hold: " * claim)
    println("  ✓ ", claim)
    return nothing
end

"""
    temp_env(pkgs...)

Activate a temporary environment holding `pkgs`, for claims about packages the docs
environment does not have. The docs environment stays first in the load path. The first call downloads
and precompiles them.
"""
function temp_env(pkgs::AbstractString...)
    Pkg = Base.require(Base.PkgId(Base.UUID("44cfe95a-1eb2-52ea-b672-e2afdf69b78f"), "Pkg"))
    # Pkg is loaded just above, in a newer world: call it through invokelatest.
    Base.invokelatest(Pkg.activate; temp=true, io=devnull)
    Base.invokelatest(Pkg.add, collect(pkgs); io=devnull)
    return nothing
end

# A small problem used by several probes: the energy-minimal double integrator.
const ENERGY_DEF = quote
    @def begin
        t ∈ [0, 1], time
        x = (q, v) ∈ R², state
        u ∈ R, control
        x(0) == [-1, 0]
        x(1) == [0, 0]
        ẋ(t) == [v(t), u(t)]
        0.5∫(u(t)^2) → min
    end
end
