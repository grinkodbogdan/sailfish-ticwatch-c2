/*
 * Settings: WiFi, Bluetooth, display, sound, watch face, about, and a way
 * into the full Sailfish Settings application.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import MeeGo.Connman 0.2
import org.nemomobile.systemsettings 1.0
import org.nemomobile.lipstick 0.1
import Nemo.Configuration 1.0
import Nemo.DBus 2.0
import ".."

AppPage {
    id: app

    title: "Settings"
    accent: Theme.settings

    // connman objects only when connman runs (see main.cpp).
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
    ProfileControl { id: profile }

    // Raise to wake lives in skipjack-sensorhelper (system bus).
    DBusInterface {
        id: sensorHelper
        bus: DBus.SystemBus
        service: "org.sailfishos.skipjack.Sensors"
        path: "/"
        iface: "org.sailfishos.skipjack.Sensors"
        signalsEnabled: true

        property bool available: false
        property bool raiseEnabled: false

        function raiseToWakeChanged(enabled) { raiseEnabled = enabled }
        function setRaise(enabled) {
            raiseEnabled = enabled
            typedCall("setRaiseToWake", [{ "type": "b", "value": enabled }])
        }

        Component.onCompleted: typedCall("raiseToWake", [], function(enabled) {
            available = true
            raiseEnabled = enabled
        })
    }

    // Development: WATCH_SHELL_START_SUB=wifi|bluetooth|display|sound|face|about
    Component.onCompleted: {
        var pages = { "wifi": wifiPage, "bluetooth": bluetoothPage, "display": displayPage,
                      "sound": soundPage, "face": facePage, "about": aboutPage }
        if (typeof startSub !== "undefined" && pages[startSub])
            push(pages[startSub])
    }

    LauncherItem {
        id: phoneSettings
        filePath: "/usr/share/applications/jolla-settings.desktop"
    }

    ListView {
        anchors.fill: parent
        anchors.bottomMargin: 30 * app.unit
        spacing: 8 * app.unit
        clip: true
        model: ListModel {
            ListElement { key: "wifi"; label: "WiFi"; icon: "icon-m-wlan" }
            ListElement { key: "bluetooth"; label: "Bluetooth"; icon: "icon-m-bluetooth" }
            ListElement { key: "display"; label: "Display"; icon: "icon-m-display" }
            ListElement { key: "sound"; label: "Sound"; icon: "icon-m-sounds" }
            ListElement { key: "ambience"; label: "Ambience"; icon: "icon-m-ambience" }
            ListElement { key: "face"; label: "Watch face"; icon: "icon-m-watch" }
            ListElement { key: "about"; label: "About"; icon: "icon-m-about" }
            ListElement { key: "phone"; label: "Phone settings"; icon: "icon-m-device" }
        }

        delegate: Item {
            width: ListView.view.width
            height: row.height

            ListRow {
                id: row
                anchors.horizontalCenter: parent.horizontalCenter
                unit: app.unit
                icon: model.icon
                iconColor: key === "wifi" ? Theme.wifi
                         : key === "bluetooth" ? Theme.bluetooth
                         : key === "display" ? Theme.calculator
                         : key === "sound" ? Theme.alarms
                         : key === "face" ? Theme.notifications
                         : key === "phone" ? Theme.textDim : Theme.settings
                label: model.label
                value: key === "wifi" ? (app.wifi ? (app.wifi.powered ? (app.wifi.connected ? "connected" : "on") : "off") : "")
                     : key === "bluetooth" ? (app.bluetooth ? (app.bluetooth.powered ? "on" : "off") : "")
                     : key === "sound" ? (profile.profile === "silent" ? "silent" : "on")
                     : ""
                onClicked: {
                    if (key === "wifi") app.push(wifiPage)
                    else if (key === "bluetooth") app.push(bluetoothPage)
                    else if (key === "display") app.push(displayPage)
                    else if (key === "sound") app.push(soundPage)
                    else if (key === "ambience") app.push(Qt.createComponent("AmbienceApp.qml"))
                    else if (key === "face") app.push(facePage)
                    else if (key === "about") app.push(aboutPage)
                    else if (key === "phone" && phoneSettings.isValid) phoneSettings.launchApplication()
                }
            }
        }
    }

    // ---- WiFi and Bluetooth (WifiPage.qml, BluetoothPage.qml) -------------
    Component {
        id: wifiPage
        WifiPage { }
    }

    Component {
        id: bluetoothPage
        BluetoothPage { }
    }

    // ---- Display ----------------------------------------------------------
    Component {
        id: displayPage
        AppPage {
            id: dp
            title: "Display"
            accent: Theme.calculator

            readonly property var timeouts: [10, 15, 30, 60]

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12 * dp.unit

                Silica.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.textDim
                    font.pixelSize: 15 * dp.unit
                    text: "Brightness"
                }
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 220 * dp.unit
                    height: 30 * dp.unit
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 10 * dp.unit
                        radius: height / 2
                        color: Theme.surfaceHigh
                        Rectangle {
                            width: display.maximumBrightness > 0 ? parent.width * display.brightness / display.maximumBrightness : 0
                            height: parent.height
                            radius: parent.radius
                            color: Theme.calculator
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        function apply(x) {
                            if (display.maximumBrightness > 0)
                                display.brightness = Math.max(1, Math.round(Math.max(0, Math.min(1, x / width)) * display.maximumBrightness))
                        }
                        onPressed: apply(mouse.x)
                        onPositionChanged: apply(mouse.x)
                    }
                }

                ListRow {
                    unit: dp.unit
                    icon: "icon-m-moon"
                    iconColor: Theme.agenda
                    label: "Sleep after"
                    value: display.dimTimeout + " s"
                    onClicked: {
                        var i = dp.timeouts.indexOf(display.dimTimeout)
                        display.dimTimeout = dp.timeouts[(i + 1) % dp.timeouts.length]
                    }
                }

                ToggleRow {
                    unit: dp.unit
                    visible: sensorHelper.available
                    icon: "icon-m-gesture"
                    iconColor: Theme.highlight
                    label: "Raise to wake"
                    checked: sensorHelper.raiseEnabled
                    onToggled: sensorHelper.setRaise(!sensorHelper.raiseEnabled)
                }

                ToggleRow {
                    unit: dp.unit
                    icon: "icon-m-battery-saver"
                    iconColor: Theme.battery
                    label: "Power saving"
                    checked: display.powerSaveModeForced
                    onToggled: display.powerSaveModeForced = !display.powerSaveModeForced
                }
            }
        }
    }

    // ---- Sound ------------------------------------------------------------
    Component {
        id: soundPage
        AppPage {
            id: sp
            title: "Sound"
            accent: Theme.alarms
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12 * sp.unit
                ToggleRow {
                    unit: sp.unit
                    icon: "icon-m-sounds"
                    iconColor: Theme.alarms
                    label: "Silent"
                    checked: profile.profile === "silent"
                    onToggled: profile.profile = (profile.profile === "silent" ? "general" : "silent")
                }
                Silica.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.textDim
                    font.pixelSize: 15 * sp.unit
                    text: "Volume " + profile.ringerVolume + "%"
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 24 * sp.unit
                    CircleButton { unit: sp.unit; label: "−"; accent: Theme.alarms; onClicked: profile.ringerVolume = Math.max(0, profile.ringerVolume - 20) }
                    CircleButton { unit: sp.unit; icon: "icon-m-add"; accent: Theme.alarms; onClicked: profile.ringerVolume = Math.min(100, profile.ringerVolume + 20) }
                }
            }
        }
    }

    // ---- Watch face -------------------------------------------------------
    Component {
        id: facePage
        AppPage {
            id: fp
            title: "Watch face"
            accent: Theme.notifications

            ConfigurationValue { id: faceStyle; key: "/desktop/watchshell/face"; defaultValue: "sailfish" }
            ConfigurationValue { id: faceAccent; key: "/desktop/watchshell/accent"; defaultValue: "" }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14 * fp.unit

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10 * fp.unit
                    Repeater {
                        model: ["sailfish", "analog"]
                        Rectangle {
                            width: 112 * fp.unit
                            height: 44 * fp.unit
                            radius: height / 2
                            color: faceStyle.value === modelData ? Theme.dim(Theme.highlightBackground, 0.6) : Theme.surface
                            Silica.Label {
                                anchors.centerIn: parent
                                color: faceStyle.value === modelData ? Theme.highlight : Theme.text
                                font.pixelSize: 17 * fp.unit
                                text: modelData === "analog" ? "Analog" : "Sailfish"
                            }
                            MouseArea { anchors.fill: parent; onClicked: faceStyle.value = modelData }
                        }
                    }
                }

                Silica.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.textDim
                    font.pixelSize: 15 * fp.unit
                    text: "Accent colour (first = ambience)"
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 4
                    spacing: 12 * fp.unit
                    Repeater {
                        model: Theme.accents
                        Rectangle {
                            width: 40 * fp.unit
                            height: width
                            radius: width / 2
                            color: modelData === "" ? Theme.highlight : modelData
                            border.color: Theme.text
                            border.width: String(faceAccent.value) === String(modelData) ? 3 * fp.unit : 0
                            MouseArea { anchors.fill: parent; onClicked: faceAccent.value = String(modelData) }
                        }
                    }
                }
            }
        }
    }

    // ---- About ------------------------------------------------------------
    Component {
        id: aboutPage
        AppPage {
            id: ap
            title: "About"
            accent: Theme.settings
            AboutSettings { id: about }
            DeviceInfo { id: device }
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6 * ap.unit
                Repeater {
                    model: [
                        ["Device", device.prettyName || "TicWatch C2"],
                        ["System", about.localizedOperatingSystemName || about.operatingSystemName],
                        ["Version", about.softwareVersionId || about.softwareVersion],
                        ["WiFi MAC", about.wlanMacAddress || "-"],
                        ["Serial", about.serial || "-"]
                    ]
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        Silica.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Theme.settings
                            font.pixelSize: 13 * ap.unit
                            text: modelData[0]
                        }
                        Silica.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Theme.text
                            font.pixelSize: 17 * ap.unit
                            text: modelData[1]
                        }
                    }
                }
            }
        }
    }
}
