# Cobalt Spark

A compact Oh My Zsh theme that uses restrained colors to avoid competing with
typical command output, such as `ls` listings. A prominent lightning anchor
makes command lines easy to find while scanning the screen and visually
separates the context on the left from the command on the right.

**Experimental:** the theme can also run without Oh My Zsh through its small
[standalone loader](#standalone-mode-experimental).

<img width="909" height="817" alt="Cobalt Spark Screenshot" src="https://github.com/user-attachments/assets/738870bc-e211-4761-a033-251433facdf4" />

The prompt includes the parent of the current directory, important Git state
such as the branch, detached `HEAD`, working-tree changes, and unpushed commits,
and Python's virtual environment via the `virtualenv` plugin. It also indicates
nested shells and background jobs when present.

## Installation

Clone the repository into the Oh My Zsh custom themes directory:

```sh
git clone https://github.com/azhuchkov/cobalt-spark.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/cobalt-spark"
```

Then select the theme in `~/.zshrc`:

```sh
ZSH_THEME="cobalt-spark/cobalt-spark"
```

To compare it with another theme using Oh My Zsh's random theme selection:

```sh
ZSH_THEME="random"
ZSH_THEME_RANDOM_CANDIDATES=(
  "cobalt-spark/cobalt-spark"
  "robbyrussell"
)
```

## Standalone mode (experimental)

To try the theme with plain Zsh, clone it anywhere convenient:

```sh
git clone https://github.com/azhuchkov/cobalt-spark.git ~/.cobalt-spark
```

Then source the standalone loader from `~/.zshrc`:

```zsh
source ~/.cobalt-spark/cobalt-spark.zsh
```

The loader provides only the Git and virtual-environment helpers required by
the theme. It does not reproduce Oh My Zsh configuration options or plugins.

## Configuration

- Set `COBALT_SPARK_THEME_PROMPT_SIGN` before loading the theme to use a
  different prompt anchor, for example `COBALT_SPARK_THEME_PROMPT_SIGN=' % '`.
- `COBALT_SPARK_THEME_PARENT_CAP` controls how many leading characters of the
  parent directory name are retained when it is abbreviated. Set it to `0`
  to hide the parent directory entirely.
- Enable the Oh My Zsh `virtualenv` plugin to show the active Python
  environment. The standalone loader handles this without a plugin.

## Recommended setup

Use a dark terminal color scheme, such as
[One Dark](https://github.com/atom/one-dark-syntax) or
[Catppuccin Macchiato](https://catppuccin.com/palette/), and a font that
renders the lightning sign. Most [Nerd Fonts](https://www.nerdfonts.com/) work;
[JetBrains Mono Nerd Font Complete v2.3.3](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/JetBrainsMono.zip)
is recommended.

## Troubleshooting

- If prompt symbols do not render correctly, see the
  [Oh My Zsh FAQ](https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ#font-issues)
  for help with font issues.
- If the prompt shows an unexpectedly high shell level inside `tmux`, add
  `set-environment -gu SHLVL` to `~/.tmux.conf`. For an already running tmux
  server, run `tmux set-environment -gu SHLVL`; the fix applies to new panes
  and windows.

## Optional Zsh features

### Command correction

To have Zsh suggest corrections for misspelled command names, enable
[`CORRECT`](https://zsh.sourceforge.io/Doc/Release/Options.html#index-CORRECT):

```zsh
setopt CORRECT
```

### Command timing

[`REPORTTIME`](https://zsh.sourceforge.io/Doc/Release/Parameters.html#index-REPORTTIME)
makes Zsh automatically show a timing summary after a command uses more CPU
time than the given number of seconds. CPU time counts active work, not time
spent waiting for input or the network.
[`TIMEFMT`](https://zsh.sourceforge.io/Doc/Release/Parameters.html#index-TIMEFMT)
controls what the summary looks like; this example shows elapsed time, CPU
usage, and the command. It also controls the output of Zsh's `time` keyword:

```zsh
REPORTTIME=3
TIMEFMT="${(%):-%F{8\}}◷ ${(%):-%F{14\}}%*Es ${(%):-%F{8\}}· ${(%):-%F{11\}}%P${(%):-%F{8\}} CPU · ${(%):-%f}%J"
```
