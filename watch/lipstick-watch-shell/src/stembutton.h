/*
 * The watch's side button. The power button is MCE's (display on/off); the
 * other one ("stem", gpio-keys, Android STEM_1 = evdev code 265) has no
 * meaning in Sailfish, so the shell reads it directly and uses it as the
 * Wear "home" button.
 * SPDX-License-Identifier: LGPL-2.1-only
 */

#ifndef STEMBUTTON_H
#define STEMBUTTON_H

#include <QObject>
#include <QSocketNotifier>

class StemButton : public QObject
{
    Q_OBJECT
public:
    explicit StemButton(QObject *parent = nullptr);
    ~StemButton();

signals:
    void pressed();

private:
    void read();

    int m_fd = -1;
    QSocketNotifier *m_notifier = nullptr;
};

#endif
