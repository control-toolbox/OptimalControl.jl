#
const add = ControlToolbox.add
const gFD = ControlToolbox.getFullDescription

# make a description from symbols or a tuple of symbols
@test ControlToolbox.makeDescription(:tt, :vv) == (:tt, :vv)
@test ControlToolbox.makeDescription((:tt, :vv)) == (:tt, :vv)

#
a = ()
a = add(a, (:tata,))
a = add(a, (:toto,))
@test a[1] == (:tata,)
@test a[2] == (:toto,)

# get the complete description of the chosen method
algorithmes = ()
algorithmes = add(algorithmes, (:descent, :bfgs, :bissection))
algorithmes = add(algorithmes, (:descent, :bfgs, :backtracking))
algorithmes = add(algorithmes, (:descent, :bfgs, :fixedstep))
algorithmes = add(algorithmes, (:descent, :gradient, :bissection))
algorithmes = add(algorithmes, (:descent, :gradient, :backtracking))
algorithmes = add(algorithmes, (:descent, :gradient, :fixedstep))

@test gFD((:descent,), algorithmes) == (:descent, :bfgs, :bissection)
@test gFD((:bfgs,), algorithmes) == (:descent, :bfgs, :bissection)
@test gFD((:bissection,), algorithmes) == (:descent, :bfgs, :bissection)
@test gFD((:backtracking,), algorithmes) == (:descent, :bfgs, :backtracking)
@test gFD((:fixedstep,), algorithmes) == (:descent, :bfgs, :fixedstep)
@test gFD((:fixedstep, :gradient), algorithmes) == (:descent, :gradient, :fixedstep)

# incorrect description
@test_throws AmbiguousDescription gFD((:ttt,), algorithmes)
@test_throws AmbiguousDescription gFD((:descent, :ttt), algorithmes)
