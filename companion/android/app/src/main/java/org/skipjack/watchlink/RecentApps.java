package org.skipjack.watchlink;

import android.content.Context;
import android.content.SharedPreferences;

import org.json.JSONArray;
import org.json.JSONObject;

/** Apps that recently posted notifications, for the per-app mute list in the app. */
final class RecentApps {
    private RecentApps() {}

    private static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences("recentApps", Context.MODE_PRIVATE);
    }

    static void note(Context c, String pkg, String label) {
        prefs(c).edit().putString(pkg, label + "\n" + System.currentTimeMillis()).apply();
    }

    /** [{pkg, name, muted}], most recent first. */
    static JSONArray list(Context c) {
        Prefs p = new Prefs(c);
        java.util.List<String[]> rows = new java.util.ArrayList<>();
        for (java.util.Map.Entry<String, ?> e : prefs(c).getAll().entrySet()) {
            String[] v = String.valueOf(e.getValue()).split("\n");
            rows.add(new String[] { e.getKey(), v[0], v.length > 1 ? v[1] : "0" });
        }
        rows.sort((a, b) -> Long.compare(Long.parseLong(b[2]), Long.parseLong(a[2])));
        JSONArray out = new JSONArray();
        java.util.Set<String> muted = p.mutedApps();
        try {
            for (String[] r : rows)
                out.put(new JSONObject().put("pkg", r[0]).put("name", r[1]).put("muted", muted.contains(r[0])));
        } catch (Exception ignored) {
        }
        return out;
    }
}
