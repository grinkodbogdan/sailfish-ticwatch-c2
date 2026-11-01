/*
 * Timer: pick minutes:seconds, countdown ring. Uses a Nemo.Alarms countdown
 * alarm, so it rings through the system alarm UI even if the watch sleeps.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import Nemo.Alarms 1.0
import ".."

AppPage {
    id: app

    title: "Timer"
    accent: Theme.timer

    property int total: 300          // seconds
    property double endTime: 0       // ms since epoch, 0 = stopped
    property int remaining: total
    property var countdown: null

    AlarmsModel { id: alarms; onlyCountdown: true }

    function fmt(s) {
        var m = Math.floor(s / 60), r = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r
    }

    function start() {
        endTime = Date.now() + total * 1000
        countdown = alarms.createAlarm()
        countdown.countdown = true
        countdown.second = total
        countdown.title = "Timer"
        countdown.enabled = true
        countdown.save()
    }

    function stop() {
        endTime = 0
        remaining = total
        if (countdown) {
            countdown.deleteAlarm()
            countdown = null
        }
    }

    Timer {
        running: app.endTime > 0
        interval: 250
        repeat: true
        onTriggered: {
            app.remaining = Math.max(0, Math.round((app.endTime - Date.now()) / 1000))
            if (app.remaining === 0) {
                app.endTime = 0
                app.countdown = null
                app.remaining = app.total
            }
        }
    }

    ProgressRing {
        parent: app
        anchors.fill: parent
        anchors.margins: 6 * app.unit
        unit: app.unit
        color: Theme.timer
        value: app.endTime > 0 ? app.remaining / app.total : 0
    }

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 20 * app.unit }
        spacing: 14 * app.unit

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14 * app.unit
            visible: app.endTime === 0
            CircleButton { unit: app.unit; size: 44; label: "−"; accent: Theme.timer; onClicked: app.total = Math.max(10, app.total - (app.total > 60 ? 60 : 10)) }
            Silica.Label {
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                font { pixelSize: 54 * app.unit; weight: Font.Light }
                text: app.fmt(app.total)
            }
            CircleButton { unit: app.unit; size: 44; icon: "icon-m-add"; accent: Theme.timer; onClicked: app.total = Math.min(5940, app.total + (app.total >= 60 ? 60 : 10)) }
        }

        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: app.endTime > 0
            color: Theme.text
            font { pixelSize: 64 * app.unit; weight: Font.Light }
            text: app.fmt(app.remaining)
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10 * app.unit
            visible: app.endTime === 0
            Repeater {
                model: [60, 180, 300, 600]
                Rectangle {
                    width: 52 * app.unit
                    height: 32 * app.unit
                    radius: height / 2
                    color: app.total === modelData ? Theme.timer : Theme.surface
                    Silica.Label {
                        anchors.centerIn: parent
                        color: app.total === modelData ? "black" : Theme.textDim
                        font.pixelSize: 14 * app.unit
                        text: (modelData / 60) + "m"
                    }
                    MouseArea { anchors.fill: parent; onClicked: app.total = modelData }
                }
            }
        }
    }

    CircleButton {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 * app.unit }
        unit: app.unit
        size: 64
        icon: app.endTime > 0 ? "icon-m-pause" : "icon-m-play"
        accent: Theme.timer
        filled: true
        onClicked: app.endTime > 0 ? app.stop() : app.start()
    }
}
