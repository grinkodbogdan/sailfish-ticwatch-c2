/*
 * Calculator: round keypad, left-to-right evaluation.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import ".."

AppPage {
    id: app

    title: ""
    accent: Theme.calculator

    property string display: "0"
    property real acc: 0
    property string op: ""
    property bool fresh: true

    function input(k) {
        if (k >= "0" && k <= "9" || k === ".") {
            if (fresh) { display = (k === "." ? "0." : k); fresh = false }
            else if (!(k === "." && display.indexOf(".") >= 0) && display.length < 12) display += k
        } else if (k === "C") {
            display = "0"; acc = 0; op = ""; fresh = true
        } else if (k === "±") {
            display = display.charAt(0) === "-" ? display.substring(1) : (display === "0" ? "0" : "-" + display)
        } else {
            var v = parseFloat(display)
            if (op !== "" && !fresh) {
                if (op === "+") acc += v
                else if (op === "−") acc -= v
                else if (op === "×") acc *= v
                else if (op === "÷") acc = v === 0 ? NaN : acc / v
            } else if (op === "" || k === "=") {
                acc = v
            }
            display = isFinite(acc) ? String(parseFloat(acc.toPrecision(10))) : "Error"
            op = k === "=" ? "" : k
            fresh = true
        }
    }

    Silica.Label {
        id: screen
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: -16 * app.unit }
        width: 210 * app.unit
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        color: Theme.calculator
        font { pixelSize: 36 * app.unit; weight: Font.Light }
        text: app.display
    }

    Grid {
        anchors { horizontalCenter: parent.horizontalCenter; top: screen.bottom; topMargin: 6 * app.unit }
        columns: 4
        spacing: 6 * app.unit
        Repeater {
            model: ["7", "8", "9", "÷", "4", "5", "6", "×", "1", "2", "3", "−", "C", "0", "=", "+"]
            Rectangle {
                readonly property bool isOp: "÷×−+=".indexOf(modelData) >= 0
                width: 50 * app.unit
                height: 44 * app.unit
                radius: height / 2
                color: mouse.pressed ? Theme.surfaceHigh : (isOp ? Theme.dim(Theme.calculator, 0.22) : Theme.surface)
                Silica.Label {
                    anchors.centerIn: parent
                    color: parent.isOp ? Theme.calculator : (modelData === "C" ? Theme.timer : Theme.text)
                    font.pixelSize: 22 * app.unit
                    text: modelData
                }
                MouseArea { id: mouse; anchors.fill: parent; onClicked: app.input(modelData) }
            }
        }
    }
}
