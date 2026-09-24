#!/usr/bin/env bash
set -uo pipefail

dry=0
if [ "${1:-}" = "--dry-run" ]; then dry=1; shift; fi
reset_at="${1:?usage: waker.sh [--dry-run] <HH:MM> <supervisor-session> <sessions.txt>}"
supervisor="${2:?missing supervisor session id}"
state_dir="$(cd "$(dirname "${3:?missing sessions.txt}")" && pwd)"
roster="$state_dir/$(basename "$3")"
log="$state_dir/waker.log"
woken=" "
send="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/send.sh"
limited='limit reached|hit your (usage )?limit|limit will reset|resets at [0-9]|out of extra usage'

is_limited() {
  agtermctl session text --target "$1" --pane left --lines 12 2>/dev/null | grep -Eiq "$limited"
}

wake() {
  while read -r sid transcript_file; do
    case "$woken" in *" $sid "*) continue ;; esac
    is_limited "$sid" || continue
    if [ "$dry" -eq 1 ]; then echo "WOULD WAKE $sid"; continue; fi
    if [ "$sid" = "$supervisor" ]; then
      "$send" "$sid" - "Usage limits reset. Wake any supervised session still limited, then run /babysit poll $state_dir" >>"$log" 2>&1
    else
      "$send" --plain "$sid" "$transcript_file" "continue" >>"$log" 2>&1
    fi
    status=$?
    [ "$status" -eq 3 ] || woken="$woken$sid "
    echo "$(date +%H:%M:%S) $sid send exit $status" >>"$log"
  done < <(awk '$1 !~ /^#/ && NF {print $1, $3}' "$roster"; echo "$supervisor -")
}

if [ "$dry" -eq 1 ]; then wake; echo "dry run done"; exit 0; fi

echo $$ >"$state_dir/waker.pid"
target=$(date -j -f '%Y-%m-%d %H:%M' "$(date +%Y-%m-%d) $reset_at" +%s) || exit 2
now=$(date +%s)
[ "$target" -gt "$now" ] || target=$((target + 86400))
echo "$(date '+%H:%M:%S') armed for $(date -r "$target" '+%H:%M')" >>"$log"
sleep $((target - now))
for delay in 0 900 1200 1800; do
  sleep "$delay"
  echo "$(date +%H:%M:%S) pass" >>"$log"
  wake
done
echo "$(date +%H:%M:%S) finished" >>"$log"
rm -f "$state_dir/waker.pid"
