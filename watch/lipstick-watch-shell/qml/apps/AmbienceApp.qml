/*
 * Ambience: pick the system ambience (wallpaper + highlight colours) like in
 * Sailfish Settings. Lists /usr/share/ambience/<name>/<name>.ambience and
 * applies the choice through ambienced (com.jolla.ambienced.setAmbience).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Qt.labs.folderlistmodel 2.1
import Sailfish.Silica 1.0 as Silica
import Nemo.DBus 2.0
import ".."

AppPage {
    id: app

    title: "Ambience"

    readonly property string root: "/usr/share/ambience"

    DBusInterface {
        id: ambienced
        bus: DBus.SessionBus
        service: "com.jolla.ambienced"
        path: "/com/jolla/ambienced"
        iface: "com.jolla.ambienced"
    }

    ListModel { id: ambiences }

    function basename(path) {
        var s = String(path)
        return s.substring(s.lastIndexOf("/") + 1)
    }

    function titleOf(key, name) {
        var n = (key || name).replace(/^ambience-/, "").replace(/[-_]/g, " ")
        return n.charAt(0).toUpperCase() + n.substring(1)
    }

    // Reads one .ambience file (JSON) and appends it to the model.
    function load(dir) {
        var name = basename(dir)
        var file = dir + "/" + name + ".ambience"
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.responseText === "")
                return
            try {
                var a = JSON.parse(xhr.responseText)
                ambiences.append({
                    "name": titleOf(a.displayName, name),
                    "file": file,
                    "wallpaper": "file://" + dir + "/images/" + a.wallpaper,
                    "wallpaperFile": a.wallpaper,
                    "highlight": a.highlightColor || "#ffffff"
                })
            } catch (e) {
                console.warn("ambience", file, e)
            }
        }
        xhr.open("GET", "file://" + file)
        xhr.send()
    }

    FolderListModel {
        id: folders
        folder: "file://" + app.root
        showFiles: false
        showDirs: true
        sortField: FolderListModel.Name
        onCountChanged: {
            if (count > 0 && ambiences.count === 0)
                for (var i = 0; i < count; i++)
                    app.load(app.root + "/" + get(i, "fileName"))
        }
    }

    ListView {
        id: list
        anchors { fill: parent; bottomMargin: 20 * app.unit }
        clip: true
        spacing: 10 * app.unit
        model: ambiences

        delegate: Item {
            width: list.width
            height: 112 * app.unit
            readonly property bool current: app.basename(Theme.wallpaper).indexOf(model.wallpaperFile.replace(/\.[^.]+$/, "")) >= 0
            readonly property bool down: mouse.pressed && mouse.containsMouse

            Row {
                anchors.centerIn: parent
                spacing: 14 * app.unit

                Item {
                    width: 96 * app.unit
                    height: width
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -4 * app.unit
                        radius: width / 2
                        color: "transparent"
                        border.width: 3 * app.unit
                        border.color: model.highlight
                        visible: current || down
                    }
                    RoundImage {
                        anchors.fill: parent
                        source: model.wallpaper
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 120 * app.unit
                    Silica.Label {
                        width: parent.width
                        truncationMode: Silica.TruncationMode.Fade
                        color: current || down ? model.highlight : Theme.text
                        font.pixelSize: 21 * app.unit
                        text: model.name
                    }
                    Row {
                        spacing: 4 * app.unit
                        Rectangle {
                            width: 14 * app.unit
                            height: width
                            radius: width / 2
                            color: model.highlight
                        }
                        Silica.Label {
                            color: Theme.textDim
                            font.pixelSize: 14 * app.unit
                            text: current ? "current" : ""
                        }
                    }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                onClicked: ambienced.call("setAmbience", ["file://" + model.file])
            }
        }
    }
}
