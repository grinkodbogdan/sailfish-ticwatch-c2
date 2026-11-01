/*
 * Shell styling, derived from the Silica Theme so the shell follows the
 * current Sailfish ambience (wallpaper, highlight colour, fonts).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

pragma Singleton
import QtQuick 2.6
import Sailfish.Silica 1.0 as Silica

QtObject {
    // Ambience
    readonly property url wallpaper: Silica.Theme.backgroundImage
    readonly property color highlight: Silica.Theme.highlightColor
    readonly property color secondaryHighlight: Silica.Theme.secondaryHighlightColor
    readonly property color highlightBackground: Silica.Theme.highlightBackgroundColor
    readonly property real highlightBackgroundOpacity: Silica.Theme.highlightBackgroundOpacity
    readonly property color pressBackground: Silica.Theme.rgba(Silica.Theme.highlightBackgroundColor,
                                                              Silica.Theme.highlightBackgroundOpacity)

    // Base
    readonly property color background: "transparent"
    readonly property color dimmer: Qt.rgba(0, 0, 0, 0.55)
    readonly property color text: Silica.Theme.primaryColor
    readonly property color textDim: Silica.Theme.secondaryColor
    readonly property color textFaint: Silica.Theme.rgba(Silica.Theme.primaryColor, 0.3)
    readonly property color surface: Silica.Theme.rgba(Silica.Theme.primaryColor, 0.08)
    readonly property color surfaceHigh: Silica.Theme.rgba(Silica.Theme.primaryColor, 0.16)
    readonly property color error: Silica.Theme.errorColor

    readonly property string fontFamily: Silica.Theme.fontFamily
    readonly property string fontFamilyHeading: Silica.Theme.fontFamilyHeading

    // Sailfish uses one accent: the ambience highlight. The per-app names
    // stay so app code reads naturally.
    readonly property color settings: highlight
    readonly property color alarms: highlight
    readonly property color timer: highlight
    readonly property color stopwatch: highlight
    readonly property color agenda: highlight
    readonly property color music: highlight
    readonly property color calculator: highlight
    readonly property color torch: highlight
    readonly property color battery: highlight
    readonly property color notifications: highlight
    readonly property color wifi: highlight
    readonly property color bluetooth: highlight

    // Watch-face accent choices; "" means "follow the ambience".
    readonly property var accents: ["", "#38c6f4", "#ff5e6c", "#ff9f43", "#2ed47a", "#b46bff", "#ffd23f"]

    function dim(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    // Sailfish theme icon, tinted.
    function icon(name, color) {
        return "image://theme/" + name + "?" + color
    }
}
