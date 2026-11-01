/*
 * Agenda: events of the next 7 days (org.nemomobile.calendar).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import org.nemomobile.calendar 1.0
import ".."

AppPage {
    id: app

    title: "Agenda"
    accent: Theme.agenda

    AgendaModel {
        id: agenda
        startDate: new Date()
        endDate: new Date(Date.now() + 7 * 24 * 3600 * 1000)
    }

    Silica.Label {
        anchors.centerIn: parent
        visible: agenda.count === 0
        width: 220 * app.unit
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: Theme.textFaint
        font.pixelSize: 18 * app.unit
        text: "Nothing in the next 7 days"
    }

    ListView {
        anchors { fill: parent; bottomMargin: 36 * app.unit }
        clip: true
        spacing: 8 * app.unit
        model: agenda
        delegate: Item {
            width: ListView.view.width
            height: card.height
            Rectangle {
                id: card
                anchors.horizontalCenter: parent.horizontalCenter
                width: 250 * app.unit
                height: col.height + 16 * app.unit
                radius: 18 * app.unit
                color: Theme.surface
                Rectangle {
                    anchors { left: parent.left; leftMargin: 10 * app.unit; verticalCenter: parent.verticalCenter }
                    width: 4 * app.unit
                    height: parent.height - 18 * app.unit
                    radius: width / 2
                    color: Theme.agenda
                }
                Column {
                    id: col
                    anchors { left: parent.left; leftMargin: 24 * app.unit; right: parent.right; rightMargin: 14 * app.unit; verticalCenter: parent.verticalCenter }
                    Silica.Label {
                        width: parent.width
                        color: Theme.agenda
                        font.pixelSize: 13 * app.unit
                        text: model.event && model.event.allDay
                              ? Qt.formatDate(model.occurrence.startTime, "ddd d MMM") + " · all day"
                              : Qt.formatDateTime(model.occurrence.startTime, "ddd d MMM · hh:mm")
                    }
                    Silica.Label {
                        width: parent.width
                        color: Theme.text
                        elide: Text.ElideRight
                        font.pixelSize: 17 * app.unit
                        text: model.event ? model.event.displayLabel : ""
                    }
                    Silica.Label {
                        width: parent.width
                        visible: text.length > 0
                        color: Theme.textDim
                        elide: Text.ElideRight
                        font.pixelSize: 13 * app.unit
                        text: model.event ? model.event.location : ""
                    }
                }
            }
        }
    }
}
