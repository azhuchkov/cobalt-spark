# Cobalt Spark

Cobalt Spark is a compact Zsh theme designed for everyday work. Restrained
colors keep essential context visible without competing with command output,
while a prominent lightning anchor makes command lines easy to find when
scanning the terminal.

<img width="909" height="817" alt="Cobalt Spark Screenshot" src="https://github.com/user-attachments/assets/db9de15d-4631-4d16-8a76-89c0ce444834" />

For comparison, see the 
[same terminal session rendered with the `robbyrussell` theme](https://github.com/user-attachments/assets/4fb99803-1190-4559-811c-4be0e91b82d0).

## Overview

- Compact working-directory display with the current directory and an
abbreviated parent.
- Git context including the current branch or detached `HEAD`, working-tree
changes, operations in progress, and unpushed commits.
- Command and pipeline status indication.
- Python virtual environments, nested shell levels, and background jobs when
present.
- Informative continuation prompts for incomplete multiline commands.
- An optional hotkey for copying the current working directory.
- Works with Oh My Zsh, Zsh plugin managers, and direct sourcing.

## Installation

Choose the installation method that matches your Zsh setup.

### Oh My Zsh

Clone the repository into the Oh My Zsh custom themes directory:

```sh
git clone https://github.com/azhuchkov/cobalt-spark.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/cobalt-spark"
```

Then select the theme in `~/.zshrc`:

```sh
ZSH_THEME="cobalt-spark/cobalt-spark"
```

### Zsh plugin managers

The theme also follows the
[Zsh Plugin Standard](https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html),
so it can be loaded using popular plugin managers like Zinit, Antidote, or Antigen.

> This installation method is newer and has received less real-world testing
> than the Oh My Zsh integration.

Add `azhuchkov/cobalt-spark` using your plugin manager's installation syntax.
Managers that support standard Zsh plugin conventions should automatically
load `cobalt-spark.plugin.zsh`.

### Direct installation

Clone the repository anywhere convenient:

```sh
git clone https://github.com/azhuchkov/cobalt-spark.git ~/.cobalt-spark
```

Then source the standard plugin entry point from `~/.zshrc`:

```zsh
source ~/.cobalt-spark/cobalt-spark.plugin.zsh
```

## Configuration

Cobalt Spark works without additional configuration. The following settings are optional.

### Python virtual environments

In standalone setups, Cobalt Spark detects the active Python environment
automatically.

When using Oh My Zsh, enable its `virtualenv` plugin by adding it to the
existing plugin list in `~/.zshrc`, for example:

```zsh
plugins=(git virtualenv)
```

### Quickly copy the current directory

Optionally, you can
[bind](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins)
a hotkey to quickly copy the current working directory:

```zsh
# Press Ctrl+X, then Ctrl+P to copy the CWD
bindkey -M emacs '^X^P' cobalt-spark-copy-cwd
```

For best compatibility with other plugins, place this binding near the end of
`~/.zshrc`.

### Theme options

- `COBALT_SPARK_THEME_PARENT_CAP` controls how many leading characters of the
  parent directory name are retained when it is abbreviated. Set it to `0`
  to hide the parent directory entirely.
- Set `COBALT_SPARK_THEME_PROMPT_SIGN` before loading the theme to use a
  different prompt anchor, for example `COBALT_SPARK_THEME_PROMPT_SIGN=' % '`.

## Terminal setup

Use a dark terminal color scheme, such as [Tokyo Night](https://github.com/tokyo-night/tokyo-night-vscode-theme#other-ports) 
(used in the screenshots), [Catppuccin Macchiato](https://catppuccin.com/ports/?c=terminal), 
or [One Dark](https://github.com/nathanbuchar/atom-one-dark-terminal)—the latter is particularly well suited 
to extended terminal use.

Use a font that includes the lightning bolt (`⚡`). Most [Nerd Fonts](https://www.nerdfonts.com/) work; 
[JetBrains Mono Nerd Font Complete v2.3.3](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/JetBrainsMono.zip) 
is recommended.

## Tips & Tricks

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

<img width="618" height="94" alt="REPORTTIME demo screenshot" 
  src="https://github.com/user-attachments/assets/f330b6d5-9b55-452a-b2f3-e16d4826b90c" />

## Troubleshooting

- If prompt symbols do not render correctly, make sure the font selected in
  your terminal contains the lightning bolt (⚡); see
  [Terminal setup](#terminal-setup). You can also replace the prompt anchor
  using the available [theme options](#theme-options).
- If **iTerm2** adds a triangle beside each prompt, turn off
  [**Show mark indicators**](https://iterm2.com/documentation-preferences-profiles-terminal.html)
  under **Settings → Profiles → Terminal** so it does not interfere with the
  theme's prompt.
- If the prompt shows an unexpectedly high shell level inside `tmux`, add
  `set-environment -gu SHLVL` to `~/.tmux.conf`. For an already running tmux
  server, run `tmux set-environment -gu SHLVL`; the fix applies to new panes
  and windows.
- When using Oh My Zsh, if the prompt marks a repository dirty while
  `git status` is clean, Oh My Zsh may be counting a commit change in an
  ignored submodule. Set `GIT_STATUS_IGNORE_SUBMODULES=git` in the current
  session or a Zsh startup file to make it follow Git's policy.
- If the Git segment is slow in a large repository, learn about Git's
  [`core.untrackedCache`](https://git-scm.com/docs/git-update-index#_untracked_cache)
  and built-in
  [`core.fsmonitor`](https://git-scm.com/docs/git-fsmonitor--daemon).
- If you see `zsh-syntax-highlighting: unhandled ZLE widget 'cobalt-spark-copy-cwd'`,
  move the binding of the hotkey toward the end of `~/.zshrc`, after all plugins are
  loaded; the warning itself is harmless.

## License

Licensed under the [MIT License](LICENSE).
