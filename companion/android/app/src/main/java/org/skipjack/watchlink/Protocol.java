package org.skipjack.watchlink;

import java.nio.charset.StandardCharsets;
import java.util.Calendar;
import java.util.UUID;

/**
 * The watch's Bluetooth LE protocol: AsteroidOS's btsyncd services, served
 * on the watch by watch-btsyncd. UUIDs and encodings follow its source.
 */
final class Protocol {
    private Protocol() {}

    private static UUID asteroid(String shortId) {
        return UUID.fromString("0000" + shortId + "-0000-0000-0000-00a57e401d05");
    }

    /** Advertised by the watch; used to find it in a scan. */
    static final UUID ADVERTISED = UUID.fromString("00000000-0000-0000-0000-00a57e401d05");

    static final UUID NOTIFICATIONS = asteroid("9071");
    static final UUID NOTIFICATION_UPDATE = asteroid("9001");

    static final UUID WEATHER = asteroid("8071");
    static final UUID WEATHER_CITY = asteroid("8001");
    static final UUID WEATHER_IDS = asteroid("8002");
    static final UUID WEATHER_MIN = asteroid("8003");
    static final UUID WEATHER_MAX = asteroid("8004");

    static final UUID MEDIA = asteroid("7071");
    static final UUID MEDIA_TITLE = asteroid("7001");
    static final UUID MEDIA_ALBUM = asteroid("7002");
    static final UUID MEDIA_ARTIST = asteroid("7003");
    static final UUID MEDIA_PLAYING = asteroid("7004");
    static final UUID MEDIA_COMMANDS = asteroid("7005");
    static final UUID MEDIA_VOLUME = asteroid("7006");

    static final UUID TIME = asteroid("5071");
    static final UUID TIME_SET = asteroid("5001");

    static final UUID BATTERY = UUID.fromString("0000180f-0000-1000-8000-00805f9b34fb");
    static final UUID BATTERY_LEVEL = UUID.fromString("00002a19-0000-1000-8000-00805f9b34fb");

    static final UUID CCC_DESCRIPTOR = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");

    // Commands the watch sends on MEDIA_COMMANDS.
    static final int MEDIA_PREVIOUS = 0;
    static final int MEDIA_NEXT = 1;
    static final int MEDIA_PLAY = 2;
    static final int MEDIA_PAUSE = 3;
    static final int MEDIA_SET_VOLUME = 4;

    /** Local time: year-1900, month (0-11), day, hour, minute, second. */
    static byte[] time(Calendar c) {
        return new byte[] {
            (byte) (c.get(Calendar.YEAR) - 1900),
            (byte) c.get(Calendar.MONTH),
            (byte) c.get(Calendar.DAY_OF_MONTH),
            (byte) c.get(Calendar.HOUR_OF_DAY),
            (byte) c.get(Calendar.MINUTE),
            (byte) c.get(Calendar.SECOND),
        };
    }

    /** Five big-endian 16-bit values (weather ids, temperatures in Kelvin). */
    static byte[] fiveShorts(int[] values) {
        byte[] out = new byte[10];
        for (int i = 0; i < 5; i++) {
            int v = i < values.length ? values[i] : 0;
            out[i * 2] = (byte) ((v >> 8) & 0xff);
            out[i * 2 + 1] = (byte) (v & 0xff);
        }
        return out;
    }

    static int kelvin(double celsius) {
        return (int) Math.round(celsius + 273.15);
    }

    static byte[] utf8(String s) {
        return (s == null ? "" : s).getBytes(StandardCharsets.UTF_8);
    }

    private static String escape(String s) {
        if (s == null)
            return "";
        StringBuilder b = new StringBuilder(s.length());
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
            case '&': b.append("&amp;"); break;
            case '<': b.append("&lt;"); break;
            case '>': b.append("&gt;"); break;
            case '"': b.append("&quot;"); break;
            case '\'': b.append("&apos;"); break;
            default:
                // XML 1.0 forbids most control characters.
                if (c >= 0x20 || c == '\n' || c == '\t')
                    b.append(c);
            }
        }
        return b.toString();
    }

    /**
     * New or updated notification. vibrate: none, normal, strong, ringtone.
     * The watch reassembles it from several writes (it waits for </insert>).
     */
    static byte[] notificationInsert(String packageName, int id, String appName, String icon,
                                     String summary, String body, String vibrate) {
        String xml = "<insert>"
                + "<pn>" + escape(packageName) + "</pn>"
                + "<id>" + id + "</id>"
                + "<an>" + escape(appName) + "</an>"
                + "<ai>" + escape(icon) + "</ai>"
                + "<su>" + escape(summary) + "</su>"
                + "<bo>" + escape(body) + "</bo>"
                + "<vb>" + escape(vibrate) + "</vb>"
                + "</insert>";
        return utf8(xml);
    }

    static byte[] notificationRemoved(int id) {
        return utf8("<removed><id>" + id + "</id></removed>");
    }
}
