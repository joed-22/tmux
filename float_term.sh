##!/usr/bin/env bash

SESSION_NAME="${1:-floating}"
CMD="${2:-}"

W="70%"
H="65%"

CURRENT_DIR=$(tmux display-message -p '#{pane_current_path}')

X="R"
Y="0"

# If we're currently inside this session, detach (closes the popup)
if [ "$(tmux display-message -p '#S')" = "$SESSION_NAME" ]; then
    tmux detach-client
    exit 0
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux popup -d "$CURRENT_DIR" \
        -x"$X" -y"$Y" -w"$W" -h"$H" \
        -E "tmux attach -t $SESSION_NAME"
else
    if [ -n "$CMD" ]; then
        tmux new-session -d -s "$SESSION_NAME" -c "$CURRENT_DIR" "bash -c 'while true; do $CMD; done'"
    else
        tmux new-session -d -s "$SESSION_NAME" -c "$CURRENT_DIR"
    fi
    tmux popup -d "$CURRENT_DIR" \
        -x"$X" -y"$Y" -w"$W" -h"$H" \
        -E "tmux attach -t $SESSION_NAME"
fi
