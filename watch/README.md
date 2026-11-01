# Sailfish OS port for the TicWatch C2 (skipjack)

Built with the Sailfish Platform SDK 4.6.0.13 (armv7hl), on top of
AsteroidOS's prebuilt hybris userspace and kernel.

## Layout

| Directory | What |
|---|---|
| `droid-hal-skipjack/` | Droid HAL package: spec, Android `init.rc`, property contexts, systemd units |
| `droid-config-skipjack/` | Device configuration: udev rules, persist mount, WiFi start, sensor registry overlay, RTC clock offset, sensorfw config |
| `lipstick-watch-shell/` | Round lipstick home screen (Qt 5.6 / QML): face, launcher, quick settings, notifications, watch apps (Settings, Clock, Heart rate, Ambience, …), T9 keypad, Bluetooth pairing agent |
| `watch-btsyncd/` | asteroid-btsyncd (Qt5 branch + later upstream fixes) for Sailfish: phone sync over Bluetooth LE |
| `skipjack-sensorhelper/` | Root daemon: raise to wake (wrist tilt → MCE), heart rate over D-Bus, time from the phone |
| `boot/` | Boot image script and the patched initramfs `init` (boots Sailfish from userdata) |
| `hal-build/` | AOSP 9 hybris-hal build environment (Dockerfile, build script, manifests) — optional, the port uses AsteroidOS prebuilts |
| `tools/` | Development helpers (telnet shell runner, on-watch screenshots, sensor HAL test, nested-shell sandbox) |

## Not included

These are proprietary or large and must be provided locally:

- `hybris-o-msm8909.tar.gz`: hybris-patched Android userspace + headers
  (AsteroidOS `meta-asteroid` *android_armv7-oreo*).
- `system-skipjack.tar.gz`: stock C2 `/system` and `/vendor`
  (AsteroidOS `meta-skipjack` *android-system-data_skipjack-p*).
- Kernel (`zImage`) and the initramfs binaries from the AsteroidOS skipjack
  boot image (`boot/make-boot.sh` expects `zImage` and `ramdisk/` next to it).

## Build

In the Sailfish Platform SDK (target `SailfishOS-4.6.0.13-armv7hl.skipjack`):

```sh
# hardware adaptation
cd droid-hal-skipjack && cp /path/to/{hybris-o-msm8909,system-skipjack}.tar.gz . && \
  rpmbuild -bb droid-hal-skipjack.spec
cd droid-config-skipjack && tar -cf sparse.tar -C sparse . && rpmbuild -bb droid-config-skipjack.spec

# middleware and UI
for p in lipstick-watch-shell watch-btsyncd skipjack-sensorhelper; do
  (cd $p && mb2 -t SailfishOS-4.6.0.13-armv7hl.skipjack build)
done
```

Extra build dependencies in the target: `kf5bluezqt-bluez5-devel`,
`mpris-qt5-devel`, `libhybris-libhardware-devel`.

## Flash

1. Build the root filesystem image with `mic` (packages above + the Sailfish
   wearable package set) and write it to the userdata partition (`mmcblk0p37`).
2. `boot/make-boot.sh` → `sailfish-boot.img`, then
   `fastboot boot sailfish-boot.img` (or `fastboot flash boot` to make it the default).

## Notes

- The factory sensor registry (`/persist/sensors/sns.reg`) must be used; a
  regenerated one makes the sensor hub find no sensors. `skipjack-sensors-dir.service`
  overlays `/persist/sensors` with a writable copy seeded from it.
- `persist.mount` uses `/dev/disk/by-partlabel/persist`: the
  `/dev/block/bootdevice/by-name` links are made by a script, not udev, so
  systemd never sees a device unit for them.
- WiFi (wcnss) crash-loops on a watchdog until the WLAN driver is opened;
  `skipjack-wlan.service` does that once `/persist` is mounted.
- The phone must pair over Bluetooth LE: classic pairing plus derived LE keys
  fails on the watch's stack ("key missing").
- The 3.18 kernel drops LE connections when the remote answers the
  feature-exchange request with "Unknown LMP PDU" (seen with some PC
  controllers).
