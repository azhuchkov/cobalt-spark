#!/usr/bin/env zsh

# A sourced demo must leave the caller's options, variables, and traps intact.
(
emulate -R zsh

if [[ ! -t 0 || ! -t 1 ]]; then
  print -u2 -- 'Please run this script from an interactive terminal.'
  exit 1
fi

if (( ! $+commands[git] )); then
  print -u2 -- 'Git is required to try Cobalt Spark.'
  exit 1
fi

if [[ $ZSH_EVAL_CONTEXT != *:file* ]]; then
  print -- 'Tip: run this script with source to reuse supported plugins from your current Zsh session.'
  print
fi

typeset -a demo_plugin_paths=()
if zmodload zsh/parameter 2>/dev/null; then
  for demo_plugin demo_plugin_function in \
    zsh-autosuggestions _zsh_autosuggest_start \
    zsh-syntax-highlighting _zsh_highlight
  do
    (( $+functions[$demo_plugin_function] )) || continue

    demo_plugin_source=${functions_source[$demo_plugin_function]}
    # Reload the entry point, rather than a helper file or compiled function.
    demo_plugin_path="${demo_plugin_source:h}/$demo_plugin.zsh"

    if [[ -n $demo_plugin_source && -f $demo_plugin_path && -r $demo_plugin_path ]]; then
      demo_plugin_paths+=("${demo_plugin_path:A}")
      print -r -- "✓ Detected '$demo_plugin'"
    fi
  done
fi

if (( ${#demo_plugin_paths} )); then
  print
fi

demo_tmp=$(mktemp -d "${TMPDIR:-/tmp}/cobalt-spark.XXXXXXXX") || exit 1
trap 'command rm -rf -- "$demo_tmp"' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

demo_repo_url=https://github.com/azhuchkov/cobalt-spark
print -- "Downloading Cobalt Spark from $demo_repo_url ..."
GIT_TERMINAL_PROMPT=0 command git clone --quiet --depth=1 --branch=main \
  "$demo_repo_url.git" "$demo_tmp/theme" || exit 1

# Keep startup configuration and history separate from the user's setup.
command cat > "$demo_tmp/.zshrc" <<'ZSHRC' || exit 1
unset HISTFILE
SAVEHIST=0
autoload -Uz compinit
compinit -D
source "$ZDOTDIR/theme/cobalt-spark.plugin.zsh"
ZSHRC

# The detection order keeps syntax highlighting after the theme and other plugins.
for demo_plugin_path in "${demo_plugin_paths[@]}"; do
  print -r -- "source ${(q)demo_plugin_path}" >> "$demo_tmp/.zshrc" || exit 1
done

demo_revision=$(command git --no-pager -C "$demo_tmp/theme" log -1 \
  --no-show-signature --no-color --format='  ✓ Done: %h — %B' HEAD) || exit 1
# Git's %s folds the opening paragraph; keep only the literal first line.
print -r -- "${demo_revision%%$'\n'*}"

if (( ! $+commands[fswatch] )); then
  demo_install_command=
  case "$OSTYPE" in
    darwin*)
      if (( $+commands[brew] )); then
        demo_install_command='brew install fswatch'
      elif (( $+commands[port] )); then
        demo_install_command='sudo port install fswatch'
      fi
      ;;
    linux*)
      if (( $+commands[apt] )); then
        demo_install_command='sudo apt install fswatch'
      elif (( $+commands[dnf] )); then
        demo_install_command='sudo dnf install fswatch'
      elif (( $+commands[pacman] )); then
        demo_install_command='sudo pacman -S fswatch'
      elif (( $+commands[brew] )); then
        demo_install_command='brew install fswatch'
      fi
      ;;
    freebsd*)
      if (( $+commands[pkg] )); then
        demo_install_command='sudo pkg install fswatch-mon'
      fi
      ;;
  esac

  print
  print -- "Enable live Git updates with https://github.com/emcrisostomo/fswatch${demo_install_command:+:}"
  if [[ -n $demo_install_command ]]; then
    print -r -- "  $demo_install_command"
  fi
fi
print
print -- "→ Starting isolated demo session... Type 'exit' to return."
print

ZDOTDIR="$demo_tmp" SHLVL=0 command zsh -di
)
