# --------------------------------------------------------------------------------------------
# From a function: we consider it as a Hamiltonian
# --------------------------------------------------------------------------------------------

# Flow from a function
"""
    Flow(f::Function, description...; kwargs_Flow...)

TBW
"""
function Flow(f::Function, description...; kwargs_Flow...)
    return Flow(Hamiltonian(f), description...; kwargs_Flow...)
end