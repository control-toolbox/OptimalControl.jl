module Flows

    # todo: this could be a package
    # todo: add non-autonomous rhs

    # Packages needed: 
    using ForwardDiff: jacobian, gradient, ForwardDiff
    using OrdinaryDiffEq: ODEProblem, solve, Tsit5, OrdinaryDiffEq

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

    function __method()
        return OrdinaryDiffEq.Tsit5()
    end

    # -------------------------------------------------------------------------------------------------- 
    # Description of the variants of the methods
    #
    const DescVarArg  = Vararg{Symbol} # or Symbol...
    const Description = Tuple{DescVarArg}
    
    function makeDescription(desc::DescVarArg)
        return Tuple(desc)
    end
    
    function makeDescription(desc::Description)
        return desc
    end
    
    # default is autonomous
    isnonautonomous(desc::Description) = :nonautonomous in desc

    # --------------------------------------------------------------------------------------------------
    # Aliases for types
    #
    const Time = Number

    const State = Vector{<:Number} # Vector{de sous-type de Number}
    const Adjoint = Vector{<:Number}
    const CoTangent = Vector{<:Number}
    const Control = Vector{<:Number}

    const DState = Vector{<:Number}
    const DAdjoint = Vector{<:Number}
    const DCoTangent = Vector{<:Number}

    # --------------------------------------------------------------------------------------------
    # all flows
    include("flows/flow_hamiltonian.jl")
    include("flows/flow_function.jl")
    include("flows/flow_hvf.jl")
    include("flows/flow_vf.jl")

    #todo: ajout du temps, de paramètres...
    #include("flows/flow_lagrange_system.jl")
    #include("flows/flow_mayer_system.jl")
    #include("flows/flow_pseudo_ham.jl")
    #include("flows/flow_si_mayer.jl")

    export VectorField
    export Hamiltonian
    export Flow

end