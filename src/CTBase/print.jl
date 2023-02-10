# --------------------------------------------------------------------------------------------------
# Display: text/html ?  
# Base.show, Base.print
# pretty print : https://docs.julialang.org/en/v1/manual/types/#man-custom-pretty-printing
function Base.show(io::IO, ::MIME"text/plain", ocp::OptimalControlModel{time_dependence}) where {time_dependence}

    dimx = state_dimension(ocp) === nothing ? "n" : state_dimension(ocp)
    dimu = control_dimension(ocp) === nothing ? "m" : control_dimension(ocp)

    printstyled(io, "\nOptimal control problem of the form:\n", bold=true)
    println(io, "")
    printstyled(io, "    minimize  ", color=:blue); print("J(t0, tf, x, u) = ")
    if ocp.mayer !== nothing
        print(io, " g(t0, x(t0), tf, x(tf))")
    end
    if ocp.mayer !== nothing && lagrange(ocp) !== nothing 
        print(io, " +")
    end
    if lagrange(ocp) !== nothing 
        isnonautonomous(ocp) ? 
        println(io, '\u222B', " f⁰(t, x(t), u(t)) dt, over [t0, tf]") : 
        println(io, '\u222B', " f⁰(x(t), u(t)) dt, over [t0, tf]")
    end
    println(io, "")
    printstyled(io, "    subject to\n", color=:blue)
    println(io, "")
    isnonautonomous(ocp) ? println(io, "        x", '\u0307', "(t) = f(t, x(t), u(t)), t in [t0, tf] a.e.,") : println(io, "        x", '\u0307', "(t) = f(x(t), u(t)), t in [t0, tf] a.e.,")
    println(io, "")
    # constraints
    ξ, ψ, ϕ = nlp_constraints(ocp)
    dim_ξ = length(ξ[1])      # dimension of the boundary constraints
    dim_ψ = length(ψ[1])
    dim_ϕ = length(ϕ[1])
    has_ξ = !isempty(ξ[1])
    has_ψ = !isempty(ψ[1])
    has_ϕ = !isempty(ϕ[1])
    if has_ξ
        isnonautonomous(ocp) ? 
        println(io, "        ξl ≤ ξ(t, u(t)) ≤ ξu, ") :
        println(io, "        ξl ≤ ξ(u(t)) ≤ ξu, ") 
    end
    if has_ψ
        isnonautonomous(ocp) ? 
        println(io, "        ψl ≤ ψ(t, x(t), u(t)) ≤ ψu, ") :
        println(io, "        ψl ≤ ψ(x(t), u(t)) ≤ ψu, ") 
    end
    if has_ϕ
        println(io, "        ϕl ≤ ϕ(t0, x(t0), tf, x(tf)) ≤ ϕu, ") 
    end
    println(io, "")
    print(io, "    where x(t) ", '\u2208', " R", dimx == 1 ? "" : Base.string("^", dimx))
    print(io, " and u(t) ", '\u2208', " R", dimu == 1 ? "" : Base.string("^", dimu), ".")
    println(io, "")
    println(io, "")
    nb_fixed = 0
    s = ""
    if initial_time(ocp) !== nothing
        s = s * "t0"
        nb_fixed += 1
    end
    if final_time(ocp) !== nothing
        if s == ""
            s = s * "tf"
        else
            s = s * ", tf"
        end
        nb_fixed += 1
    end
    if initial_condition(ocp) !== nothing
        if s == ""
            s = s * "x0"
        else
            s = s * " and x0"
        end
        nb_fixed += 1
    end
    if nb_fixed > 1
        s = s * " are fixed."
    elseif nb_fixed == 1
        s = s * " is fixed."
    end
    if nb_fixed > 0
        println(io, "    Besides, ", s)
    end
    #println(io, "")

end
