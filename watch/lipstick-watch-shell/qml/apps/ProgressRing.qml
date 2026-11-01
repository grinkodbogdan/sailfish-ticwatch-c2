/*
 * Ring progress indicator along the circle.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import ".."

Canvas {
    id: ring

    property real unit: 1
    property real value: 0          // 0..1
    property color color: Theme.timer
    property real thickness: 8

    renderStrategy: Canvas.Cooperative
    onValueChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        var c = getContext("2d")
        var t = thickness * unit
        var r = Math.min(width, height) / 2 - t
        c.reset()
        c.lineWidth = t
        c.lineCap = "round"
        c.strokeStyle = "#22222c"
        c.beginPath(); c.arc(width / 2, height / 2, r, 0, 2 * Math.PI); c.stroke()
        if (value > 0) {
            c.strokeStyle = color
            c.beginPath()
            c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(1, value))
            c.stroke()
        }
    }
}
