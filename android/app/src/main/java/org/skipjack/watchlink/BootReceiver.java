package org.skipjack.watchlink;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Reconnect to the watch after the phone restarts or the app is updated. */
public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (!new Prefs(context).address().isEmpty() && MainActivity.hasBluetoothPermission(context))
            WatchService.start(context);
    }
}
