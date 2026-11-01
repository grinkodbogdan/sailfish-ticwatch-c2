/*
 * One launcher row: Sailfish launcher icon (or a monochrome icon on a
 * highlight disc) and its label. Shrinks/fades towards the rim of the
 * circle, based on its position in the Flickable `view`.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import "."

Item {
    id: row

    property Flickable view
    property real unit: 1
    property string label
    property string iconUrl
    property string monoIcon

    signal activated

    width: view ? view.width : 0
    height: 64 * unit

    // Position of the row's centre in the visible viewport. Depends on
    // view.contentY, so it updates while scrolling.
    readonly property real centerY: view ? (parent ? parent.y : 0) + y + height / 2 - view.contentY : 0
    readonly property real dist: view ? Math.min(1, Math.abs(centerY - view.height / 2) / (view.height / 2)) : 0
    readonly property real chord: view ? Math.sqrt(Math.max(0, 1 - dist * dist)) * view.width / 2 : 0
    readonly property bool down: mouse.pressed && mouse.containsMouse

    Row {
        anchors.centerIn: parent
        spacing: 14 * row.unit
        width: Math.max(0, Math.min(row.chord * 2 - 30 * row.unit, 250 * row.unit))
        scale: 1 - 0.35 * row.dist
        opacity: 1 - 0.8 * row.dist

        Item {
            id: iconBox
            width: 52 * row.unit
            height: width

            Image {
                anchors.fill: parent
                visible: row.iconUrl !== ""
                sourceSize.width: width
                sourceSize.height: height
                source: row.iconUrl
                asynchronous: true
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2 * row.unit
                visible: row.monoIcon !== ""
                radius: width / 2
                color: Theme.dim(Theme.highlightBackground, 0.6)
                SfIcon {
                    anchors.centerIn: parent
                    width: parent.width * 0.66
                    name: row.monoIcon
                    color: Theme.text
                }
            }
        }

        Silica.Label {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - iconBox.width - parent.spacing
            color: row.down ? Theme.highlight : Theme.text
            truncationMode: Silica.TruncationMode.Fade
            font.pixelSize: 22 * row.unit
            text: row.label
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: row.activated()
    }
}
