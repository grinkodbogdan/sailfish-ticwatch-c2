/*
 * Quick settings in the style of the Sailfish top menu: round icon toggles
 * with labels (active ones on the ambience highlight), a Silica brightness
 * slider and Settings (tap: watch Settings, long-press: the full Sailfish
 * Settings application). Swipe up to go back to the watch face.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import MeeGo.Connman 0.2
import org.nemomobile.systemsettings 1.0
import org.nemomobile.lipstick 0.1
import Nemo.Mce 1.0
import "."

Item {
    id: settings

    property real unit: 1

    signal closeRequested
    signal openWatchApp(string name)

    // Created only when connman runs (connmanAvailable, set in main.cpp).
    Loader {
        id: connman
        active: connmanAvailable
        sourceComponent: Item {
            // Creating the NetworkManager first registers connman-qt's D-Bus
            // types; without it the first technology reply is fatal.
            NetworkManager { id: networkManager }
            property alias wifi: wifiTech
            property alias bluetooth: btTech
            NetworkTechnology { id: wifiTech; path: "/net/connman/technology/wifi" }
            NetworkTechnology { id: btTech; path: "/net/connman/technology/bluetooth" }
        }
    }
    readonly property QtObject wifi: connman.item ? connman.item.wifi : null
    readonly property QtObject bluetooth: connman.item ? connman.item.bluetooth : null

    DisplaySettings { id: display }
    MceBatteryLevel { id: battery }

    LauncherItem {
        id: phoneSettings
        filePath: "/usr/share/applications/jolla-settings.desktop"
    }

    Wallpaper {
        anchors.fill: parent
        dim: 0.7
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 6 * settings.unit
        spacing: 10 * settings.unit

        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.highlight
            font.pixelSize: 18 * settings.unit
            text: battery.valid ? battery.percent + "%" : ""
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6 * settings.unit

            Repeater {
                model: [
                    { "key": "wifi", "icon": "icon-m-wlan", "label": "WLAN" },
                    { "key": "bluetooth", "icon": "icon-m-bluetooth", "label": "Bluetooth" },
                    { "key": "torch", "icon": "icon-m-flashlight", "label": "Flashlight" },
                    { "key": "saver", "icon": "icon-m-battery-saver", "label": "Saver" }
                ]

                Column {
                    spacing: 4 * settings.unit
                    width: 60 * settings.unit

                    CircleButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        unit: settings.unit
                        size: 54
                        icon: modelData.icon
                        filled: modelData.key === "wifi" ? (settings.wifi !== null && settings.wifi.powered)
                              : modelData.key === "bluetooth" ? (settings.bluetooth !== null && settings.bluetooth.powered)
                              : modelData.key === "saver" ? display.powerSaveModeForced
                              : false
                        enabled: modelData.key === "wifi" ? (settings.wifi !== null)
                               : modelData.key === "bluetooth" ? (settings.bluetooth !== null)
                               : true
                        onClicked: {
                            if (modelData.key === "wifi") settings.wifi.powered = !settings.wifi.powered
                            else if (modelData.key === "bluetooth") settings.bluetooth.powered = !settings.bluetooth.powered
                            else if (modelData.key === "saver") display.powerSaveModeForced = !display.powerSaveModeForced
                            else if (modelData.key === "torch") settings.openWatchApp("TorchApp")
                        }
                    }

                    Silica.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: Theme.textDim
                        font.pixelSize: 12 * settings.unit
                        text: modelData.label
                    }
                }
            }
        }

        Silica.Slider {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 250 * settings.unit
            minimumValue: 1
            maximumValue: Math.max(2, display.maximumBrightness)
            stepSize: 1
            value: display.brightness
            label: "Brightness"
            enabled: display.maximumBrightness > 0
            onReleased: display.brightness = Math.round(value)
        }

        ListRow {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 190 * settings.unit
            unit: settings.unit
            icon: "icon-launcher-settings"
            iconColor: Theme.text
            label: "Settings"
            onClicked: settings.openWatchApp("SettingsApp")
            onPressAndHold: {
                if (phoneSettings.isValid) {
                    phoneSettings.launchApplication()
                    settings.closeRequested()
                }
            }
        }
    }

    // Back: swipe up from the lower part.
    MouseArea {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height * 0.15
        property real startY
        onPressed: startY = mouse.y
        onReleased: if (startY - mouse.y > 30 * settings.unit) settings.closeRequested()
    }
}
