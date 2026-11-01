/*
 * System prompts the phone home screen would normally show:
 *  - WiFi passphrase: connectionagent (com.jolla.Connectiond) asks for
 *    connman's user input; answered with the T9 keypad.
 *  - Bluetooth pairing: confirm the passkey / show a code, from the shell's
 *    BlueZ agent (bluetoothAgent, main.cpp).
 *  - Short notices for connection errors.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import Nemo.DBus 2.0
import MeeGo.Connman 0.2
import "."

Item {
    id: prompts

    property real unit: 1
    readonly property bool active: keypad.visible || pairing.visible

    function notify(text) {
        toastLabel.text = text
        toast.opacity = 1
        toastTimer.restart()
    }

    // ---- WiFi -------------------------------------------------------------
    DBusInterface {
        id: connectiond
        bus: DBus.SessionBus
        service: "com.jolla.Connectiond"
        path: "/Connectiond"
        iface: "com.jolla.Connectiond"
        signalsEnabled: true

        function userInputRequested(servicePath, fields) {
            // Only passphrases are asked on the watch (no enterprise logins).
            if (!fields || fields["Passphrase"] === undefined) {
                connectiond.call("sendUserReply", [{}])
                prompts.notify("Set this network up on the phone Settings app")
                return
            }
            requestedService.path = servicePath
            keypad.reset()
            keypad.visible = true
        }

        function userInputCanceled() {
            keypad.visible = false
        }

        function errorReported(servicePath, error) {
            if (error === "invalid-key" || error === "auth-failed")
                prompts.notify("Wrong password")
            else if (error === "connect-failed")
                prompts.notify("Could not connect")
            else if (error !== "")
                prompts.notify("WiFi: " + error)
        }
    }

    // The network asking for a password, for its name. NetworkManager is
    // created first: it registers connman-qt's D-Bus types.
    Loader {
        id: serviceLoader
        active: connmanAvailable
        sourceComponent: Item {
            property alias service: service
            NetworkManager { }
            NetworkService { id: service; path: requestedService.path }
        }
    }
    Connections {
        target: requestedService.service
        ignoreUnknownSignals: true
        onConnectedChanged: {
            var service = requestedService.service
            if (service.connected && !service.autoConnect)
                service.autoConnect = true
        }
    }
    QtObject {
        id: requestedService
        property string path
        readonly property QtObject service: serviceLoader.item ? serviceLoader.item.service : null
        readonly property string name: service && service.name ? service.name : "WiFi"
    }

    T9Keypad {
        id: keypad
        anchors.fill: parent
        visible: false
        unit: prompts.unit
        title: requestedService.name
        onAccepted: {
            connectiond.call("sendUserReply", [{ "Passphrase": text }])
            visible = false
            keypad.reset()
        }
        onCanceled: {
            connectiond.call("sendUserReply", [{}])
            visible = false
            keypad.reset()
        }
    }

    // ---- Bluetooth pairing ------------------------------------------------
    Item {
        id: pairing

        property string name
        property string code
        property bool confirm       // true: Yes/No; false: just show the code

        anchors.fill: parent
        visible: false

        Connections {
            target: bluetoothAgent
            onConfirmationRequested: { pairing.name = name; pairing.code = passkey; pairing.confirm = true; pairing.visible = true }
            onAuthorizationRequested: { pairing.name = name; pairing.code = ""; pairing.confirm = true; pairing.visible = true }
            onCodeShown: { pairing.name = name; pairing.code = code; pairing.confirm = false; pairing.visible = true }
            onCanceled: pairing.visible = false
        }

        Wallpaper {
            anchors.fill: parent
            dim: 0.8
        }
        MouseArea { anchors.fill: parent }

        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -24 * prompts.unit
            spacing: 6 * prompts.unit

            SfIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 44 * prompts.unit
                name: "icon-m-bluetooth"
                color: Theme.highlight
            }
            Silica.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 240 * prompts.unit
                horizontalAlignment: Text.AlignHCenter
                truncationMode: Silica.TruncationMode.Fade
                color: Theme.highlight
                font.pixelSize: 22 * prompts.unit
                text: pairing.name
            }
            Silica.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 240 * prompts.unit
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: Theme.textDim
                font.pixelSize: 16 * prompts.unit
                text: pairing.confirm ? (pairing.code !== "" ? "Pair? Check the other device shows" : "Allow this device to pair?")
                                      : "Type this code on the other device"
            }
            Silica.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: pairing.code !== ""
                color: Theme.text
                font { pixelSize: 46 * prompts.unit; family: Theme.fontFamilyHeading; letterSpacing: 3 * prompts.unit }
                text: pairing.code
            }
        }

        Row {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 36 * prompts.unit }
            spacing: 34 * prompts.unit
            CircleButton {
                unit: prompts.unit
                size: 56
                icon: "icon-m-cancel"
                onClicked: { bluetoothAgent.reject(); pairing.visible = false }
            }
            CircleButton {
                visible: pairing.confirm
                unit: prompts.unit
                size: 56
                filled: true
                icon: "icon-m-accept"
                onClicked: { bluetoothAgent.accept(); pairing.visible = false }
            }
        }
    }

    // ---- notices ------------------------------------------------------------
    Rectangle {
        id: toast
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 54 * prompts.unit }
        width: Math.min(toastLabel.implicitWidth + 36 * prompts.unit, 250 * prompts.unit)
        height: toastLabel.height + 18 * prompts.unit
        radius: Math.min(height / 2, 22 * prompts.unit)
        color: Theme.dim(Theme.highlightBackground, 0.9)
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Silica.Label {
            id: toastLabel
            anchors.centerIn: parent
            width: Math.min(implicitWidth, 214 * prompts.unit)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: Theme.text
            font.pixelSize: 16 * prompts.unit
        }
        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: toast.opacity = 0
        }
    }
}
