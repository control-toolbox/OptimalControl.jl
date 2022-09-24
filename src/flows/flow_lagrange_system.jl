# --------------------------------------------------------------------------------------------
# Lagrange
# --------------------------------------------------------------------------------------------
struct Lagrange 
    f::Function
    f⁰::Function 
end

# Flow from Lagrange system
Flow(Σu::Lagrange, p⁰::Number=-1.0) = Flow(PseudoHamiltonian((x, p, p⁰, u) -> p⁰*Σu.f⁰(x,u)+p'*Σu.f(x,u)), p⁰=p⁰);
