/*
 * Popup for incoming notifications (phone notifications from Gadgetbridge
 * arrive through watch-btsyncd like any other): wakes the display and shows
 * the newest notification for a few seconds. Tap: open the notification
 * list; swipe sideways: dismiss the popup.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import org.nemomobile.lipstick 0.1
import Nemo.DBus 2.0
import "."

Item {
    id: popup

    property real unit: 1
    property QtObject notification

    signal openRequested

    function show(n) {
        notification = n
        card.x = card.centerX
        opacity = 1
        hideTimer.restart()
        mce.call("req_display_state_on", [])
    }

    function hide() {
        opacity = 0
        hideTimer.stop()
    }

    visible: opacity > 0
    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 180 } }

    NotificationListModel {
        id: model
        onRowsInserted: {
            var n = model.get(first)
            // Notifications restored at startup are not new.
            if (n && popup.ready)
                popup.show(n)
        }
    }
    property bool ready: false
    Timer { running: true; interval: 3000; onTriggered: popup.ready = true }

    DBusInterface {
        id: mce
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"
    }

    Connections {
        target: popup.notification
        ignoreUnknownSignals: true
        // Removed on the phone (or here): drop the popup with it.
        onRemoveRequested: popup.hide()
    }

    Timer {
        id: hideTimer
        interval: 6000
        onTriggered: popup.hide()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.dimmer
    }

    Rectangle {
        id: card
        // x is the centred position plus the swipe offset.
        readonly property real centerX: (popup.width - width) / 2
        x: centerX
        width: 280 * popup.unit
        height: Math.min(column.height + 34 * popup.unit, 230 * popup.unit)
        y: (parent.height - height) / 2
        radius: 26 * popup.unit
        color: Theme.dim(Theme.highlightBackground, 0.92)
        clip: true
        Behavior on x { enabled: !drag.drag.active; NumberAnimation { duration: 150 } }

        Column {
            id: column
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 16 * popup.unit }
            width: parent.width - 40 * popup.unit
            spacing: 3 * popup.unit

            Silica.Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                truncationMode: Silica.TruncationMode.Fade
                color: Theme.highlight
                font.pixelSize: 15 * popup.unit
                text: popup.notification ? popup.notification.appName : ""
            }
            Silica.Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.text
                font { pixelSize: 21 * popup.unit; family: Theme.fontFamilyHeading }
                text: popup.notification ? (popup.notification.previewSummary || popup.notification.summary) : ""
            }
            Silica.Label {
                width: parent.width
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                color: Theme.textDim
                font.pixelSize: 16 * popup.unit
                text: popup.notification ? (popup.notification.previewBody || popup.notification.body) : ""
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            drag.target: card
            drag.axis: Drag.XAxis
            onPressed: hideTimer.stop()
            onReleased: {
                if (Math.abs(card.x - card.centerX) > 70 * popup.unit) {
                    popup.hide()
                } else {
                    card.x = card.centerX
                    hideTimer.restart()
                }
            }
            onClicked: {
                popup.hide()
                popup.openRequested()
            }
        }
    }
}
