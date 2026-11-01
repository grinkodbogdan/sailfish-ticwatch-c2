/*
 * Watch face host, over the ambience wallpaper.
 *   "sailfish" (default): big time, weekday and date as on the Sailfish
 *                         lock screen, with small status icons
 *   "analog":             hands and ticks in the Silica colours
 * toggleStyle() switches (long-press); the choice is in dconf
 * /desktop/watchshell/face, the accent in /desktop/watchshell/accent
 * ("" = ambience highlight).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import Nemo.Time 1.0
import Nemo.Mce 1.0
import Nemo.Configuration 1.0
import "."

Item {
    id: face

    property real unit: 1
    property int notificationCount: 0

    readonly property bool analog: style.value === "analog"
    readonly property color accent: accentConf.value !== "" ? accentConf.value : Theme.highlight

    function toggleStyle() {
        style.value = analog ? "sailfish" : "analog"
    }

    ConfigurationValue { id: style; key: "/desktop/watchshell/face"; defaultValue: "sailfish" }
    ConfigurationValue { id: accentConf; key: "/desktop/watchshell/accent"; defaultValue: "" }

    // Weather from the phone (Gadgetbridge -> watch-btsyncd), in Kelvin.
    ConfigurationValue { id: weatherCity; key: "/org/asteroidos/weather/city-name"; defaultValue: "" }
    ConfigurationValue { id: weatherMax; key: "/org/asteroidos/weather/day0/max-temp"; defaultValue: 0 }
    ConfigurationValue { id: weatherTime; key: "/org/asteroidos/weather/timestamp-day0"; defaultValue: 0 }
    readonly property string weather: {
        var fresh = weatherTime.value > 0 && clock.time.getTime() / 1000 - weatherTime.value < 12 * 3600
        if (!fresh || weatherMax.value <= 0)
            return ""
        return Math.round(weatherMax.value - 273.15) + "°" + (weatherCity.value !== "" ? " " + weatherCity.value : "")
    }

    WallClock {
        id: clock
        enabled: face.visible
        updateFrequency: face.analog ? WallClock.Second : WallClock.Minute
    }

    MceBatteryLevel { id: battery }
    MceCableState { id: cable }

    Wallpaper {
        anchors.fill: parent
        dim: face.analog ? 0.6 : 0.3
    }

    AnalogFace {
        anchors.fill: parent
        visible: face.analog
        unit: face.unit
        time: clock.time
        batteryPercent: battery.valid ? battery.percent : -1
        charging: cable.connected
        accent: face.accent
    }

    // ---- Sailfish face ------------------------------------------------------
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -6 * face.unit
        visible: !face.analog
        spacing: 0

        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.text
            font { pixelSize: 104 * face.unit; family: Theme.fontFamilyHeading; weight: Font.Light }
            text: Qt.formatTime(clock.time, "hh:mm")
        }

        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: face.accent
            font.pixelSize: 26 * face.unit
            text: {
                var day = Qt.formatDate(clock.time, "dddd")
                return day.charAt(0).toUpperCase() + day.substring(1)
            }
        }

        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.textDim
            font.pixelSize: 22 * face.unit
            text: Qt.formatDate(clock.time, "d MMMM")
        }

        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: face.weather !== ""
            width: Math.min(implicitWidth, 220 * face.unit)
            truncationMode: Silica.TruncationMode.Fade
            color: Theme.textDim
            font.pixelSize: 18 * face.unit
            text: face.weather
        }
    }

    // Status icons along the bottom of the circle (both faces).
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: (face.analog ? 70 : 40) * face.unit }
        spacing: 8 * face.unit
        visible: !face.analog

        SfIcon {
            anchors.verticalCenter: parent.verticalCenter
            width: 26 * face.unit
            name: cable.connected ? "icon-m-charging" : "icon-m-battery"
            color: battery.valid && battery.percent <= 15 && !cable.connected ? Theme.error : Theme.textDim
        }
        Silica.Label {
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textDim
            font.pixelSize: 18 * face.unit
            text: battery.valid ? battery.percent + "%" : ""
        }
        SfIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: face.notificationCount > 0
            width: 26 * face.unit
            name: "icon-m-notifications"
            color: face.accent
        }
    }

    // Unread notifications on the analog face: a glowing dot at 12.
    Silica.GlassItem {
        visible: face.analog && face.notificationCount > 0
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 58 * face.unit }
        width: 40 * face.unit
        height: width
        color: face.accent
        radius: 0.22
        falloffRadius: 0.18
    }
}
