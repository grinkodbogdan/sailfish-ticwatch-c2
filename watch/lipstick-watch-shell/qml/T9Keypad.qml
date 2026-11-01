/*
 * Text entry for the round screen: a phone keypad with multi-tap (T9 style).
 * Tap a key repeatedly to cycle its letters; the letter is taken after a
 * short pause or when another key is pressed. Long-press enters the digit.
 *   1      punctuation and symbols
 *   0      space
 *   mode   abc -> Abc (next letter) -> ABC -> 123 (digits only, one tap)
 *   ⌫      delete (long-press: clear)
 * The field on top shows the text in clear, the letter being cycled in the
 * highlight colour; ✕ and ✓ beside it cancel and accept.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import "."

Item {
    id: keypad

    property real unit: 1
    property string title
    property string text
    property string placeholder: "Password"
    // 0 lower, 1 next letter upper, 2 upper, 3 digits only
    property int caseMode: 0
    readonly property bool numbers: caseMode === 3

    signal accepted(string text)
    signal canceled

    // Multi-tap state: the key being cycled and the position in its cycle.
    property string pendingKey: ""
    property int pendingIndex: 0

    readonly property var cycles: {
        "1": ".,?!@-_'/:;&#$%*+=()\"1",
        "2": "abc2", "3": "def3",
        "4": "ghi4", "5": "jkl5", "6": "mno6",
        "7": "pqrs7", "8": "tuv8", "9": "wxyz9",
        "0": " 0"
    }

    function reset() {
        text = ""
        caseMode = 0
        pendingKey = ""
        commitTimer.stop()
    }

    function applyCase(c) {
        return caseMode === 1 || caseMode === 2 ? c.toUpperCase() : c
    }

    function commit() {
        if (pendingKey !== "" && caseMode === 1 && cycles[pendingKey].charAt(pendingIndex).match(/[a-z]/))
            caseMode = 0
        pendingKey = ""
        commitTimer.stop()
    }

    function tap(key) {
        if (numbers) {
            digit(key)
            return
        }
        var cycle = cycles[key]
        if (key === pendingKey && commitTimer.running) {
            pendingIndex = (pendingIndex + 1) % cycle.length
            text = text.slice(0, -1) + applyCase(cycle.charAt(pendingIndex))
        } else {
            commit()
            pendingKey = key
            pendingIndex = 0
            text += applyCase(cycle.charAt(0))
        }
        commitTimer.restart()
    }

    function digit(key) {
        commit()
        text += key
    }

    function backspace() {
        commit()
        text = text.slice(0, -1)
    }

    Timer {
        id: commitTimer
        interval: 900
        onTriggered: keypad.commit()
    }

    Wallpaper {
        anchors.fill: parent
        dim: 0.8
    }

    // Swallow touches so nothing underneath reacts.
    MouseArea { anchors.fill: parent }

    Silica.Label {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 20 * keypad.unit }
        width: 190 * keypad.unit
        horizontalAlignment: Text.AlignHCenter
        truncationMode: Silica.TruncationMode.Fade
        color: Theme.highlight
        font.pixelSize: 17 * keypad.unit
        text: keypad.title
    }

    // ---- field row: cancel, text, accept --------------------------------
    Row {
        id: fieldRow
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 48 * keypad.unit }
        spacing: 6 * keypad.unit

        CircleButton {
            anchors.verticalCenter: parent.verticalCenter
            unit: keypad.unit
            size: 40
            icon: "icon-m-cancel"
            onClicked: { keypad.commit(); keypad.canceled() }
        }

        Rectangle {
            width: 152 * keypad.unit
            height: 40 * keypad.unit
            radius: height / 2
            color: Theme.surface
            border.color: Theme.dim(Theme.highlight, 0.6)
            border.width: Math.max(1, keypad.unit)
            clip: true

            Silica.Label {
                id: field
                anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 14 * keypad.unit }
                width: Math.min(implicitWidth, parent.width - 28 * keypad.unit)
                horizontalAlignment: implicitWidth > width ? Text.AlignRight : Text.AlignHCenter
                elide: Text.ElideLeft
                color: Theme.text
                font.pixelSize: 20 * keypad.unit
                textFormat: Text.StyledText
                text: {
                    function escape(t) {
                        return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/ /g, "&nbsp;")
                    }
                    var t = keypad.text
                    if (!commitTimer.running || t.length === 0)
                        return escape(t)
                    return escape(t.slice(0, -1)) + "<font color=\"" + Theme.highlight + "\">"
                            + escape(t.slice(-1)) + "</font>"
                }
            }

            Silica.Label {
                anchors.centerIn: parent
                visible: keypad.text.length === 0
                color: Theme.textFaint
                font.pixelSize: 15 * keypad.unit
                text: keypad.placeholder
            }
        }

        CircleButton {
            anchors.verticalCenter: parent.verticalCenter
            unit: keypad.unit
            size: 40
            filled: true
            icon: "icon-m-accept"
            enabled: keypad.text.length > 0
            onClicked: { keypad.commit(); keypad.accepted(keypad.text) }
        }
    }

    // ---- keypad -----------------------------------------------------------
    Grid {
        id: grid
        anchors { horizontalCenter: parent.horizontalCenter; top: fieldRow.bottom; topMargin: 10 * keypad.unit }
        columns: 3
        columnSpacing: 6 * keypad.unit
        rowSpacing: 5 * keypad.unit

        Repeater {
            model: [
                { "key": "1", "letters": ".,?!" }, { "key": "2", "letters": "abc" }, { "key": "3", "letters": "def" },
                { "key": "4", "letters": "ghi" }, { "key": "5", "letters": "jkl" }, { "key": "6", "letters": "mno" },
                { "key": "7", "letters": "pqrs" }, { "key": "8", "letters": "tuv" }, { "key": "9", "letters": "wxyz" },
                { "key": "*", "letters": "" }, { "key": "0", "letters": "␣" }, { "key": "del", "letters": "" }
            ]

            Rectangle {
                id: key
                readonly property bool down: keyMouse.pressed
                readonly property bool cycling: keypad.pendingKey === modelData.key && commitTimer.running

                width: 72 * keypad.unit
                height: 44 * keypad.unit
                radius: height / 2
                color: down ? Theme.pressBackground : (cycling ? Theme.surfaceHigh : Theme.surface)

                Column {
                    anchors.centerIn: parent
                    visible: modelData.key !== "del" && modelData.key !== "*"
                    spacing: -4 * keypad.unit
                    Silica.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: key.down || key.cycling ? Theme.highlight : Theme.text
                        font { pixelSize: 21 * keypad.unit; family: Theme.fontFamilyHeading }
                        text: modelData.key
                    }
                    Silica.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: modelData.letters !== "" && !keypad.numbers
                        color: key.down || key.cycling ? Theme.highlight : Theme.textDim
                        font.pixelSize: 11 * keypad.unit
                        text: keypad.caseMode === 1 || keypad.caseMode === 2 ? modelData.letters.toUpperCase() : modelData.letters
                    }
                }

                // Case key: shows the current mode.
                Silica.Label {
                    anchors.centerIn: parent
                    visible: modelData.key === "*"
                    color: keypad.caseMode > 0 ? Theme.highlight : Theme.text
                    font.pixelSize: 17 * keypad.unit
                    text: ["abc", "Abc", "ABC", "123"][keypad.caseMode]
                }

                SfIcon {
                    anchors.centerIn: parent
                    visible: modelData.key === "del"
                    width: 32 * keypad.unit
                    name: "icon-m-backspace-keypad"
                    color: key.down ? Theme.highlight : Theme.text
                }

                MouseArea {
                    id: keyMouse
                    anchors.fill: parent
                    onClicked: {
                        if (modelData.key === "del")
                            keypad.backspace()
                        else if (modelData.key === "*") {
                            keypad.commit()
                            keypad.caseMode = (keypad.caseMode + 1) % 4
                        } else
                            keypad.tap(modelData.key)
                    }
                    onPressAndHold: {
                        if (modelData.key === "del") {
                            keypad.commit()
                            keypad.text = ""
                        } else if (modelData.key !== "*") {
                            keypad.digit(modelData.key)
                        }
                    }
                }
            }
        }
    }
}
