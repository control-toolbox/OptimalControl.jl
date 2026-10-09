# Page: getting-started/installation.md, tip "Other integrators"
# Claims: the package is OrdinaryDiffEqVerner (there is no OrdinaryDiffEqVern9), and another
# integrator works with `alg=` as long as OrdinaryDiffEqTsit5 is loaded too.
# Known upstream bug (CTSolvers.jl#230): without OrdinaryDiffEqTsit5, `alg=Vern9()` fails.
# This probe checks the current behaviour, so it fails once the bug is fixed: then relax the
# tip ("keep OrdinaryDiffEqTsit5 loaded in every case") and this probe.

include("common.jl")
temp_env("OrdinaryDiffEqVerner", "OrdinaryDiffEqTsit5")
using OptimalControl
using OrdinaryDiffEqVerner

ocp = eval(ENERGY_DEF)
law(x, p) = p[2]

msg = error_text(() -> Flow(ocp, law; alg=Vern9()))
check(occursin("IncorrectArgument", msg),
    "known bug CTSolvers.jl#230: without Tsit5, Flow(ocp, law; alg=Vern9()) fails (update the docs when this fails)")

using OrdinaryDiffEqTsit5

φ = Flow(ocp, law; alg=Vern9())
xf, pf = φ(0, [-1, 0], [12, 6], 1)
check(isapprox(xf, [0, 0]; atol=1e-10) && isapprox(pf, [12, -6]; atol=1e-10),
    "with Tsit5 also loaded, alg=Vern9() works and reaches x(1) = (0, 0)")
