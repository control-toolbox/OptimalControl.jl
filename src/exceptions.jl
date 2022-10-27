# --------------------------------------------------------------------------------------------------
# General abstract type for exceptions
abstract type CTException <: Exception end

# Incorrect method
struct MethodValueError <: CTException 
    var::Symbol
end

Base.showerror(io::IO, e::MethodValueError) = print(io, e.var, " is not an existing method")

# Ambiguous description
struct AmbiguousDescriptionError <: CTException 
    var::Description
end

Base.showerror(io::IO, e::AmbiguousDescriptionError) = print(io, "the description ", 
    e.var, " is ambiguous / incorrect")
