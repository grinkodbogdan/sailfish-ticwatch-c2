/*
 * SPDX-License-Identifier: LGPL-2.1-only
 */

#include "stembutton.h"

#include <QDir>
#include <QFile>

#include <fcntl.h>
#include <linux/input.h>
#include <unistd.h>

// Evdev key codes the watch uses for its function button.
static bool isStemCode(int code)
{
    return code == 265 /* STEM_1 */ || code == 266 || code == 267 || code == KEY_OPEN;
}

StemButton::StemButton(QObject *parent)
    : QObject(parent)
{
    const QString device = qEnvironmentVariableIsSet("WATCH_SHELL_STEM_DEVICE")
            ? QString::fromLocal8Bit(qgetenv("WATCH_SHELL_STEM_DEVICE"))
            : QStringLiteral("gpio-keys");

    const QStringList inputs = QDir(QStringLiteral("/sys/class/input"))
            .entryList(QStringList() << QStringLiteral("event*"));
    for (const QString &event : inputs) {
        QFile name(QStringLiteral("/sys/class/input/%1/device/name").arg(event));
        if (!name.open(QIODevice::ReadOnly) || name.readAll().trimmed() != device.toLatin1())
            continue;
        m_fd = ::open(QFile::encodeName(QStringLiteral("/dev/input/") + event).constData(),
                      O_RDONLY | O_NONBLOCK | O_CLOEXEC);
        break;
    }
    if (m_fd < 0)
        return;

    m_notifier = new QSocketNotifier(m_fd, QSocketNotifier::Read, this);
    connect(m_notifier, &QSocketNotifier::activated, this, &StemButton::read);
}

StemButton::~StemButton()
{
    if (m_fd >= 0)
        ::close(m_fd);
}

void StemButton::read()
{
    struct input_event events[16];
    ssize_t n;
    while ((n = ::read(m_fd, events, sizeof(events))) > 0) {
        for (size_t i = 0; i < size_t(n) / sizeof(events[0]); i++) {
            if (events[i].type == EV_KEY && events[i].value == 1 && isStemCode(events[i].code))
                emit pressed();
        }
    }
}
