
#### NE FONCTIONNE PAS

# --------------------------------------------------------------------------------------------------
# Display: text/html ?  
# Base.show, Base.print
# pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
function Base.show(io::IO, ocp::OptimalControlModel{time_dependence}) where {time_dependence}

    dimx = state_dimension(ocp) === nothing ? "n" : state_dimension(ocp)
    dimu = control_dimension(ocp) === nothing ? "m" : control_dimension(ocp)
    dimc = "p" #ocp.final_constraint_dimension === nothing ? "p" : ocp.final_constraint_dimension

    println(io, "Optimal control problem of the form:")
    println(io, "")
    print(io, "    minimize  J(x, u) = ")
    isnonautonomous(ocp) ? println(io, '\u222B', " f⁰(t, x(t), u(t)) dt, over [t0, tf]") : println(io, '\u222B', " f⁰(x(t), u(t)) dt, over [t0, tf]")
    println(io, "")
    println(io, "    subject to")
    println(io, "")
    isnonautonomous(ocp) ? println(io, "        x", '\u0307', "(t) = f(t, x(t), u(t)), t in [t0, tf] a.e.,") : println(io, "        x", '\u0307', "(t) = f(x(t), u(t)), t in [t0, tf] a.e.,")
    println(io, "")
    println(io, "        x(t0) = x0, c(x(tf)) = 0,")
    println(io, "")
    print(io, "    where x(t) ", '\u2208', " R", dimx == 1 ? "" : Base.string("^", dimx), ", u(t) ", '\u2208', " R", dimu == 1 ? "" : Base.string("^", dimu), " and c(x) ", '\u2208', " R", dimc == 1 ? "" : Base.string("^", dimc), ".")
    #println(io, "")
    println(io, " Besides, t0, tf and x0 are fixed. ")
    #println(io, "")

end
