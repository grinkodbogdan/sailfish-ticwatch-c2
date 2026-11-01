#!/bin/bash
# Run lipstick-watch-shell inside the nested 360x360 Weston kiosk (run as root in sfos-sdk).
set -e
TN=SailfishOS-4.6.0.13-i486.watchshell
T=/srv/mer/targets/$TN
W=/home/mersdk/work
su mersdk -c "sb2 -t $TN -m sdk-install -R rpm -Uvh --force --nodeps $W/src/lipstick-watch-shell/RPMS/lipstick-watch-shell-*.i486.rpm" >/dev/null
install -D -m 0755 $W/wstest/wlsocket-shim.so $T/usr/local/lib/wlsocket-shim.so
for d in proc sys dev dev/pts; do mountpoint -q $T/$d || mount --bind /$d $T/$d; done
# Weston (watch-weston container) socket, shared through work/wstest/rt.
mkdir -p $T/run/host-wl; mountpoint -q $T/run/host-wl || mount --bind $W/wstest/rt $T/run/host-wl
pkill -x lipstick-watch- 2>/dev/null || true; sleep 1
chroot $T /bin/bash -c '
  mkdir -p /run/dbus /tmp/lipstick-rt && chmod 700 /tmp/lipstick-rt
  [ -S /run/dbus/system_bus_socket ] || dbus-daemon --system --fork
  export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address)
  echo "$DBUS_SESSION_BUS_ADDRESS" > /tmp/ws.bus
  export XDG_RUNTIME_DIR=/tmp/lipstick-rt
  export WAYLAND_DISPLAY=/run/host-wl/watch-wl LIPSTICK_WAYLAND_SOCKET=lipstick-0
  export QT_QPA_PLATFORM=wayland-egl EGL_PLATFORM=wayland LIBGL_ALWAYS_SOFTWARE=1
  export LD_PRELOAD=/usr/local/lib/wlsocket-shim.so
  export WATCH_SHELL_SCREENSHOT=/tmp/ws-shot.png WATCH_SHELL_FORCE_DISPLAY_ON=1
  [ -f /run/host-wl/ws.env ] && . /run/host-wl/ws.env
  nohup lipstick-watch-shell > /tmp/ws.log 2>&1 &
  sleep 6
  pgrep -a lipstick-watch || echo "NOT RUNNING"
  tail -25 /tmp/ws.log
'
