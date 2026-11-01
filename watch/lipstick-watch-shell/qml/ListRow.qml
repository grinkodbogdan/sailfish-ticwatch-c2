/*
 * Sailfish-style list item: no background, ambience highlight while pressed,
 * monochrome theme icon, label, value in the secondary colour.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import "."

Item {
    id: row

    property real unit: 1
    property string icon            // Sailfish theme icon name, e.g. "icon-m-alarm"
    property color iconColor: highlighted ? Theme.highlight : Theme.text
    property string label
    property string value
    property string valueIcon       // small icon in place of the value text
    property color labelColor: highlighted ? Theme.highlight : Theme.text
    readonly property bool highlighted: mouse.pressed && mouse.containsMouse
    property alias pressed: mouse.pressed

    signal clicked
    signal pressAndHold

    width: 260 * unit
    height: 56 * unit

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.pressBackground
        visible: row.highlighted
    }

    SfIcon {
        id: iconItem
        visible: row.icon !== ""
        anchors { left: parent.left; leftMargin: 12 * row.unit; verticalCenter: parent.verticalCenter }
        width: 34 * row.unit
        name: row.icon
        color: row.iconColor
    }

    Silica.Label {
        anchors {
            left: iconItem.visible ? iconItem.right : parent.left
            leftMargin: iconItem.visible ? 12 * row.unit : 20 * row.unit
            right: valueText.left
            rightMargin: 8 * row.unit
            verticalCenter: parent.verticalCenter
        }
        color: row.labelColor
        truncationMode: Silica.TruncationMode.Fade
        font.pixelSize: 21 * row.unit
        text: row.label
    }

    Silica.Label {
        id: valueText
        anchors { right: parent.right; rightMargin: 18 * row.unit; verticalCenter: parent.verticalCenter }
        color: row.highlighted ? Theme.secondaryHighlight : Theme.textDim
        font.pixelSize: 17 * row.unit
        text: row.value
    }

    SfIcon {
        visible: row.valueIcon !== "" && row.value === ""
        anchors { right: parent.right; rightMargin: 16 * row.unit; verticalCenter: parent.verticalCenter }
        width: 24 * row.unit
        name: row.valueIcon
        color: row.highlighted ? Theme.secondaryHighlight : Theme.textDim
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        onClicked: row.clicked()
        onPressAndHold: row.pressAndHold()
    }
}
