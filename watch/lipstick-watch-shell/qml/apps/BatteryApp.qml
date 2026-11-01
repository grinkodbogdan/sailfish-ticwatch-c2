/*
 * Battery: charge ring, charging state, power saving.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import Nemo.Mce 1.0
import org.nemomobile.systemsettings 1.0
import ".."

AppPage {
    id: app

    title: "Battery"
    accent: Theme.battery

    MceBatteryLevel { id: battery }
    MceCableState { id: cable }
    DisplaySettings { id: display }

    readonly property int percent: battery.valid ? battery.percent : 0
    readonly property color level: percent <= 15 ? Theme.timer : (percent <= 35 ? Theme.alarms : Theme.battery)

    ProgressRing {
        parent: app
        anchors.fill: parent
        anchors.margins: 6 * app.unit
        unit: app.unit
        thickness: 10
        color: app.level
        value: app.percent / 100
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 14 * app.unit }
        spacing: 4 * app.unit
        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: app.level
            font { pixelSize: 72 * app.unit; weight: Font.Light }
            text: battery.valid ? app.percent + "%" : "--"
        }
        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: cable.connected ? Theme.battery : Theme.textDim
            font.pixelSize: 17 * app.unit
            text: cable.connected ? "⚡ Charging" : "On battery"
        }
    }

    ToggleRow {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 46 * app.unit }
        unit: app.unit
        icon: "icon-m-battery-saver"
        iconColor: Theme.battery
        label: "Power saving"
        checked: display.powerSaveModeForced
        onToggled: display.powerSaveModeForced = !display.powerSaveModeForced
    }
}
