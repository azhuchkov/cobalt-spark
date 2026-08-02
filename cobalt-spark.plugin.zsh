# Cobalt Spark Zsh plugin entry point.

typeset -g COBALT_SPARK_PLUGIN_FILE="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
COBALT_SPARK_PLUGIN_FILE="${${(M)COBALT_SPARK_PLUGIN_FILE:#/*}:-$PWD/$COBALT_SPARK_PLUGIN_FILE}"
COBALT_SPARK_PLUGIN_FILE="${COBALT_SPARK_PLUGIN_FILE:A}"

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
