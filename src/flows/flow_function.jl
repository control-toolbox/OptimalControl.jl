# --------------------------------------------------------------------------------------------
# From a function: we consider it as a Hamiltonian
# --------------------------------------------------------------------------------------------

# Flow from a function
function Flow(f::Function, args...; kwargs_Flow...)
    return Flow(Hamiltonian(f), args...; kwargs_Flow...)
end