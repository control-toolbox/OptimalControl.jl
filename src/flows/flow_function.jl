# --------------------------------------------------------------------------------------------
# From a function: we consider it as a Hamiltonian
# --------------------------------------------------------------------------------------------

# Flow from a function
"""
	Flow(f::Function, description...; kwargs_Flow...)

TBW
"""
function Flow(f::Function, description...; 
                alg=__alg(), abstol=__abstol(), reltol=__reltol(), saveat=__saveat(), kwargs_Flow...)
    return Flow(Hamiltonian(f), description...; 
                    alg=alg, abstol=abstol, reltol=reltol, saveat=saveat, kwargs_Flow...)
end
