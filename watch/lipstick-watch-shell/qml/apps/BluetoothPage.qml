/*
 * Settings > Bluetooth: on/off, visibility (for pairing from a phone),
 * paired devices (tap: connect/disconnect, hold: details) and nearby
 * devices found by a scan (tap: pair, then connect). Pairing questions are
 * answered in ConnectivityPrompts.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import MeeGo.Connman 0.2
import org.kde.bluezqt 1.0 as BluezQt
import ".."

AppPage {
    id: bp

    title: "Bluetooth"

    // Power goes through connman, as in Sailfish.
    Loader {
        id: connman
        active: connmanAvailable
        sourceComponent: Item {
            property alias tech: tech
            NetworkManager { }
            NetworkTechnology { id: tech; path: "/net/connman/technology/bluetooth" }
        }
    }
    readonly property QtObject tech: connman.item ? connman.item.tech : null
    readonly property QtObject adapter: BluezQt.Manager.usableAdapter
    readonly property bool powered: adapter !== null && adapter.powered

    // Addresses with a pair/connect in progress, and the last failures.
    property var busy: ({})
    property var failed: ({})

    function setState(address, isBusy, isFailed) {
        var b = busy; b[address] = isBusy; busy = b
        var f = failed; f[address] = isFailed; failed = f
    }

    function notify(text) {
        if (typeof prompts !== "undefined")
            prompts.notify(text)
    }

    function connectDevice(device) {
        var address = device.address
        setState(address, true, false)
        var call = device.connectToDevice()
        call.finished.connect(function() {
            bp.setState(address, false, call.error !== 0)
            if (call.error !== 0)
                bp.notify("Could not connect " + device.name)
        })
    }

    function pairDevice(device) {
        var address = device.address
        setState(address, true, false)
        var call = device.pair()
        call.finished.connect(function() {
            if (call.error !== 0) {
                bp.setState(address, false, true)
                bp.notify("Pairing failed")
                return
            }
            device.trusted = true
            bp.connectDevice(device)
        })
    }

    // Bluetooth network access point (the phone shares its connection).
    function sharesInternet(device) {
        return device.uuids.indexOf("00001116-0000-1000-8000-00805f9b34fb") >= 0
    }

    function iconFor(icon) {
        if (icon.indexOf("audio-head") === 0) return "icon-m-headphone"
        if (icon === "audio-card") return "icon-m-speaker"
        if (icon === "phone") return "icon-m-phone"
        if (icon === "computer") return "icon-m-computer"
        if (icon === "input-keyboard") return "icon-m-keyboard"
        if (icon === "input-mouse") return "icon-m-mouse"
        if (icon.indexOf("input-tablet") === 0) return "icon-m-tablet"
        return "icon-m-bluetooth-device"
    }

    // Scanning drains the battery: scan for a minute when the page opens
    // and on "Scan again".
    property bool scanning: adapter !== null && adapter.discovering
    function scan() {
        if (powered && !adapter.discovering)
            adapter.startDiscovery()
        scanTimer.restart()
    }
    Timer {
        id: scanTimer
        interval: 60000
        onTriggered: if (bp.adapter && bp.adapter.discovering) bp.adapter.stopDiscovery()
    }
    onPoweredChanged: if (powered) scan()
    Component.onCompleted: { countPaired(); scan() }
    Component.onDestruction: if (adapter && adapter.discovering) adapter.stopDiscovery()


    // Devices known to BlueZ, refreshed as they come and go (the
    // DevicesModel wrapper stays empty on this BluezQt build). Named ones
    // first, by name.
    property var deviceList: []
    property int pairedCount: 0
    function countPaired() {
        var list = BluezQt.Manager.devices
        var all = []
        var n = 0
        for (var i = 0; i < list.length; i++) {
            all.push(list[i])
            if (list[i].paired)
                n++
        }
        all.sort(function(a, b) { return a.name.localeCompare(b.name) })
        pairedCount = n
        if (all.length !== deviceList.length || all.some(function(d, i) { return d !== deviceList[i] }))
            deviceList = all
    }
    Connections {
        target: BluezQt.Manager
        onDeviceAdded: bp.countPaired()
        onDeviceRemoved: bp.countPaired()
        onDeviceChanged: bp.countPaired()
    }

    Flickable {
        id: flick
        anchors { fill: parent; bottomMargin: 20 * bp.unit }
        contentHeight: column.height + 60 * bp.unit
        clip: true

        Column {
            id: column
            width: flick.width

            ToggleRow {
                anchors.horizontalCenter: parent.horizontalCenter
                unit: bp.unit
                icon: "icon-m-bluetooth"
                label: "Bluetooth"
                available: bp.tech !== null
                checked: bp.tech !== null && bp.tech.powered
                onToggled: bp.tech.powered = !bp.tech.powered
            }

            ToggleRow {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: bp.powered
                unit: bp.unit
                icon: "icon-m-phone"
                label: "Visible to phones"
                checked: bp.adapter !== null && bp.adapter.discoverable
                onToggled: bp.adapter.discoverable = !bp.adapter.discoverable
            }

            SectionLabel { unit: bp.unit; text: "Paired"; visible: bp.powered && bp.pairedCount > 0 }

            Repeater {
                model: bp.powered ? bp.deviceList : null
                DeviceRow {
                    page: bp
                    device: modelData
                    showPaired: true
                }
            }

            SectionLabel {
                unit: bp.unit
                visible: bp.powered
                text: bp.scanning ? "Nearby · searching…" : "Nearby"
            }

            Repeater {
                model: bp.powered ? bp.deviceList : null
                DeviceRow {
                    page: bp
                    device: modelData
                    showPaired: false
                }
            }

            ListRow {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: bp.powered && !bp.scanning
                unit: bp.unit
                icon: "icon-m-search"
                label: "Scan again"
                onClicked: bp.scan()
            }
        }
    }
}
