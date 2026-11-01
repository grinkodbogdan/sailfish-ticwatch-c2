#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <android-config.h>
#include <hardware/hardware.h>
#include <hardware/sensors.h>
int main(int argc, char **argv) {
    setvbuf(stdout, NULL, _IONBF, 0);
    struct sensors_module_t *m; struct sensors_poll_device_t *dev;
    if (hw_get_module(SENSORS_HARDWARE_MODULE_ID, (const hw_module_t **)&m)) { puts("no module"); return 1; }
    if (argc > 1) sleep(atoi(argv[1]));
    const struct sensor_t *list; int n = m->get_sensors_list(m, &list);
    printf("%d sensors\n", n);
    for (int i = 0; i < n; i++) printf("  %d type=%d %s / %s\n", list[i].handle, list[i].type, list[i].name, list[i].vendor);
    if (n <= 0 || argc < 3) return 0;
    sensors_open(&m->common, &dev);
    int h = -1; for (int i = 0; i < n; i++) if (list[i].type == atoi(argv[2])) { h = list[i].handle; break; }
    if (h < 0) return 0;
    dev->setDelay(dev, h, 200000000LL); dev->activate(dev, h, 1);
    sensors_event_t ev[8];
    int polls = argc > 3 ? atoi(argv[3]) : 5;
    for (int k = 0; k < polls; k++) { int r = dev->poll(dev, ev, 8); for (int j = 0; j < r; j++) printf("ev h=%d t=%d %f %f %f\n", ev[j].sensor, ev[j].type, ev[j].data[0], ev[j].data[1], ev[j].data[2]); }
    dev->activate(dev, h, 0); return 0;
}
