# ============================================================================
# Re-export assertion helpers
# ============================================================================
# `Test.@test isdefined(OptimalControl, :foo)` is vacuously true for every name
# that also exists in `Base` — `time`, `merge`, `*`, `status`, `name`, `value`,
# `describe`, `success`, … Julia resolves those through the implicit `using
# Base`, so the whole re-export group can go green while OptimalControl
# re-exports none of them.
#
# These helpers assert *ownership* instead: the binding reachable from the
# module must be the very object the owning submodule defines. That is what
# actually breaks when a symbol changes package.
#
# Included (not `using`-ed) by each reexport test file, since TestRunner runs
# files independently and each must stand alone.

module ReexportUtils

"""
    is_exported(mod, name)

`true` when `name` is in `mod`'s public export list.
"""
is_exported(mod::Module, name::Symbol) = name ∈ names(mod; all=false)

"""
    owner(mod, name)

The module that *defines* the object `mod.name` refers to — as opposed to the
module we happened to import it through.
"""
owner(mod::Module, name::Symbol) = parentmodule(getfield(mod, name))

"""
    reexports(mod, name, from)

`true` when `mod` re-exports `name` **and** that name resolves to the object
owned by `from`. This is the assertion to use for every name that also exists
in `Base`; `isdefined` alone proves nothing there.
"""
function reexports(mod::Module, name::Symbol, from::Module)
    isdefined(mod, name) || return false
    is_exported(mod, name) || return false
    return owner(mod, name) === from
end

"""
    imports(mod, name, from)

Like [`reexports`](@ref) but for names deliberately kept out of the public
export list — reachable as `mod.name`, absent from `names(mod)`.
"""
function imports(mod::Module, name::Symbol, from::Module)
    isdefined(mod, name) || return false
    is_exported(mod, name) && return false
    return owner(mod, name) === from
end

"""
    same_object(mod, name, ref)

`true` when `mod.name` is the very object `ref` — identity, not just a name
match. Use it when the owner is awkward to name (e.g. `Base` generics extended
downstream).
"""
function same_object(mod::Module, name::Symbol, ref)
    return isdefined(mod, name) && getfield(mod, name) === ref
end

end # module
