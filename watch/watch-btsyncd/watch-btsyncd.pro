# AsteroidOS's Bluetooth LE sync daemon (asteroid-btsyncd, Qt5 branch with
# later upstream fixes), built for Sailfish OS so Gadgetbridge's AsteroidOS
# support works with this watch.
TEMPLATE = app
TARGET = watch-btsyncd
QT = core dbus
CONFIG += link_pkgconfig c++14
PKGCONFIG += mpris-qt5 mlite5

SOURCES += $$files(src/*.cpp)
HEADERS += $$files(src/*.h)

target.path = /usr/bin

unit.files = watch-btsyncd.service
unit.path = /usr/lib/systemd/user

INSTALLS += target unit
