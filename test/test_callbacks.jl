# replace default callback
function mystop(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ, ng₀, oTol, aTol, sTol, iterations)
    stop     = false
    stopping = nothing
    success  = nothing
    message  = nothing
    return stop, stopping, message, success
end
@test typeof(StopCallback(mystop)) == StopCallback 

# print (not replacing) and stop (replacing) callbacks
function myprint(i, sᵢ, dᵢ, xᵢ, gᵢ, fᵢ)
    nothing
end
@test typeof(PrintCallback(myprint)) == PrintCallback