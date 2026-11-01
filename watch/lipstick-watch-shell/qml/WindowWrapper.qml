/*
 * Hosts one compositor window (Wayland client or in-process overlay) full screen.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6

Item {
    id: wrapper

    property Item window

    anchors.fill: parent
    visible: false

    Component.onCompleted: {
        if (!window)
            return
        window.parent = wrapper
        window.x = 0
        window.y = 0
        window.visible = true
        if (!window.isInProcess)
            window.resize(Qt.size(wrapper.width, wrapper.height))
        if (window.isInProcess)
            wrapper.visible = true
    }

    onWidthChanged: if (window && !window.isInProcess) window.resize(Qt.size(width, height))
    onHeightChanged: if (window && !window.isInProcess) window.resize(Qt.size(width, height))
}
