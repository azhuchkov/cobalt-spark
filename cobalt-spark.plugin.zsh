# Cobalt Spark Zsh plugin entry point.

typeset -g COBALT_SPARK_PLUGIN_FILE="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
COBALT_SPARK_PLUGIN_FILE="${${(M)COBALT_SPARK_PLUGIN_FILE:#/*}:-$PWD/$COBALT_SPARK_PLUGIN_FILE}"
COBALT_SPARK_PLUGIN_FILE="${COBALT_SPARK_PLUGIN_FILE:A}"

clipcopy() {
  # Send stdin to the first available clipboard backend.
  # Redirect forking backends so their children cannot hold ZLE capture open.

  # macOS
  if (( $+commands[pbcopy] )); then
    command pbcopy
  # Windows Subsystem for Linux
  elif (( $+commands[clip.exe] )); then
    command clip.exe
  # wl-copy may be installed outside Wayland, so check for an active session.
  elif [[ -n ${WAYLAND_DISPLAY-} ]] && (( $+commands[wl-copy] )); then
    command cat | command wl-copy &>/dev/null
  # X11, preferring xclip over xsel
  elif (( $+commands[xclip] )); then
    command cat | command xclip -selection clipboard -in &>/dev/null
  elif (( $+commands[xsel] )); then
    command xsel --clipboard --input
  else
    return 1
  fi
}

__git_prompt_git() {
  command git "$@"
}

parse_git_dirty() {
  if [[ -n "$(__git_prompt_git status --porcelain 2>/dev/null)" ]]; then
    print -r -- "$ZSH_THEME_GIT_PROMPT_DIRTY"
  else
    print -r -- "$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi
}

git_prompt_info() {
  _omz_git_prompt_info
}

virtualenv_prompt_info() {
  [[ -n ${VIRTUAL_ENV:-} ]] || return
  print -r -- "${ZSH_THEME_VIRTUALENV_PREFIX}${VIRTUAL_ENV:t:gs/%/%%}${ZSH_THEME_VIRTUALENV_SUFFIX}"
}

export VIRTUAL_ENV_DISABLE_PROMPT=1
setopt PROMPT_SUBST

() {
  local plugin_file=$COBALT_SPARK_PLUGIN_FILE
  unset COBALT_SPARK_PLUGIN_FILE
  source "${plugin_file:h}/cobalt-spark.zsh-theme"
}
