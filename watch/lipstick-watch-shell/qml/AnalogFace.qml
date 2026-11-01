/*
 * Analog watch face: hour ticks, hour/minute/second hands, date window at
 * 3 o'clock, battery at 6 o'clock.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import "."

Item {
    id: face

    property real unit: 1
    property date time
    property int batteryPercent: -1
    property bool charging
    property color accent: Theme.notifications

    readonly property real radius: Math.min(width, height) / 2
    readonly property real hours: time.getHours() % 12 + time.getMinutes() / 60
    readonly property real minutes: time.getMinutes() + time.getSeconds() / 60
    readonly property real seconds: time.getSeconds()

    // Hour and minute ticks.
    Repeater {
        model: 60
        Item {
            width: face.width
            height: face.height
            rotation: index * 6
            Rectangle {
                readonly property bool major: index % 5 === 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: 14 * face.unit
                width: (major ? 4 : 2) * face.unit
                height: (major ? 18 : 8) * face.unit
                radius: width / 2
                color: major ? (index === 0 ? face.accent : Theme.text) : Theme.textFaint
                antialiasing: true
            }
        }
    }

    // Numerals at 12, 3, 6, 9 would collide with the complications at 3
    // and 6, so only 12 and 9 get one.
    Silica.Label {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 38 * face.unit }
        color: Theme.text
        font { pixelSize: 30 * face.unit; family: Theme.fontFamilyHeading }
        text: "12"
    }
    Silica.Label {
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 40 * face.unit }
        color: Theme.text
        font { pixelSize: 30 * face.unit; family: Theme.fontFamilyHeading }
        text: "9"
    }

    // Date window at 3 o'clock.
    Rectangle {
        anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 34 * face.unit }
        width: dateText.width + 14 * face.unit
        height: dateText.height + 6 * face.unit
        radius: 6 * face.unit
        color: Theme.dim(face.accent, 0.12)
        border.color: Theme.dim(face.accent, 0.5)
        border.width: 1
        Silica.Label {
            id: dateText
            anchors.centerIn: parent
            color: face.accent
            font.pixelSize: 18 * face.unit
            text: Qt.formatDate(face.time, "ddd d").toUpperCase()
        }
    }

    // Battery at 6 o'clock.
    Silica.Label {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 44 * face.unit }
        color: face.charging ? Theme.battery : (face.batteryPercent >= 0 && face.batteryPercent <= 15 ? Theme.timer : Theme.textDim)
        font.pixelSize: 18 * face.unit
        text: (face.batteryPercent >= 0 ? face.batteryPercent + "%" : "--") + (face.charging ? " ⚡" : "")
    }

    Hand { anchors.fill: parent; angle: face.hours * 30; length: face.radius * 0.5; thickness: 8 * face.unit; tail: 14 * face.unit }
    Hand { anchors.fill: parent; angle: face.minutes * 6; length: face.radius * 0.75; thickness: 5 * face.unit; tail: 16 * face.unit }
    Hand { anchors.fill: parent; angle: face.seconds * 6; length: face.radius * 0.82; thickness: 2 * face.unit; tail: 24 * face.unit; color: face.accent }

    Rectangle {
        anchors.centerIn: parent
        width: 14 * face.unit
        height: width
        radius: width / 2
        color: face.accent
        border.color: "black"
        border.width: 2 * face.unit
    }
}
