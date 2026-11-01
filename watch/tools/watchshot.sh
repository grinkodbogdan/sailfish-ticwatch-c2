#!/bin/bash
# watchshot.sh <name.png>: fetch the shell's latest scene screenshot from the watch.
~/sfos-skipjack-env/wt.sh "sleep 2.5; cp /tmp/wshot.png /tmp/wshot-up.png 2>/dev/null && curl -s -T /tmp/wshot-up.png http://192.168.2.1:8098/$1 && echo UPLOADED" 10
