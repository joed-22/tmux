#!/bin/sh

width=$1
session=$2

case $width in
  ''|*[!0-9]*) exit 0 ;;
esac

case $session in
  '$'[0-9]*) ;;
  *) exit 0 ;;
esac

tmux_format() {
  tmux display-message -p -t "$session" -F "$1" 2>/dev/null
}

text_width() {
  printf '%s' "$1" | wc -m | tr -d '[:space:]'
}

session_name=$(tmux_format '#{session_name}')
command=$(tmux_format '#{pane_current_command}')
path=$(tmux_format '#{b:pane_current_path}')
host=$(tmux_format '#H')
zoomed=$(tmux_format '#{window_zoomed_flag}')

window_count=0
full_windows=0
short_windows=0

while IFS='	' read -r index name; do
  [ -n "$index" ] || continue
  index_width=$(text_width "$index")
  name_width=$(text_width "$name")

  window_count=$((window_count + 1))
  full_windows=$((full_windows + index_width + 2 + name_width + 2))
  short_windows=$((short_windows + index_width + 2 + (name_width > 6 ? 6 : name_width) + 2))
done <<EOF
$(tmux list-windows -t "$session" -F '#{window_index}	#{window_name}' 2>/dev/null)
EOF

[ "$window_count" -gt 0 ] || exit 0

# Separators occupy one cell between adjacent window labels.
separators=$((window_count - 1))
full_windows=$((full_windows + separators))
short_windows=$((short_windows + separators))

# The icon glyphs are each one terminal cell in the configured Nerd Font.
base_left=$(( $(text_width "$session_name") + 4 ))
command_left=$((base_left + $(text_width "$command") + 5))
path_left=$((command_left + $(text_width "$path") + 5))
[ "$zoomed" = "1" ] && base_left=$((base_left + 7))

time_right=9
cpu_right=$((time_right + 11))
host_right=$((cpu_right + $(text_width "$host") + 5))

# Keep a small gap between the centered window list and both side segments.
fits() {
  [ "$1" -le $((width - $2 - $3 - 2)) ]
}

if fits "$full_windows" "$path_left" "$host_right"; then
  mode=full
  show_path=1
  show_command=1
  show_host=1
  show_cpu=1
elif fits "$full_windows" "$command_left" "$cpu_right"; then
  mode=full
  show_path=0
  show_command=1
  show_host=0
  show_cpu=1
elif fits "$full_windows" "$base_left" "$time_right"; then
  mode=full
  show_path=0
  show_command=0
  show_host=0
  show_cpu=0
else
  # Always keep some name text; never fall back to numbers only.
  mode=short
  show_path=0
  show_command=0
  show_host=0
  show_cpu=0
fi

tmux set-option -gq @status_window_mode "$mode"
tmux set-option -gq @status_show_path "$show_path"
tmux set-option -gq @status_show_command "$show_command"
tmux set-option -gq @status_show_host "$show_host"
tmux set-option -gq @status_show_cpu "$show_cpu"
