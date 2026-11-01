/*
 * List item with a Silica Switch (the glowing glass dot) on the right.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import "."

ListRow {
    id: row

    property bool checked
    property bool available: true
    property color onColor: Theme.highlight

    signal toggled

    opacity: available ? 1 : 0.4
    onClicked: if (available) toggled()

    Silica.Switch {
        anchors { right: parent.right; rightMargin: -2 * row.unit; verticalCenter: parent.verticalCenter }
        width: 56 * row.unit
        height: 56 * row.unit
        automaticCheck: false
        checked: row.checked
        highlighted: row.highlighted
        enabled: row.available
        onClicked: row.toggled()
    }
}
