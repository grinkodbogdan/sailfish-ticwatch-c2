/*
 * Settings > WiFi: on/off, nearby networks with signal strength, connect on
 * tap (the password is asked by ConnectivityPrompts' T9 keypad), and a
 * details page for the connected or saved networks (disconnect, forget,
 * auto-connect).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import MeeGo.Connman 0.2
import ".."

AppPage {
    id: wp

    title: "WiFi"

    // connman objects only when connman runs (see main.cpp). NetworkManager
    // first: it registers connman-qt's D-Bus types.
    Loader {
        id: connman
        active: connmanAvailable
        sourceComponent: Item {
            property alias wifi: tech
            property alias networks: networkModel
            NetworkManager { }
            NetworkTechnology { id: tech; path: "/net/connman/technology/wifi" }
            TechnologyModel { id: networkModel; name: "wifi" }
        }
    }
    readonly property QtObject wifi: connman.item ? connman.item.wifi : null
    readonly property QtObject networks: connman.item ? connman.item.networks : null
    readonly property bool powered: wifi !== null && wifi.powered

    function signalIcon(strength) {
        return "icon-m-wlan-" + Math.max(0, Math.min(4, Math.round(strength / 25)))
    }

    function secured(service) {
        return service.security && service.security.length > 0 && service.security[0] !== "none"
    }

    function busy(service) {
        return service.connecting || service.state === "association" || service.state === "configuration"
    }

    Timer {
        running: wp.powered && wp.networks !== null && wp.visible
        interval: 15000
        repeat: true
        triggeredOnStart: true
        onTriggered: wp.networks.requestScan()
    }

    Flickable {
        id: flick
        anchors { fill: parent; bottomMargin: 20 * wp.unit }
        contentHeight: column.height + 60 * wp.unit
        clip: true

        Column {
            id: column
            width: flick.width

            ToggleRow {
                anchors.horizontalCenter: parent.horizontalCenter
                unit: wp.unit
                icon: "icon-m-wlan"
                label: "WiFi"
                available: wp.wifi !== null
                checked: wp.powered
                onToggled: wp.wifi.powered = !wp.wifi.powered
            }

            Silica.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: wp.powered && wp.networks !== null && wp.networks.count === 0
                height: 50 * wp.unit
                verticalAlignment: Text.AlignVCenter
                color: Theme.textDim
                font.pixelSize: 16 * wp.unit
                text: "Searching…"
            }

            Repeater {
                model: wp.powered ? wp.networks : null

                Item {
                    // Hidden networks have no name; they can't be picked here.
                    visible: modelData.name !== ""
                    width: column.width
                    height: visible ? netRow.height + 4 * wp.unit : 0

                    Connections {
                        target: modelData
                        ignoreUnknownSignals: true
                        onConnectedChanged: if (modelData.connected && modelData.saved && !modelData.autoConnect) modelData.autoConnect = true
                    }

                    ListRow {
                        id: netRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 262 * wp.unit
                        unit: wp.unit
                        icon: wp.signalIcon(modelData.strength)
                        iconColor: modelData.connected ? Theme.highlight : Theme.text
                        label: modelData.name
                        labelColor: modelData.connected || highlighted ? Theme.highlight : Theme.text
                        value: modelData.connected ? "connected"
                             : wp.busy(modelData) ? "connecting…"
                             : modelData.saved ? "saved" : ""
                        valueIcon: wp.secured(modelData) ? "icon-m-device-lock" : ""
                        onClicked: {
                            if (modelData.connected)
                                wp.push(detailsPage, { "service": modelData })
                            else if (!wp.busy(modelData))
                                modelData.requestConnect()
                        }
                        onPressAndHold: if (modelData.saved || modelData.connected) wp.push(detailsPage, { "service": modelData })
                    }
                }
            }
        }
    }

    // ---- network details ----------------------------------------------------
    Component {
        id: detailsPage
        AppPage {
            id: dp
            property QtObject service
            title: service ? service.name : ""

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6 * dp.unit

                Silica.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.textDim
                    font.pixelSize: 16 * dp.unit
                    text: {
                        if (!dp.service)
                            return ""
                        var state = dp.service.connected ? "Connected" : (wp.busy(dp.service) ? "Connecting…" : "Not connected")
                        var ip = dp.service.ipv4 && dp.service.ipv4["Address"] ? dp.service.ipv4["Address"] : ""
                        return ip !== "" ? state + " · " + ip : state
                    }
                }

                ListRow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    unit: dp.unit
                    icon: dp.service && dp.service.connected ? "icon-m-dismiss" : "icon-m-wlan"
                    label: dp.service && dp.service.connected ? "Disconnect" : "Connect"
                    onClicked: {
                        if (dp.service.connected)
                            dp.service.requestDisconnect()
                        else
                            dp.service.requestConnect()
                    }
                }

                ToggleRow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    unit: dp.unit
                    icon: "icon-m-refresh"
                    label: "Auto-connect"
                    available: dp.service !== null && dp.service.saved
                    checked: dp.service !== null && dp.service.autoConnect
                    onToggled: dp.service.autoConnect = !dp.service.autoConnect
                }

                ListRow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: dp.service !== null && dp.service.saved
                    unit: dp.unit
                    icon: "icon-m-delete"
                    iconColor: Theme.error
                    label: "Forget network"
                    onClicked: {
                        dp.service.remove()
                        dp.closeRequested()
                    }
                }
            }
        }
    }
}
