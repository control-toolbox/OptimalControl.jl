# --------------------------------------------------------------------------------------------------
# Abstract Optimal control problem, init and solution
abstract type AbstractOptimalControlProblem end
abstract type AbstractOptimalControlInit end
abstract type AbstractOptimalControlSolution end

# --------------------------------------------------------------------------------------------------
# OCP possibilities
# 1. cost: Lagrange, Mayer, Bolza
# 2. control constraints: yes, no
# 3. state constraints: yes, no
# 4. fixed or free: t0, tf, x0, xf

# Remark: for the moment, 
#   everything is fixed, except xf
#   we consider only Lagrange cost

# --------------------------------------------------------------------------------------------------
# OCP:
# Lagrange cost
# Unconstrained: 
#   no control constraints
#   no state constraints
# fixed: t0, tf, x0
# free: xf (final constraint)
#
struct UncFreeXfProblem <: AbstractOptimalControlProblem
    description::Description
    state_dimension::Union{Dimension,Nothing}
    control_dimension::Union{Dimension,Nothing}
    final_constraint_dimension::Union{Dimension,Nothing}
    Lagrange_cost::Function
    dynamics::Function
    initial_time::Time
    initial_condition::State
    final_time::Time
    final_constraint::Function
end

function OptimalControlProblem(Lagrange_cost::Function, dynamics::Function, initial_time::Time, 
    initial_condition::State, final_time::Time, final_constraint::Function, 
    state_dimension::Dimension, control_dimension::Dimension, final_constraint_dimension::Dimension,
    description...)
    ocp = UncFreeXfProblem(makeDescription(description...), state_dimension, 
        control_dimension, final_constraint_dimension, Lagrange_cost, dynamics, initial_time, 
        initial_condition, final_time, final_constraint)
    return ocp
end

struct UncFreeXfInit <: AbstractOptimalControlInit
    U::Controls
end

struct UncFreeXfSolution <: AbstractOptimalControlSolution
    T::TimesDisc # the times
    X::States # the states at the times T
    U::Controls # the controls at T
    P::Adjoints # the adjoint at T
    state_dimension::Dimension # the dimension of the state
    control_dimension::Dimension # the dimension of the control
    stopping::Symbol # the stopping criterion
    message::String # the message corresponding to the stopping criterion
    success::Bool # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    iterations::Integer # the number of iterations
end

# --------------------------------------------------------------------------------------------------
# OCP:
# Lagrange cost
# Unconstrained: 
#   no control constraints
#   no state constraints
# fixed: t0, tf, x0, xf
#
struct UncFixedXfProblem <: AbstractOptimalControlProblem
    description::Description
    state_dimension::Union{Dimension,Nothing}
    control_dimension::Union{Dimension,Nothing}
    Lagrange_cost::Function
    dynamics::Function
    initial_time::Time
    initial_condition::State
    final_time::Time
    final_condition::State
end

function OptimalControlProblem(Lagrange_cost::Function, dynamics::Function, initial_time::Time,
    initial_condition::State, final_time::Time, final_condition::State, state_dimension::Dimension, 
    control_dimension::Dimension, description...)
    ocp = UncFixedXfProblem(makeDescription(description...), state_dimension, 
        control_dimension, Lagrange_cost, dynamics, initial_time, initial_condition, 
        final_time, final_condition)
    return ocp
end

struct UncFixedXfInit <: AbstractOptimalControlInit
    U::Controls
end

struct UncFixedXfSolution <: AbstractOptimalControlSolution
    T::TimesDisc # the times
    X::States # the states at the times T
    U::Controls # the controls at T
    P::Adjoints # the adjoint at T
    state_dimension::Dimension # the dimension of the state
    control_dimension::Dimension # the dimension of the control
    stopping::Symbol # the stopping criterion
    message::String # the message corresponding to the stopping criterion
    success::Bool # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    iterations::Integer # the number of iterations
end

# convert
function convert(ocp::UncFixedXfProblem, ocp_type::DataType)
    if ocp_type == UncFreeXfProblem
        c(x) = x - ocp.final_condition
        ocp_new = OptimalControlProblem(ocp.Lagrange_cost, ocp.dynamics, ocp.initial_time, ocp.initial_condition, ocp.final_time, c, ocp.state_dimension, ocp.control_dimension, ocp.state_dimension, ocp.description...)
    else
        throw(IncorrectMethod(Symbol(ocp_type)))
    end
    return ocp_new
end

function convert(sol::UncFreeXfSolution, ocp_type::DataType)
    if ocp_type == UncFixedXfSolution
        sol_new = UncFixedXfSolution(sol.T, sol.X, sol.U, sol.P, sol.state_dimension, sol.control_dimension,
            sol.stopping, sol.message, sol.success, sol.iterations)
    else
        throw(IncorrectMethod(Symbol(ocp_type)))
    end
    return sol_new
end

function convert(sol::UncFixedXfSolution, ocp_type::DataType)
    if ocp_type == UncFreeXfSolution
        sol_new = UncFreeXfSolution(sol.T, sol.X, sol.U, sol.P, sol.state_dimension, sol.control_dimension,
            sol.stopping, sol.message, sol.success, sol.iterations)
    else
        throw(IncorrectMethod(Symbol(ocp_type)))
    end
    return sol_new
end

# --------------------------------------------------------------------------------------------------
# Display: text/html ?  
# Base.show, Base.print
# pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
function Base.show(io::IO, ocp::UncFreeXfProblem)

    dimx = ocp.state_dimension === nothing ? "n" : ocp.state_dimension
    dimu = ocp.control_dimension === nothing ? "m" : ocp.control_dimension
    dimc = ocp.final_constraint_dimension === nothing ? "p" : ocp.final_constraint_dimension

    desc = ocp.description

    println(io, "Optimal control problem of the form:")
    println(io, "")
    print(io, "    minimize  J(x, u) = ")
    isnonautonomous(desc) ? println(io, '\u222B', " f⁰(t, x(t), u(t)) dt, over [t0, tf]") : println(io, '\u222B', " f⁰(x(t), u(t)) dt, over [t0, tf]")
    println(io, "")
    println(io, "    subject to")
    println(io, "")
    isnonautonomous(desc) ? println(io, "        x", '\u0307', "(t) = f(t, x(t), u(t)), t in [t0, tf] a.e.,") : println(io, "        x", '\u0307', "(t) = f(x(t), u(t)), t in [t0, tf] a.e.,")
    println(io, "")
    println(io, "        x(t0) = x0, c(x(tf)) = 0,")
    println(io, "")
    print(io, "    where x(t) ", '\u2208', " R", dimx == 1 ? "" : Base.string("^", dimx), ", u(t) ", '\u2208', " R", dimu == 1 ? "" : Base.string("^", dimu), " and c(x) ", '\u2208', " R", dimc == 1 ? "" : Base.string("^", dimc), ".")
    #println(io, "")
    println(io, " Besides, t0, tf and x0 are fixed. ")
    #println(io, "")

end

function Base.show(io::IO, ocp::UncFixedXfProblem)

    dimx = ocp.state_dimension === nothing ? "n" : ocp.state_dimension
    dimu = ocp.control_dimension === nothing ? "m" : ocp.control_dimension

    desc = ocp.description

    println(io, "Optimal control problem of the form:")
    println(io, "")
    print(io, "    minimize  J(x, u) = ")
    isnonautonomous(desc) ? println(io, '\u222B', " f⁰(t, x(t), u(t)) dt, over [t0, tf]") : println(io, '\u222B', " f⁰(x(t), u(t)) dt, over [t0, tf]")
    println(io, "")
    println(io, "    subject to")
    println(io, "")
    isnonautonomous(desc) ? println(io, "        x", '\u0307', "(t) = f(t, x(t), u(t)), t in [t0, tf] a.e.,") : println(io, "        x", '\u0307', "(t) = f(x(t), u(t)), t in [t0, tf] a.e.,")
    println(io, "")
    println(io, "        x(t0) = x0, x(tf) = xf,")
    println(io, "")
    print(io, "    where x(t) ", '\u2208', " R", dimx == 1 ? "" : Base.string("^", dimx), " and u(t) ", '\u2208', " R", dimu == 1 ? "" : Base.string("^", dimu), ".")
    #println(io, "")
    println(io, " Besides, t0, tf, x0 and xf are fixed. ")
    #println(io, "")

end
