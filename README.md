# Watch Link

Companion app for a smartwatch running **Sailfish OS** (built for the TicWatch C2,
"skipjack"). It talks to the watch over Bluetooth LE using the
[AsteroidOS](https://asteroidos.org) sync protocol, served on the watch by
`watch-btsyncd` (asteroid-btsyncd built for Sailfish OS).

The UI is a web app (`android/app/src/main/assets/www`, installable as a PWA);
the Android app hosts it and adds what a web page can't do: a background
Bluetooth connection, reading the phone's notifications and the playing media.

## Features

| | |
|---|---|
| Notifications | Phone notifications appear on the watch and are removed when cleared; per-app mute, vibration strength |
| Weather | [Open-Meteo](https://open-meteo.com) (no key): current location or a searched city, 5-day forecast, hourly refresh |
| Music | Now playing on the watch; play/pause, skip, volume from the watch |
| Time | Watch clock set from the phone on connect and on time-zone/time changes |
| Battery | Watch battery level in the app and its status notification |
| Internet | Guided Bluetooth tethering setup (Android only lets the user switch it on) |

## Build

Requirements: JDK 17, Android SDK (platform 34, build-tools 34), Gradle 8.7.

```sh
cd android
echo "sdk.dir=$HOME/Android/Sdk" > local.properties
gradle assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Pairing notes

- If the phone was paired with the watch before (for example under Wear OS),
  remove that pairing in the phone's Bluetooth settings first.
- The app pairs over Bluetooth LE. Pairing over classic Bluetooth and deriving
  LE keys (what Android does for a plain `createBond()` on a dual-mode device)
  fails with the watch's Bluetooth stack ("key missing").

## Layout

```
android/
  app/src/main/java/org/skipjack/watchlink/
    WatchService.java          connection, GATT queue, sync logic (foreground service)
    NotificationForwarder.java notification listener
    WeatherClient.java         Open-Meteo forecast and city search
    Protocol.java              watch protocol: UUIDs and encodings
    MainActivity.java          WebView host and JS bridge (window.Native)
  app/src/main/assets/www/     web UI / PWA
```

## Status

Linux support (a desktop service serving the same UI) is planned.
