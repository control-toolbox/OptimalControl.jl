# --------------------------------------------------------------------------------------------------
# Plot solution
# print("x", '\u2080'+9) : x₉ 
#

# General plot
"""
	Plots.plot(sol::UncFreeXfSolution, args...; 
	state_style=(), 
	control_style=(), 
	adjoint_style=(), kwargs...)

TBW
"""
function Plots.plot(sol::DirectShootingSolution, args...; 
    state_style=(), control_style=(), adjoint_style=(), kwargs...)

    # todo : gérer le cas dans les labels où m, n > 9

    n = sol.state_dimension
    m = sol.control_dimension

    px = Plots.plot(; xlabel="time", title="state", state_style...)
    if n == 1
        Plots.plot!(px, sol, :time, (:state, i); label="x", state_style...)
    else
        for i in range(1, n)
            Plots.plot!(px, sol, :time, (:state, i); label="x" * ('\u2080' + i), state_style...)
        end
    end
    
    pu = Plots.plot(; xlabel="time", title="control", control_style...)
    if m == 1
        Plots.plot!(pu, sol, :time, (:control, 1); label="u", control_style...)
    else
        for i in range(1, m)
            Plots.plot!(pu, sol, :time, (:control, i); label="u" * ('\u2080' + i), control_style...)
        end
    end

    pp = Plots.plot(; xlabel="time", title="adjoint", adjoint_style...)
    if n == 1
        Plots.plot!(pp, sol, :time, (:adjoint, i); label="p", adjoint_style...)
    else
        for i in range(1, n)
            Plots.plot!(pp, sol, :time, (:adjoint, i); label="p" * ('\u2080' + i), adjoint_style...)
        end
    end

    ps = Plots.plot(px, pu, pp, args..., layout=(1, 3); kwargs...)

    return ps

end

# specific plot
function Plots.plot(sol::DirectShootingSolution, 
    xx::Union{Symbol,Tuple{Symbol,Integer}}, yy::Union{Symbol,Tuple{Symbol,Integer}}, args...; kwargs...)

    x = get(sol, xx)
    y = get(sol, yy)

    return Plots.plot(x, y, args...; kwargs...)

end

function Plots.plot!(p::Plots.Plot{<:Plots.AbstractBackend}, sol::DirectShootingSolution, 
    xx::Union{Symbol,Tuple{Symbol,Integer}}, yy::Union{Symbol,Tuple{Symbol,Integer}}, args...; kwargs...)

    x = get(sol, xx)
    y = get(sol, yy)

    Plots.plot!(p, x, y, args...; kwargs...)

end
#plot!(p, x, y, args...; kwargs...) = Plots.plot!(p, x, y, args...; kwargs...)

"""
	get(sol::UncFreeXfSolution, xx::Union{Symbol, Tuple{Symbol, Integer}})

TBW
"""
function get(sol::DirectShootingSolution, xx::Union{Symbol,Tuple{Symbol,Integer}})

    T = sol.T
    X = sol.X
    U = sol.U
    P = sol.P

    m = length(T)

    if typeof(xx) == Symbol
        vv = xx
        if vv == :time
            x = T
        elseif vv == :state
            x = [X[i][1] for i in 1:m]
        elseif vv == :adjoint || vv == :costate
            x = [P[i][1] for i in 1:m]
        else
            x = vcat([U[i][1] for i in 1:m-1], U[m-1][1])
        end
    else
        vv = xx[1]
        ii = xx[2]
        if vv == :time
            x = T
        elseif vv == :state
            x = [X[i][ii] for i in 1:m]
        elseif vv == :adjoint || vv == :costate
            x = [P[i][ii] for i in 1:m]
        else
            x = vcat([U[i][ii] for i in 1:m-1], U[m-1][ii])
        end
    end

    return x

end
