println("testing: constraint types")

if !isdefined(Main, :goddard)
    include("../problems/goddard.jl")
end

# ad hoc constraints / multipliers check
check_constraint_mult = false

if !check_constraint_mult

    # box constraints
    @testset verbose = true showtiming = true ":goddard :box_constraints" begin
        prob = goddard()
        sol = solve(prob.ocp, display = false)
        @test sol.objective ≈ prob.obj rtol = 1e-2
    end

    # all constraints
    @testset verbose = true showtiming = true ":goddard :all_constraints" begin
        prob = goddard_all()
        sol = solve(prob.ocp, display = false, init = prob.init)
        @test sol.objective ≈ prob.obj rtol = 1e-2
    end

else
    # ad hoc check on goddard problem
    # NB. sign mismatch between p(tf) and multiplier for final constraints 
    # +++if possible fix ordering in OCP: initial THEN final constraints !
    using SplitApplyCombine
    pyplot()

    ocp = goddard_all()
    sol = solve(ocp.ocp, display = false, init = ocp.init)

    # plot state, control and costate
    psol = plot(sol)

    # check constraints and multipliers
    T = sol.time_grid

    # POINT CONSTRAINTS
    # boundary constraints (NB. ORDERING IS NOT OBVIOUS)
    println("Boundary constraints: ", sol.boundary_constraints)
    println("multipliers: ", sol.mult_boundary_constraints)
    println("p(t0): ", sol.costate(T[1]), " p_m(tf) ", sol.costate(T[end])[3])
    # variable constraints / box
    println("\nVariable constraints: ", sol.variable_constraints)
    println("multipliers: ", sol.mult_variable_constraints)
    println(
        "\nVariable box multipliers LB: ",
        sol.mult_variable_box_lower,
        " UB ",
        sol.mult_variable_box_upper,
    )

    # PATH CONSTRAINTS
    # state box
    x = invert(sol.state.(T))
    x_box_lb = invert(sol.mult_state_box_lower.(T))
    x_box_ub = invert(sol.mult_state_box_upper.(T))

    p1_a = plot(T, x[1], label = "r")
    p1_b = plot(T, [x_box_lb[1] x_box_ub[1]], label = ["LB" "UB"])
    p1 = plot(p1_a, p1_b, layout = (2, 1))

    p2_a = plot(T, x[2], label = "v")
    p2_b = plot(T, [x_box_lb[2] x_box_ub[2]], label = ["LB" "UB"])
    p2 = plot(p2_a, p2_b, layout = (2, 1))

    p3_a = plot(T, x[3], label = "m")
    p3_b = plot(T, [x_box_lb[3] x_box_ub[3]], label = ["LB" "UB"])
    p3 = plot(p3_a, p3_b, layout = (2, 1))

    # control box
    u = sol.control.(T)
    u_box_lb = flatten(sol.mult_control_box_lower.(T))
    u_box_ub = flatten(sol.mult_control_box_upper.(T))
    p4_a = plot(T, u, label = "u")
    p4_b = plot(T, [u_box_lb u_box_ub], label = ["LB" "UB"])
    p4 = plot(p4_a, p4_b, layout = (2, 1))

    p_box =
        plot(p1, p2, p3, p4, layout = (2, 2), title = ["r box" "" "v box" "" "m box" "" "u box" ""])
    display(p_box)
    readline() #ffs julia, fix your damn plots

    # nonlinear path constraints
    # control constraints
    c_u = flatten(sol.control_constraints.(T))
    m_c_u = flatten(sol.mult_control_constraints.(T))
    p5_a = plot(T, c_u, label = "c_u")
    p5_b = plot(T, m_c_u, label = "mul")
    p5 = plot(p5_a, p5_b, layout = (2, 1))

    # state constraints
    c_x = flatten(sol.state_constraints.(T))
    m_c_x = flatten(sol.mult_state_constraints.(T))
    p6_a = plot(T, c_x, label = "c_x")
    p6_b = plot(T, m_c_x, label = "mul")
    p6 = plot(p6_a, p6_b, layout = (2, 1))

    # mixed constraints
    c_xu = flatten(sol.mixed_constraints.(T))
    m_c_xu = flatten(sol.mult_mixed_constraints.(T))
    p7_a = plot(T, c_xu, label = "c_xu")
    p7_b = plot(T, m_c_xu, label = "mul")
    p7 = plot(p7_a, p7_b, layout = (2, 1))

    p_cons = plot(
        p5,
        p6,
        p7,
        layout = (1, 3),
        title = ["control cons" "" "state cons" "" "mixed cons" ""],
    )

end
