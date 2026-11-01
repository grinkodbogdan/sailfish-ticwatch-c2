/*
 * SPDX-License-Identifier: LGPL-2.1-only
 */

#include "sensorhelper.h"

#include <QDBusConnection>
#include <QDBusError>
#include <QDBusMessage>
#include <QDBusReply>
#include <QDBusServiceWatcher>
#include <QDebug>
#include <QFile>
#include <QTimer>

#include <hardware/hardware.h>

#include <QDateTime>
#include <QProcess>

#include <time.h>

static const char *settingFile = "/var/lib/skipjack-sensors/raise-to-wake";
static const char *wakeLock = "skipjack_raise_to_wake";

void PollThread::run()
{
    sensors_event_t events[16];
    for (;;) {
        int n = m_device->poll(m_device, events, 16);
        for (int i = 0; i < n; i++) {
            if (events[i].type == SENSOR_TYPE_META_DATA)
                continue;
            if (events[i].type == SENSOR_TYPE_HEART_RATE)
                emit event(events[i].sensor, events[i].heart_rate.bpm, events[i].heart_rate.status);
            else
                emit event(events[i].sensor, events[i].data[0], 0);
        }
    }
}

SensorHelper::SensorHelper(QObject *parent)
    : QObject(parent)
{
    QFile setting(QString::fromLatin1(settingFile));
    if (setting.open(QIODevice::ReadOnly))
        m_raiseToWake = setting.readAll().trimmed() != "0";
}

bool SensorHelper::init()
{
    sensors_module_t *module = nullptr;
    if (hw_get_module(SENSORS_HARDWARE_MODULE_ID, (const hw_module_t **)&module) || !module) {
        qWarning() << "no sensors HAL";
        return false;
    }

    const sensor_t *list = nullptr;
    const int count = module->get_sensors_list(module, &list);
    for (int i = 0; i < count; i++) {
        const bool wakeUp = list[i].flags & SENSOR_FLAG_WAKE_UP;
        if (list[i].type == SENSOR_TYPE_WRIST_TILT_GESTURE && m_tilt < 0)
            m_tilt = list[i].handle;
        else if (list[i].type == SENSOR_TYPE_HEART_RATE && !wakeUp && m_heartRate < 0)
            m_heartRate = list[i].handle;
    }
    // The sensor hub publishes its sensors a while after sensors.qcom
    // starts; fail so systemd retries.
    if (m_tilt < 0 && m_heartRate < 0) {
        qWarning() << "sensors not ready:" << count << "sensors";
        return false;
    }

    if (sensors_open(&module->common, &m_device) || !m_device) {
        qWarning() << "cannot open the sensors HAL";
        return false;
    }

    QDBusConnection bus = QDBusConnection::systemBus();
    if (!bus.registerObject(QStringLiteral("/"), this,
                            QDBusConnection::ExportScriptableSlots | QDBusConnection::ExportScriptableSignals)) {
        qWarning() << "cannot register the D-Bus object";
        return false;
    }
    if (!bus.registerService(QStringLiteral("org.sailfishos.skipjack.Sensors"))) {
        qWarning() << "cannot own the D-Bus name:" << bus.lastError().message();
        return false;
    }
    m_watcher = new QDBusServiceWatcher(this);
    m_watcher->setConnection(bus);
    m_watcher->setWatchMode(QDBusServiceWatcher::WatchForUnregistration);
    connect(m_watcher, &QDBusServiceWatcher::serviceUnregistered, this, &SensorHelper::removeClient);

    PollThread *poll = new PollThread(m_device, this);
    connect(poll, &PollThread::event, this, &SensorHelper::onEvent, Qt::QueuedConnection);
    poll->start();

    if (m_tilt >= 0 && m_raiseToWake)
        m_device->activate(m_device, m_tilt, 1);

    qInfo() << "wrist tilt" << m_tilt << "heart rate" << m_heartRate << "raise to wake" << m_raiseToWake;
    return true;
}

void SensorHelper::setRaiseToWake(bool enabled)
{
    if (enabled == m_raiseToWake)
        return;
    m_raiseToWake = enabled;
    if (m_tilt >= 0)
        m_device->activate(m_device, m_tilt, enabled);

    QFile setting(QString::fromLatin1(settingFile));
    if (setting.open(QIODevice::WriteOnly | QIODevice::Truncate))
        setting.write(enabled ? "1\n" : "0\n");
    emit raiseToWakeChanged(enabled);
}

void SensorHelper::startHeartRate()
{
    if (!calledFromDBus())
        return;
    const QString client = message().service();
    if (!m_clients.contains(client)) {
        m_clients.insert(client);
        m_watcher->addWatchedService(client);
    }
    updateHeartRate();
}

void SensorHelper::stopHeartRate()
{
    if (calledFromDBus())
        removeClient(message().service());
}

void SensorHelper::removeClient(const QString &client)
{
    m_clients.remove(client);
    m_watcher->removeWatchedService(client);
    updateHeartRate();
}

void SensorHelper::updateHeartRate()
{
    const bool active = !m_clients.isEmpty();
    if (m_heartRate < 0 || active == m_heartRateActive)
        return;
    m_heartRateActive = active;
    if (active)
        m_device->setDelay(m_device, m_heartRate, 1000000000LL);
    m_device->activate(m_device, m_heartRate, active);
}

void SensorHelper::onEvent(int handle, float value, int status)
{
    if (handle == m_heartRate && m_heartRateActive)
        emit heartRate(qRound(value), status);
    else if (handle == m_tilt && m_raiseToWake)
        wakeDisplay();
}

void SensorHelper::wakeDisplay()
{
    // Keep the system up until MCE has the display on.
    QFile lock(QStringLiteral("/sys/power/wake_lock"));
    if (lock.open(QIODevice::WriteOnly))
        lock.write(wakeLock);

    QDBusMessage request = QDBusMessage::createMethodCall(
                QStringLiteral("com.nokia.mce"), QStringLiteral("/com/nokia/mce/request"),
                QStringLiteral("com.nokia.mce.request"), QStringLiteral("req_display_state_on"));
    QDBusConnection::systemBus().call(request, QDBus::NoBlock);

    QTimer::singleShot(2000, []() {
        QFile unlock(QStringLiteral("/sys/power/wake_unlock"));
        if (unlock.open(QIODevice::WriteOnly))
            unlock.write(wakeLock);
    });
}

bool SensorHelper::setSystemTime(qint64 msecs)
{
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (qAbs(now - msecs) <= 2000)
        return true;

    struct timespec ts;
    ts.tv_sec = msecs / 1000;
    ts.tv_nsec = (msecs % 1000) * 1000000;
    if (clock_settime(CLOCK_REALTIME, &ts) != 0) {
        qWarning() << "cannot set the time";
        return false;
    }
    qInfo() << "time set from the phone, was off by" << (now - msecs) << "ms";
    // Keep the RTC offset in step (see skipjack-clock.service).
    QProcess::startDetached(QStringLiteral("/usr/libexec/skipjack/clock-offset"),
                            QStringList() << QStringLiteral("save"));
    return true;
}
