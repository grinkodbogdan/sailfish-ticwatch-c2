/*
 * Heart rate: a spot measurement with the optical sensor (PAH8011), through
 * skipjack-sensorhelper on the system bus. Measures for up to 30 s, or until
 * the reading has been steady for a few seconds, then shows the result; the
 * last result is kept in dconf.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import Nemo.DBus 2.0
import Nemo.KeepAlive 1.2
import Nemo.Configuration 1.0
import ".."

AppPage {
    id: app

    title: "Heart rate"
    accent: Theme.highlight

    readonly property int duration: 30
    property bool measuring: false
    property bool available: true
    property int bpm: 0
    property int status: -1          // 3..1 accuracy, 0 unreliable, -1 no contact
    property int elapsed: 0
    property int steady: 0           // consecutive accurate readings
    property var readings: []

    function start() {
        if (!available)
            return
        bpm = 0
        status = -1
        elapsed = 0
        steady = 0
        readings = []
        measuring = true
        sensors.call("startHeartRate", [])
    }

    function finish() {
        measuring = false
        sensors.call("stopHeartRate", [])
        if (readings.length > 0) {
            var sorted = readings.slice().sort(function(a, b) { return a - b })
            bpm = sorted[Math.floor(sorted.length / 2)]
            lastBpm.value = bpm
            lastTime.value = new Date().getTime()
        }
    }

    DBusInterface {
        id: sensors
        bus: DBus.SystemBus
        service: "org.sailfishos.skipjack.Sensors"
        path: "/"
        iface: "org.sailfishos.skipjack.Sensors"
        signalsEnabled: true

        function heartRate(value, accuracy) {
            if (!app.measuring)
                return
            app.status = accuracy
            if (value > 0 && accuracy >= 0)
                app.bpm = value
            if (value > 0 && accuracy >= 1) {
                var r = app.readings
                r.push(value)
                app.readings = r
                app.steady++
                if (app.steady >= 8)
                    app.finish()
            } else {
                app.steady = 0
            }
        }
    }

    ConfigurationValue { id: lastBpm; key: "/desktop/watchshell/heartrate/last"; defaultValue: 0 }
    ConfigurationValue { id: lastTime; key: "/desktop/watchshell/heartrate/time"; defaultValue: 0 }

    DisplayBlanking { preventBlanking: app.measuring }

    Timer {
        running: app.measuring
        interval: 1000
        repeat: true
        onTriggered: {
            app.elapsed++
            if (app.elapsed >= app.duration)
                app.finish()
        }
    }

    Component.onCompleted: {
        sensors.typedCall("heartRateAvailable", [],
                          function(ok) { app.available = ok; if (ok) app.start() },
                          function() { app.available = false })
    }
    Component.onDestruction: if (measuring) sensors.call("stopHeartRate", [])

    ProgressRing {
        parent: app
        anchors.fill: parent
        anchors.margins: 6 * app.unit
        unit: app.unit
        thickness: 10
        color: Theme.highlight
        value: app.measuring ? app.elapsed / app.duration : 0
        visible: app.measuring
    }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -10 * app.unit
        spacing: 0

        Image {
            id: heart
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56 * app.unit
            height: width
            sourceSize { width: width; height: height }
            source: Theme.icon("icon-m-health", app.measuring ? Theme.highlight : Theme.textDim)

            SequentialAnimation on scale {
                running: app.measuring && app.bpm > 0
                loops: Animation.Infinite
                alwaysRunToEnd: true
                NumberAnimation { to: 1.18; duration: 120; easing.type: Easing.OutQuad }
                NumberAnimation { to: 1.0; duration: 260; easing.type: Easing.InQuad }
                PauseAnimation { duration: Math.max(80, 60000 / Math.max(app.bpm, 30) - 380) }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6 * app.unit
            Silica.Label {
                color: app.measuring && app.status < 1 ? Theme.textDim : Theme.text
                font { pixelSize: 76 * app.unit; family: Theme.fontFamilyHeading; weight: Font.Light }
                text: app.bpm > 0 ? app.bpm : "--"
            }
            Silica.Label {
                anchors.baseline: parent.children[0].baseline
                color: Theme.highlight
                font.pixelSize: 20 * app.unit
                text: "bpm"
            }
        }

        Silica.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200 * app.unit
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: Theme.textDim
            font.pixelSize: 16 * app.unit
            text: {
                if (!app.available)
                    return "Heart rate sensor not available"
                if (app.measuring)
                    return app.status < 0 ? "Wear the watch snugly\nand keep still"
                                          : "Measuring…"
                if (lastTime.value > 0)
                    return "Measured " + Qt.formatTime(new Date(lastTime.value), "hh:mm")
                return ""
            }
        }
    }

    CircleButton {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 20 * app.unit }
        unit: app.unit
        size: 48
        icon: app.measuring ? "icon-m-pause" : "icon-m-refresh"
        filled: !app.measuring
        visible: app.available
        onClicked: app.measuring ? app.finish() : app.start()
    }
}
