# --------------------------------------------------------------------------------------------------
# General abstract type for exceptions
abstract type CTException <: Exception end

# inconsistent argument
struct InconsistentArgument <: CTException
    var::String
end

"""
	Base.showerror(io::IO, e::InconsistentArgument)

TBW
"""
Base.showerror(io::IO, e::InconsistentArgument) = print(io, e.var)


# incorrect method
struct IncorrectMethod <: CTException
    var::Symbol
end

"""
	Base.showerror(io::IO, e::IncorrectMethod)

TBW
"""
Base.showerror(io::IO, e::IncorrectMethod) = print(io, e.var, " is not an existing method")