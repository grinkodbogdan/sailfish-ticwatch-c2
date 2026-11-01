/*
 * The current Sailfish ambience wallpaper with a dimmer on top, as behind
 * Sailfish pages.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import "."

Item {
    property real dim: 0.55

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Image {
        anchors.fill: parent
        source: Theme.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: width
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, parent.dim)
    }
}
