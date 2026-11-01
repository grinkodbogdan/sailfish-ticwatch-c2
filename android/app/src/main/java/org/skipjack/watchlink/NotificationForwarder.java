package org.skipjack.watchlink;

import android.app.Notification;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;

/**
 * Sends the phone's notifications to the watch (needs "notification access",
 * which also lets WatchService see what music is playing).
 */
public class NotificationForwarder extends NotificationListenerService {

    private static boolean connected;

    static boolean isConnected() { return connected; }

    @Override
    public void onListenerConnected() {
        connected = true;
        WatchService s = WatchService.get();
        if (s != null)
            s.onListenerConnected();
    }

    @Override
    public void onListenerDisconnected() {
        connected = false;
    }

    private static int idFor(StatusBarNotification sbn) {
        return sbn.getKey().hashCode() & 0x7fffffff;
    }

    private static boolean forwardable(StatusBarNotification sbn, String ownPackage) {
        Notification n = sbn.getNotification();
        if (sbn.getPackageName().equals(ownPackage))
            return false;
        if (sbn.isOngoing() || (n.flags & Notification.FLAG_FOREGROUND_SERVICE) != 0)
            return false;   // music players, downloads, navigation…
        if ((n.flags & Notification.FLAG_GROUP_SUMMARY) != 0)
            return false;   // the individual messages are forwarded instead
        if (Notification.CATEGORY_TRANSPORT.equals(n.category) || Notification.CATEGORY_PROGRESS.equals(n.category))
            return false;
        return true;
    }

    private String appName(String pkg) {
        try {
            PackageManager pm = getPackageManager();
            ApplicationInfo ai = pm.getApplicationInfo(pkg, 0);
            return pm.getApplicationLabel(ai).toString();
        } catch (Exception e) {
            return pkg;
        }
    }

    private static String text(Bundle extras, String key) {
        CharSequence cs = extras.getCharSequence(key);
        return cs == null ? "" : cs.toString();
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        WatchService s = WatchService.get();
        if (s == null || !forwardable(sbn, getPackageName()))
            return;
        Bundle e = sbn.getNotification().extras;
        String title = text(e, Notification.EXTRA_TITLE);
        String body = text(e, Notification.EXTRA_BIG_TEXT);
        if (body.isEmpty())
            body = text(e, Notification.EXTRA_TEXT);
        // Messaging style: the latest lines.
        CharSequence[] lines = e.getCharSequenceArray(Notification.EXTRA_TEXT_LINES);
        if (body.isEmpty() && lines != null && lines.length > 0)
            body = lines[lines.length - 1].toString();
        if (title.isEmpty() && body.isEmpty())
            return;
        if (body.length() > 400)
            body = body.substring(0, 400) + "…";
        s.forwardNotification(sbn.getPackageName(), idFor(sbn), appName(sbn.getPackageName()), title, body);
        RecentApps.note(this, sbn.getPackageName(), appName(sbn.getPackageName()));
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        WatchService s = WatchService.get();
        if (s != null && forwardable(sbn, getPackageName()))
            s.removeNotification(idFor(sbn));
    }
}
