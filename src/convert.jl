#
function convert(ocp::RegularOCPFinalCondition, ocp_type::DataType)
    if ocp_type==RegularOCPFinalConstraint
        c(x) = x-ocp.final_condition
        ocp_new = OCP(ocp.Lagrange_cost, ocp.dynamics, ocp.initial_time, ocp.initial_condition,
        ocp.final_time, c, ocp.state_dimension, ocp.control_dimension, ocp.state_dimension,
        ocp.description...)
    else
        error("No such a conversion")
    end
    return ocp_new
end