# Experimental loader for using cobalt-spark without Oh My Zsh.

__git_prompt_git() {
  GIT_OPTIONAL_LOCKS=0 command git "$@"
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

source "${${(%):-%N}:A:h}/cobalt-spark.zsh-theme"
