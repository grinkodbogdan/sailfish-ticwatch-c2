/*
 * lipstick-watch-shell - round smartwatch homescreen for Sailfish OS.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlEngine>
#include <QScreen>
#include <QTimer>
#include <QWindow>

#include <homeapplication.h>
#include <lipstickcompositor.h>
#include <homewindow.h>

#include "bluetoothagent.h"
#include "stembutton.h"

int main(int argc, char **argv)
{
    HomeApplication app(argc, argv, QString());

    // WATCH_SHELL_QML_DIR lets the QML be iterated on without reinstalling.
    const QString qmlDir = qEnvironmentVariableIsSet("WATCH_SHELL_QML_DIR")
            ? QString::fromLocal8Bit(qgetenv("WATCH_SHELL_QML_DIR"))
            : QStringLiteral("/usr/share/lipstick-watch-shell/qml");

    app.engine()->rootContext()->setContextProperty(QStringLiteral("shellQmlDir"), qmlDir);
    app.engine()->rootContext()->setContextProperty(
                QStringLiteral("roundScreen"), !qEnvironmentVariableIsSet("WATCH_SHELL_SQUARE"));

    // Development: WATCH_SHELL_START_PAGE=face|launcher|settings|notifications
    app.engine()->rootContext()->setContextProperty(
                QStringLiteral("startPage"), QString::fromLocal8Bit(qgetenv("WATCH_SHELL_START_PAGE")));

    // Development: WATCH_SHELL_START_APP=<SettingsApp|AlarmsApp|...> opens a watch app.
    app.engine()->rootContext()->setContextProperty(
                QStringLiteral("startApp"), QString::fromLocal8Bit(qgetenv("WATCH_SHELL_START_APP")));

    app.engine()->rootContext()->setContextProperty(
                QStringLiteral("startSub"), QString::fromLocal8Bit(qgetenv("WATCH_SHELL_START_SUB")));

    // Development: WATCH_SHELL_SCREENSHOT=<file.png> saves the scene every 2 s.
    app.engine()->rootContext()->setContextProperty(
                QStringLiteral("screenshotPath"), QString::fromLocal8Bit(qgetenv("WATCH_SHELL_SCREENSHOT")));

    app.engine()->rootContext()->setContextProperty(
                QStringLiteral("stemButton"), new StemButton(&app));
    app.engine()->rootContext()->setContextProperty(
                QStringLiteral("bluetoothAgent"), new BluetoothAgent(&app));

    // connman-qt aborts on D-Bus errors when connman is not running (e.g. in a
    // test session), so only create its objects when the service exists.
    QDBusConnectionInterface *bus = QDBusConnection::systemBus().interface();
    app.engine()->rootContext()->setContextProperty(
                QStringLiteral("connmanAvailable"),
                bus && bus->isServiceRegistered(QStringLiteral("net.connman")).value());

    // Everything visible lives in the compositor scene; the home window is an
    // empty placeholder lipstick requires.
    app.setCompositorPath(qmlDir + QStringLiteral("/compositor.qml"));
    app.setQmlPath(qmlDir + QStringLiteral("/HomeWindow.qml"));
    app.mainWindowInstance()->showFullScreen();

    // Development: without MCE (e.g. nested in a desktop) lipstick never sees
    // the display turn on, so it neither shows nor renders the compositor.
    // WATCH_SHELL_FORCE_DISPLAY_ON=1 stands in for MCE's "display on".
    if (qEnvironmentVariableIsSet("WATCH_SHELL_FORCE_DISPLAY_ON")) {
        QTimer *poll = new QTimer(&app);
        QObject::connect(poll, &QTimer::timeout, [poll]() {
            LipstickCompositor *compositor = LipstickCompositor::instance();
            if (!compositor)
                return;
            compositor->showFullScreen();
            compositor->setUpdatesEnabledNow(true);
            poll->stop();
        });
        poll->start(200);
    }

    // Development: WATCH_SHELL_WINDOWED=<size> shows the compositor as a
    // size x size window (e.g. nested in a desktop session) instead of full
    // screen.
    const int windowed = qgetenv("WATCH_SHELL_WINDOWED").toInt();
    if (windowed > 0) {
        QTimer::singleShot(0, [windowed]() {
            for (QWindow *window : QGuiApplication::topLevelWindows()) {
                if (window->inherits("LipstickCompositor")) {
                    window->showNormal();
                    window->resize(windowed, windowed);
                    window->setTitle(QStringLiteral("lipstick-watch-shell"));
                }
            }
        });
    }

    return app.exec();
}
