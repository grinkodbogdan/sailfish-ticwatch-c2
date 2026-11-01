/*
 * A Sailfish theme icon (image://theme/<name>), tinted with `color`.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import "."

Image {
    property string name
    property color color: Theme.text

    width: 48
    height: width
    sourceSize.width: width
    sourceSize.height: height
    fillMode: Image.PreserveAspectFit
    // Launcher icons are full colour; only monochrome icons get tinted.
    source: name === "" ? "" : (name.indexOf("icon-launcher") === 0 ? "image://theme/" + name : Theme.icon(name, color))
}
