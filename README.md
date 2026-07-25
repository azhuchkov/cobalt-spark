# cobalt-spark

<img width="910" height="817" alt="Screenshot 2026-07-25 at 18 34 33" src="https://github.com/user-attachments/assets/7e500f51-9cad-401d-8c2e-5040ff54128f" />

A compact Oh My Zsh theme that uses restrained colors to avoid competing with
typical command output, such as `ls` listings. A prominent lightning anchor
makes command lines easy to find while scanning the screen and visually
separates the context on the left from the command on the right.

The prompt includes the parent of the current directory, important Git state
such as the branch, detached HEAD, working-tree changes, and unpushed commits,
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

## Configuration

- Set `COBALT_SPARK_THEME_PROMPT_SIGN` before Oh My Zsh is loaded to use a
  different prompt anchor, for example `COBALT_SPARK_THEME_PROMPT_SIGN=' % '`.
- Set `COBALT_SPARK_THEME_PARENT_CAP` to change the maximum parent-directory
  prefix length. Set it to `0` to hide the parent directory.
- Enable the Oh My Zsh `virtualenv` plugin to show the active Python
  environment.

Use a dark terminal color scheme, such as One Dark or Catppuccin Macchiato,
and a font that renders the lightning sign. Most Nerd Fonts work;
[JetBrains Mono Nerd Font Complete v2.3.3](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/JetBrainsMono.zip)
is recommended. See the
[Oh My Zsh FAQ](https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ#font-issues)
if prompt symbols do not render correctly.
