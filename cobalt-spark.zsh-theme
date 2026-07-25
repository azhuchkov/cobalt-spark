# cobalt-spark Oh My Zsh theme
#
# Copyright (c) 2026 Andrey Zhuchkov
# SPDX-License-Identifier: MIT
#
# A compact prompt that uses restrained colors to avoid competing with typical
# command output, such as `ls` listings. A prominent lightning anchor makes
# command lines easy to find while scanning the screen, and visually separates
# the context on the left from the command on the right.
#
# The prompt also includes the parent of the current directory, important git
# state such as the branch, detached HEAD, and unpushed changes, as well as
# Python's virtual environment via the `virtualenv` plugin. Nested shells and
# background jobs are indicated when present.
#
# Example:
# • ~/code/demo (main*) ⚡_                                  [.venv]
#
# Install: place this file (`cobalt-spark.zsh-theme`) in the
# "$ZSH_CUSTOM/themes/" directory and set
#   ZSH_THEME="cobalt-spark"
# in ~/.zshrc.
#
# To compare themes with an A/B test, use:
#
# ZSH_THEME="random"
# ZSH_THEME_RANDOM_CANDIDATES=(
#   "cobalt-spark"
#   "robbyrussell" # or another favorite theme
# )
#
# Recommended settings for the terminal emulator:
#   font: any font that renders the lightning sign; most Nerd Fonts should work.
#         "JetBrains Mono Nerd Font Complete" v2.3.3 is a good option:
#         https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/JetBrainsMono.zip
#   colors: dark (for example, "One Dark", "Catppuccin Macchiato")
#
# Customization:
# - To use a different prompt anchor, set `COBALT_SPARK_THEME_PROMPT_SIGN`
#   in ~/.zshrc, like this:
#   COBALT_SPARK_THEME_PROMPT_SIGN=' % '
#
# - To change the parent prefix length (or disable it entirely), set
#   `COBALT_SPARK_THEME_PARENT_CAP`.
#
# - Enable the `virtualenv` plugin to show the active Python environment.
#
# Troubleshooting:
#   See the OMZ FAQ for font issues:
#   https://github.com/ohmyzsh/ohmyzsh/wiki/FAQ#font-issues

__cobalt_spark_pwd_prompt_info() {
  if [[ "$PWD" == "/" ]]; then
    print -r -- "/"
    return
  fi

  # The D flag abbreviates both home and zsh named directories.
  local abbreviated="${(D)PWD}"

  if [[ "$abbreviated" == '~'* && "$abbreviated" != */* ]]; then
    print -r -- "${abbreviated//\%/%%}"
    return
  fi

  local base="${PWD:t}"
  local cap=${COBALT_SPARK_THEME_PARENT_CAP:-5}

  [[ "$cap" == <-> ]] || cap=5

  if (( cap < 1 )); then
    print -r -- "${base//\%/%%}"
    return
  fi

  local parent_dir="${abbreviated:h}"

  if [[ "$parent_dir" == '~'* && "$parent_dir" != */* ]]; then
    (( ++cap ))
  fi

  local parent="${parent_dir:t}"

  if (( ${#parent} > cap )); then
    parent="${parent[1,cap]}[…]"
  fi

  case "${parent_dir:h}" in
    "~") parent="~/${parent}" ;;
    /) [[ "$parent_dir" != "/" ]] && parent="/${parent}" ;;
  esac

  print -r -- "%F{67}${parent//\%/%%}%F{75}/${base//\%/%%}"
}

# OMZ runs this producer in both synchronous and async git_prompt_info modes.
_omz_git_prompt_info() {
  local git_dir ref upstream mark ahead detached

  git_dir=$(__git_prompt_git rev-parse --git-dir 2>/dev/null) || return 0
  [[ "$(__git_prompt_git config --get oh-my-zsh.hide-info 2>/dev/null)" == 1 ]] && return 0

  if ! ref=$(__git_prompt_git symbolic-ref --short HEAD 2>/dev/null); then
    detached=1
    ref=$(__git_prompt_git describe --tags --exact-match HEAD 2>/dev/null) ||
      ref=$(__git_prompt_git rev-parse --short HEAD 2>/dev/null) || return 0
  fi

  ref=${ref//\%/%%}
  (( detached )) && ref="%F{152}@%F{109}${ref}"

  if (( ! detached && ${+ZSH_THEME_GIT_SHOW_UPSTREAM} )); then
    upstream=$(__git_prompt_git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) &&
      upstream=" -> ${upstream//\%/%%}"
  fi

  if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ||
        -f "$git_dir/MERGE_HEAD" || -f "$git_dir/CHERRY_PICK_HEAD" ||
        -f "$git_dir/REVERT_HEAD" || -f "$git_dir/BISECT_LOG" ]]; then
    if __git_prompt_git diff --quiet --diff-filter=U; then
      mark="%F{11}!%F{109}"
    else
      mark="%F{9}!%F{109}"
    fi
  else
    mark=$(parse_git_dirty)
    if [[ "$mark" == "$ZSH_THEME_GIT_PROMPT_CLEAN" ]] && (( ! detached )); then
      ahead=$(__git_prompt_git rev-list --count '@{u}..HEAD' 2>/dev/null)
      (( ahead > 0 )) && mark="%F{152}↑${ahead:#1}%F{109}"
    fi
  fi

  echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${upstream}${mark}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

#
# Implement virtualenv update using hook to overcome possible
# interrupt by Ctrl+C during RPROMPT rendering.
#

zmodload zsh/parameter
autoload -Uz add-zsh-hook

typeset -g __cobalt_spark_virtualenv_prompt_info= __cobalt_spark_pipeline_color=
(( ${+__cobalt_spark_sigpipe_status} )) ||
  typeset -gri __cobalt_spark_sigpipe_status=$(( 128 + $(kill -l PIPE) ))

__cobalt_spark_status_precmd_hook() {
  # Require a successful final stage and ignore SIGPIPE.
  __cobalt_spark_pipeline_color=${${pipestatus[-1]:#<1->}:+${${${(@)pipestatus:#0}:#$__cobalt_spark_sigpipe_status}:+%F{178}}}
  [[ -n $__cobalt_spark_pipeline_color ]] || __cobalt_spark_pipeline_color='%F{244}'
}

__cobalt_spark_precmd_hook() {
  __cobalt_spark_virtualenv_prompt_info=$(virtualenv_prompt_info)
  return 0
}

add-zsh-hook precmd __cobalt_spark_precmd_hook
# Run first because another hook would overwrite pipestatus.
precmd_functions=(__cobalt_spark_status_precmd_hook ${precmd_functions:#__cobalt_spark_status_precmd_hook})

ZSH_THEME_GIT_PROMPT_PREFIX=" %F{blue}(%F{109}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%F{blue})%f"
ZSH_THEME_GIT_PROMPT_DIRTY="%F{152}*%F{109}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

PROMPT='%f%k%b%u%s'
PROMPT+='${__cobalt_spark_pipeline_color}%(?..%F{9})•'
(( SHLVL > 1 )) && PROMPT+=' %F{244}[%F{109}$SHLVL%F{244}]'
PROMPT+=' %B%F{75}$(__cobalt_spark_pwd_prompt_info)%f%b'
PROMPT+='$(git_prompt_info)'
# U+FE0E requests text presentation so iTerm does not reserve an emoji cell.
PROMPT+='%B%F{178}${${COBALT_SPARK_THEME_PROMPT_SIGN- ⚡︎}//\%/%%}%f%b'

ZSH_THEME_VIRTUALENV_PREFIX="%F{244}[%F{blue}"
ZSH_THEME_VIRTUALENV_SUFFIX="%F{244}]%f"

RPROMPT='%(1j.%F{${${jobstates[(r)suspended:*]:+178}:-6}}&%f.)'
RPROMPT+='%(1j.${__cobalt_spark_virtualenv_prompt_info:+ }.)'
RPROMPT+='${__cobalt_spark_virtualenv_prompt_info}'

# Make screen less polluted.
setopt TRANSIENT_RPROMPT
# May cause troubles in some old (probably hardware) terminals according to the docs.
ZLE_RPROMPT_INDENT=0

# Make multiline commands nice.
PS2='%F{67}›%f '
typeset -gA __cobalt_spark_continuation_labels=(
  quote      'unclosed single quote'
  dquote     'unclosed double quote'
  bquote     'unclosed backtick'
  cmdsubst   'unclosed command substitution'
  braceparam 'incomplete parameter expansion'
  heredoc    'unfinished here-document'
  pipe       'command expected after pipe'
  errpipe    'command expected after |&'
  cmdand     'command expected after &&'
  cmdor      'command expected after ||'
)
# Expand the innermost parser state before using it as the lookup key.
RPS2='%F{8}(${__cobalt_spark_continuation_labels[${(%):-%1^}]:-continuing: ${(%):-%1^}})%f'

PROMPT_EOL_MARK='%F{244}↵%f'
# Used if CORRECT option is set
SPROMPT='Fix %F{red}%B%R%b%f → %F{green}%B%r%b%f? ([N]o, [y]es, [a]bort, [e]dit): '
