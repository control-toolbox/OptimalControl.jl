# NLP and DOCP manipulations

```@meta
CurrentModule =  OptimalControl
```

We describe here some more advanced operations related to the discretized optimal control problem.
When calling ```solve(ocp)``` three steps are performed internally:
- first, the OCP is discretized into a DOCP (a nonlinear optimization problem) with *direct_transcription*
- then, this DOCP is solved, also with the method *solve*
- finally, a functional solution of the OCP is rebuilt from the solution of the discretized problem, with *ocp_solution_from_docp*

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

First let us discretize the problem
```@example main
docp = direct_transcription(ocp)
nothing # hide
```
The DOCP contains a copy of the original OCP, and the resulting discretized problem, in our case an *ADNLPModel*.
You can extract this raw NLP problem  with the *get_nlp* function
```@example main
nlp = get_nlp(docp)
```
You could then use a custom solver that would return the solution for the NLP problem, such as
```
nlpsol = MySolver(getNLP(docp))
```
For illustrative purpose we can mimick this by using the *solve* from *CTDirect* on the DOCP, and extract the NLP solution alone, without the multipliers and other informations
```@example main
using CTDirect
dsol = CTDirect.solve(docp, display=false)
nlpsol = dsol.solution
nothing # hide
```
Then we can rebuild and plot an OCP solution (note that the costate has not been retrieved in this case)
```@example main
sol = ocp_solution_from_nlp(docp, nlpsol)
plot(sol)
```

An initial guess, including warm start, can be passed to *direct_transcription* the same way as for *solve*
```@example main
docp = direct_transcription(ocp, init=sol)
nothing # hide
```
and it can also be changed after the transcription is done, with *set_initial_guess*
```@example main
set_initial_guess(docp, sol)
nothing # hide
```

Back to the function *solve*, passing an explicit initial guess to
- *solve(ocp)* will transmit it to *direct_transcription*, therefore the resulting DOCP will have the initial guess embedded in it.
- *solve(docp)* will override the initial guess in the DOCP and used the given one instead, without modifying the DOCP. 