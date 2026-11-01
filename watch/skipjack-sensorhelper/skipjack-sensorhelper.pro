TEMPLATE = app
TARGET = skipjack-sensorhelper
QT = core dbus
CONFIG += link_pkgconfig c++11
PKGCONFIG += libhardware android-headers

SOURCES += src/main.cpp src/sensorhelper.cpp
HEADERS += src/sensorhelper.h

target.path = /usr/libexec/skipjack

unit.files = data/skipjack-sensorhelper.service
unit.path = /usr/lib/systemd/system

policy.files = data/org.sailfishos.skipjack.Sensors.conf
policy.path = /usr/share/dbus-1/system.d

INSTALLS += target unit policy
