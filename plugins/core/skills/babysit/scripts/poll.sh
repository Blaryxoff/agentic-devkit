#!/usr/bin/env bash
set -uo pipefail

roster="${1:?usage: poll.sh <sessions.txt>}"
state_dir="$(dirname "$roster")"
now=$(date +%s)

date '+%H:%M %Z'
if [ -f "$state_dir/waker.log" ]; then
  kill -0 "$(cat "$state_dir/waker.pid" 2>/dev/null)" 2>/dev/null && echo "waker: armed" || echo "waker: exited"
  tail -2 "$state_dir/waker.log"
fi

while read -r sid name transcript_file _; do
  case "$sid" in ''|\#*) continue ;; esac
  age="-"
  if [ "$transcript_file" != "-" ] && [ -f "$transcript_file" ]; then
    age="$(( (now - $(stat -f %m "$transcript_file")) / 60 ))m"
  fi
  echo "######## ${sid:0:8} $name | transcript idle $age"
  echo "-- left:"
  agtermctl session text --target "$sid" --pane left --lines 40 2>&1 | grep -v '^[[:space:]]*$' | tail -"${LN:-8}"
  echo "-- right:"
  agtermctl session text --target "$sid" --pane right --lines 40 2>&1 | grep -v '^[[:space:]]*$' | tail -"${RN:-5}"
done < "$roster"
