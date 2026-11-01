/*
 * Torch: full white screen at maximum brightness; tap to close.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import org.nemomobile.systemsettings 1.0
import Nemo.KeepAlive 1.2
import ".."

Rectangle {
    id: app

    property real unit: 1
    signal closeRequested

    color: "white"

    DisplaySettings { id: display }
    property int savedBrightness: -1

    // Keep the screen on while the torch is shown.
    DisplayBlanking { preventBlanking: app.visible }

    Component.onCompleted: {
        savedBrightness = display.brightness
        if (display.maximumBrightness > 0)
            display.brightness = display.maximumBrightness
    }
    Component.onDestruction: {
        if (savedBrightness > 0)
            display.brightness = savedBrightness
    }

    Silica.Label {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 40 * app.unit }
        color: "#999999"
        font.pixelSize: 15 * app.unit
        text: "tap to turn off"
    }

    MouseArea { anchors.fill: parent; onClicked: app.closeRequested() }
}
