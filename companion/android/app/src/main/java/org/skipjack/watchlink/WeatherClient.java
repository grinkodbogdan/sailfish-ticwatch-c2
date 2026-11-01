package org.skipjack.watchlink;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

/** Open-Meteo forecasts and city search (no account or key needed). Blocking: call off the UI thread. */
final class WeatherClient {
    private WeatherClient() {}

    private static String get(String url) throws Exception {
        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
        c.setConnectTimeout(15000);
        c.setReadTimeout(15000);
        c.setRequestProperty("User-Agent", "WatchLink/1.0");
        try (InputStream in = c.getInputStream()) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            int n;
            while ((n = in.read(buf)) > 0)
                out.write(buf, 0, n);
            return out.toString("UTF-8");
        } finally {
            c.disconnect();
        }
    }

    /**
     * Current conditions and a 5-day forecast, as
     * {city, updated, current:{temp, code, wind, humidity}, days:[{date, code, max, min, rain}]}.
     */
    static JSONObject forecast(double lat, double lon, String city) throws Exception {
        String url = String.format(Locale.US,
                "https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f"
                + "&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,apparent_temperature"
                + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
                + "&timezone=auto&forecast_days=5", lat, lon);
        JSONObject r = new JSONObject(get(url));
        JSONObject current = r.getJSONObject("current");
        JSONObject daily = r.getJSONObject("daily");

        JSONObject out = new JSONObject();
        out.put("city", city);
        out.put("updated", System.currentTimeMillis());
        out.put("current", new JSONObject()
                .put("temp", current.getDouble("temperature_2m"))
                .put("feels", current.optDouble("apparent_temperature", current.getDouble("temperature_2m")))
                .put("code", current.getInt("weather_code"))
                .put("wind", current.optDouble("wind_speed_10m", 0))
                .put("humidity", current.optInt("relative_humidity_2m", 0)));
        JSONArray days = new JSONArray();
        JSONArray dates = daily.getJSONArray("time");
        for (int i = 0; i < dates.length() && i < 5; i++) {
            days.put(new JSONObject()
                    .put("date", dates.getString(i))
                    .put("code", daily.getJSONArray("weather_code").getInt(i))
                    .put("max", daily.getJSONArray("temperature_2m_max").getDouble(i))
                    .put("min", daily.getJSONArray("temperature_2m_min").getDouble(i))
                    .put("rain", daily.getJSONArray("precipitation_probability_max").optInt(i, 0)));
        }
        out.put("days", days);
        return out;
    }

    /** Up to 6 places matching a name: [{name, detail, lat, lon}]. */
    static JSONArray searchCity(String query) throws Exception {
        String url = "https://geocoding-api.open-meteo.com/v1/search?count=6&format=json&language="
                + Locale.getDefault().getLanguage() + "&name="
                + URLEncoder.encode(query, StandardCharsets.UTF_8.name());
        JSONObject r = new JSONObject(get(url));
        JSONArray results = r.optJSONArray("results");
        JSONArray out = new JSONArray();
        if (results == null)
            return out;
        for (int i = 0; i < results.length(); i++) {
            JSONObject p = results.getJSONObject(i);
            StringBuilder detail = new StringBuilder();
            for (String key : new String[] { "admin1", "country" }) {
                String v = p.optString(key, "");
                if (!v.isEmpty()) {
                    if (detail.length() > 0) detail.append(", ");
                    detail.append(v);
                }
            }
            out.put(new JSONObject()
                    .put("name", p.getString("name"))
                    .put("detail", detail.toString())
                    .put("lat", p.getDouble("latitude"))
                    .put("lon", p.getDouble("longitude")));
        }
        return out;
    }

    /**
     * WMO weather code (Open-Meteo) to the OpenWeatherMap condition id the
     * watch protocol carries.
     */
    static int owmId(int wmo) {
        switch (wmo) {
        case 0: return 800;                 // clear
        case 1: return 801;                 // mainly clear
        case 2: return 802;                 // partly cloudy
        case 3: return 804;                 // overcast
        case 45: case 48: return 741;       // fog
        case 51: return 300;                // drizzle
        case 53: return 301;
        case 55: return 302;
        case 56: case 57: return 511;       // freezing drizzle
        case 61: return 500;                // rain
        case 63: return 501;
        case 65: return 502;
        case 66: case 67: return 511;       // freezing rain
        case 71: return 600;                // snow
        case 73: return 601;
        case 75: return 602;
        case 77: return 600;                // snow grains
        case 80: return 520;                // showers
        case 81: return 521;
        case 82: return 522;
        case 85: return 620;                // snow showers
        case 86: return 622;
        case 95: return 211;                // thunderstorm
        case 96: case 99: return 202;       // thunderstorm with hail
        default: return 803;
        }
    }
}
