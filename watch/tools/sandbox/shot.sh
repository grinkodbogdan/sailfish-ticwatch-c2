#!/bin/bash
# shot.sh <page> <out.png> [WatchApp]: relaunch the nested shell on <page>
# (optionally with a watch app open) and save a screenshot.
T=/srv/mer/targets/SailfishOS-4.6.0.13-i486.watchshell
W=/home/mersdk/work/wstest
printf 'export WATCH_SHELL_START_PAGE=%s WATCH_SHELL_START_APP=%s WATCH_SHELL_START_SUB=%s\n' "$1" "$3" "$4" > $W/rt/ws.env
rm -f $T/tmp/ws-shot.png
bash $W/run-nested.sh >/dev/null 2>&1
for i in $(seq 1 10); do [ -s $T/tmp/ws-shot.png ] && break; sleep 2; done
sleep 2.5; cp $T/tmp/ws-shot.png $W/$2 && chmod 644 $W/$2
grep -E "\.qml:[0-9]+|ReferenceError|TypeError|is not a type|Cannot assign|not installed" $T/tmp/ws.log | sort -u | head -8
