/*
 * App launcher, Sailfish style on a round screen: launcher icons with labels
 * over the dimmed ambience, in a vertical list that curves with the circle
 * (rows shrink and fade towards the rim). Built-in watch apps first, then the
 * installed Sailfish apps. Pull down at the top to go back to the face.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import org.nemomobile.lipstick 0.1
import "."

Item {
    id: launcher

    property real unit: 1

    signal launched
    signal openWatchApp(string name)
    signal closeRequested

    // icon: Sailfish launcher icon, or a monochrome icon-m-* drawn on a
    // highlight disc when there is no launcher icon for it.
    ListModel {
        id: watchApps
        ListElement { app: "SettingsApp"; name: "Settings"; icon: "icon-launcher-settings" }
        ListElement { app: "ClockApp"; name: "Clock"; icon: "icon-launcher-clock" }
        ListElement { app: "AmbienceApp"; name: "Ambience"; icon: "icon-m-ambience" }
        ListElement { app: "HeartRateApp"; name: "Heart rate"; icon: "icon-m-health" }
        ListElement { app: "AgendaApp"; name: "Calendar"; icon: "icon-launcher-calendar" }
        ListElement { app: "MusicApp"; name: "Media"; icon: "icon-launcher-mediaplayer" }
        ListElement { app: "CalculatorApp"; name: "Calculator"; icon: "icon-launcher-calculator" }
        ListElement { app: "TorchApp"; name: "Flashlight"; icon: "icon-m-flashlight" }
        ListElement { app: "BatteryApp"; name: "Battery"; icon: "icon-m-battery-saver" }
    }

    // Phone apps the watch apps above replace.
    readonly property var replaced: ["jolla-settings", "jolla-clock", "jolla-calendar", "jolla-mediaplayer", "jolla-calculator"]

    LauncherModel { id: installedApps }

    function iconSource(iconId) {
        if (!iconId)
            return ""
        if (iconId.indexOf("/") === 0)
            return "file://" + iconId
        if (iconId.indexOf("image://") === 0 || iconId.indexOf("file://") === 0)
            return iconId
        return "image://theme/" + iconId
    }

    function isReplaced(item) {
        if (!item)
            return true
        for (var i = 0; i < replaced.length; i++)
            if (item.filePath.indexOf("/" + replaced[i] + ".desktop") >= 0)
                return true
        return false
    }

    Wallpaper { anchors.fill: parent }

    Flickable {
        id: flick

        anchors.fill: parent
        contentHeight: column.y + column.height + height / 2 - 32 * launcher.unit
        clip: true
        flickableDirection: Flickable.VerticalFlick

        Column {
            id: column
            y: flick.height / 2 - 32 * launcher.unit
            width: flick.width

            Repeater {
                model: watchApps
                LauncherRow {
                    view: flick
                    unit: launcher.unit
                    label: model.name
                    iconUrl: model.icon.indexOf("icon-launcher") === 0 ? "image://theme/" + model.icon : ""
                    monoIcon: model.icon.indexOf("icon-m-") === 0 ? model.icon : ""
                    onActivated: launcher.openWatchApp(model.app)
                }
            }

            Silica.Label {
                width: flick.width - 90 * launcher.unit
                anchors.horizontalCenter: parent.horizontalCenter
                height: 44 * launcher.unit
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                color: Theme.highlight
                font.pixelSize: 16 * launcher.unit
                text: "More apps"
            }

            Repeater {
                model: installedApps
                LauncherRow {
                    view: flick
                    unit: launcher.unit
                    visible: model.object && model.object.shouldDisplay !== false && !launcher.isReplaced(model.object)
                    height: visible ? 64 * launcher.unit : 0
                    label: model.object ? model.object.title : ""
                    iconUrl: model.object ? launcher.iconSource(model.object.iconId) : ""
                    onActivated: {
                        if (model.object) {
                            model.object.launchApplication()
                            launcher.launched()
                        }
                    }
                }
            }
        }

        onContentYChanged: if (dragging && contentY < -70 * launcher.unit) launcher.closeRequested()
    }
}
