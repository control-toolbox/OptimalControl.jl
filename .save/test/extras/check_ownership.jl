using OptimalControl
using CTBase
using CTSolvers
using CTDirect
using CTFlows
using CTModels
using CTParser

# Symbol to check
sym_to_check = :initial_guess

# List of modules to check
modules = [
    (:CTBase, CTBase),
    (:CTSolvers, CTSolvers),
    (:CTDirect, CTDirect),
    (:CTFlows, CTFlows),
    (:CTModels, CTModels),
    (:CTParser, CTParser),
    (:OptimalControl, OptimalControl)
]

println("Checking symbol: :$(sym_to_check)")
println("-"^30)

for (name, mod) in modules
    is_defined = isdefined(mod, sym_to_check)
    is_exported = sym_to_check in names(mod)

    status = if is_exported
        "Exported"
    elseif is_defined
        "Defined (internal)"
    else
        "Not found"
    end

    println("$(name): $(status)")
end
