# -------------------------------------------------------------------------------------------------- 
# A desription is a tuple of symbols
const DescVarArg  = Vararg{Symbol} # or Symbol...
const Description = Tuple{DescVarArg}

# -------------------------------------------------------------------------------------------------- 
# the description may be given as a tuple or a list of symbols (Vararg{Symbol})
makeDescription(desc::DescVarArg)  = Tuple(desc) # create a description from Vararg{Symbol}
makeDescription(desc::Description) = desc

# -------------------------------------------------------------------------------------------------- 
# Possible algorithms
add(x::Tuple{}, y::Description) = (y, )
add(x::Tuple{Vararg{Description}}, y::Description) = (x..., y)

# by order of preference
algorithmes = ()
algorithmes = add(algorithmes, (:descent, :bfgs, :backtracking))
algorithmes = add(algorithmes, (:descent, :bfgs, :fixedstep))
algorithmes = add(algorithmes, (:descent, :gradient, :backtracking))
algorithmes = add(algorithmes, (:descent, :gradient, :fixedstep))

# this function transform an incomplete description to a complete one
function getCompleteSolverDescription(desc::Description)::Description
    # todo : vérifier si fonctionne si des descriptions de différentes tailles
    n = length(algorithmes)
    table = zeros(Int8, n, 2)
    for i ∈ range(1, n)
        table[i, 1] = length(desc ∩ algorithmes[i])
        table[i, 2] = desc ⊆ algorithmes[i] ? 1 : 0
    end
    if maximum(table[:,2]) == 0
        error("The description of the method is ambiguous.")
    end
    # argmax : Return the index or key of the maximal element in a collection.
    # If there are multiple maximal elements, then the first one will be returned.
    return algorithmes[argmax(table[:, 1])]
end