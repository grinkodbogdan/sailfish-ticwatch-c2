/*
 * Notifications: round cards, tap to dismiss. Swipe right to go back.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import org.nemomobile.lipstick 0.1
import "."

Rectangle {
    id: page

    property real unit: 1
    readonly property int count: notificationModel.itemCount

    signal closeRequested

    color: "transparent"

    Wallpaper { anchors.fill: parent; dim: 0.7 }

    NotificationListModel {
        id: notificationModel
    }

    Silica.Label {
        anchors.centerIn: parent
        visible: notificationModel.itemCount === 0
        color: "#666666"
        font.pixelSize: 22 * page.unit
        text: "No notifications"
    }

    ListView {
        id: list

        anchors.fill: parent
        anchors.topMargin: 60 * page.unit
        anchors.bottomMargin: 60 * page.unit
        model: notificationModel
        spacing: 8 * page.unit
        clip: true

        delegate: Rectangle {
            width: 260 * page.unit
            height: column.height + 20 * page.unit
            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
            radius: 20 * page.unit
            color: Theme.surface

            Column {
                id: column
                anchors.centerIn: parent
                width: parent.width - 28 * page.unit
                spacing: 2 * page.unit

                Silica.Label {
                    width: parent.width
                    color: Theme.notifications
                    elide: Text.ElideRight
                    font.pixelSize: 14 * page.unit
                    text: model.object ? model.object.appName : ""
                }
                Silica.Label {
                    width: parent.width
                    color: "white"
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: 18 * page.unit
                    text: model.object ? model.object.summary : ""
                }
                Silica.Label {
                    width: parent.width
                    visible: text.length > 0
                    color: "#bbbbbb"
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    font.pixelSize: 15 * page.unit
                    text: model.object ? model.object.body : ""
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (model.object) model.object.removeRequested()
            }
        }
    }

    // Back: swipe right.
    MouseArea {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        width: parent.width * 0.3
        property real startX
        onPressed: startX = mouse.x
        onReleased: if (mouse.x - startX > 40 * page.unit) page.closeRequested()
    }
}
