# transform a Vector{<:Vector{<:Number}} to a Vector{<:Number}
function vec2vec(x::Vector{<:Vector{<:Number}})
    y = x[1]
    for i in range(2, length(x))
        y = vcat(y, x[i])
    end
    return y
end

# transform a Vector{<:Number} to a Vector{<:Vector{<:Number}}
function vec2vec(x::Vector{<:Number}, n::Integer)
    y = [x[1:n]]
    for i in n+1:n:length(x)-n+1
        y = vcat(y, [x[i:i+n-1]])
    end
    return y
end
