#!/usr/bin/env zsh

emulate -L zsh
setopt errexit nounset pipefail nobgnice

for tool in git tmux fswatch zsh; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    print -u2 -r -- "cobalt-spark demo: $tool is required"
    exit 1
  fi
done

theme_file="${0:A:h}/cobalt-spark.plugin.zsh"
host_zdotdir=${ZDOTDIR:-$HOME}
host_zshrc="$host_zdotdir/.zshrc"
if [[ ! -r $host_zshrc ]]; then
  print -u2 -r -- "cobalt-spark demo: cannot read $host_zshrc"
  exit 1
fi

demo_dir=$(mktemp -d "${TMPDIR:-/tmp}/cobalt-spark-demo.XXXXXX")
demo_dir=${demo_dir:A}
demo_home="$demo_dir/home"
repo="$demo_home/code/demo"
remote="$demo_dir/remote.git"
hooks="$demo_dir/hooks"
top_zdotdir="$demo_dir/top-shell"
bottom_zdotdir="$demo_dir/bottom-shell"
session="cobalt-spark-demo-$$"
playback_pid=

cleanup() {
  trap - EXIT INT TERM
  [[ -n $playback_pid ]] && kill "$playback_pid" 2>/dev/null || true
  tmux kill-session -t "$session" 2>/dev/null || true
  rm -rf -- "$demo_dir"
}
trap cleanup EXIT INT TERM

git init --quiet --bare "$remote"
mkdir -p "$repo"
git init --quiet --initial-branch=main "$repo"
mkdir "$hooks" "$top_zdotdir" "$bottom_zdotdir"
git -C "$repo" config user.name 'Cobalt Spark Demo'
git -C "$repo" config user.email 'demo@example.invalid'
git -C "$repo" config core.hooksPath "$hooks"
git -C "$repo" config commit.gpgSign false
print -r -- 'Cobalt Spark' >"$repo/README.md"
print -r -- 'Live Git demo' >"$repo/demo.txt"
git -C "$repo" add README.md demo.txt
git -C "$repo" commit --quiet -m 'Initial commit'
git -C "$repo" remote add origin "$remote"
git -C "$repo" push --quiet --set-upstream origin main

print -rl -- "ZDOTDIR=${(q)host_zdotdir}" "source ${(q)host_zshrc}" \
  'typeset -g _ZSH_AUTOSUGGEST_DISABLED=1' \
  "HOME=${(q)demo_home}" "source ${(q)theme_file}" "cd ${(q)repo}" clear \
  >"$top_zdotdir/.zshrc"
print -rl -- "ZDOTDIR=${(q)host_zdotdir}" "source ${(q)host_zshrc}" \
  "HOME=${(q)demo_home}" "source ${(q)theme_file}" "cd ${(q)repo}" \
  >"$bottom_zdotdir/.zshrc"

top_pane=$(tmux new-session -d -P -F '#{pane_id}' \
  -s "$session" -c "$repo" env ZDOTDIR="$top_zdotdir" zsh -d)
bottom_pane=$(tmux split-window -v -P -F '#{pane_id}' \
  -t "$top_pane" -c "$repo" env ZDOTDIR="$bottom_zdotdir" zsh -d)
tmux set-option -w -t "$top_pane" pane-border-status top
tmux set-option -w -t "$top_pane" pane-border-format \
  '#{?#{==:#{pane_title},Idle prompt · Live Git},#[fg=colour141],} #{pane_title} #[default]'
tmux select-pane -t "$top_pane" -T 'Active prompt'
tmux select-pane -t "$bottom_pane" -T 'Idle prompt · Live Git'
terminal_height=${LINES:-24}
full_height=$(( terminal_height * 3 / 5 ))
(( full_height < 10 )) && full_height=10
top_height=$(( (full_height - 2) / 2 ))
(( top_height < 5 )) && top_height=5
bottom_height=$(( top_height / 2 ))
(( bottom_height < 3 )) && bottom_height=3
bottom_height=$(( bottom_height + 3 ))
window_height=$(( top_height + bottom_height + 2 ))
(( window_height > terminal_height )) && window_height=$terminal_height
tmux resize-window -t "$top_pane" -x "${COLUMNS:-80}" -y "$window_height"
tmux resize-pane -t "$bottom_pane" -y "$bottom_height"

tmux select-pane -t "$top_pane"

(
  sleep 1

  type_line() {
    local line=$1
    local index

    for index in {1..${#line}}; do
      tmux send-keys -t "$top_pane" -l -- "$line[$index]"
      sleep 0.045
    done
  }

  scene() {
    type_line "$1"
    tmux send-keys -t "$top_pane" Enter
    sleep 1.25
  }

  scene "echo 'Change' >> demo.txt"
  scene 'git restore demo.txt'
  scene 'git switch -c live-git-demo origin/main'
  scene "echo 'Change' >> demo.txt"
  scene "git commit -am 'Update demo'"
  scene 'git switch main'

  type_line "# And there's more."
  sleep 1
  type_line " Enjoy!"
) >/dev/null 2>&1 &
playback_pid=$!

tmux attach-session -t "$session"
