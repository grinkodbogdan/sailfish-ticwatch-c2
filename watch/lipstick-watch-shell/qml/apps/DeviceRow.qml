/*
 * A Bluetooth device in BluetoothPage: paired devices connect/disconnect on
 * tap (hold for details), nearby ones pair on tap.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import MeeGo.Connman 0.2
import ".."

Item {
    id: deviceRow

    property Item page
    property QtObject device
    property bool showPaired

    readonly property bool paired: device !== null && device.paired
    readonly property bool busy: device !== null && page.busy[device.address] === true
    readonly property bool failed: device !== null && page.failed[device.address] === true

    // Nearby: only named devices (anonymous BLE beacons are noise).
    visible: device !== null && paired === showPaired && (paired || device.remoteName !== "")
    width: parent ? parent.width : 0
    height: visible ? row.height + 4 * page.unit : 0

    ListRow {
        id: row
        anchors.horizontalCenter: parent.horizontalCenter
        width: 262 * deviceRow.page.unit
        unit: deviceRow.page.unit
        icon: deviceRow.device ? deviceRow.page.iconFor(deviceRow.device.icon) : ""
        iconColor: deviceRow.device && deviceRow.device.connected ? Theme.highlight : Theme.text
        label: deviceRow.device ? (deviceRow.device.name !== "" ? deviceRow.device.name : deviceRow.device.address) : ""
        labelColor: (deviceRow.device && deviceRow.device.connected) || highlighted ? Theme.highlight : Theme.text
        value: deviceRow.busy ? (deviceRow.paired ? "connecting…" : "pairing…")
             : deviceRow.device && deviceRow.device.connected ? "connected"
             : deviceRow.failed ? "failed" : ""
        onClicked: {
            if (deviceRow.busy)
                return
            if (!deviceRow.paired)
                deviceRow.page.pairDevice(deviceRow.device)
            else if (deviceRow.device.icon === "phone" || deviceRow.page.sharesInternet(deviceRow.device))
                deviceRow.page.push(detailsComponent, { "device": deviceRow.device })
            else if (deviceRow.device.connected)
                deviceRow.device.disconnectFromDevice()
            else
                deviceRow.page.connectDevice(deviceRow.device)
        }
        onPressAndHold: if (deviceRow.paired) deviceRow.page.push(detailsComponent, { "device": deviceRow.device })
    }

    Component {
        id: detailsComponent
        AppPage {
            id: dp
            property QtObject device
            title: device ? device.name : ""

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6 * dp.unit

                Silica.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Theme.textDim
                    font.pixelSize: 15 * dp.unit
                    text: dp.device ? dp.device.address : ""
                }

                ListRow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: dp.device !== null && dp.device.icon !== "phone"
                    unit: dp.unit
                    icon: dp.device && dp.device.connected ? "icon-m-dismiss" : "icon-m-bluetooth"
                    label: dp.device && dp.device.connected ? "Disconnect" : "Connect"
                    onClicked: {
                        if (dp.device.connected)
                            dp.device.disconnectFromDevice()
                        else
                            deviceRow.page.connectDevice(dp.device)
                    }
                }

                // Internet from a phone over Bluetooth tethering (PAN): connman
                // lists the phone as a "bluetooth" service while tethering is
                // on there.
                Loader {
                    id: pan
                    active: connmanAvailable && dp.device !== null
                    sourceComponent: Item {
                        property alias service: panService
                        NetworkManager { }
                        NetworkService {
                            id: panService
                            path: "/net/connman/service/bluetooth_"
                                  + dp.device.adapter.address.replace(/:/g, "").toLowerCase() + "_"
                                  + dp.device.address.replace(/:/g, "").toLowerCase()
                        }
                    }
                }
                readonly property QtObject panService: pan.item ? pan.item.service : null
                readonly property bool panAvailable: panService !== null && panService.name !== ""

                ToggleRow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: dp.device !== null && (dp.device.icon === "phone" || deviceRow.page.sharesInternet(dp.device))
                    unit: dp.unit
                    icon: "icon-m-wlan-hotspot"
                    label: "Phone internet"
                    available: parent.panAvailable
                    checked: parent.panService !== null && parent.panService.connected
                    onToggled: {
                        var service = parent.panService
                        if (service.connected) {
                            service.autoConnect = false
                            service.requestDisconnect()
                        } else {
                            service.autoConnect = true
                            service.requestConnect()
                        }
                    }
                }

                Silica.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: dp.device !== null && dp.device.icon === "phone" && !parent.panAvailable
                    width: 220 * dp.unit
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: Theme.textDim
                    font.pixelSize: 14 * dp.unit
                    text: "Turn on Bluetooth tethering on the phone"
                }

                ToggleRow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    unit: dp.unit
                    icon: "icon-m-device-lock"
                    label: "Trusted"
                    checked: dp.device !== null && dp.device.trusted
                    onToggled: dp.device.trusted = !dp.device.trusted
                }

                ListRow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    unit: dp.unit
                    icon: "icon-m-delete"
                    iconColor: Theme.error
                    label: "Forget device"
                    onClicked: {
                        var device = dp.device
                        dp.closeRequested()
                        device.adapter.removeDevice(device)
                    }
                }
            }
        }
    }
}
