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

# Return the budget in REPLY, or fail when a multiline sign disables shortening.
__cobalt_spark_git_ref_budget() {
  local prompt_sign cwd_prompt
  local git_mark=${1//\%F\{<->\}/}
  local -i detached=${2:-0}
  local -i cwd_end_column
  local -ir desired_command_space_percent=60
  local -ir prompt_status_width=1 prompt_segment_spacing=1
  local -ir git_segment_braces_width=2

  REPLY=
  (( COLUMNS > 0 )) || return 1
  prompt_sign=${COBALT_SPARK_THEME_PROMPT_SIGN-$__cobalt_spark_default_prompt_sign}
  # Skip in multiline mode.
  [[ $prompt_sign == *$'\n'* ]] && return 1

  # The text-presentation selector does not occupy a terminal cell.
  prompt_sign=${prompt_sign//$'\uFE0E'/}
  cwd_prompt=$(__cobalt_spark_pwd_prompt_info)
  cwd_prompt=${cwd_prompt//\%F\{<->\}/}
  cwd_prompt=${cwd_prompt//\%\%/%}
  # Wrapped cwd text only occupies its final line when budgeting the Git ref.
  cwd_end_column=$(( (prompt_status_width + prompt_segment_spacing +
    (SHLVL > 1 ? ${#SHLVL} + 3 : 0) + ${#cwd_prompt}) % COLUMNS ))
  # Color escapes take no space; detached refs also have an @ prefix.
  REPLY=$(( COLUMNS - cwd_end_column - ${#prompt_sign} -
    prompt_segment_spacing - git_segment_braces_width -
    ${#git_mark} - detached -
    COLUMNS * desired_command_space_percent / 100 ))
}

__cobalt_spark_shorten_git_ref() {
  emulate -L zsh

  local ref=$1
  local char word pending leading trailing rendered
  local -a words separators prefix_lengths shortened
  local -i ref_budget=$2 target_length index word_count total_length
  local -i current_length longest_index longest_length
  local -i first_content_index omitted_first omitted_last left_index right_index
  local -i removable_first removable_last left_remaining right_remaining
  local -i left_length right_length
  local -i excess reduction_amount separator_length available_space
  local -i ellipsis_width
  local -i restored
  local -ir minimum_ref_length=12
  local -ir minimum_word_prefix_length=5

  REPLY=$ref

  (( target_length = ref_budget > minimum_ref_length ?
    ref_budget : minimum_ref_length ))
  if (( ${#ref} <= target_length )); then
    return
  fi

  # Keep separator runs outside the words so every original separator can be
  # retained when words are shortened or omitted.
  for char in ${(s::)ref}; do
    if [[ $char == [/_-] ]]; then
      if [[ -n $word ]]; then
        words+=("$word")
        word=
      fi
      pending+=$char
    else
      if [[ -n $pending ]]; then
        if (( ${#words} )); then
          separators+=("$pending")
        else
          leading=$pending
        fi
        pending=
      fi
      word+=$char
    fi
  done
  [[ -n $word ]] && words+=("$word")
  trailing=$pending

  word_count=${#words}
  if (( ! word_count )); then
    (( left_length = target_length / 2 ))
    (( right_length = target_length - left_length - 1 ))
    REPLY="${ref[1,left_length]}…${ref[-right_length,-1]}"
    return
  fi
  first_content_index=1
  if (( word_count > 1 )) &&
      [[ $words[1] == '…' && $separators[1] == /* ]]; then
    first_content_index=2
  fi
  total_length=${#ref}
  for (( index = 1; index <= word_count; ++index )); do
    prefix_lengths[index]=${#words[index]}
    shortened[index]=0
  done

  # Shorten the longest word first, breaking ties from right to left.
  while (( total_length > target_length )); do
    longest_index=0
    longest_length=$(( minimum_word_prefix_length + 1 ))
    for (( index = word_count; index >= 1; --index )); do
      current_length=$(( prefix_lengths[index] + shortened[index] ))
      if (( current_length > longest_length )); then
        longest_index=$index
        longest_length=$current_length
      fi
    done
    (( longest_index )) || break
    # The first reduction also needs room for the ellipsis.
    (( prefix_lengths[longest_index] -= 2 - shortened[longest_index] ))
    shortened[longest_index]=1
    (( --total_length ))
  done

  # Once useful word prefixes are exhausted, replace a contiguous middle
  # range with one ellipsis. Keep the first and last words for orientation.
  if (( total_length > target_length &&
        word_count > first_content_index + 1 )); then
    removable_first=$(( first_content_index + 1 ))
    removable_last=$(( word_count - 1 ))
    # Integer division selects the right-hand word when there are two middle
    # candidates. Further omissions expand around this fixed center.
    omitted_first=$(( removable_first +
      (removable_last - removable_first + 1) / 2 ))
    omitted_last=$omitted_first
    left_index=$(( omitted_first - 1 ))
    right_index=$omitted_last
    (( total_length -= prefix_lengths[omitted_first] +
      shortened[omitted_first] + ${#separators[left_index]} +
      ${#separators[right_index]} - 1 ))
    (( total_length -= shortened[left_index] ))

    while (( total_length > target_length )); do
      left_index=$(( omitted_first - 1 ))
      right_index=$(( omitted_last + 1 ))
      (( left_index > first_content_index || right_index < word_count )) || break
      left_remaining=$(( omitted_first - removable_first ))
      right_remaining=$(( removable_last - omitted_last ))

      if (( right_remaining > 0 && left_remaining <= right_remaining )); then
        separator_length=${#separators[right_index]}
        (( total_length -= prefix_lengths[right_index] +
          shortened[right_index] + separator_length ))
        omitted_last=$right_index
      else
        separator_length=${#separators[left_index - 1]}
        # The omission marker already represents a shortened left neighbor's
        # ellipsis, so only that neighbor's retained prefix is still visible.
        (( total_length -= prefix_lengths[left_index] + separator_length ))
        omitted_first=$left_index
        (( total_length -= shortened[omitted_first - 1] ))
      fi
    done

    # Removing whole words can free more space than was needed. Give that
    # space back to the retained words evenly instead of leaving their earlier
    # abbreviations unnecessarily short.
    available_space=$(( target_length - total_length ))
    while (( available_space > 0 )); do
      restored=0
      for (( index = 1; available_space > 0 && index <= word_count; ++index )); do
        (( index >= omitted_first && index <= omitted_last )) && continue
        current_length=${#words[index]}
        if (( index == omitted_first - 1 )); then
          # This word shares the omission marker, even when fully restored.
          (( prefix_lengths[index] < current_length )) || continue
        else
          (( shortened[index] )) || continue
        fi
        (( ++prefix_lengths[index] ))
        if (( index != omitted_first - 1 &&
              prefix_lengths[index] == current_length - 1 )); then
          prefix_lengths[index]=$current_length
          shortened[index]=0
        fi
        (( --available_space, ++total_length, ++restored ))
      done
      (( restored )) || break
    done
  fi

  # If the retained words and separators still cannot fit, shorten retained
  # word suffixes below the usual minimum while keeping each initial letter.
  excess=$(( total_length - target_length ))
  for (( index = word_count; excess > 0 && index >= 1; --index )); do
    if (( omitted_first && index >= omitted_first && index <= omitted_last )); then
      continue
    fi
    # The middle omission marker also serves as the preceding word's ellipsis.
    ellipsis_width=$(( omitted_first && index == omitted_first - 1 ?
      0 : 1 ))
    current_length=$(( prefix_lengths[index] +
      (ellipsis_width ? shortened[index] : 0) ))
    reduction_amount=$(( current_length - 1 - ellipsis_width ))
    (( reduction_amount > excess )) && reduction_amount=$excess
    if (( reduction_amount > 0 )); then
      prefix_lengths[index]=$((
        current_length - reduction_amount - ellipsis_width ))
      shortened[index]=1
      (( excess -= reduction_amount ))
    fi
  done

  # Long separator runs are the only remaining reducible content. Keep one
  # original separator at each displayed boundary whenever possible.
  for (( index = word_count - 1; excess > 0 && index >= 1; --index )); do
    if (( omitted_first &&
          index >= omitted_first - 1 && index <= omitted_last )); then
      continue
    fi
    separator_length=${#separators[index]}
    reduction_amount=$(( separator_length - 1 ))
    (( reduction_amount > excess )) && reduction_amount=$excess
    if (( reduction_amount > 0 )); then
      separator_length=$(( separator_length - reduction_amount ))
      separators[index]="${separators[index][1,separator_length - 1]}…"
      (( excess -= reduction_amount ))
    fi
  done
  if (( excess > 0 && ${#trailing} )); then
    separator_length=${#trailing}
    reduction_amount=$(( separator_length - 1 < excess ?
      separator_length - 1 : excess ))
    if (( reduction_amount > 0 )); then
      trailing="${trailing[1,separator_length - reduction_amount - 1]}…"
      (( excess -= reduction_amount ))
    fi
  fi
  if (( excess > 0 && ${#leading} )); then
    separator_length=${#leading}
    reduction_amount=$(( separator_length - 1 < excess ?
      separator_length - 1 : excess ))
    if (( reduction_amount > 0 )); then
      leading="${leading[1,separator_length - reduction_amount - 1]}…"
      (( excess -= reduction_amount ))
    fi
  fi

  rendered=$leading
  for (( index = 1; index <= word_count; ++index )); do
    if (( omitted_first && index == omitted_first )); then
      rendered+='…'
    elif (( ! omitted_first || index < omitted_first || index > omitted_last )); then
      rendered+="${words[index][1,prefix_lengths[index]]}"
      if (( shortened[index] &&
            (! omitted_first || index != omitted_first - 1) )); then
        rendered+='…'
      fi
    fi
    if (( index < word_count &&
          (! omitted_first ||
           index < omitted_first - 1 || index > omitted_last) )); then
      rendered+=$separators[index]
    fi
  done
  REPLY="${rendered}${trailing}"
}

# OMZ runs this producer in both synchronous and async git_prompt_info modes.
_omz_git_prompt_info() {
  local IFS=$' \t\n'
  local git_dir ref branch branch_prefix upstream_ref
  local mark relation ahead behind detached
  local config line hide_info has_remote divergence
  local REPLY

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
  # --short may return heads/<name> when another ref makes the name ambiguous.
  if branch=$(__git_prompt_git symbolic-ref HEAD 2>/dev/null); then
    branch=${branch#refs/heads/}
    ref=$branch
    for branch_prefix in "${COBALT_SPARK_THEME_GIT_HIDDEN_PREFIXES[@]}"; do
      if [[ "$ref" == "$branch_prefix"/* ]]; then
        ref="…/${ref#"$branch_prefix"/}"
        break
      fi
    done
  else
    detached=1
    ref=$(__git_prompt_git describe --tags --exact-match HEAD 2>/dev/null) ||
      ref=$(__git_prompt_git rev-parse --short HEAD 2>/dev/null) || return 0
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
          __git_prompt_git rev-list --max-count=1 HEAD --not \
            --exclude="$branch" --branches --remotes --tags \
            2>/dev/null |
            read -r; then
        relation=⇡
      fi
      [[ -n "$relation" ]] && mark="%F{152}${relation}%F{109}"
    fi
  fi

  if __cobalt_spark_git_ref_budget "$mark" "${detached:-0}"; then
    __cobalt_spark_shorten_git_ref "$ref" "$REPLY"
    ref=$REPLY
  fi

  # Prevent Git-provided names from being interpreted as prompt escapes.
  ref=${ref//\%/%%}
  (( detached )) && ref="%F{152}@%F{109}${ref}"

  echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${ref}${mark}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

#
# Implement virtualenv update using hook to overcome possible
# interrupt by Ctrl+C during RPROMPT rendering.
#

zmodload zsh/parameter
autoload -Uz add-zsh-hook

(( ${+COBALT_SPARK_THEME_GIT_HIDDEN_PREFIXES} )) ||
  typeset -ga COBALT_SPARK_THEME_GIT_HIDDEN_PREFIXES=(
    feature feat bugfix chore docs refactor fix
  )

typeset -g __cobalt_spark_virtualenv_prompt_info= __cobalt_spark_pipeline_color=
(( ${+__cobalt_spark_sigpipe_status} )) ||
  typeset -gri __cobalt_spark_sigpipe_status=$(( 128 + $(kill -l PIPE) ))

__cobalt_spark_cmd_status_hook() {
  # Require a successful final stage and ignore SIGPIPE.
  __cobalt_spark_pipeline_color=${${pipestatus[-1]:#<1->}:+${${${(@)pipestatus:#0}:#$__cobalt_spark_sigpipe_status}:+%F{178}}}
  [[ -n $__cobalt_spark_pipeline_color ]] || __cobalt_spark_pipeline_color='%F{244}'
}

__cobalt_spark_virtualenv_hook() {
  __cobalt_spark_virtualenv_prompt_info=$(virtualenv_prompt_info)
  return 0
}

add-zsh-hook precmd __cobalt_spark_virtualenv_hook
# Run first because another hook would overwrite pipestatus.
precmd_functions=(__cobalt_spark_cmd_status_hook ${precmd_functions:#__cobalt_spark_cmd_status_hook})

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

# Dynamic FD syntax must be parsed with this option off.
# Restore the caller's setting after the watcher is initialized.
typeset -g __cobalt_spark_restore_ignorebraces=${options[ignorebraces]}

unsetopt ignorebraces

if (( ! ${+__cobalt_spark_live_git_events_fd} )); then
  typeset -gi __cobalt_spark_live_git_events_fd=-1
  typeset -gi __cobalt_spark_live_git_supervisor_fd=-1
  typeset -g  __cobalt_spark_live_git_root=
fi

__cobalt_spark_live_git_shutdown_if_running() {
  emulate -L zsh

  if (( __cobalt_spark_live_git_events_fd >= 0 )); then
    zle -F "$__cobalt_spark_live_git_events_fd" 2>/dev/null
    exec {__cobalt_spark_live_git_events_fd}<&-
    __cobalt_spark_live_git_events_fd=-1
  fi

  if (( __cobalt_spark_live_git_supervisor_fd >= 0 )); then
    print -r -u "$__cobalt_spark_live_git_supervisor_fd" -- shutdown
    exec {__cobalt_spark_live_git_supervisor_fd}>&-
    __cobalt_spark_live_git_supervisor_fd=-1
  fi

  __cobalt_spark_live_git_root=
}

# Clean up any existing watcher when the theme is re-sourced.
__cobalt_spark_live_git_shutdown_if_running

__cobalt_spark_live_git_quote_ere() {
  emulate -L zsh
  setopt localoptions extended_glob

  local MATCH MBEGIN MEND
  local pattern='(#m)[\[.^$*+?(){}|\\]'
  REPLY=${1//$~pattern/\\$MATCH}
}

__cobalt_spark_live_git_on_watch_event() {
  emulate -L zsh

  local fd=$1
  local error=${2-}

  # Prevent reads from polluting the user's session.
  local REPLY

  # EOF / watcher failure.
  if [[ -n $error ]] || ! IFS= read -r -u "$fd"; then
    __cobalt_spark_live_git_shutdown_if_running
    return
  fi

  # Drain any batches already waiting in the pipe.
  while IFS= read -r -t -u "$fd"; do
    :
  done

  if (( ${+parameters[_omz_async_functions]} )) &&
      (( ${_omz_async_functions[(Ie)_omz_git_prompt_info]} )) &&
      (( ${+functions[_omz_async_request]} )); then
    # OMZ has no per-handler request API, so dynamically scope its handler list
    # to keep repository events from restarting unrelated async prompt work.
    local -a _omz_async_functions=(_omz_git_prompt_info)
    _omz_async_request
  else
    zle .reset-prompt
  fi
}

__cobalt_spark_live_git_bootstrap() {
  emulate -L zsh
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
      -e "^${REPLY}/objects(/.*)?$"
      -e "^${REPLY}/logs(/.*)?$"
      -e "^${REPLY}/fsmonitor--daemon(/.*)?$"
      -e "^${REPLY}/fsmonitor--daemon\\.ipc$"
      -e "^${REPLY}/.*\\.lock$"
      -e "^${REPLY}/COMMIT_EDITMSG$"
    )
  done

  local tmpdir=${TMPDIR:-/tmp}
  local fifo_dir
  fifo_dir=$(command mktemp -d \
    "${tmpdir%/}/cobalt-spark-fswatch.XXXXXX") || return 1

  local events_fifo="$fifo_dir/events"
  local supervisor_fifo="$fifo_dir/supervisor"

  __cobalt_spark_live_git_fs_cleanup() {
    command rm -f -- "$events_fifo" "$supervisor_fifo"
    command rmdir -- "$fifo_dir" 2>/dev/null
  }

  command mkfifo "$events_fifo" "$supervisor_fifo" || {
    __cobalt_spark_live_git_fs_cleanup
    return 1
  }

  # Exclude the FIFO directory in case $TMPDIR is inside a watched path.
  __cobalt_spark_live_git_quote_ere "${fifo_dir:A}"
  filters+=(-e "^${REPLY}(/.*)?$")

  # O_RDWR opens the FIFO without waiting for a reader or writer.
  local supervisor_fd
  sysopen -r -w -o cloexec -u supervisor_fd "$supervisor_fifo" || {
    __cobalt_spark_live_git_fs_cleanup
    return 1
  }

  # Keep the detached supervisor from overwriting the caller's $!.
  (
    # The inner subshell stops fswatch when the caller shuts down or runs exec.
    (
      emulate -L zsh
      setopt localoptions nobgnice

      # Reopen the descriptor read-only so closing the writer produces EOF.
      exec {supervisor_fd}>&-
      sysopen -r -u supervisor_fd "$supervisor_fifo" || {
        # Open and close the events FIFO so the parent observes EOF.
        : >"$events_fifo"
        exit 1
      }

      # ZLE handles fswatch startup failure asynchronously as EOF.
      command fswatch --recursive --one-per-batch \
        --latency "${COBALT_SPARK_THEME_LIVE_GIT_LATENCY:-0.5}" \
        --monitor-property darwin.eventStream.noDefer=true \
        --extended --allow-overflow \
        "${filters[@]}" -- "${paths[@]}" >"$events_fifo" \
        2> >(while IFS= read -r line; do
          print -u2 -r -- "cobalt-spark fswatch: $line"
        done) &

      local fswatch_pid=$!

      # Wait for an explicit shutdown signal or EOF.
      IFS= read -r -u "$supervisor_fd"

      kill "$fswatch_pid" 2>/dev/null
      wait "$fswatch_pid" 2>/dev/null

      exec {supervisor_fd}<&-

      __cobalt_spark_live_git_fs_cleanup
    ) &!
  )

  local events_fd
  sysopen -r -o cloexec -u events_fd "$events_fifo" || {
    exec {supervisor_fd}>&-
    return 1
  }

  __cobalt_spark_live_git_root=$root
  __cobalt_spark_live_git_events_fd=$events_fd
  __cobalt_spark_live_git_supervisor_fd=$supervisor_fd

  if ! zle -F "$events_fd" __cobalt_spark_live_git_on_watch_event; then
    __cobalt_spark_live_git_shutdown_if_running
    return 1
  fi
}

__cobalt_spark_live_git_check_pwd() {
  emulate -L zsh

  if [[ -n $COBALT_SPARK_THEME_LIVE_GIT_OFF ]]; then
    __cobalt_spark_live_git_shutdown_if_running
    return 0
  fi

  # Skip setup when live Git updates are unavailable.
  if ! zmodload zsh/system || ! whence -p fswatch >/dev/null 2>&1; then
    # A watcher may have started before fswatch was removed from PATH.
    __cobalt_spark_live_git_shutdown_if_running
    return 0
  fi

  local -a git_dirs

  git_dirs=("${(@f)$(
    __git_prompt_git rev-parse \
      --show-toplevel \
      --git-dir \
      --git-common-dir \
      2>/dev/null
  )}") || git_dirs=()

  # Not inside a worktree.
  if (( ${#git_dirs} != 3 )); then
    __cobalt_spark_live_git_shutdown_if_running
    return 0
  fi

  local root=${git_dirs[1]:A}
  local git_dir=${git_dirs[2]:A}
  local common_dir=${git_dirs[3]:A}

  # Moving around inside the same repository requires no action.
  [[ $root == $__cobalt_spark_live_git_root ]] && return

  __cobalt_spark_live_git_shutdown_if_running

  local -a paths=("$root")

  # Needed for linked worktrees / external Git directories.
  [[ $git_dir != $root/* ]] &&
    paths+=("$git_dir")

  [[ $common_dir != $root/* && $common_dir != $git_dir ]] &&
    paths+=("$common_dir")

  __cobalt_spark_live_git_bootstrap \
    "$root" "$git_dir" "$common_dir" "${paths[@]}" || return 0
}

# Remove hooks left by a previous sourcing of the theme.
add-zsh-hook -d precmd __cobalt_spark_live_git_check_pwd
add-zsh-hook -d zshexit __cobalt_spark_live_git_shutdown_if_running

add-zsh-hook precmd __cobalt_spark_live_git_check_pwd
add-zsh-hook zshexit __cobalt_spark_live_git_shutdown_if_running

# Restore the caller's IGNORE_BRACES setting.
[[ $__cobalt_spark_restore_ignorebraces == on ]] && setopt ignorebraces

unset __cobalt_spark_restore_ignorebraces
