/*
 * Clock: alarms, timer and stopwatch, as in the Sailfish Clock app.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import Nemo.Time 1.0
import ".."

AppPage {
    id: app

    title: "Clock"

    WallClock { id: clock; updateFrequency: WallClock.Minute }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4 * app.unit

        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.text
            font { pixelSize: 48 * app.unit; family: Theme.fontFamilyHeading }
            text: Qt.formatTime(clock.time, "hh:mm")
        }

        Item { width: 1; height: 6 * app.unit }

        ListRow {
            anchors.horizontalCenter: parent.horizontalCenter
            unit: app.unit
            icon: "icon-m-alarm"
            label: "Alarms"
            onClicked: app.push(Qt.createComponent("AlarmsApp.qml"))
        }
        ListRow {
            anchors.horizontalCenter: parent.horizontalCenter
            unit: app.unit
            icon: "icon-m-timer"
            label: "Timer"
            onClicked: app.push(Qt.createComponent("TimerApp.qml"))
        }
        ListRow {
            anchors.horizontalCenter: parent.horizontalCenter
            unit: app.unit
            icon: "icon-m-clock"
            label: "Stopwatch"
            onClicked: app.push(Qt.createComponent("StopwatchApp.qml"))
        }
    }
}
