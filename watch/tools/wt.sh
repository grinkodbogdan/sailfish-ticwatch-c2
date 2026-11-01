#!/bin/bash
# Run a command on the watch via the debug telnet shell; $2 = seconds to wait.
{ sleep 1; printf '%s; echo __DONE__\n' "$1"; sleep "${2:-4}"; printf 'exit\n'; } | nc -q 2 192.168.2.15 23 2>/dev/null | tr -d '\r' | sed -e 's/\x1b\[[0-9;]*[a-zA-Z]//g' -e 's/[^[:print:]\t]//g' | sed -n '/; echo __DONE__/,/^__DONE__/p' | sed '1d;$d'
