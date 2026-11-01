/*
 * SPDX-License-Identifier: LGPL-2.1-only
 */

#include "bluetoothagent.h"

#include <BluezQt/Device>
#include <BluezQt/InitManagerJob>
#include <BluezQt/Manager>
#include <BluezQt/PendingCall>

#include <QDebug>

static QString displayName(const BluezQt::DevicePtr &device)
{
    return device->friendlyName().isEmpty() ? device->address() : device->friendlyName();
}

BluetoothAgent::BluetoothAgent(QObject *parent)
    : BluezQt::Agent(parent)
    , m_manager(new BluezQt::Manager(this))
{
    BluezQt::InitManagerJob *job = m_manager->init();
    connect(job, &BluezQt::InitManagerJob::result, this, [this](BluezQt::InitManagerJob *job) {
        if (job->error()) {
            qWarning() << "Bluetooth agent: BlueZ unavailable:" << job->errorText();
            return;
        }
        registerAgent();
    });
    job->start();

    // bluetoothd restarts drop the agent.
    connect(m_manager, &BluezQt::Manager::operationalChanged, this, [this](bool operational) {
        if (operational)
            registerAgent();
    });
}

void BluetoothAgent::registerAgent()
{
    if (!m_manager->isOperational())
        return;
    BluezQt::PendingCall *call = m_manager->registerAgent(this);
    connect(call, &BluezQt::PendingCall::finished, this, [this](BluezQt::PendingCall *call) {
        if (call->error() && call->error() != BluezQt::PendingCall::AlreadyExists)
            qWarning() << "Bluetooth agent: register failed:" << call->errorText();
        m_manager->requestDefaultAgent(this);
    });
}

QDBusObjectPath BluetoothAgent::objectPath() const
{
    return QDBusObjectPath(QStringLiteral("/org/sailfishos/watchshell/bluetoothagent"));
}

BluezQt::Agent::Capability BluetoothAgent::capability() const
{
    return DisplayYesNo;
}

void BluetoothAgent::requestPinCode(BluezQt::DevicePtr device, const BluezQt::Request<QString> &request)
{
    // Legacy (pre-2.1) devices: headsets use a fixed PIN, nearly always 0000.
    Q_UNUSED(device)
    request.accept(QStringLiteral("0000"));
}

void BluetoothAgent::displayPinCode(BluezQt::DevicePtr device, const QString &pinCode)
{
    emit codeShown(displayName(device), pinCode);
}

void BluetoothAgent::requestPasskey(BluezQt::DevicePtr device, const BluezQt::Request<quint32> &request)
{
    // Entering the other device's passkey on the watch is not supported.
    Q_UNUSED(device)
    request.reject();
}

void BluetoothAgent::displayPasskey(BluezQt::DevicePtr device, const QString &passkey, const QString &entered)
{
    Q_UNUSED(entered)
    emit codeShown(displayName(device), passkey);
}

void BluetoothAgent::requestConfirmation(BluezQt::DevicePtr device, const QString &passkey, const BluezQt::Request<> &request)
{
    reject();
    m_pending = request;
    m_hasPending = true;
    emit confirmationRequested(displayName(device), passkey);
}

void BluetoothAgent::requestAuthorization(BluezQt::DevicePtr device, const BluezQt::Request<> &request)
{
    reject();
    m_pending = request;
    m_hasPending = true;
    emit authorizationRequested(displayName(device));
}

void BluetoothAgent::authorizeService(BluezQt::DevicePtr device, const QString &uuid, const BluezQt::Request<> &request)
{
    // Services of devices the user paired are allowed.
    Q_UNUSED(uuid)
    if (device->isPaired() || device->isTrusted())
        request.accept();
    else
        request.reject();
}

void BluetoothAgent::cancel()
{
    m_hasPending = false;
    emit canceled();
}

void BluetoothAgent::release()
{
    cancel();
}

void BluetoothAgent::accept()
{
    if (m_hasPending)
        m_pending.accept();
    m_hasPending = false;
}

void BluetoothAgent::reject()
{
    if (m_hasPending)
        m_pending.reject();
    m_hasPending = false;
}
