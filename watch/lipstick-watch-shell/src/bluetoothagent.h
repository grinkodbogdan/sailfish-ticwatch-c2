/*
 * BlueZ pairing agent for the watch. Sailfish's pairing UI lives in the
 * phone home screen, which the watch shell replaces, so the shell registers
 * its own default agent and shows the requests (confirm a passkey, show a
 * PIN) in QML.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

#ifndef BLUETOOTHAGENT_H
#define BLUETOOTHAGENT_H

#include <BluezQt/Agent>
#include <BluezQt/Request>
#include <BluezQt/Types>

class BluetoothAgent : public BluezQt::Agent
{
    Q_OBJECT
public:
    explicit BluetoothAgent(QObject *parent = nullptr);

    QDBusObjectPath objectPath() const override;
    Capability capability() const override;

    void requestPinCode(BluezQt::DevicePtr device, const BluezQt::Request<QString> &request) override;
    void displayPinCode(BluezQt::DevicePtr device, const QString &pinCode) override;
    void requestPasskey(BluezQt::DevicePtr device, const BluezQt::Request<quint32> &request) override;
    void displayPasskey(BluezQt::DevicePtr device, const QString &passkey, const QString &entered) override;
    void requestConfirmation(BluezQt::DevicePtr device, const QString &passkey, const BluezQt::Request<> &request) override;
    void requestAuthorization(BluezQt::DevicePtr device, const BluezQt::Request<> &request) override;
    void authorizeService(BluezQt::DevicePtr device, const QString &uuid, const BluezQt::Request<> &request) override;
    void cancel() override;
    void release() override;

    // Answer to confirmationRequested / authorizationRequested.
    Q_INVOKABLE void accept();
    Q_INVOKABLE void reject();

signals:
    void confirmationRequested(const QString &name, const QString &passkey);
    void authorizationRequested(const QString &name);
    // A code to type on the other device (keyboards) or compare.
    void codeShown(const QString &name, const QString &code);
    void canceled();

private:
    void start();
    void registerAgent();

    BluezQt::Manager *m_manager = nullptr;
    BluezQt::Request<> m_pending;
    bool m_hasPending = false;
};

#endif
