# utils.jl

"""
$(TYPEDSIGNATURES)

Serve as a fake @def macro.

# Example

```jldoctest
julia> @__def t ∈ [ 0, tf ], time
```
"""
macro __def(e)
    ocp = Model()
    :( $ocp )
end
