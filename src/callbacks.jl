# --------------------------------------------------------------------------------------------------
# General abstract type for callbacks
abstract type CTCallback end

const CTCallbacks = Tuple{Vararg{CTCallback}}

# --------------------------------------------------------------------------------------------------
# Print callback
mutable struct PrintCallback <: CTCallback
    callback::Function
    priority::Integer
    function PrintCallback(cb::Function; priority::Integer=1)
        new(cb, priority)
    end
end
function (cb::PrintCallback)(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)
    return cb.callback(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)
end

const PrintCallbacks = Tuple{Vararg{PrintCallback}}

#
function get_priority_print_callbacks(cbs::CTCallbacks)
    callbacks_print = ()
    priority = -Inf
    
    # search higher priority
    for cb in cbs
        if typeof(cb) === PrintCallback && cb.priority ≥ priority
            priority = cb.priority
        end
    end

    # add callbacks
    for cb in cbs
        if typeof(cb) === PrintCallback && cb.priority == priority
            callbacks_print = (callbacks_print..., cb)
        end
    end
    return callbacks_print
end