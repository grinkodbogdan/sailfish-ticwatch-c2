/*
 * One clock hand: an Item covering the face, rotated around its centre, with
 * the hand drawn from the centre outwards (plus a short tail).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import "."

Item {
    id: hand

    property real angle
    property real length
    property real thickness
    property real tail: 0
    property color color: Theme.text

    rotation: angle

    Rectangle {
        x: hand.width / 2 - width / 2
        y: hand.height / 2 - hand.length
        width: hand.thickness
        height: hand.length + hand.tail
        radius: width / 2
        color: hand.color
        antialiasing: true
    }
}
