/*
 * Base for watch apps, Sailfish style: the ambience shows through a dimmer,
 * the page title sits at the top of the circle in the highlight colour.
 * Swipe right (from the left edge) to go back. Sub-pages are pushed with
 * push(component, properties).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import "."

Item {
    id: page

    property real unit: 1
    property string title
    property color accent: Theme.highlight
    default property alias content: body.data
    property var stack: []

    signal closeRequested

    function push(component, properties) {
        var props = properties || {}
        props.unit = page.unit
        var sub = component.createObject(page, props)
        // Sub-pages have no size of their own; make them cover this page.
        sub.anchors.fill = page
        sub.z = 10 + stack.length
        sub.closeRequested.connect(function() { page.pop() })
        var s = stack
        s.push(sub)
        stack = s
        return sub
    }

    function pop() {
        if (stack.length === 0) {
            closeRequested()
            return
        }
        var s = stack
        var top = s.pop()
        stack = s
        top.destroy()
    }

    Wallpaper { anchors.fill: parent }

    Silica.Label {
        id: header
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 24 * page.unit }
        color: page.accent
        font { pixelSize: 24 * page.unit; family: Theme.fontFamilyHeading }
        text: page.title
    }

    Item {
        id: body
        anchors { fill: parent; topMargin: 60 * page.unit }
    }

    MouseArea {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * 0.14
        z: 5
        property real startX
        onPressed: startX = mouse.x
        onReleased: if (mouse.x - startX > 50 * page.unit) page.pop()
    }
}
