import Base: show, Base
# we get an error when a solution is printed so I add this function
# which has to be put in the package CTBase and has to be completed
function Base.show(io::IO, ::MIME"text/plain", sol::OptimalControlSolution)
    nothing
end
