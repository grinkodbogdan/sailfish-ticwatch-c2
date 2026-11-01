/*
 * List section heading, Sailfish style: highlight colour, right-aligned.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import "."

Silica.Label {
    property real unit: 1

    anchors.horizontalCenter: parent.horizontalCenter
    width: 240 * unit
    height: visible ? 40 * unit : 0
    verticalAlignment: Text.AlignBottom
    horizontalAlignment: Text.AlignRight
    color: Theme.highlight
    font.pixelSize: 15 * unit
}
