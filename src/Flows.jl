module Flows

    # todo: this could be a package

    # Packages needed: 
    using ForwardDiff: jacobian, gradient, ForwardDiff
    using OrdinaryDiffEq: ODEProblem, solve, Tsit5, OrdinaryDiffEq
    import Base: isempty

    #
    """
    isempty(p::OrdinaryDiffEq.SciMLBase.NullParameters)

TBW
"""
isempty(p::OrdinaryDiffEq.SciMLBase.NullParameters) = true

    # --------------------------------------------------------------------------------------------
    # Default options for flows
    # --------------------------------------------------------------------------------------------
    __abstol() = 1e-10
    __reltol() = 1e-10
    __saveat() = []
    __method() = OrdinaryDiffEq.Tsit5()

    # -------------------------------------------------------------------------------------------------- 
    # A desription is a tuple of symbols
    const DescVarArg  = Vararg{Symbol} # or Symbol...
    const Description = Tuple{DescVarArg}
    
    # -------------------------------------------------------------------------------------------------- 
    # the description may be given as a tuple or a list of symbols (Vararg{Symbol})
    """
    makeDescription(desc::DescVarArg)

TBW
"""
makeDescription(desc::DescVarArg)  = Tuple(desc) # create a description from Vararg{Symbol}
    """
    makeDescription(desc::Description)

TBW
"""
makeDescription(desc::Description) = desc
    
    # default is autonomous
    """
    isnonautonomous(desc::Description)

TBW
"""
isnonautonomous(desc::Description) = :nonautonomous ∈ desc

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
    export isnonautonomous

end