# Sailfish OS on the TicWatch C2

Sailfish OS running on the Mobvoi **TicWatch C2** (codename *skipjack*,
MSM8909W), with a round watch home screen and a phone companion app.

```
companion/   Watch Link: Android companion app (web UI / PWA + native service)
watch/       the Sailfish OS port: hardware adaptation, round shell, services
```

## Screenshots

Taken on the watch (360×360, round). Sample notifications and weather city; nearby network and device names are pixelated.

| | | |
|:-:|:-:|:-:|
| <img src="docs/screenshots/01-face.png" width="220" alt="Watch face"><br>Watch face | <img src="docs/screenshots/02-face-analog.png" width="220" alt="Analog face"><br>Analog face | <img src="docs/screenshots/03-launcher.png" width="220" alt="App list"><br>App list |
| <img src="docs/screenshots/04-quick-settings.png" width="220" alt="Quick settings"><br>Quick settings | <img src="docs/screenshots/15-notification-popup.png" width="220" alt="Notification from the phone"><br>Notification from the phone | <img src="docs/screenshots/05-notifications.png" width="220" alt="Notifications"><br>Notifications |
| <img src="docs/screenshots/06-settings.png" width="220" alt="Settings"><br>Settings | <img src="docs/screenshots/07-wifi.png" width="220" alt="WiFi"><br>WiFi | <img src="docs/screenshots/08-bluetooth.png" width="220" alt="Bluetooth"><br>Bluetooth |
| <img src="docs/screenshots/09-display.png" width="220" alt="Display"><br>Display | <img src="docs/screenshots/10-heart-rate.png" width="220" alt="Heart rate"><br>Heart rate | <img src="docs/screenshots/11-ambience.png" width="220" alt="Ambiences"><br>Ambiences |
| <img src="docs/screenshots/12-clock.png" width="220" alt="Clock"><br>Clock | <img src="docs/screenshots/13-battery.png" width="220" alt="Battery"><br>Battery |  |

## What works

| Area | Status |
|---|---|
| Display, touch, GPU | ✅ hwcomposer, 360×360 round |
| Round home screen | ✅ watch face, launcher, quick settings, notifications, watch apps |
| WiFi | ✅ wcnss/prima, password entry with an on-watch T9 keypad |
| Bluetooth | ✅ pairing, devices, internet from a phone (Bluetooth tethering) |
| Phone sync | ✅ notifications, weather, music, time, battery (AsteroidOS protocol) |
| Sensors | ✅ accelerometer, gyroscope, step counter, heart rate, wrist tilt |
| Raise to wake | ✅ wrist-tilt gesture |
| Heart rate | ✅ spot measurement app |
| Clock | ✅ RTC offset kept across reboots, network/phone time |
| Vibration, brightness, battery | ✅ |
| Buttons | ✅ power (display), side button (home/back) |
| GPS, NFC | ❌ not supported (not on AsteroidOS either) |
| Audio | — the C2 has no speaker |

See [watch/README.md](watch/README.md) for building and flashing, and
[companion/README.md](companion/README.md) for the app.

## Licenses

- `watch/watch-btsyncd`: GPLv3 (AsteroidOS asteroid-btsyncd, see its LICENSE).
- `watch/lipstick-watch-shell`, `watch/skipjack-sensorhelper`: LGPL-2.1 (SPDX headers).
- Proprietary Android/vendor binaries are **not** included (see watch/README.md).
