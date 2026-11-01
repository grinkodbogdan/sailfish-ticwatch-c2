#!/bin/bash
# launch-app.sh <binary> <out.png>: run an app as a client of the nested shell.
T=/srv/mer/targets/SailfishOS-4.6.0.13-i486.watchshell
chroot $T /bin/bash -c "
  export DBUS_SESSION_BUS_ADDRESS=\$(cat /tmp/ws.bus)
  export XDG_RUNTIME_DIR=/tmp/lipstick-rt WAYLAND_DISPLAY=lipstick-0
  export QT_QPA_PLATFORM=wayland-egl EGL_PLATFORM=wayland LIBGL_ALWAYS_SOFTWARE=1
  nohup $1 > /tmp/app.log 2>&1 &
"
sleep 12
rm -f $T/tmp/ws-shot.png; for i in $(seq 1 6); do [ -s $T/tmp/ws-shot.png ] && break; sleep 1; done; sleep 1
cp $T/tmp/ws-shot.png /home/mersdk/work/wstest/$2 && chmod 644 /home/mersdk/work/wstest/$2
grep -vE "dconf|^\$|ca.desrt" $T/tmp/app.log | tail -6
