module Flows

    # todo: this could be a package

    # Packages needed: 
    using ForwardDiff
    using OrdinaryDiffEq

    # --------------------------------------------------------------------------------------------
    # Default options for flows
    # --------------------------------------------------------------------------------------------
    function __abstol()
        return 1e-10
    end

    function __reltol()
        return 1e-10
    end

    function __saveat()
        return []
    end

    # --------------------------------------------------------------------------------------------
    # all flows
    include("flows/flow_hamiltonian.jl")
    include("flows/flow_hvf.jl")
    include("flows/flow_lagrange_system.jl")
    include("flows/flow_mayer_system.jl")
    include("flows/flow_pseudo_ham.jl")
    include("flows/flow_si_mayer.jl")
    include("flows/flow_vf.jl")

    export VectorField
    export Hamiltonian
    export Flow

end