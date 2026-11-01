/*
 * Music: controls whichever media player is running (MPRIS).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica
import Amber.Mpris 1.0
import ".."

AppPage {
    id: app

    title: "Music"
    accent: Theme.music

    MprisController { id: mpris }

    readonly property bool hasPlayer: mpris.availableServices.length > 0
    readonly property bool playing: mpris.playbackStatus === Mpris.Playing

    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 6 * app.unit }
        width: 240 * app.unit
        spacing: 4 * app.unit

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 84 * app.unit
            height: width
            radius: width / 2
            color: Theme.dim(Theme.music, 0.18)
            Image {
                anchors.fill: parent
                anchors.margins: 4 * app.unit
                visible: status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                source: mpris.metaData.artUrl || ""
            }
            SfIcon {
                anchors.centerIn: parent
                width: 42 * app.unit
                height: width
                visible: !mpris.metaData.artUrl
                name: "icon-m-music"
                color: Theme.music
            }
        }
        Silica.Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: Theme.text
            font.pixelSize: 19 * app.unit
            text: app.hasPlayer ? (mpris.metaData.title || mpris.identity || "Playing") : "Nothing playing"
        }
        Silica.Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: Theme.textDim
            font.pixelSize: 15 * app.unit
            text: app.hasPlayer ? (mpris.metaData.contributingArtist || "") : "Start a player on the watch or phone"
        }
    }

    Row {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 34 * app.unit }
        spacing: 14 * app.unit
        CircleButton { anchors.verticalCenter: parent.verticalCenter; unit: app.unit; size: 50; icon: "icon-m-previous"; accent: Theme.music; enabled: mpris.canGoPrevious; onClicked: mpris.previous() }
        CircleButton { anchors.verticalCenter: parent.verticalCenter; unit: app.unit; size: 70; icon: app.playing ? "icon-m-pause" : "icon-m-play"; accent: Theme.music; filled: true; enabled: app.hasPlayer; onClicked: mpris.playPause() }
        CircleButton { anchors.verticalCenter: parent.verticalCenter; unit: app.unit; size: 50; icon: "icon-m-next"; accent: Theme.music; enabled: mpris.canGoNext; onClicked: mpris.next() }
    }
}
