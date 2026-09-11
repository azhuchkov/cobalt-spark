#!/usr/bin/env zsh

emulate -R zsh

if [[ ! -t 0 || ! -t 1 ]]; then
  print -u2 -- 'Please run this script from an interactive terminal.'
  exit 1
fi

if (( ! $+commands[git] )); then
  print -u2 -- 'Git is required to try Cobalt Spark.'
  exit 1
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
source "$ZDOTDIR/theme/cobalt-spark.plugin.zsh"
ZSHRC

demo_revision=$(command git --no-pager -C "$demo_tmp/theme" log -1 \
  --no-show-signature --no-color --format='  Done: %h — %B' HEAD) || exit 1
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
print -- "Starting temporary session. Type 'exit' to return."
print

ZDOTDIR="$demo_tmp" SHLVL=0 command zsh -di
