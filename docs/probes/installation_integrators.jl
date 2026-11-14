# Page: getting-started/installation.md, tip "Other integrators"
# Claims: the package is OrdinaryDiffEqVerner (there is no OrdinaryDiffEqVern9); another
# integrator works with `alg=` without OrdinaryDiffEqTsit5 (CTSolvers.jl#230, fixed in
# CTSolvers 0.5.8); without Tsit5 and without `alg`, the error says how to choose one.

include("common.jl")
temp_env("OrdinaryDiffEqVerner")
using OptimalControl
using OrdinaryDiffEqVerner

ocp = eval(ENERGY_DEF)
law(x, p) = p[2]

check(!isdefined(Main, :Tsit5), "OrdinaryDiffEqTsit5 is not loaded")

φ = Flow(ocp, law; alg=Vern9())
xf, pf = φ(0, [-1, 0], [12, 6], 1)
check(
    isapprox(xf, [0, 0]; atol=1e-10) && isapprox(pf, [12, -6]; atol=1e-10),
    "without Tsit5, Flow(ocp, law; alg=Vern9()) works and reaches x(1) = (0, 0)",
)

msg = error_text(() -> Flow(ocp, law))
check(
    occursin("PreconditionError", msg) && occursin("Flow(ocp, law; alg=Vern6())", msg),
    "without Tsit5 and without alg, a PreconditionError shows how to pass alg",
)
