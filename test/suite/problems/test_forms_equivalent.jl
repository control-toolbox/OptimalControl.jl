# ============================================================================
# Front-end equivalence
# ============================================================================
# Every problem in the library is built two ways:
#
#   `:abstract`   — the `@def` DSL, which parses a definition into a model
#   `:functional` — the `CTModels.Building` API, called directly
#
# The two front ends are the boundary OptimalControl owns: `@def` is sugar over
# `Building`, and if the sugar and the API drift apart, one of them is lying.
# This file is what holds them together — one body, run over every problem.
#
# What is deliberately *not* asserted: the abstract form carries a
# `definition` (the parsed expression) and the functional form does not. That
# is a real, intended difference, so it is asserted as a difference rather than
# quietly skipped.

module TestFormsEquivalent

using Test: Test
using OptimalControl

include(joinpath(@__DIR__, "..", "..", "problems", "TestProblems.jl"))
using .TestProblems

const VERBOSE = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

"""
    sample_point(pb)

A `(t, x, u, v)` inside the problem's domain, to evaluate dynamics and cost at.

Derived from the problem's own `data` where it says something (`x0`), rather
than hard-coded per problem: a constant per problem is one more thing to keep
in sync, and picking blind risks a division by zero on models like Goddard
(`1/r²`) or the transfer (`√(P/μ)`).
"""
function sample_point(pb)
    ocp = pb.ocp
    n = state_dimension(ocp)
    m = control_dimension(ocp)
    q = variable_dimension(ocp)

    x = haskey(pb.data, :x0) ? collect(float.(pb.data.x0)) : fill(0.5, n)
    u = fill(0.3, m)
    v = q == 0 ? Float64[] : fill(0.5, q)
    t = 0.3

    return (t, x, u, v)
end

"""
    dyn_at(ocp, t, x, u, v)

Evaluate the (in-place) dynamics out of place, so two models can be compared.
"""
function dyn_at(ocp, t, x, u, v)
    r = zeros(state_dimension(ocp))
    dynamics(ocp)(r, t, x, u, v)
    return r
end

function test_forms_equivalent()
    Test.@testset "Front-end equivalence" verbose = VERBOSE showtiming = SHOWTIMING begin
        for name in TestProblems.PROBLEMS
            Test.@testset "$name" begin
                a = TestProblems.build(name, :abstract)
                f = TestProblems.build(name, :functional)

                Test.@testset "shape" begin
                    for acc in (state_dimension, control_dimension, variable_dimension)
                        Test.@test acc(a.ocp) == acc(f.ocp)
                    end
                    Test.@test is_autonomous(a.ocp) == is_autonomous(f.ocp)
                    Test.@test is_variable(a.ocp) == is_variable(f.ocp)
                    Test.@test is_control_free(a.ocp) == is_control_free(f.ocp)
                end

                Test.@testset "horizon" begin
                    # Fixed vs free is a *trait*, and getting it wrong in one
                    # form silently changes which `Flow` methods apply. Check
                    # the trait first — `final_time(ocp)` is a
                    # `PreconditionError` on a free-final-time model, so the
                    # value comparison has to go through the variable.
                    Test.@test is_initial_time_fixed(a.ocp) == is_initial_time_fixed(f.ocp)
                    Test.@test is_final_time_fixed(a.ocp) == is_final_time_fixed(f.ocp)

                    _, _, _, v = sample_point(a)

                    if is_initial_time_fixed(a.ocp)
                        Test.@test initial_time(a.ocp) == initial_time(f.ocp)
                    else
                        Test.@test initial_time(a.ocp, v) == initial_time(f.ocp, v)
                    end

                    if is_final_time_fixed(a.ocp)
                        Test.@test final_time(a.ocp) == final_time(f.ocp)
                    else
                        Test.@test final_time(a.ocp, v) == final_time(f.ocp, v)
                    end
                end

                Test.@testset "cost" begin
                    Test.@test criterion(a.ocp) == criterion(f.ocp)
                    Test.@test is_mayer_cost_defined(a.ocp) == is_mayer_cost_defined(f.ocp)
                    Test.@test is_lagrange_cost_defined(a.ocp) ==
                        is_lagrange_cost_defined(f.ocp)

                    t, x, u, v = sample_point(a)
                    if is_lagrange_cost_defined(a.ocp)
                        Test.@test lagrange(a.ocp)(t, x, u, v) ≈
                            lagrange(f.ocp)(t, x, u, v)
                    end
                    if is_mayer_cost_defined(a.ocp)
                        Test.@test mayer(a.ocp)(x, x, v) ≈ mayer(f.ocp)(x, x, v)
                    end
                end

                Test.@testset "dynamics" begin
                    t, x, u, v = sample_point(a)
                    Test.@test dyn_at(a.ocp, t, x, u, v) ≈ dyn_at(f.ocp, t, x, u, v)
                end

                Test.@testset "constraint dimensions" begin
                    for acc in (
                        dim_path_constraints_nl,
                        dim_boundary_constraints_nl,
                        dim_state_constraints_box,
                        dim_control_constraints_box,
                        dim_variable_constraints_box,
                    )
                        Test.@test acc(a.ocp) == acc(f.ocp)
                    end
                end

                Test.@testset "reference data is shared" begin
                    # The two forms must agree on what the answer is, or a
                    # form-parameterised solve test would be comparing against
                    # two different targets.
                    Test.@test a.objective == f.objective
                    Test.@test a.methods == f.methods
                    Test.@test keys(a.data) == keys(f.data)
                end

                Test.@testset "definition differs, by design" begin
                    # `@def` records the parsed expression; the functional API
                    # has nothing to record.
                    Test.@test has_abstract_definition(a.ocp)
                    Test.@test !has_abstract_definition(f.ocp)
                end
            end
        end
    end
end

end # module

# Redefine in outer scope for TestRunner
test_forms_equivalent() = TestFormsEquivalent.test_forms_equivalent()
