# --------------------------------------------------------------------------------------------------
# General abstract type for exceptions
abstract type CTException <: Exception end

# Incorrect method
struct MethodError <: CTException 
    var::Symbol
end

Base.showerror(io::IO, e::MethodError) = print(io, e.var, " is not an existing method")

# Ambiguous description
struct AmbiguousDescriptionError <: CTException 
    var::Description
end

Base.showerror(io::IO, e::AmbiguousDescriptionError) = print(io, "the description ", 
    e.var, " is ambiguous / incorrect")
