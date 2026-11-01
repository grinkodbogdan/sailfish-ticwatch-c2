/*
 * Hour / minute wheels for the round screen.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import ".."

Row {
    id: picker

    property real unit: 1
    property color accent: Theme.alarms
    property int hour: 7
    property int minute: 0

    spacing: 18 * unit

    Repeater {
        model: 2
        Item {
            readonly property bool isHour: index === 0
            width: 80 * picker.unit
            height: 150 * picker.unit

            Rectangle {
                anchors.centerIn: parent
                width: parent.width
                height: 50 * picker.unit
                radius: 12 * picker.unit
                color: Theme.dim(picker.accent, 0.18)
                border.color: Theme.dim(picker.accent, 0.6)
                border.width: 1
            }

            ListView {
                id: wheel
                anchors.fill: parent
                clip: true
                model: isHour ? 24 : 60
                readonly property real rowHeight: 50 * picker.unit
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: height / 2 - rowHeight / 2
                preferredHighlightEnd: height / 2 + rowHeight / 2
                snapMode: ListView.SnapOneItem
                Component.onCompleted: positionViewAtIndex(isHour ? picker.hour : picker.minute, ListView.Center)
                onCurrentIndexChanged: {
                    if (isHour) picker.hour = currentIndex
                    else picker.minute = currentIndex
                }
                delegate: Silica.Label {
                    width: ListView.view.width
                    height: wheel.rowHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: ListView.isCurrentItem ? Theme.text : Theme.textFaint
                    font.pixelSize: (ListView.isCurrentItem ? 36 : 26) * picker.unit
                    text: (index < 10 ? "0" : "") + index
                }
            }
        }
    }
}
