# --------------------------------------------------------------------------------------------------
# Utils for the transcription from ocp to descent problem

# forward integration of the state
"""
	model(x0, T, U, f)

TBW
"""
function model(x0, T, U, f)
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
function adjoint(xₙ, pₙ, T, U, f)
    X = [xₙ]
    P = [pₙ]
    for n in range(length(T), 2, step=-1)
        xₙ, pₙ = f(T[n], xₙ, pₙ, T[n-1], U[n-1])
        X = vcat([xₙ], X)
        P = vcat([pₙ], P)
    end
    return xₙ, pₙ, X, P
end