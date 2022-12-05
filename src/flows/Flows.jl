module Flows
# todo: this could be a package

# Packages needed: 
using ForwardDiff: jacobian, gradient, ForwardDiff
using OrdinaryDiffEq: ODEProblem, solve, Tsit5, OrdinaryDiffEq
import Base: isempty

#
include("../common/description.jl")

#
isempty(p::OrdinaryDiffEq.SciMLBase.NullParameters) = true

# --------------------------------------------------------------------------------------------
# Default options for flows
# --------------------------------------------------------------------------------------------
__abstol() = 1e-10
__reltol() = 1e-10
__saveat() = []
__alg() = OrdinaryDiffEq.Tsit5()

# -------------------------------------------------------------------------------------------------- 
# desription 

# default is autonomous
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
include("flow_hamiltonian.jl")
include("flow_function.jl")
include("flow_hvf.jl")
include("flow_vf.jl")

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
