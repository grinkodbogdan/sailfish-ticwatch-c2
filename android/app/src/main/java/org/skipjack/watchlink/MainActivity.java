package org.skipjack.watchlink;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.provider.Settings;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executors;

/**
 * Hosts the web UI (assets/www, also usable as a PWA) and bridges it to
 * WatchService as window.Native.
 */
public class MainActivity extends Activity implements WatchService.Listener {
    private WebView web;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private Prefs prefs;

    static String[] bluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= 31)
            return new String[] { Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT };
        return new String[] { Manifest.permission.ACCESS_FINE_LOCATION };
    }

    static boolean hasBluetoothPermission(Context c) {
        for (String p : bluetoothPermissions())
            if (c.checkSelfPermission(p) != PackageManager.PERMISSION_GRANTED)
                return false;
        return true;
    }

    private boolean granted(String p) {
        return checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED;
    }

    private boolean listenerEnabled() {
        String flat = Settings.Secure.getString(getContentResolver(), "enabled_notification_listeners");
        return flat != null && flat.contains(new ComponentName(this, NotificationForwarder.class).flattenToString());
    }

    @SuppressLint({ "SetJavaScriptEnabled", "AddJavascriptInterface" })
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = new Prefs(this);
        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        web.setBackgroundColor(0xff0d1b2a);
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new android.webkit.WebChromeClient()); // confirm() dialogs
        web.addJavascriptInterface(new Bridge(), "Native");
        web.loadUrl("file:///android_asset/www/index.html");
        setContentView(web);

        if (hasBluetoothPermission(this))
            WatchService.start(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        WatchService.setListener(this);
        onStateChanged();
    }

    @Override
    protected void onPause() {
        WatchService.setListener(null);
        super.onPause();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] results) {
        if (hasBluetoothPermission(this))
            WatchService.start(this);
        onStateChanged();
    }

    @Override
    public void onStateChanged() {
        String json = stateJson().toString();
        web.evaluateJavascript("window.onNativeState && window.onNativeState(" + json + ")", null);
    }

    private void js(String call) {
        handler.post(() -> web.evaluateJavascript(call, null));
    }

    private JSONObject stateJson() {
        WatchService svc = WatchService.get();
        JSONObject s = svc != null ? svc.state() : new JSONObject();
        try {
            if (svc == null) {
                s.put("status", prefs.address().isEmpty() ? "no_watch" : "disconnected");
                s.put("name", prefs.deviceName());
                s.put("address", prefs.address());
                String w = prefs.lastWeather();
                s.put("weather", w.isEmpty() ? JSONObject.NULL : new JSONObject(w));
            }
            PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
            s.put("permissions", new JSONObject()
                    .put("bluetooth", hasBluetoothPermission(this))
                    .put("location", granted(Manifest.permission.ACCESS_COARSE_LOCATION))
                    .put("notifications", Build.VERSION.SDK_INT < 33 || granted(Manifest.permission.POST_NOTIFICATIONS))
                    .put("listener", listenerEnabled())
                    .put("battery", pm.isIgnoringBatteryOptimizations(getPackageName())));
            s.put("settings", new JSONObject()
                    .put("notifications", prefs.notifications())
                    .put("weather", prefs.weather())
                    .put("music", prefs.music())
                    .put("timeSync", prefs.timeSync())
                    .put("vibration", prefs.vibration())
                    .put("weatherMode", prefs.weatherMode())
                    .put("cityName", prefs.cityName())
                    .put("fahrenheit", prefs.fahrenheit()));
            s.put("apps", RecentApps.list(this));
            s.put("platform", "android");
        } catch (Exception ignored) {
        }
        return s;
    }

    private void startActivitySafe(Intent... intents) {
        for (Intent i : intents) {
            try {
                startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
                return;
            } catch (Exception ignored) {
            }
        }
    }

    /** window.Native in the web UI. Methods run on a binder thread; UI work is posted. */
    private final class Bridge {
        @JavascriptInterface public String getState() { return stateJson().toString(); }

        @JavascriptInterface public void requestPermissions() {
            handler.post(() -> {
                List<String> want = new ArrayList<>();
                for (String p : bluetoothPermissions())
                    if (!granted(p)) want.add(p);
                if (!granted(Manifest.permission.ACCESS_COARSE_LOCATION)) {
                    want.add(Manifest.permission.ACCESS_COARSE_LOCATION);
                    want.add(Manifest.permission.ACCESS_FINE_LOCATION);
                }
                if (Build.VERSION.SDK_INT >= 33 && !granted(Manifest.permission.POST_NOTIFICATIONS))
                    want.add(Manifest.permission.POST_NOTIFICATIONS);
                if (!want.isEmpty())
                    MainActivity.this.requestPermissions(want.toArray(new String[0]), 1);
            });
        }

        @JavascriptInterface public void openNotificationAccess() {
            handler.post(() -> startActivitySafe(new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)));
        }

        @SuppressLint("BatteryLife")
        @JavascriptInterface public void openBatterySettings() {
            handler.post(() -> startActivitySafe(
                    new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:" + getPackageName())),
                    new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)));
        }

        /** Android only lets the user turn on Bluetooth tethering, so open that screen. */
        @JavascriptInterface public void openTethering() {
            handler.post(() -> startActivitySafe(
                    new Intent().setComponent(new ComponentName("com.android.settings", "com.android.settings.TetherSettings")),
                    new Intent().setComponent(new ComponentName("com.android.settings", "com.android.settings.Settings$TetherSettingsActivity")),
                    new Intent(Settings.ACTION_WIRELESS_SETTINGS)));
        }

        @JavascriptInterface public void openBluetoothSettings() {
            handler.post(() -> startActivitySafe(new Intent(Settings.ACTION_BLUETOOTH_SETTINGS)));
        }

        @JavascriptInterface public void scan() {
            handler.post(() -> {
                if (!hasBluetoothPermission(MainActivity.this)) {
                    requestPermissions();
                    return;
                }
                WatchService.start(MainActivity.this);
                handler.postDelayed(() -> {
                    WatchService s = WatchService.get();
                    if (s != null) s.startScan();
                }, 300);
            });
        }

        @JavascriptInterface public void stopScan() {
            handler.post(() -> { WatchService s = WatchService.get(); if (s != null) s.stopScan(); });
        }

        @JavascriptInterface public void choose(String address, String name) {
            handler.post(() -> { WatchService s = WatchService.get(); if (s != null) s.chooseWatch(address, name); });
        }

        @JavascriptInterface public void forget(boolean unpair) {
            handler.post(() -> { WatchService s = WatchService.get(); if (s != null) s.forgetWatch(unpair); onStateChanged(); });
        }

        @JavascriptInterface public void repair() {
            handler.post(() -> { WatchService s = WatchService.get(); if (s != null) s.repair(); });
        }

        @JavascriptInterface public void setSetting(String key, String value) {
            handler.post(() -> {
                switch (key) {
                case "vibration": prefs.setString(key, value); break;
                case "notifications": case "weather": case "music": case "timeSync": case "fahrenheit":
                    prefs.setBool(key, Boolean.parseBoolean(value)); break;
                default: return;
                }
                WatchService s = WatchService.get();
                if (s != null && key.equals("weather") && prefs.weather()) s.refreshWeather();
                if (s != null && key.equals("timeSync") && prefs.timeSync()) s.syncTime();
                onStateChanged();
            });
        }

        @JavascriptInterface public void setMuted(String pkg, boolean muted) {
            handler.post(() -> { prefs.setMuted(pkg, muted); onStateChanged(); });
        }

        @JavascriptInterface public void refreshWeather() {
            handler.post(() -> { WatchService s = WatchService.get(); if (s != null) s.refreshWeather(); });
        }

        @JavascriptInterface public void useGpsWeather() {
            handler.post(() -> {
                prefs.setString("weatherMode", "gps");
                WatchService s = WatchService.get();
                if (s != null) s.refreshWeather();
                onStateChanged();
            });
        }

        @JavascriptInterface public void setCity(String name, double lat, double lon) {
            handler.post(() -> {
                prefs.setCity(name, lat, lon);
                WatchService s = WatchService.get();
                if (s != null) s.refreshWeather();
                onStateChanged();
            });
        }

        @JavascriptInterface public void searchCity(String query) {
            Executors.newSingleThreadExecutor().execute(() -> {
                JSONArray r;
                try {
                    r = WeatherClient.searchCity(query);
                } catch (Exception e) {
                    r = new JSONArray();
                }
                js("window.onCityResults && window.onCityResults(" + r + ")");
            });
        }

        @JavascriptInterface public void testNotification() {
            handler.post(() -> { WatchService s = WatchService.get(); if (s != null) s.sendTestNotification(); });
        }

        @JavascriptInterface public void syncTime() {
            handler.post(() -> { WatchService s = WatchService.get(); if (s != null) s.syncTime(); });
        }
    }
}
