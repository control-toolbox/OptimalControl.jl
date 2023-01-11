# stop callback
function mystop(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, oTol, aTol, sTol, iterations)
    stop = false
    stopping = nothing
    success = nothing
    message = nothing
    return stop, stopping, message, success
end
cb = StopCallback(mystop)
@test typeof(cb) == StopCallback
cb(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)

# print callback
function myprint(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)
    nothing
end
cb = PrintCallback(myprint)
@test typeof(cb) == PrintCallback
cb(1, 1, 1, 1, 1, 1)

# priority
cb_stop_1 = StopCallback(mystop)
cb_stop_2 = StopCallback(mystop, priority=2)
cb_print_1 = PrintCallback(myprint)
cb_print_2 = PrintCallback(myprint, priority=0)

cbs = (cb_stop_1, cb_print_1, cb_stop_2, cb_print_2)

callbacks_print = OptimalControl.get_priority_print_callbacks(cbs)
callbacks_stop = OptimalControl.get_priority_stop_callbacks(cbs)

@test callbacks_print[1] == cb_print_1
@test callbacks_stop[1] == cb_stop_2