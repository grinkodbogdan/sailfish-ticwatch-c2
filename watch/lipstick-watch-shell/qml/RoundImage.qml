/*
 * An image masked to a circle (Qt 5.6 has no rounded clipping, so a small
 * shader does it).
 * SPDX-License-Identifier: LGPL-2.1-only
 */

import QtQuick 2.6

Item {
    id: root

    property alias source: image.source
    property alias status: image.status

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: width
        asynchronous: true
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        property variant src: image
        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D src;
            uniform lowp float qt_Opacity;
            void main() {
                highp vec2 d = qt_TexCoord0 - vec2(0.5);
                lowp float inside = 1.0 - smoothstep(0.24, 0.25, dot(d, d));
                gl_FragColor = texture2D(src, qt_TexCoord0) * inside * qt_Opacity;
            }"
    }
}
