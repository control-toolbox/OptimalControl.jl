v = [1.0; 2.0; 3.0; 4.0; 5.0; 6.0]
n = 2
u = ControlToolbox.vec2vec(v, n)
w = ControlToolbox.vec2vec(u)
@test v == w