# ============================================================================
# Goddard Indirect Method Tests
# ============================================================================
# Indirect shooting for the Goddard rocket, B+ S C B0 structure.
#
# ⚠️ Three v2.1.0-beta breaks are exercised here at once:
#
#  1. `Lie(X, f)` → `ad(X, f)`; `Lift`, `@Lie` now come from CTLie.
#  2. Constrained flows take *paired keywords*: `Flow(ocp, u; constraint=g,
#     multiplier=μ)`. The old three-positional form is a `MethodError`, and
#     one keyword without the other is a `PreconditionError`.
#  3. `variable=` is mandatory on a `NonFixed` flow — Goddard declares
#     `tf ∈ R, variable`, so every call site needs `variable=tf`. Omitting it
#     raises a `PreconditionError`, it does not silently default.
#
# `Flow` also needs an integrator loaded now (Q7): that is what the
# `OrdinaryDiffEqTsit5` import below is for.

module TestGoddardIndirect

using Test: Test
using OptimalControl: OptimalControl
import LinearAlgebra: norm
import OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator

# ⚠️ `@Lie` expands to bare `CTLie.*` and `CTBase.Traits.*` prefixes, so both
# modules must be in scope *at the call site*.
#
# OptimalControl does re-export them (`src/imports/ctlie.jl`,
# `src/imports/ctbase.jl`), so plain `using OptimalControl` would suffice — but
# this file imports qualified (`using OptimalControl: OptimalControl`), which
# brings in the single name `OptimalControl` and nothing else. Hence the two
# explicit imports below. This is the same reason the file used to carry
# `import CTFlows: CTFlows`, back when the macro lived in CTFlows.
import CTLie: CTLie
import CTBase: CTBase

# Include shared test problems via TestProblems module
include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# ============================================================================
# TOP-LEVEL: Problem parameters
# ============================================================================

const Cd = 310
const Tmax = 3.5
const β = 500
const b = 2
const t0 = 0
const r0 = 1
const v0 = 0
const vmax = 0.1
const m0 = 1
const mf = 0.6
const x0 = [r0, v0, m0]

function test_goddard()
    Test.@testset "Goddard Indirect Method" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # INTEGRATION TEST - Indirect Shooting Method
        # ====================================================================

        Test.@testset "Shooting with B+ S C B0 structure" begin
            # Get problem from TestProblems
            prob_data = TestProblems.Goddard()
            ocp = prob_data.ocp
            F0 = prob_data.data.F0
            F1 = prob_data.data.F1

            # Constraint function
            g(x) = vmax - x[2]
            final_mass_cons(xf) = xf[3] - mf

            # Bang controls
            u0 = 0
            u1 = 1

            # Singular control
            H0 = OptimalControl.Lift(F0)
            H1 = OptimalControl.Lift(F1)
            H01 = OptimalControl.@Lie {H0, H1}
            H001 = OptimalControl.@Lie {H0, H01}
            H101 = OptimalControl.@Lie {H1, H01}
            us(x, p) = -H001(x, p) / H101(x, p)

            # Boundary control — `Lie(X, f)` is `ad(X, f)` since v2.1.0-beta.
            # The `⋅` spelling was dropped with no replacement.
            ub(x) = -OptimalControl.ad(F0, g)(x) / OptimalControl.ad(F1, g)(x)
            μ(x, p) = H01(x, p) / OptimalControl.ad(F1, g)(x)

            # Flows — note the keyword pair on the constrained one.
            f0 = OptimalControl.Flow(ocp, (x, p, v) -> u0)
            f1 = OptimalControl.Flow(ocp, (x, p, v) -> u1)
            fs = OptimalControl.Flow(ocp, (x, p, v) -> us(x, p))
            fb = OptimalControl.Flow(
                ocp,
                (x, p, v) -> ub(x);
                constraint=(x, u, v) -> g(x),
                multiplier=(x, p, v) -> μ(x, p),
            )

            # Shooting function — `variable=tf` on every call, the OCP is NonFixed.
            function shoot!(s, p0, t1, t2, t3, tf)
                x1, p1 = f1(t0, x0, p0, t1; variable=tf)
                x2, p2 = fs(t1, x1, p1, t2; variable=tf)
                x3, p3 = fb(t2, x2, p2, t3; variable=tf)
                xf, pf = f0(t3, x3, p3, tf; variable=tf)
                s[1] = final_mass_cons(xf)
                s[2:3] = pf[1:2] - [1, 0]
                s[4] = H1(x1, p1)
                s[5] = H01(x1, p1)
                s[6] = g(x2)
                return s[7] = H0(xf, pf)
            end

            # Known solution — carried by the problem, not restated here.
            # `TestProblem` rejects an `:indirect` fixture with no `p0`, so
            # these cannot silently drift apart from the model.
            p0 = prob_data.data.p0
            t1, t2, t3 = prob_data.data.switching_times
            tf = prob_data.data.tf_ref

            # Test shooting function with known solution
            s = zeros(eltype(p0), 7)
            shoot!(s, p0, t1, t2, t3, tf)

            # Verify solution
            Test.@test norm(s) < 1e-6

            # ------------------------------------------------------------
            # Guard rails on the new calling convention
            # ------------------------------------------------------------

            Test.@testset "variable is mandatory on NonFixed" begin
                Test.@test_throws OptimalControl.PreconditionError f1(t0, x0, p0, t1)
            end

            Test.@testset "constraint and multiplier are a pair" begin
                # `IncorrectArgument`, not `PreconditionError` — the migration
                # report had this one wrong.
                Test.@test_throws OptimalControl.IncorrectArgument OptimalControl.Flow(
                    ocp, (x, p, v) -> ub(x); constraint=(x, u, v) -> g(x)
                )
                Test.@test_throws OptimalControl.IncorrectArgument OptimalControl.Flow(
                    ocp, (x, p, v) -> ub(x); multiplier=(x, p, v) -> μ(x, p)
                )
            end

            Test.@testset "Lift from a Function is not a Hamiltonian" begin
                # Semantic break: `HamiltonianLift` became
                # `CTLie.LiftedHamiltonianFunction`, which is `<: Function`
                # and no longer `<: AbstractHamiltonian`. `F0` is a plain
                # function here, so this is the `Lift(::Function)` overload.
                Test.@test H0 isa OptimalControl.LiftedHamiltonianFunction
                Test.@test !(H0 isa OptimalControl.AbstractHamiltonian)
                # …whereas the Poisson bracket of two of them is one.
                Test.@test H01 isa OptimalControl.AbstractHamiltonian
            end
        end
    end
end

end # module

# CRITICAL: Redefine in outer scope for TestRunner
test_goddard() = TestGoddardIndirect.test_goddard()
