# transform a Vector{<:Vector{<:Real}} to a Vector{<:Real}
function vec2vec(x::Vector{<:Vector{<:Real}})
    y = x[1]
    for i in range(2, length(x))
        y = vcat(y, x[i])
    end
    return y
end

function expand(x::Vector{<:Vector{<:Real}})
    return vec2vec(x)
end
function expand(x::Vector{<:Real})
    return x
end

# transform a Vector{<:Real} to a Vector{<:Vector{<:Real}}
function vec2vec(x::Vector{<:Real}, n::Integer)
    y = [x[1:n]]
    for i in n+1:n:length(x)-n+1
        y = vcat(y, [x[i:i+n-1]])
    end
    return y
end

function Ad(X, f)
    return x -> ∇(f, x)'*X(x)
end

function Poisson(f, g)
    function fg(x, p)
        n = size(x, 1)
        ff = z -> f(z[1:n], z[n+1:2n])
        gg = z -> g(z[1:n], z[n+1:2n])
        df = ∇(ff, [ x ; p ])
        dg = ∇(gg, [ x ; p ])
        return df[n+1:2n]'*dg[1:n] - df[1:n]'*dg[n+1:2n]
    end
    return fg
end