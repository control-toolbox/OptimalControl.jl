import CTParser: CTParser, @def, @init
export @def, @init

function __init__()
    CTParser.prefix_fun!(:OptimalControl)
    CTParser.prefix_exa!(:OptimalControl)
    CTParser.e_prefix!(:OptimalControl)
end