#
e = InconsistentArgument("e")
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String

e = IncorrectMethod(:e)
@test_throws ErrorException error(e)
@test typeof(sprint(showerror, e)) == String