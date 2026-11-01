package org.skipjack.watchlink;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.HashSet;
import java.util.Set;

/** App settings. */
final class Prefs {
    private final SharedPreferences p;

    Prefs(Context context) {
        p = context.getSharedPreferences("watchlink", Context.MODE_PRIVATE);
    }

    String address() { return p.getString("address", ""); }
    String deviceName() { return p.getString("deviceName", ""); }
    void setDevice(String address, String name) {
        p.edit().putString("address", address).putString("deviceName", name).apply();
    }
    void forgetDevice() { p.edit().remove("address").remove("deviceName").apply(); }

    boolean bool(String key, boolean def) { return p.getBoolean(key, def); }
    void setBool(String key, boolean value) { p.edit().putBoolean(key, value).apply(); }

    String string(String key, String def) { return p.getString(key, def); }
    void setString(String key, String value) { p.edit().putString(key, value).apply(); }

    // Features (all on by default).
    boolean notifications() { return bool("notifications", true); }
    boolean weather() { return bool("weather", true); }
    boolean music() { return bool("music", true); }
    boolean timeSync() { return bool("timeSync", true); }

    /** none | normal | strong */
    String vibration() { return string("vibration", "normal"); }

    /** Weather location: "gps" or a searched city. */
    String weatherMode() { return string("weatherMode", "gps"); }
    String cityName() { return string("cityName", ""); }
    double lat() { return Double.longBitsToDouble(p.getLong("lat", Double.doubleToLongBits(Double.NaN))); }
    double lon() { return Double.longBitsToDouble(p.getLong("lon", Double.doubleToLongBits(Double.NaN))); }
    void setCity(String name, double lat, double lon) {
        p.edit().putString("weatherMode", "city").putString("cityName", name)
                .putLong("lat", Double.doubleToLongBits(lat))
                .putLong("lon", Double.doubleToLongBits(lon)).apply();
    }
    boolean fahrenheit() { return bool("fahrenheit", false); }

    String lastWeather() { return string("lastWeather", ""); }
    void setLastWeather(String json) { setString("lastWeather", json); }

    Set<String> mutedApps() { return new HashSet<>(p.getStringSet("mutedApps", new HashSet<>())); }
    void setMuted(String pkg, boolean muted) {
        Set<String> s = mutedApps();
        if (muted) s.add(pkg); else s.remove(pkg);
        p.edit().putStringSet("mutedApps", s).apply();
    }
}
