/*
 * Alarms (Nemo.Alarms): list with switches, + to add, long-press to delete.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import Nemo.Alarms 1.0
import ".."

AppPage {
    id: app

    title: "Alarms"
    accent: Theme.alarms

    AlarmsModel {
        id: alarms
        onlyCountdown: false
    }

    function pad(n) { return (n < 10 ? "0" : "") + n }

    Silica.Label {
        anchors.centerIn: parent
        visible: listView.count === 0
        color: Theme.textFaint
        font.pixelSize: 18 * app.unit
        text: "No alarms"
    }

    ListView {
        id: listView
        anchors { fill: parent; bottomMargin: 92 * app.unit }
        clip: true
        spacing: 8 * app.unit
        model: alarms
        delegate: Item {
            width: ListView.view.width
            height: row.height
            visible: !alarm.countdown
            ToggleRow {
                id: row
                anchors.horizontalCenter: parent.horizontalCenter
                unit: app.unit
                icon: "icon-m-alarm"
                iconColor: Theme.alarms
                label: app.pad(alarm.hour) + ":" + app.pad(alarm.minute)
                value: alarm.title
                checked: alarm.enabled
                onToggled: {
                    alarm.enabled = !alarm.enabled
                    alarm.save()
                }
                onPressAndHold: alarm.deleteAlarm()
            }
        }
    }

    CircleButton {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 26 * app.unit }
        unit: app.unit
        size: 58
        icon: "icon-m-add"
        accent: Theme.alarms
        filled: true
        onClicked: app.push(newAlarm)
    }

    Component {
        id: newAlarm
        AppPage {
            id: np
            title: "New alarm"
            accent: Theme.alarms
            TimePicker {
                id: picker
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                unit: np.unit
                hour: new Date().getHours()
                minute: 0
            }
            CircleButton {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 26 * np.unit }
                unit: np.unit
                size: 58
                label: "✓"
                accent: Theme.alarms
                filled: true
                onClicked: {
                    var a = alarms.createAlarm()
                    a.hour = picker.hour
                    a.minute = picker.minute
                    a.title = "Alarm"
                    a.enabled = true
                    a.save()
                    np.closeRequested()
                }
            }
        }
    }
}
