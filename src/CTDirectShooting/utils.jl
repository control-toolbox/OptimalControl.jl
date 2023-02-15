# --------------------------------------------------------------------------------------------------
# Utils for the transcription from ocp to descent problem

function parse_ocp_direct_shooting(ocp::OptimalControlModel)

    # parsing ocp
    dy = dynamics(ocp)
    co = lagrange(ocp)
    cf = final_constraint(ocp)
    x0 = initial_condition(ocp)
    n = state_dimension(ocp)
    m = control_dimension(ocp)

    return dy, co, cf, x0, n, m

end

# forward integration of the state
"""
	model(x0, T, U, f)

TBW
"""
function model_primal_forward(x0, T, U, f)
    xₙ = x0
    X = [xₙ]
    for n in range(1, length(T) - 1)
        xₙ = f(T[n], xₙ, T[n+1], U[n])
        X = vcat(X, [xₙ]) # vcat gives a vector of vector
    end
    return xₙ, X
end

# backward integration of state and costate
"""
	adjoint(xₙ, pₙ, T, U, f)

TBW
"""
function model_adjoint_backward(xₙ, pₙ, T, U, f)
    X = [xₙ]
    P = [pₙ]
    for n in range(length(T), 2, step=-1)
        xₙ, pₙ = f(T[n], xₙ, pₙ, T[n-1], U[n-1])
        X = vcat([xₙ], X)
        P = vcat([pₙ], P)
    end
    return xₙ, pₙ, X, P
end