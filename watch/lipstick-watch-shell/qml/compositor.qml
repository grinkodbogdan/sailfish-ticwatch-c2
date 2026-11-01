/*
 * lipstick-watch-shell - round smartwatch homescreen for Sailfish OS.
 * SPDX-License-Identifier: LGPL-2.1-only
 *
 * Scene layout (bottom to top):
 *   pages      watch face / launcher / quick settings / notifications
 *   watchApp   built-in watch app (qml/apps/*App.qml) when one is open
 *   appLayer   application windows (Wayland clients), full screen
 *   overlays   in-process windows other than home (dialogs, security UI)
 *   gestures   edge swipes while an application is shown
 *   roundMask  black ring outside the circle (only visible off-device)
 */

import QtQuick 2.6
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import "."

Compositor {
    id: root

    color: "black"

    // Diameter of the round display; the scene is a centred square of this size.
    readonly property real diameter: Math.min(width, height)
    readonly property real unit: diameter / 360

    property Item homeWindow
    property Item currentApp
    // Page slides are only animated once the scene has its final size, so
    // nothing visibly slides into place at startup.
    property bool animationsReady: false
    Timer { running: true; interval: 800; onTriggered: root.animationsReady = true }

    property string page: startPage !== "" ? startPage : "face"   // face | launcher | settings | notifications

    function showPage(name) {
        page = name
    }

    function openWatchApp(name) {
        watchApp.setSource("apps/" + name + ".qml", { "unit": root.unit })
    }

    function closeWatchApp() {
        watchApp.source = ""
    }

    function goHome() {
        closeWatchApp()
        if (currentApp) {
            currentApp.visible = false
            currentApp = null
        }
        homeActive = true
        showPage("face")
    }

    // Side (stem) button: back out one level towards the face; on the face
    // it opens the app list.
    function stemPressed() {
        if (watchApp.source != "")
            closeWatchApp()
        else if (currentApp)
            goHome()
        else if (page !== "face")
            showPage("face")
        else
            showPage("launcher")
    }

    Connections {
        target: stemButton
        onPressed: root.stemPressed()
    }

    function showApp(wrapper) {
        if (currentApp && currentApp !== wrapper)
            currentApp.visible = false
        currentApp = wrapper
        wrapper.visible = true
        homeActive = false
        topmostWindowId = wrapper.window.windowId
    }

    function closeCurrentApp() {
        if (currentApp) {
            var id = currentApp.window.windowId
            goHome()
            root.closeClientForWindowId(id)
        }
    }

    onWindowAdded: {
        if (window.isInProcess && !homeWindow) {
            // lipstick's own home window: an empty placeholder, keep it hidden.
            window.visible = false
            homeWindow = window
            return
        }
        var layer = window.isInProcess ? overlays : appLayer
        var wrapper = wrapperComponent.createObject(layer, { "window": window })
        window.userData = wrapper
        if (!window.isInProcess)
            showApp(wrapper)
    }

    onWindowRaised: {
        if (window.userData && !window.isInProcess)
            showApp(window.userData)
    }

    onWindowRemoved: {
        var wrapper = window.userData
        if (!wrapper)
            return
        if (wrapper === currentApp)
            goHome()
        wrapper.destroy()
    }

    // Back to the face only when the display has been off for a while, as
    // on Wear: a quick blank (wrist down, power key) keeps the open app.
    property real displayOffTime: 0
    onDisplayOff: displayOffTime = new Date().getTime()
    onDisplayOn: {
        unlock()
        if (displayOffTime > 0 && new Date().getTime() - displayOffTime > 60000)
            goHome()
        displayOffTime = 0
    }

    // MCE turns the touch lock on whenever the display blanks and expects
    // the home screen to show a lock screen and unlock. The watch has none
    // (the security code is asked by the device lock), so unlock directly;
    // a locked tklock also makes MCE blank after a few seconds.
    function unlock() {
        if (lipstickSettings.lockscreenVisible)
            lipstickSettings.lockscreenVisible = false
    }
    Timer {
        id: unlockTimer
        interval: 0
        onTriggered: root.unlock()
    }
    Connections {
        target: lipstickSettings
        onLockscreenVisibleChanged: if (lipstickSettings.lockscreenVisible && root.displayOffTime === 0) unlockTimer.restart()
    }

    Component.onCompleted: {
        unlock()
        if (startApp !== "")
            openWatchApp(startApp)
    }

    Component {
        id: wrapperComponent
        WindowWrapper { }
    }

    Item {
        id: scene

        width: root.diameter
        height: root.diameter
        anchors.centerIn: parent

        // Ambience behind everything, including application windows (Silica
        // apps draw translucent over it).
        Wallpaper {
            anchors.fill: parent
        }

        // ---- pages -------------------------------------------------------
        Item {
            id: pages

            anchors.fill: parent
            visible: root.homeActive

            WatchFace {
                id: face
                anchors.fill: parent
                unit: root.unit
                opacity: root.page === "face" ? 1 : 0
                visible: opacity > 0
                notificationCount: notifications.count
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Launcher {
                width: parent.width
                height: parent.height
                unit: root.unit
                y: root.page === "launcher" ? 0 : parent.height
                visible: y < parent.height
                Behavior on y { enabled: root.animationsReady; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                onLaunched: root.showPage("face")
                onOpenWatchApp: { root.openWatchApp(name); root.showPage("face") }
                onCloseRequested: root.showPage("face")
            }

            QuickSettings {
                width: parent.width
                height: parent.height
                unit: root.unit
                y: root.page === "settings" ? 0 : -parent.height
                visible: y > -parent.height
                Behavior on y { enabled: root.animationsReady; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                onOpenWatchApp: { root.openWatchApp(name); root.showPage("face") }
                onCloseRequested: root.showPage("face")
            }

            Notifications {
                id: notifications
                width: parent.width
                height: parent.height
                unit: root.unit
                x: root.page === "notifications" ? 0 : parent.width
                visible: x < parent.width
                Behavior on x { enabled: root.animationsReady; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                onCloseRequested: root.showPage("face")
            }

            // Swipe detection on the watch face only; the other pages handle
            // their own "back" swipe.
            MouseArea {
                anchors.fill: parent
                enabled: root.page === "face"
                property real startX
                property real startY
                onPressed: { startX = mouse.x; startY = mouse.y }
                onPressAndHold: face.toggleStyle()
                onReleased: {
                    var dx = mouse.x - startX
                    var dy = mouse.y - startY
                    var min = 40 * root.unit
                    if (Math.abs(dy) > Math.abs(dx) && Math.abs(dy) > min)
                        root.showPage(dy < 0 ? "launcher" : "settings")
                    else if (Math.abs(dx) > min && dx < 0)
                        root.showPage("notifications")
                }
            }
        }

        // ---- built-in watch app --------------------------------------------
        Loader {
            id: watchApp
            anchors.fill: parent
            visible: status === Loader.Ready && root.homeActive
            onLoaded: item.closeRequested.connect(root.closeWatchApp)
        }

        // ---- application windows ------------------------------------------
        Item {
            id: appLayer
            anchors.fill: parent
        }

        Item {
            id: overlays
            anchors.fill: parent
        }

        // Incoming notifications (including the phone's, via Gadgetbridge).
        NotificationPopup {
            anchors.fill: parent
            unit: root.unit
            onOpenRequested: {
                if (root.currentApp)
                    root.goHome()
                root.closeWatchApp()
                root.showPage("notifications")
            }
        }

        // WiFi password, Bluetooth pairing and connection notices.
        ConnectivityPrompts {
            id: prompts
            anchors.fill: parent
            unit: root.unit
        }

        // ---- edge gestures over applications ------------------------------
        // Left edge -> back to the watch face; top edge pulled down -> close.
        MouseArea {
            id: leftEdge
            enabled: root.currentApp !== null
            width: 24 * root.unit
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            property real startX
            onPressed: startX = mouse.x
            onReleased: if (mouse.x - startX > 60 * root.unit) root.goHome()
        }

        MouseArea {
            id: topEdge
            enabled: root.currentApp !== null
            height: 24 * root.unit
            anchors { left: parent.left; right: parent.right; top: parent.top }
            property real startY
            onPressed: startY = mouse.y
            onReleased: if (mouse.y - startY > 120 * root.unit) root.closeCurrentApp()
        }

        // ---- development screenshots (WATCH_SHELL_SCREENSHOT) ---------------
        Timer {
            running: screenshotPath !== ""
            repeat: true
            interval: 2000
            onTriggered: scene.grabToImage(function(result) { result.saveToFile(screenshotPath) })
        }

        // ---- round mask (off-device preview) ------------------------------
        Rectangle {
            id: roundMask
            visible: roundScreen
            readonly property real ring: root.diameter * 0.25
            width: root.diameter + 2 * ring
            height: width
            radius: width / 2
            anchors.centerIn: parent
            color: "transparent"
            border.width: ring
            border.color: "black"
        }
    }
}
