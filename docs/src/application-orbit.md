# [Minimum time orbit transfer](@id orbit)

## Introduction

Let us consider [^1] and [^2]

```@raw html
<img src="./assets/batch.jpg" style="display: block; margin: 0 auto 20px auto;" width="400px">
```

Foo

```math
\begin{align*}
  \dot{s} &= -w_M(s)(1-r)V,\\
  \dot{p} &= w_M(s)(1-r) - w_R(p)r(p+1),\\
  \dot{r} &= (\alpha-r)w_R(p)r,\\
  \dot{V} &= w_R(p)rV,
\end{align*}
```

## Biomass maximisation

We first import the needed packages.

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

## References

[^1]: Bonnard, B.; Caillau, J.-B.; Trélat, E. Geometric optimal control of elliptic Keplerian orbits.  *Discrete Contin. Dyn. Syst. Ser. B* **5** (2005), no. 4, 929-956.

[^2]: Caillau, J.-B.; Gergaud, J.; Noailles, J. 3D Geosynchronous Transfer of a Satellite: continuation on the Thrust. *J. Optim. Theory Appl.* **118** (2003), no. 3, 541-565.