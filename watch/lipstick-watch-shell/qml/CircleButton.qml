/*
 * Round button in the Sailfish IconButton style: a theme icon (or a text
 * label) that turns highlight-coloured when pressed; `filled` draws the
 * ambience highlight disc used for primary actions and active toggles.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import "."

Item {
    id: button

    property real unit: 1
    property string icon            // Sailfish theme icon name
    property string label
    property color accent: Theme.highlight
    property bool filled
    property real size: 64
    readonly property bool down: mouse.pressed && mouse.containsMouse

    signal clicked
    signal pressAndHold

    width: size * unit
    height: width
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: button.filled ? Theme.dim(Theme.highlightBackground, button.down ? 0.75 : 0.5)
                             : (button.down ? Theme.pressBackground : "transparent")
        border.color: button.filled ? "transparent" : Theme.dim(Theme.text, 0.25)
        border.width: Math.max(1, 1.5 * button.unit)
    }

    SfIcon {
        visible: button.icon !== ""
        anchors.centerIn: parent
        width: parent.width * 0.6
        name: button.icon
        color: button.down ? Theme.highlight : (button.filled ? Theme.text : Theme.text)
    }

    Silica.Label {
        visible: button.icon === ""
        anchors.centerIn: parent
        color: button.down ? Theme.highlight : Theme.text
        font { pixelSize: button.width * 0.36; family: Theme.fontFamilyHeading }
        text: button.label
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: button.clicked()
        onPressAndHold: button.pressAndHold()
    }
}
