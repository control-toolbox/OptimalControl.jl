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