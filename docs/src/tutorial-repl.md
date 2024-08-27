# The control-toolbox REPL

We present in this tutorial the control-toolbox REPL which permits first an incremental 
definition of the optimal control problem, but also to solve it (with default options only) 
and plot the solution (with default options only). 

- To define the problem please check the [abstract syntax tutorial](@ref tutorial-abstract).
- For more details about solving an optimal control problem, we refer to the [solve tutorial](@ref tutorial-solve) and to plot a solution, check the [plot a solution tutorial](@ref tutorial-plot).

To enter into the control-toolbox, press `>` key.

!!! tip "Standard usage"

    You can define the problem under the control-toolbox REPL and then, solve it
    and plot the solution in the Julia REPL. Use the command `NAME` to rename the 
    optimal control problem: `ct> NAME=ocp`.

!!! note "Nota bene"

    In the following gif, the plot is not displayed since only the terminal is recorded.

```@raw html
<style>
@media (orientation: landscape) { .ct-repl-img {content:url('assets/ct-repl-95x30.gif');} }
@media (orientation: portrait)  { .ct-repl-img {content:url('assets/ct-repl-95x60.gif');} }
</style>
<p><img url="assets/ct-repl-95x30.gif" alt="Control-toolbox REPL" class="ct-repl-img"> </p>
```

!!! note "Credits"

    This gif has been made with this version of [Replay.jl](https://github.com/ocots/Replay.jl). To make the gif we first need a script (named ct-repl.jl) containing:

    ```julia
    using Replay

    repl_script = """
    using OptimalControl
    t0 = 0
    tf = 1
    # press ">" to enter into control-toolbox repl
    >t ∈ [t0, tf], time
    # rename the ocp and the sol 
    NAME=(ocp, sol)
    SHOW
    # more commands
    HELP
    # add ";" at the end of the line for no output
    x ∈ R^2, state;
    u ∈ R, control;
    x(t0) == [ -1, 0 ];
    x(tf) == [ 0, 0 ];
    \\partial$(TAB)(x)(t) == [ x\\_2$(TAB)(t), u(t) ];
    \\int$(TAB)( 0.5u(t)^2 ) \\to$(TAB) min;
    SHOW
    $BACKSPACE
    using NLPModelsIpopt
    >SOLVE
    $BACKSPACE
    # you can access the ocp and the sol in Julia repl
    ocp
    sol
    using Plots
    >PLOT
    $BACKSPACE
    """

    replay(
        repl_script, 
        stdout, 
        julia_project=@__DIR__, 
        use_ghostwriter=true, 
        cmd=`--color=yes`
    )
    ```

    Then, to register the terminal we have used 
    [asciinema](https://github.com/asciinema/asciinema) 
    and to save the record into a gif file, we have used 
    [agg](https://github.com/asciinema/agg). 
    The shell script to obtain the gif is:

    ```bash
    julia --project=@. -e 'using Pkg; Pkg.instantiate()'
    asciinema rec result.cast \
        -i 2 \
        --cols=95 \
        --rows=30 \
        --overwrite \
        --command "julia --project=@. ./ct-repl.jl"
    agg result.cast ct-repl.gif
    ```