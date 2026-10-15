## Contributing

[issue-url]: https://github.com/control-toolbox/OptimalControl.jl/issues
[first-good-issue-url]: https://github.com/control-toolbox/OptimalControl.jl/contribute

If you think you found a bug or if you have a feature request / suggestion, feel free to open an [issue][issue-url].  
Before opening a pull request, please start an issue or a discussion on the topic. 

Contributions are welcomed, check out [how to contribute to a Github project](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project). If it is your first contribution, you can also check [this first contribution tutorial](https://github.com/firstcontributions/first-contributions). You can find first good issues (if any 🙂) [here][first-good-issue-url]. You may find other packages to contribute to at the [control-toolbox organization](https://github.com/control-toolbox).

If you want to ask a question, feel free to start a discussion [here](https://github.com/orgs/control-toolbox/discussions). This forum is for general discussion about this repository and the [control-toolbox organization](https://github.com/control-toolbox).

>[!NOTE]
> If you want to add an application or a package to the control-toolbox ecosystem, please follow this [set up tutorial](https://github.com/orgs/control-toolbox/discussions/65).

---

## Developer Resources

The [ct-conventions](https://github.com/control-toolbox/ct-conventions) repository (coding rules, method, plan template) is pinned to a SemVer release tag in `AGENTS.md` ("Pinned version"). Read it from a local clone in `.conventions/`, which git ignores; `AGENTS.md` gives the clone command.

It is not a git submodule: `Pkg.add` on Julia 1.10 fails on a package whose tree contains one (`cannot get submodules without a working tree`). To bump it, change the tag in `AGENTS.md` (the "Pinned version" line and the clone command), then re-clone.
