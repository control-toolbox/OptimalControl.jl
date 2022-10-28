# replace default callback
function mystop(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, oTol, aTol, sTol, iterations)
    stop     = false
    stopping = nothing
    success  = nothing
    message  = nothing
    return stop, stopping, message, success
end
cb = StopCallback(mystop)
@test typeof(cb) == StopCallback 
cb(1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1)

# print (not replacing) and stop (replacing) callbacks
function myprint(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)
    nothing
end
cb = PrintCallback(myprint)
@test typeof(cb) == PrintCallback
cb(1, 1, 1, 1, 1, 1)