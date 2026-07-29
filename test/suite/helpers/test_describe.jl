# ============================================================================
# `describe` over the full strategy surface
# ============================================================================
# `describe(:id)` must work for every strategy OptimalControl exposes, on both
# sides of the library: the direct path (discretizer, NLP modeler, NLP solver)
# and the indirect one (AD backend `:di`, ODE integrator `:sciml`). The
# integrator and the AD backend are strategies in the control-toolbox sense
# like any other — the point of this file is that the user does not have to
# know which registry a token lives in.
#
# Two registries back that: OptimalControl's own solve registry and
# `CTFlows.Flows.flow_registry()`. `get_full_strategy_registry()` merges them.
#
# ⚠️ Merging, not `try`/`catch`. A fallback that tries one registry and catches
# its failure would swallow the genuine "unknown strategy" error and report
# whatever the second registry raised instead. The merge keeps one registry,
# one error path.
#
# ⚠️ `:sciml` is expected to FAIL today, and the `@test_broken` below is not a
# workaround — it is the tracker. `CTBase.Strategies._strategy_base_name`
# unwraps exactly one `UnionAll` layer, which only works for strategies with at
# most two type parameters; `CTSolvers.Integrators.SciML` has four. See
# control-toolbox/CTBase.jl#516 (root cause, one-line fix) and
# control-toolbox/CTSolvers.jl#191 (the missing upstream coverage that let it
# through). When CTBase ships the fix, these flip to *unexpected passes* and
# fail the suite — which is the reminder to promote them to `@test`.

module TestDescribe

using Test: Test
using OptimalControl
using CTBase: CTBase
using CTSolvers: CTSolvers
using CTFlows: CTFlows

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

const S = CTBase.Strategies

# Strategies whose `describe` works today, by family.
const WORKING = (
    :collocation,                                   # discretizer
    :adnlp, :exa,                                   # NLP modelers
    :ipopt, :madnlp, :madncl, :uno, :knitro,        # NLP solvers
    :di,                                            # AD backend
)

# Blocked on CTBase#516 — see the header.
const BROKEN = (:sciml,)

"""
    describes(id) -> Bool

`true` when `describe(id)` runs to completion. Output goes to `devnull`: this
file is about reachability and the absence of a throw, not about formatting.
"""
function describes(id::Symbol)
    S.describe(devnull, id, OptimalControl.get_full_strategy_registry())
    return true
end

"""
    ids(registry) -> Set{Symbol}

Every strategy id registered in `registry`, across all families.
"""
ids(r) = Set(S.id(T) for ts in values(r.families) for T in ts)

function test_describe()
    Test.@testset "describe over all strategies" verbose = VERBOSE showtiming = SHOWTIMING begin

        # ====================================================================
        # The merge is well posed
        # ====================================================================

        Test.@testset "the two registries are disjoint" begin
            # `get_full_strategy_registry` merges two dictionaries, which is
            # only sound while the inputs do not collide. That is an ecosystem
            # property, not a guarantee — so it is asserted, not assumed. This
            # is the test that fires if upstream ever registers a duplicate id,
            # long before a user sees `describe` resolve to the wrong strategy.
            solve_reg = OptimalControl.get_strategy_registry()
            flow_reg = CTFlows.Flows.flow_registry()

            Test.@test isempty(intersect(ids(solve_reg), ids(flow_reg)))
            Test.@test isempty(
                intersect(keys(solve_reg.families), keys(flow_reg.families))
            )

            # `:cpu`/`:gpu` exist on both sides; they must be the same types,
            # or the merge would silently pick one binding over the other.
            for (k, v) in flow_reg.parameters
                if haskey(solve_reg.parameters, k)
                    Test.@test solve_reg.parameters[k] === v
                end
            end
        end

        Test.@testset "the union is the sum of its parts" begin
            solve_reg = OptimalControl.get_strategy_registry()
            flow_reg = CTFlows.Flows.flow_registry()
            full = OptimalControl.get_full_strategy_registry()

            Test.@test length(full.families) ==
                length(solve_reg.families) + length(flow_reg.families)
            Test.@test ids(full) == union(ids(solve_reg), ids(flow_reg))
            # Nothing from either side is lost.
            Test.@test issubset(ids(solve_reg), ids(full))
            Test.@test issubset(ids(flow_reg), ids(full))
        end

        # ====================================================================
        # Every registered strategy is reachable — no id left behind
        # ====================================================================

        Test.@testset "the working/broken split covers the registry" begin
            # Guards the lists above against drift: a strategy registered
            # upstream tomorrow must be classified here rather than silently
            # escape both lists and go untested.
            registered = ids(OptimalControl.get_full_strategy_registry())
            Test.@test registered == Set([WORKING..., BROKEN...])
        end

        # ====================================================================
        # Direct path
        # ====================================================================

        Test.@testset "discretizer" begin
            Test.@test describes(:collocation)
        end

        Test.@testset "NLP modelers" begin
            for id in (:adnlp, :exa)
                Test.@testset "$id" begin
                    Test.@test describes(id)
                end
            end
        end

        Test.@testset "NLP solvers" begin
            for id in (:ipopt, :madnlp, :madncl, :uno, :knitro)
                Test.@testset "$id" begin
                    Test.@test describes(id)
                end
            end
        end

        # ====================================================================
        # Indirect path — the whole reason for the merge
        # ====================================================================

        Test.@testset "AD backend" begin
            # `:di` reaches `describe` only through the merged registry; the
            # solve registry alone does not know the token.
            Test.@test describes(:di)
            Test.@test_throws CTBase.Exceptions.CTException S.describe(
                devnull, :di, OptimalControl.get_strategy_registry()
            )
        end

        Test.@testset "ODE integrator" begin
            # See the header: blocked on CTBase#516, and deliberately recorded
            # as broken rather than skipped, so the fix landing is visible.
            Test.@test_broken describes(:sciml)

            # What *does* work is the routing that put it in the registry —
            # the token resolves and carries both parameters. This is the part
            # CTBase#516 does not affect, and it is worth pinning separately so
            # a regression here is not masked by the known-broken assertion.
            full = OptimalControl.get_full_strategy_registry()
            params = S.available_parameters(
                :sciml, CTSolvers.Integrators.AbstractIntegrator, full
            )
            Test.@test S.CPU in params
            Test.@test S.GPU in params
        end

        # ====================================================================
        # Parameters, and the failure mode
        # ====================================================================

        Test.@testset "strategy parameters" begin
            # `describe(:cpu)` walks every registered strategy to report which
            # ones support the parameter — so it inherits :sciml's breakage.
            # That contagion is the real cost of CTBase#516 and deserves to be
            # stated, not left implicit.
            Test.@test_broken describes(:cpu)
            Test.@test_broken describes(:gpu)

            # …and it is genuinely the merge that exposes it: on the solve
            # registry alone, which has no strategy above two type parameters,
            # the same call is fine.
            solve_only = OptimalControl.get_strategy_registry()
            Test.@test (S.describe(devnull, :cpu, solve_only); true)
        end

        Test.@testset "an unknown id is rejected" begin
            # The merge must not turn a typo into something that resolves.
            Test.@test_throws CTBase.Exceptions.CTException describes(:nope)
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_describe() = TestDescribe.test_describe()
