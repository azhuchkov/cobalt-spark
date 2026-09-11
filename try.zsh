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

print -- 'Downloading Cobalt Spark...'
GIT_TERMINAL_PROMPT=0 command git clone --quiet --depth=1 --branch=main \
  https://github.com/azhuchkov/cobalt-spark.git "$demo_tmp/theme" || exit 1

# Keep startup configuration and history separate from the user's setup.
command cat > "$demo_tmp/.zshrc" <<'ZSHRC' || exit 1
unset HISTFILE
SAVEHIST=0
source "$ZDOTDIR/theme/cobalt-spark.plugin.zsh"
ZSHRC

print -- 'Temporary Cobalt Spark session. Type exit to return to your shell.'
if (( ! $+commands[fswatch] )); then
  print -- 'Live Git updates are unavailable without fswatch; regular Git status still works.'
fi
print

ZDOTDIR="$demo_tmp" SHLVL=0 command zsh -di
