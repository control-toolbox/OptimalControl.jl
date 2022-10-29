# make a description from symbols or a tuple of symbols
@test ControlToolbox.makeDescription(:tt, :vv) == (:tt, :vv)
@test ControlToolbox.makeDescription((:tt, :vv)) == (:tt, :vv)

#
a = ()
a = ControlToolbox.add(a, (:tata,))
a = ControlToolbox.add(a, (:toto,))
@test a[1] == (:tata,)
@test a[2] == (:toto,)

# get the complete description of the chosen method
gCSD = ControlToolbox.getCompleteSolverDescription
@test gCSD((:descent,)) == (:descent, :bfgs, :bissection)
@test gCSD((:bfgs,)) == (:descent, :bfgs, :bissection)
@test gCSD((:bissection,)) == (:descent, :bfgs, :bissection)
@test gCSD((:backtracking,)) == (:descent, :bfgs, :backtracking)
@test gCSD((:fixedstep,)) == (:descent, :bfgs, :fixedstep)
@test gCSD((:fixedstep, :gradient)) == (:descent, :gradient, :fixedstep)

# incorrect description
@test_throws AmbiguousDescriptionError gCSD((:ttt,))
@test_throws AmbiguousDescriptionError gCSD((:descent, :ttt))
