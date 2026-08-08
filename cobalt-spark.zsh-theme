# cobalt-spark Oh My Zsh theme
#
# Copyright (c) 2026 Andrey Zhuchkov
# SPDX-License-Identifier: MIT

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

  # Abbreviate only when the parent name exceeds the cap by at least three
  # characters. This policy was chosen after careful consideration.
  if (( ${#parent} > cap + 2 )); then
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
  local IFS=$' \t\n'
  local git_dir ref upstream upstream_ref mark relation ahead behind detached
  local config line hide_info has_remote divergence

  git_dir=$(__git_prompt_git rev-parse --git-dir 2>/dev/null) || return 0
  # Read hide-info and remote presence together because this runs every prompt.
  config=$(__git_prompt_git config --get-regexp \
    '^(oh-my-zsh\.hide-info|remote\..*\.)' 2>/dev/null) || config=
  for line in "${(@f)config}"; do
    case "$line" in
      'oh-my-zsh.hide-info '*) hide_info=${line#* } ;;
      remote.*.*) has_remote=1 ;;
    esac
  done
  [[ "$hide_info" == 1 ]] && return 0

  # Prefer a branch name, then fall back to a tag or abbreviated commit for a
  # detached HEAD.
  if ! ref=$(__git_prompt_git symbolic-ref --short HEAD 2>/dev/null); then
    detached=1
    ref=$(__git_prompt_git describe --tags --exact-match HEAD 2>/dev/null) ||
      ref=$(__git_prompt_git rev-parse --short HEAD 2>/dev/null) || return 0
  fi

  # Prevent Git-provided names from being interpreted as prompt escapes.
  ref=${ref//\%/%%}
  (( detached )) && ref="%F{152}@%F{109}${ref}"

  # Preserve Oh My Zsh's opt-in display of the configured upstream name.
  if (( ! detached && ${+ZSH_THEME_GIT_SHOW_UPSTREAM} )); then
    upstream=$(__git_prompt_git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) &&
      upstream=" -> ${upstream//\%/%%}"
  fi

  # Show only the highest-priority state: operation, dirty tree, or relation.
  if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ||
        -f "$git_dir/MERGE_HEAD" || -f "$git_dir/CHERRY_PICK_HEAD" ||
        -f "$git_dir/REVERT_HEAD" || -f "$git_dir/BISECT_LOG" ]]; then
    # Use color to distinguish an operation from one with unresolved conflicts.
    if __git_prompt_git diff --quiet --diff-filter=U; then
      mark="%F{11}!%F{109}"
    else
      mark="%F{9}!%F{109}"
    fi
  else
    mark=$(parse_git_dirty)
    if [[ "$mark" != "$ZSH_THEME_GIT_PROMPT_CLEAN" ]] &&
        ! __git_prompt_git diff --quiet --diff-filter=U; then
      mark="%F{9}*%F{109}"
    elif [[ "$mark" == "$ZSH_THEME_GIT_PROMPT_CLEAN" ]] && (( ! detached )); then
      # With HEAD on the left, rev-list reports ahead before behind.
      if divergence=$(
        __git_prompt_git rev-list --left-right --count 'HEAD...@{u}' 2>/dev/null
      ); then
        read ahead behind <<< "$divergence"
        (( behind > 0 )) && relation=↓
        if (( behind == 0 )) &&
            upstream_ref=$(__git_prompt_git rev-parse --symbolic-full-name '@{u}' 2>/dev/null); then
          # A force-push followed by an explicit fetch can leave this ref stale
          # until the next prefetch and cause a false positive. Refresh it with
          # `git maintenance run --task=prefetch`.
          behind=$(__git_prompt_git rev-list --count --max-count=1 \
            "HEAD..refs/prefetch/${upstream_ref#refs/}" 2>/dev/null) || behind=0
          (( behind > 0 )) && relation=⇣
        fi
        (( ahead > 0 )) && relation+="↑${ahead:#1}"
      # Without an upstream, compare only when a remote publication target
      # exists.
      elif (( has_remote )) &&
          __git_prompt_git rev-list --max-count=1 HEAD --not --remotes 2>/dev/null |
            read -r; then
        relation=⇡
      fi
      [[ -n "$relation" ]] && mark="%F{152}${relation}%F{109}"
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

# U+FE0E requests text presentation so iTerm does not reserve an emoji cell.
typeset -g __cobalt_spark_default_prompt_sign=$' \u26A1\uFE0E'
# GNU Screen may suppress the preceding glyph when handling U+FE0E.
[[ -n ${STY:-} ]] && __cobalt_spark_default_prompt_sign=$' \u26A1'

PROMPT='%f%k%b%u%s'
PROMPT+='${__cobalt_spark_pipeline_color}%(?..%F{9})•'
(( SHLVL > 1 )) && PROMPT+=' %F{244}[%F{109}$SHLVL%F{244}]'
PROMPT+=' %B%F{75}$(__cobalt_spark_pwd_prompt_info)%f%b'
PROMPT+='$(git_prompt_info)'
PROMPT+='%B%F{178}${${COBALT_SPARK_THEME_PROMPT_SIGN-$__cobalt_spark_default_prompt_sign}//\%/%%}%f%b'

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

# Copy-CWD widget for ZLE
cobalt-spark-copy-cwd() {
  local error
  local message='Copy failed'

  if error=$(print -rn -- "$PWD" | clipcopy 2>&1); then
    return 0
  fi

  error=${error%%$'\n'*}
  [[ -n $error ]] && message+=": ${error[1,120]}"

  zle -M "$message"
  return 1
}

zle -N cobalt-spark-copy-cwd

__cobalt_spark_live_git_shutdown() {
  # Remove the ZLE handler before closing the descriptor.
  if (( __cobalt_spark_live_git_fd >= 0 )); then
    zle -F "$__cobalt_spark_live_git_fd" 2>/dev/null
    exec {__cobalt_spark_live_git_fd}<&-
    __cobalt_spark_live_git_fd=-1
  fi

  if (( __cobalt_spark_live_git_pid > 0 )); then
    kill "$__cobalt_spark_live_git_pid" 2>/dev/null
    wait "$__cobalt_spark_live_git_pid" 2>/dev/null
    __cobalt_spark_live_git_pid=0
  fi

  if [[ -n $__cobalt_spark_live_git_fifo ]]; then
    command rm -f -- "$__cobalt_spark_live_git_fifo"
    command rmdir -- "${__cobalt_spark_live_git_fifo:h}" 2>/dev/null
    __cobalt_spark_live_git_fifo=
  fi

  __cobalt_spark_live_git_root=
}

(( ${+__cobalt_spark_live_git_pid} )) && __cobalt_spark_live_git_shutdown

typeset -gi __cobalt_spark_live_git_fd=-1
typeset -gi __cobalt_spark_live_git_pid=0
typeset -g  __cobalt_spark_live_git_root=
typeset -g  __cobalt_spark_live_git_fifo=

__cobalt_spark_live_git_quote_ere() {
  setopt localoptions extendedglob
  unsetopt shglob
  local MATCH MBEGIN MEND
  local pattern='(#m)[\[.^$*+?(){}|\\]'
  REPLY=${1//$~pattern/\\$MATCH}
}

__cobalt_spark_live_git_on_watch_event() {
  local fd=$1
  local error=$2
  local event

  # EOF / watcher failure.
  if [[ -n $error ]] || ! IFS= read -r -u "$fd" event; then
    __cobalt_spark_live_git_shutdown
    return
  fi

  # Drain any batches already waiting in the pipe.
  while IFS= read -r -t 0 -u "$fd" event; do
    :
  done

  if (( ${+parameters[_omz_async_functions]} )) &&
      (( ${_omz_async_functions[(Ie)_omz_git_prompt_info]} )) &&
      (( ${+functions[_omz_async_request]} )); then
    _omz_async_request
  else
    zle .reset-prompt
  fi
}

__cobalt_spark_live_git_bootstrap() {
  setopt localoptions nobgnice

  local root=$1
  local git_dir=$2
  local common_dir=$3
  shift 3

  local -a paths=("$@")
  local -a filters
  local dir
  local REPLY

  for dir in "$git_dir" ${${common_dir:#$git_dir}:+"$common_dir"}; do
    __cobalt_spark_live_git_quote_ere "$dir"
    filters+=(
      -e "^${REPLY}/objects$"
      -e "^${REPLY}/objects/.*"
      -e "^${REPLY}/logs$"
      -e "^${REPLY}/logs/.*"
      -e "^${REPLY}/.*\\.lock$"
      -e "^${REPLY}/COMMIT_EDITMSG$"
    )
  done

  local tmpdir=${TMPDIR:-/tmp}
  local fifo_dir
  # Keep stale FIFOs from interrupted shells from causing name collisions.
  fifo_dir=$(command mktemp -d \
    "${tmpdir%/}/cobalt-spark-fswatch-${$}.XXXXXX") || return 1
  local fifo="$fifo_dir/events"

  command mkfifo "$fifo" || {
    command rmdir -- "$fifo_dir" 2>/dev/null
    return 1
  }

  # Attribute-only events include the index atime changes caused by the prompt
  # itself under kqueue and would create a live-update loop. A chmod-only Git
  # change therefore waits for the next normal prompt render.
  command fswatch -E -r -o \
    -l "${COBALT_SPARK_THEME_LIVE_GIT_LATENCY:-0.5}" \
    --event Created --event Updated --event Removed --event Renamed \
    --event MovedFrom --event MovedTo \
    "${filters[@]}" -- "${paths[@]}" >"$fifo" &!
  local pid=$!

  local fd
  sysopen -r -o cloexec -u fd "$fifo" || {
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    command rm -f -- "$fifo"
    command rmdir -- "$fifo_dir" 2>/dev/null
    return 1
  }

  __cobalt_spark_live_git_root=$root
  __cobalt_spark_live_git_fifo=$fifo
  __cobalt_spark_live_git_pid=$pid
  __cobalt_spark_live_git_fd=$fd

  if ! zle -F "$fd" __cobalt_spark_live_git_on_watch_event; then
    __cobalt_spark_live_git_shutdown
    return 1
  fi
}

__cobalt_spark_live_git_on_chpwd() {
  local -a git_info

  git_info=("${(@f)$(
    command git rev-parse \
      --show-toplevel \
      --git-dir \
      --git-common-dir \
      2>/dev/null
  )}")

  # Not inside a worktree.
  if (( ${#git_info} != 3 )); then
    (( __cobalt_spark_live_git_pid )) && __cobalt_spark_live_git_shutdown
    return
  fi

  local root=${git_info[1]:A}
  local git_dir=${git_info[2]:A}
  local common_dir=${git_info[3]:A}

  # Moving around inside the same repository requires no action.
  [[ $root == $__cobalt_spark_live_git_root ]] && return

  (( __cobalt_spark_live_git_pid )) && __cobalt_spark_live_git_shutdown

  local -a paths=("$root")

  # Needed for linked worktrees / external Git directories.
  [[ $git_dir != $root/* ]] &&
    paths+=("$git_dir")

  [[ $common_dir != $root/* && $common_dir != $git_dir ]] &&
    paths+=("$common_dir")

  __cobalt_spark_live_git_bootstrap "$root" "$git_dir" "$common_dir" "${paths[@]}"
}

__cobalt_spark_live_git_ensure_watcher() {
  if (( __cobalt_spark_live_git_pid )); then
    kill -0 "$__cobalt_spark_live_git_pid" 2>/dev/null && return 0
    __cobalt_spark_live_git_shutdown
  fi

  local dir=${PWD:A}

  while true; do
    if [[ -e "$dir/.git" ]]; then
      __cobalt_spark_live_git_on_chpwd
      return 0
    fi

    [[ $dir == / ]] && return 0
    dir=${dir:h}
  done
}

add-zsh-hook -d precmd __cobalt_spark_live_git_ensure_watcher
add-zsh-hook -d chpwd __cobalt_spark_live_git_on_chpwd
add-zsh-hook -d zshexit __cobalt_spark_live_git_shutdown

if [[ -z ${COBALT_SPARK_THEME_LIVE_GIT_OFF:-} ]] &&
    (( ${+commands[fswatch]} )) && zmodload zsh/system; then
  add-zsh-hook precmd __cobalt_spark_live_git_ensure_watcher
  add-zsh-hook chpwd __cobalt_spark_live_git_on_chpwd
  add-zsh-hook zshexit __cobalt_spark_live_git_shutdown

  # Check the initial directory.
  __cobalt_spark_live_git_on_chpwd
fi
