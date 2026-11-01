/*
 * Small line-art icons drawn with Canvas, so the shell does not depend on a
 * particular icon theme. name: settings alarm timer stopwatch agenda music
 * calculator torch battery bell wifi bluetooth back plus play pause next
 * previous phone moon sun power info watch.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6

Canvas {
    id: glyph

    property string name
    property color color: "white"
    property real stroke: Math.max(1.5, width / 14)

    width: 32
    height: 32
    renderStrategy: Canvas.Cooperative
    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        var c = getContext("2d")
        var w = width, h = height, s = Math.min(w, h)
        var cx = w / 2, cy = h / 2
        c.reset()
        c.strokeStyle = glyph.color
        c.fillStyle = glyph.color
        c.lineWidth = glyph.stroke
        c.lineCap = "round"
        c.lineJoin = "round"

        function line(x1, y1, x2, y2) { c.beginPath(); c.moveTo(x1, y1); c.lineTo(x2, y2); c.stroke() }
        function circle(x, y, r, fill) { c.beginPath(); c.arc(x, y, r, 0, 2 * Math.PI); if (fill) c.fill(); else c.stroke() }
        function rect(x, y, rw, rh, fill) { c.beginPath(); c.rect(x, y, rw, rh); if (fill) c.fill(); else c.stroke() }
        function tri(x1, y1, x2, y2, x3, y3) { c.beginPath(); c.moveTo(x1, y1); c.lineTo(x2, y2); c.lineTo(x3, y3); c.closePath(); c.fill() }

        switch (glyph.name) {
        case "settings":
            for (var i = 0; i < 8; i++) {
                var a = i * Math.PI / 4
                line(cx + Math.cos(a) * s * 0.28, cy + Math.sin(a) * s * 0.28,
                     cx + Math.cos(a) * s * 0.42, cy + Math.sin(a) * s * 0.42)
            }
            circle(cx, cy, s * 0.26)
            circle(cx, cy, s * 0.1)
            break
        case "alarm":
        case "bell":
            c.beginPath()
            c.moveTo(cx - s * 0.3, cy + s * 0.2)
            c.quadraticCurveTo(cx - s * 0.26, cy - s * 0.36, cx, cy - s * 0.36)
            c.quadraticCurveTo(cx + s * 0.26, cy - s * 0.36, cx + s * 0.3, cy + s * 0.2)
            c.closePath()
            c.stroke()
            circle(cx, cy + s * 0.3, s * 0.06, true)
            if (glyph.name === "alarm") {
                line(cx - s * 0.42, cy - s * 0.3, cx - s * 0.3, cy - s * 0.42)
                line(cx + s * 0.42, cy - s * 0.3, cx + s * 0.3, cy - s * 0.42)
            }
            break
        case "timer":
            circle(cx, cy + s * 0.05, s * 0.34)
            line(cx, cy + s * 0.05, cx + s * 0.16, cy - s * 0.12)
            line(cx - s * 0.1, cy - s * 0.42, cx + s * 0.1, cy - s * 0.42)
            break
        case "stopwatch":
            circle(cx, cy + s * 0.06, s * 0.32)
            line(cx, cy + s * 0.06, cx, cy - s * 0.12)
            line(cx, cy - s * 0.26, cx, cy - s * 0.4)
            line(cx + s * 0.24, cy - s * 0.2, cx + s * 0.32, cy - s * 0.28)
            break
        case "agenda":
            rect(cx - s * 0.34, cy - s * 0.28, s * 0.68, s * 0.62)
            line(cx - s * 0.34, cy - s * 0.1, cx + s * 0.34, cy - s * 0.1)
            line(cx - s * 0.16, cy - s * 0.4, cx - s * 0.16, cy - s * 0.2)
            line(cx + s * 0.16, cy - s * 0.4, cx + s * 0.16, cy - s * 0.2)
            circle(cx - s * 0.12, cy + s * 0.12, s * 0.04, true)
            circle(cx + s * 0.12, cy + s * 0.12, s * 0.04, true)
            break
        case "music":
            circle(cx - s * 0.16, cy + s * 0.24, s * 0.1, true)
            circle(cx + s * 0.22, cy + s * 0.16, s * 0.1, true)
            line(cx - s * 0.07, cy + s * 0.24, cx - s * 0.07, cy - s * 0.3)
            line(cx + s * 0.31, cy + s * 0.16, cx + s * 0.31, cy - s * 0.38)
            line(cx - s * 0.07, cy - s * 0.3, cx + s * 0.31, cy - s * 0.38)
            break
        case "calculator":
            rect(cx - s * 0.28, cy - s * 0.38, s * 0.56, s * 0.76)
            rect(cx - s * 0.18, cy - s * 0.28, s * 0.36, s * 0.16)
            for (var r = 0; r < 2; r++)
                for (var k = 0; k < 3; k++)
                    circle(cx - s * 0.14 + k * s * 0.14, cy + s * 0.06 + r * s * 0.16, s * 0.035, true)
            break
        case "torch":
            c.beginPath()
            c.moveTo(cx - s * 0.22, cy - s * 0.36); c.lineTo(cx + s * 0.22, cy - s * 0.36)
            c.lineTo(cx + s * 0.1, cy - s * 0.06); c.lineTo(cx + s * 0.1, cy + s * 0.38)
            c.lineTo(cx - s * 0.1, cy + s * 0.38); c.lineTo(cx - s * 0.1, cy - s * 0.06)
            c.closePath(); c.stroke()
            line(cx, cy + s * 0.04, cx, cy + s * 0.16)
            break
        case "battery":
            rect(cx - s * 0.18, cy - s * 0.32, s * 0.36, s * 0.7)
            rect(cx - s * 0.08, cy - s * 0.42, s * 0.16, s * 0.08, true)
            rect(cx - s * 0.1, cy + s * 0.02, s * 0.2, s * 0.28, true)
            break
        case "wifi":
            for (var j = 1; j <= 3; j++) {
                c.beginPath()
                c.arc(cx, cy + s * 0.28, s * 0.14 * j, -Math.PI * 0.78, -Math.PI * 0.22)
                c.stroke()
            }
            circle(cx, cy + s * 0.28, s * 0.05, true)
            break
        case "bluetooth":
            c.beginPath()
            c.moveTo(cx - s * 0.2, cy - s * 0.16); c.lineTo(cx + s * 0.18, cy + s * 0.18)
            c.lineTo(cx, cy + s * 0.38); c.lineTo(cx, cy - s * 0.38)
            c.lineTo(cx + s * 0.18, cy - s * 0.18); c.lineTo(cx - s * 0.2, cy + s * 0.16)
            c.stroke()
            break
        case "back":
            line(cx + s * 0.12, cy - s * 0.26, cx - s * 0.12, cy)
            line(cx - s * 0.12, cy, cx + s * 0.12, cy + s * 0.26)
            break
        case "plus":
            line(cx - s * 0.28, cy, cx + s * 0.28, cy)
            line(cx, cy - s * 0.28, cx, cy + s * 0.28)
            break
        case "play":
            tri(cx - s * 0.18, cy - s * 0.3, cx - s * 0.18, cy + s * 0.3, cx + s * 0.3, cy)
            break
        case "pause":
            rect(cx - s * 0.24, cy - s * 0.28, s * 0.16, s * 0.56, true)
            rect(cx + s * 0.08, cy - s * 0.28, s * 0.16, s * 0.56, true)
            break
        case "next":
            tri(cx - s * 0.3, cy - s * 0.26, cx - s * 0.3, cy + s * 0.26, cx + s * 0.04, cy)
            tri(cx - s * 0.02, cy - s * 0.26, cx - s * 0.02, cy + s * 0.26, cx + s * 0.32, cy)
            break
        case "previous":
            tri(cx + s * 0.3, cy - s * 0.26, cx + s * 0.3, cy + s * 0.26, cx - s * 0.04, cy)
            tri(cx + s * 0.02, cy - s * 0.26, cx + s * 0.02, cy + s * 0.26, cx - s * 0.32, cy)
            break
        case "phone":
            rect(cx - s * 0.2, cy - s * 0.38, s * 0.4, s * 0.76)
            line(cx - s * 0.06, cy + s * 0.28, cx + s * 0.06, cy + s * 0.28)
            break
        case "moon":
            c.beginPath()
            c.arc(cx, cy, s * 0.32, Math.PI * 0.35, Math.PI * 1.65)
            c.arc(cx + s * 0.14, cy - s * 0.04, s * 0.24, Math.PI * 1.45, Math.PI * 0.55, true)
            c.stroke()
            break
        case "sun":
            circle(cx, cy, s * 0.16)
            for (var m = 0; m < 8; m++) {
                var b = m * Math.PI / 4
                line(cx + Math.cos(b) * s * 0.26, cy + Math.sin(b) * s * 0.26,
                     cx + Math.cos(b) * s * 0.38, cy + Math.sin(b) * s * 0.38)
            }
            break
        case "power":
            c.beginPath(); c.arc(cx, cy + s * 0.04, s * 0.3, -Math.PI * 0.3, Math.PI * 1.3); c.stroke()
            line(cx, cy - s * 0.38, cx, cy - s * 0.02)
            break
        case "info":
            circle(cx, cy, s * 0.38)
            line(cx, cy - s * 0.02, cx, cy + s * 0.2)
            circle(cx, cy - s * 0.16, s * 0.04, true)
            break
        case "watch":
            circle(cx, cy, s * 0.26)
            line(cx, cy, cx, cy - s * 0.14)
            line(cx, cy, cx + s * 0.1, cy)
            line(cx - s * 0.14, cy - s * 0.22, cx - s * 0.1, cy - s * 0.4)
            line(cx + s * 0.14, cy - s * 0.22, cx + s * 0.1, cy - s * 0.4)
            line(cx - s * 0.14, cy + s * 0.22, cx - s * 0.1, cy + s * 0.4)
            line(cx + s * 0.14, cy + s * 0.22, cx + s * 0.1, cy + s * 0.4)
            break
        default:
            circle(cx, cy, s * 0.3)
        }
    }
}
