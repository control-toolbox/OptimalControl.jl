# NLP and DOCP manipulations

```@meta
CurrentModule =  OptimalControl
```

We describe here some more advanced operations related to the discretized optimal control problem.
When calling ```solve(ocp)``` three steps are performed internally:
- first, the OCP is discretized into a DOCP (a nonlinear optimization problem) with *directTranscription*
- then, this DOCP is solved (also with the method *solve*)
- finally, a functional solution of the OCP is rebuilt from the solution of the discretized problem, with *OCPSolutionFromDOCP*

These steps can also be done separately, for instance if you want to use your own NLP solver. Let us load the modules

```@example main
using OptimalControl
using NLPModelsIpopt
using Plots
```

and define a test problem

```@example main
@def ocp begin
    t ∈ [ 0, 1 ], time
    x ∈ R², state
    u ∈ R, control
    x(0) == [ -1, 0 ]
    x(1) == [ 0, 0 ]
    ẋ(t) == [ x₂(t), u(t) ]
    ∫( 0.5u(t)^2 ) → min
end
nothing # hide
```

The standard solve call
```@example main
sol = solve(ocp)
plot(sol)
```
can be decomposed as follows
```@example main
using CTDirect # needed for solve(docp)
docp = directTranscription(ocp)
# +++ solve(docp) is currently not exported in OptimalControl, only solve(ocp)... 
dsol = CTDirect.solve(docp)
sol = OCPSolutionFromDOCP(docp, dsol)
plot(sol)
```
+++ a more generic version of OCPSolutionFromDOCP is under work
+++ the example should be something like
docp = directTranscription(ocp)
#nlpsol = MySolver(getNLP(docp))
sol = OCPSolutionFromDOCP(docp, nlpsol)
plot(sol)
with maybe hidden the part that mimics what is done in CTDirect
using CTDirect
dsol = CTDirect.solve(docp)
nlpsol = dsol.+++


The DOCP contains a copy of the original OCP, and the resulting discretized problem, in our case an *ADNLPModel*.
You can extract this raw NLP problem  with the *getNLP* function
```@example main
nlp = getNLP(docp)
```

Note that an initial guess, including warm start, can be passed to *directTranscription* the same way as for *solve*
```@example main
docp = directTranscription(ocp, init=sol)
```
and the initial guess can also be changed after the transcription is done, with *setInitialGuess*
```@example main
setInitialGuess(docp, sol)
```

Back to the function *solve*, passing an explicit initial guess to
- *solve(ocp)* will transmit it to *directTranscription*, therefore the resulting DOCP will have the initial guess embedded in it.
- *solve(docp)* will override the initial guess in the DOCP and used the given one instead, without modifying the DOCP. 