/*
 * SPDX-License-Identifier: LGPL-2.1-only
 */

#include <QCoreApplication>

#include "sensorhelper.h"

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    SensorHelper helper;
    if (!helper.init())
        return 1;
    return app.exec();
}
