/*
 * Stopwatch with laps.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import ".."

AppPage {
    id: app

    title: "Stopwatch"
    accent: Theme.stopwatch

    property double startedAt: 0     // ms since epoch while running
    property double accumulated: 0   // ms
    property double elapsed: 0
    readonly property bool running: startedAt > 0

    ListModel { id: laps }

    function fmt(ms) {
        var cs = Math.floor(ms / 10) % 100
        var s = Math.floor(ms / 1000) % 60
        var m = Math.floor(ms / 60000)
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s + "." + (cs < 10 ? "0" : "") + cs
    }

    Timer {
        running: app.running && app.visible
        interval: 40
        repeat: true
        onTriggered: app.elapsed = app.accumulated + Date.now() - app.startedAt
    }

    Silica.Label {
        id: time
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 4 * app.unit }
        color: app.running ? Theme.stopwatch : Theme.text
        font { pixelSize: 50 * app.unit; weight: Font.Light }
        text: app.fmt(app.elapsed)
    }

    ListView {
        anchors { top: time.bottom; topMargin: 6 * app.unit; bottom: buttons.top; bottomMargin: 6 * app.unit; horizontalCenter: parent.horizontalCenter }
        width: 200 * app.unit
        clip: true
        model: laps
        delegate: Item {
            width: ListView.view.width
            height: 26 * app.unit
            Silica.Label { anchors.left: parent.left; color: Theme.textDim; font.pixelSize: 15 * app.unit; text: "Lap " + (laps.count - index) }
            Silica.Label { anchors.right: parent.right; color: Theme.text; font.pixelSize: 15 * app.unit; text: model.time }
        }
    }

    Row {
        id: buttons
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 * app.unit }
        spacing: 22 * app.unit

        CircleButton {
            unit: app.unit
            size: 52
            label: app.running ? "LAP" : "↺"
            accent: Theme.stopwatch
            enabled: app.running || app.elapsed > 0
            onClicked: {
                if (app.running)
                    laps.insert(0, { "time": app.fmt(app.elapsed) })
                else {
                    app.accumulated = 0
                    app.elapsed = 0
                    laps.clear()
                }
            }
        }
        CircleButton {
            unit: app.unit
            size: 64
            icon: app.running ? "icon-m-pause" : "icon-m-play"
            accent: Theme.stopwatch
            filled: true
            onClicked: {
                if (app.running) {
                    app.accumulated += Date.now() - app.startedAt
                    app.startedAt = 0
                    app.elapsed = app.accumulated
                } else {
                    app.startedAt = Date.now()
                }
            }
        }
    }
}
