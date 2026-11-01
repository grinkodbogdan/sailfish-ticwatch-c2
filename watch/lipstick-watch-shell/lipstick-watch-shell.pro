# lipstick-watch-shell: a round smartwatch homescreen for Sailfish OS
# (Qt 5.6 / lipstick-qt5 0.36), built for the TicWatch C2 (360x360 round).
TEMPLATE = app
TARGET = lipstick-watch-shell
QT += quick dbus compositor
CONFIG += link_pkgconfig c++11
PKGCONFIG += lipstick-qt5 mlite5 KF5BluezQt

SOURCES += src/main.cpp src/stembutton.cpp src/bluetoothagent.cpp
HEADERS += src/stembutton.h src/bluetoothagent.h

target.path = /usr/bin

qml.files = qml/*
qml.path = /usr/share/lipstick-watch-shell/qml

service.files = data/lipstick-watch-shell.service
service.path = /usr/lib/systemd/user

INSTALLS += target qml service
OTHER_FILES += qml/*.qml rpm/*.spec data/*
