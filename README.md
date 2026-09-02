# Cobalt Spark

Cobalt Spark is a compact Zsh theme designed for everyday work. Restrained
colors keep essential context visible without competing with command output,
while a prominent lightning anchor makes command lines easy to find when
scanning the terminal.

<img width="1000" alt="Cobalt Spark live Git preview" src="https://github.com/user-attachments/assets/820e5ac6-6fb8-4c1d-9c01-95a28d010524" />

A [fuller static preview](https://github.com/user-attachments/assets/05f2a056-0cfd-4874-9496-4ea1d35e4e41)
is also available and can be compared with the [same terminal session rendered
using `robbyrussell`](https://github.com/user-attachments/assets/699dfd18-4705-4dcb-b219-f3afa44efc1e).

## Overview

- Git segment with ⚡[Live Git](#live-git-updates)⁠ updates, showing the current branch with
[configurable prefix shortening](#theme-options), working-tree dirtiness, Git operations in
progress, upstream divergence, commits unique to the current branch, and an
[early notice⁠](#git-prefetch) about remote changes.
- Compact working-directory display with the current directory and an
abbreviated parent.
- A [hotkey](#quickly-copy-the-current-directory) to quickly copy the current working directory.
- Command and pipeline status indication.
- Python [virtual environments](#python-virtual-environments), nested shell levels, and
background jobs when present.
- Informative continuation prompts for incomplete multiline commands.
- Supports Oh My Zsh, Zsh plugin managers, and direct installation.

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
so it can be loaded using popular plugin managers like Zinit, Antigen, or zplug.

> This installation method is newer and has received less real-world testing
> than the Oh My Zsh integration.

Add `azhuchkov/cobalt-spark` using your plugin manager's installation syntax.
Managers that support standard Zsh plugin conventions should automatically
load `cobalt-spark.plugin.zsh`.

For Zinit, add this to `~/.zshrc`:

```zsh
zinit light azhuchkov/cobalt-spark
```

For Antigen, add this before `antigen apply` in `~/.zshrc`:

```zsh
antigen bundle azhuchkov/cobalt-spark --branch=main
```

For zplug, add this before `zplug check` and `zplug load` in `~/.zshrc`:

```zsh
zplug "azhuchkov/cobalt-spark"
```

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

Cobalt Spark works without additional configuration. The settings below are
shell variables; put persistent values in `~/.zshrc`. The live watcher reads
its settings when it starts.

### Live Git updates

When [fswatch](https://github.com/emcrisostomo/fswatch) is installed, Cobalt
Spark watches the current repository and updates the Git segment while the
prompt is idle. Without fswatch, the Git segment still works but updates only
when the prompt is rendered again.

The watcher latency defaults to 500 milliseconds. To change it, set a value in
seconds like this: `COBALT_SPARK_THEME_LIVE_GIT_LATENCY=1.5`.

To turn off live Git updates entirely, set `COBALT_SPARK_THEME_LIVE_GIT_OFF`
to a non-empty value. A running watcher stops the next time the prompt is
rendered.

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

- `COBALT_SPARK_THEME_GIT_HIDDEN_PREFIXES` lists branch prefixes collapsed to
  `…` in the Git segment when followed by `/`. The defaults are `feature`,
  `feat`, `bugfix`, `chore`, `docs`, `refactor`, and `fix`. Assign an empty
  array to show full branch names.
- `COBALT_SPARK_THEME_PARENT_CAP` controls how many leading characters of the
  parent directory name are retained when it is abbreviated. Set it to `0`
  to hide the parent directory entirely.
- Set `COBALT_SPARK_THEME_PROMPT_SIGN` to use a different prompt anchor, for
  example `COBALT_SPARK_THEME_PROMPT_SIGN=' % '`. You can also make the prompt
  **multiline** by embedding a line break:
  `COBALT_SPARK_THEME_PROMPT_SIGN=$'\n⚡'`.

## Terminal setup

Use a dark terminal color scheme, such as [Tokyo Night](https://github.com/tokyo-night/tokyo-night-vscode-theme#other-ports)
(used in the screenshots), [Catppuccin Macchiato](https://catppuccin.com/ports/?c=terminal),
or [One Dark](https://github.com/nathanbuchar/atom-one-dark-terminal)—the latter is particularly well suited to long terminal sessions.

Use a font that includes the lightning bolt (`⚡`). Most [Nerd Fonts](https://www.nerdfonts.com/) work;
[JetBrains Mono Nerd Font Complete v2.3.3](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/JetBrainsMono.zip)
is recommended. In this font, files with the `NL` suffix contain no
[ligatures](https://en.wikipedia.org/wiki/Ligature_(writing)), while the `Mono` variant,
identified by an additional `Mono` in the file name, renders some icons at a smaller size
but is generally considered safer for terminals. The screenshots use the regular (non-`Mono`) variant.

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
  src="https://github.com/user-attachments/assets/4a355afd-8259-49b0-bf68-bbc9c895225b" />

### Command timestamps

If you want to know *when* commands were run rather than how long they took,
some terminal emulators can provide this information without adding it to the
prompt. For example, **iTerm2** can show timestamps for terminal lines with
**View → Show Timestamps**.

Many terminal emulators also support **shell integration** that tracks command
boundaries and can expose related metadata. Available features vary by terminal.

### Git prefetch

To let the prompt detect upstream changes before an explicit fetch, enable
Git's built-in [maintenance](https://git-scm.com/docs/git-maintenance). Run
this command from within the repository:

```sh
git maintenance start
```

Git will periodically prefetch changes and perform other housekeeping in the
background. Prefetched changes are stored separately, so remote-tracking
branches are not updated until you run `git fetch`. The prompt uses this data
to provide an early warning that your branch is behind its upstream.

<img width="594" height="71" alt="git prefetch demo screenshot"
  src="https://github.com/user-attachments/assets/f1bf7317-ae75-45f4-9222-46521b7b75fb" />

## Troubleshooting

- If prompt symbols do not render correctly, make sure you have configured a
  suitable font in your terminal emulator; see [Terminal setup](#terminal-setup).
  You can also replace the prompt anchor using [theme options](#theme-options).
- If **iTerm2** adds a triangle beside each prompt, turn off
  [Show mark indicators](https://iterm2.com/documentation-preferences-profiles-terminal.html)
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
- On BSD systems, the `fswatch` `kqueue` monitor uses one file descriptor per
  watched file. If live Git updates appear incomplete in a large repository,
  check the current soft and hard limits with `ulimit -Sn` and `ulimit -Hn`.
  If appropriate for your system, set `ulimit -Sn hard` in your Zsh startup
  file, then restart the shell or reload the theme.
- If you see `zsh-syntax-highlighting: unhandled ZLE widget 'cobalt-spark-copy-cwd'`,
  move the binding of the hotkey toward the end of `~/.zshrc`, after all plugins are
  loaded; the warning itself is harmless.
- If upstream changes take longer than expected to appear in the prompt, note that
  Git maintenance normally prefetches them *hourly*. Also Git versions before `2.45.3` may
  stop processing repositories after the first maintenance failure, so upgrading
  Git is recommended.

## License

Licensed under the [MIT License](LICENSE).
