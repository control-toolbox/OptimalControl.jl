using Pkg
Pkg.activate(".")

# We want to see if AbstractOptimalControlProblem is defined BEFORE ctmodels.jl:4
# So we can't just use OptimalControl because it errors.

# Let's manually include things up to ctmodels.jl
include("src/imports/ctbase.jl")
include("src/imports/ctparser.jl")
include("src/imports/plots.jl")

println("Defined before ctmodels: ", isdefined(Main, :AbstractOptimalControlProblem))
if isdefined(Main, :AbstractOptimalControlProblem)
    println("Parent: ", parentmodule(Main.AbstractOptimalControlProblem))
end
