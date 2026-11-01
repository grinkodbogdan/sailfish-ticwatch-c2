/*
 * skipjack-sensorhelper: the TicWatch C2 sensors sensorfw has no use for.
 *
 *  - Raise to wake: the sensor hub's wrist tilt gesture asks MCE to turn
 *    the display on.
 *  - Heart rate: the PAH8011 optical sensor, measured on request and
 *    reported over D-Bus (system bus, org.sailfishos.skipjack.Sensors).
 *
 * SPDX-License-Identifier: LGPL-2.1-only
 */

#ifndef SENSORHELPER_H
#define SENSORHELPER_H

#include <QDBusContext>
#include <QObject>
#include <QSet>
#include <QThread>

#include <android-config.h>
#include <hardware/sensors.h>

class QDBusServiceWatcher;

class PollThread : public QThread
{
    Q_OBJECT
public:
    explicit PollThread(sensors_poll_device_t *device, QObject *parent = nullptr)
        : QThread(parent), m_device(device) {}

signals:
    void event(int handle, float value, int status);

protected:
    void run() override;

private:
    sensors_poll_device_t *m_device;
};

class SensorHelper : public QObject, protected QDBusContext
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.sailfishos.skipjack.Sensors")
public:
    explicit SensorHelper(QObject *parent = nullptr);
    bool init();

public slots:
    Q_SCRIPTABLE bool raiseToWake() const { return m_raiseToWake; }
    Q_SCRIPTABLE void setRaiseToWake(bool enabled);
    Q_SCRIPTABLE bool heartRateAvailable() const { return m_heartRate >= 0; }
    // A client measures from startHeartRate() until stopHeartRate() or
    // until it leaves the bus.
    Q_SCRIPTABLE void startHeartRate();
    Q_SCRIPTABLE void stopHeartRate();
    // Time from the phone (Gadgetbridge via watch-btsyncd), in ms since the
    // epoch. Applied when it differs by more than 2 s; D-Bus policy limits
    // it to the privileged group.
    Q_SCRIPTABLE bool setSystemTime(qint64 msecs);

signals:
    Q_SCRIPTABLE void raiseToWakeChanged(bool enabled);
    // status: 3 high .. 1 low accuracy, 0 unreliable, -1 no skin contact
    Q_SCRIPTABLE void heartRate(int bpm, int status);

private:
    void onEvent(int handle, float value, int status);
    void removeClient(const QString &client);
    void updateHeartRate();
    void wakeDisplay();

    sensors_poll_device_t *m_device = nullptr;
    int m_tilt = -1;
    int m_heartRate = -1;
    bool m_raiseToWake = true;
    bool m_heartRateActive = false;
    QSet<QString> m_clients;
    QDBusServiceWatcher *m_watcher = nullptr;
};

#endif
