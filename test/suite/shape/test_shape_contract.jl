# ============================================================================
# The 1-D = scalar contract, at OptimalControl's boundary
# ============================================================================
# A one-dimensional state, control or variable reaches the user's functions as
# a **scalar**, not as a length-1 vector; anything higher stays a vector.
#
# ⚠️ Deliberately *not* a copy of the upstream test. `CTDirect.jl` already owns
# the exhaustive version (`test/ci/test_shape_contract.jl`): every
# discretisation scheme, mixed dimensions, dimension zero, and the
# `_dim_coerce` primitive itself, driven through `__objective` /
# `__constraints!` directly. Re-testing that here would be redundancy that
# rots.
#
# What is *not* covered upstream, and is genuinely ours:
#
#   1. the contract surviving the whole OptimalControl `solve` stack, rather
#      than a hand-built DOCP;
#   2. the contract on the **indirect** path — CTFlows has no assertion for it,
#      only defensive guards of the form `u(t) isa Number ? u(t) : u(t)[1]`,
#      which tolerate either shape rather than pin one;
#   3. the two paths **agreeing**. A 1-D problem must look the same whichever
#      way it is solved, and nothing upstream can check that: it is precisely
#      the seam between CTDirect and CTFlows that OptimalControl owns.
#
# The recording fakes live at module top level, per the Handbook recipe: a
# closure would be recompiled per call site and the recorded types would say
# more about the closure than about the coercion.

module TestShapeContract

using Test: Test
using OptimalControl
using CTModels: CTModels
using NLPModelsIpopt: NLPModelsIpopt
import OrdinaryDiffEqTsit5: OrdinaryDiffEqTsit5 # `Flow` needs an integrator

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# What the user functions last saw. `Dict` rather than separate `Ref`s so a
# single drive can record several call boundaries.
const SEEN = Dict{Symbol,Any}()

# Written with `[1]`-indexing so the fakes are valid whether the caller hands a
# Number or a length-1 vector — only the *assertions* below distinguish the
# two. Writing them scalar-style would beg the question.
rec_dyn!(r, t, x, u, v) = (
    SEEN[:dyn] = (x, u, v);
    for i in eachindex(r)
        r[i] = -x[i] + u[min(i, length(u))]
    end;
    nothing
)

rec_lagrange(t, x, u, v) = (SEEN[:lag] = (x, u, v); sum(abs2, u))

rec_boundary!(r, x0, xf, v) = (
    SEEN[:bnd] = (x0, xf, v);
    for i in eachindex(r)
        r[i] = x0[i] - 1.0
    end;
    nothing
)

"""
    build_recording(n, m)

An OCP of declared dimensions `n` (state) and `m` (control) whose user
functions record the shapes they are handed.
"""
function build_recording(n::Int, m::Int)
    pre = CTModels.PreModel()
    CTModels.Building.variable!(pre, 0)
    CTModels.Building.time!(pre; t0=0.0, tf=1.0)
    CTModels.Building.state!(pre, n)
    CTModels.Building.control!(pre, m)
    CTModels.Building.dynamics!(pre, rec_dyn!)
    CTModels.Building.objective!(pre, :min; lagrange=rec_lagrange)
    CTModels.Building.constraint!(
        pre, :boundary; f=rec_boundary!, lb=zeros(n), ub=zeros(n), label=:rec_x0
    )
    CTModels.Building.time_dependence!(pre; autonomous=true)
    return CTModels.Building.build(pre)
end

function test_shape_contract()
    Test.@testset "Shape contract: 1-D = scalar" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # Through the direct path — the full `solve` stack
        # ====================================================================

        Test.@testset "direct path" begin
            Test.@testset "n=1, m=1 → scalars" begin
                empty!(SEEN)
                ocp = build_recording(1, 1)
                sol = solve(ocp, :collocation, :adnlp, :ipopt; display=false, grid_size=10)

                x, u, _ = SEEN[:dyn]
                # A `ForwardDiff.Dual` is still a `Number` — that is the point
                # of asserting the abstract type rather than `Float64`.
                Test.@test x isa Number
                Test.@test u isa Number

                # …and the solution side honours it too.
                Test.@test state(sol)(0.5) isa Number
                Test.@test control(sol)(0.5) isa Number
            end

            Test.@testset "n=2, m=2 → vectors" begin
                empty!(SEEN)
                ocp = build_recording(2, 2)
                sol = solve(ocp, :collocation, :adnlp, :ipopt; display=false, grid_size=10)

                x, u, _ = SEEN[:dyn]
                Test.@test x isa AbstractVector && length(x) == 2
                Test.@test u isa AbstractVector && length(u) == 2

                Test.@test state(sol)(0.5) isa AbstractVector
                Test.@test control(sol)(0.5) isa AbstractVector
            end

            Test.@testset "n=2, m=1 → coerced independently" begin
                # The two dimensions are not coupled: a vector state next to a
                # scalar control is the common case and the easiest to break.
                empty!(SEEN)
                ocp = build_recording(2, 1)
                sol = solve(ocp, :collocation, :adnlp, :ipopt; display=false, grid_size=10)

                x, u, _ = SEEN[:dyn]
                Test.@test x isa AbstractVector && length(x) == 2
                Test.@test u isa Number

                Test.@test state(sol)(0.5) isa AbstractVector
                Test.@test control(sol)(0.5) isa Number
            end
        end

        # ====================================================================
        # Through the indirect path — `Flow`
        # ====================================================================

        Test.@testset "indirect path" begin
            Test.@testset "n=1 → scalar state and costate" begin
                empty!(SEEN)
                ocp = build_recording(1, 1)
                f = Flow(ocp, (x, p) -> p)

                xf, pf = f(0.0, 1.0, 1.0, 1.0)
                Test.@test xf isa Number
                Test.@test pf isa Number

                # The dynamics saw a scalar state on this path too.
                Test.@test SEEN[:dyn][1] isa Number

                # …and so does the trajectory form.
                traj = f((0.0, 1.0), 1.0, 1.0)
                Test.@test state(traj)(0.5) isa Number
                Test.@test costate(traj)(0.5) isa Number
            end

            Test.@testset "n=2 → vector state and costate" begin
                empty!(SEEN)
                ocp = build_recording(2, 1)
                f = Flow(ocp, (x, p) -> p[1])

                xf, pf = f(0.0, [1.0, 1.0], [1.0, 1.0], 1.0)
                Test.@test xf isa AbstractVector && length(xf) == 2
                Test.@test pf isa AbstractVector && length(pf) == 2

                Test.@test SEEN[:dyn][1] isa AbstractVector

                traj = f((0.0, 1.0), [1.0, 1.0], [1.0, 1.0])
                Test.@test state(traj)(0.5) isa AbstractVector
            end
        end

        # ====================================================================
        # The two paths agree — the seam nothing upstream can check
        # ====================================================================

        Test.@testset "both paths present the same shape" begin
            for (n, m) in ((1, 1), (2, 1), (2, 2))
                Test.@testset "n=$n, m=$m" begin
                    ocp = build_recording(n, m)

                    empty!(SEEN)
                    solve(ocp, :collocation, :adnlp, :ipopt; display=false, grid_size=10)
                    direct_x = SEEN[:dyn][1]

                    empty!(SEEN)
                    law = m == 1 ? ((x, p) -> p[1]) : ((x, p) -> p[1:m])
                    x0 = n == 1 ? 1.0 : ones(n)
                    p0 = n == 1 ? 1.0 : ones(n)
                    Flow(ocp, law)(0.0, x0, p0, 1.0)
                    indirect_x = SEEN[:dyn][1]

                    # Not the same values — the same *shape*. That is the
                    # contract: a user function written once must be callable
                    # from either path without a defensive `isa Number` guard.
                    Test.@test (direct_x isa Number) == (indirect_x isa Number)
                    Test.@test (direct_x isa AbstractVector) ==
                        (indirect_x isa AbstractVector)
                end
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_shape_contract() = TestShapeContract.test_shape_contract()
