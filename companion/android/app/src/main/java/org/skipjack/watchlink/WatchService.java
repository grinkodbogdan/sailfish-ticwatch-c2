package org.skipjack.watchlink;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanFilter;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ServiceInfo;
import android.location.Location;
import android.location.LocationManager;
import android.media.AudioManager;
import android.media.MediaMetadata;
import android.media.session.MediaController;
import android.media.session.MediaSessionManager;
import android.media.session.PlaybackState;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.ParcelUuid;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONObject;

import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Keeps the watch connected and in sync: notifications, weather, time,
 * music and battery. Runs as a foreground service so the link survives with
 * the app closed. All Bluetooth work happens on the main thread.
 */
@SuppressLint("MissingPermission") // Started only once the permissions are granted (MainActivity).
public class WatchService extends Service {
    private static final String TAG = "WatchLink";
    private static final String CHANNEL = "link";
    private static final int FOREGROUND_ID = 1;
    private static final long WEATHER_INTERVAL = 60 * 60 * 1000L;
    private static final long OP_TIMEOUT = 15000;

    /** UI listener (MainActivity), called on the main thread. */
    interface Listener { void onStateChanged(); }

    private static WatchService instance;
    private static Listener listener;

    static WatchService get() { return instance; }
    static void setListener(Listener l) { listener = l; }

    static void start(Context context) {
        Intent i = new Intent(context, WatchService.class);
        if (Build.VERSION.SDK_INT >= 26)
            context.startForegroundService(i);
        else
            context.startService(i);
    }

    // ---- state ----------------------------------------------------------------
    enum Status { NO_WATCH, BLUETOOTH_OFF, CONNECTING, PAIRING, CONNECTED, DISCONNECTED }

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private Prefs prefs;
    private BluetoothAdapter adapter;
    private BluetoothGatt gatt;
    private Status status = Status.NO_WATCH;
    private int battery = -1;
    private int mtu = 23;
    private boolean ready;              // services discovered and set up
    private boolean needsResetup;       // setup hit "not paired yet"; redo once bonded
    private String lastError = "";
    private final List<String> log = Collections.synchronizedList(new ArrayList<>());

    private boolean scanning;
    private final Map<String, JSONObject> scanResults = new LinkedHashMap<>();

    private JSONObject weather;
    private boolean weatherBusy;

    // Notifications waiting for the connection (newest wins per id).
    private final LinkedHashMap<Integer, byte[]> pendingNotifications = new LinkedHashMap<>();

    // ---- lifecycle --------------------------------------------------------------
    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        prefs = new Prefs(this);
        adapter = ((BluetoothManager) getSystemService(BLUETOOTH_SERVICE)).getAdapter();
        try {
            String w = prefs.lastWeather();
            if (!w.isEmpty())
                weather = new JSONObject(w);
        } catch (Exception ignored) {
        }

        NotificationManager nm = getSystemService(NotificationManager.class);
        NotificationChannel channel = new NotificationChannel(CHANNEL, "Watch connection",
                NotificationManager.IMPORTANCE_LOW);
        channel.setShowBadge(false);
        nm.createNotificationChannel(channel);
        if (Build.VERSION.SDK_INT >= 29)
            startForeground(FOREGROUND_ID, buildNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE);
        else
            startForeground(FOREGROUND_ID, buildNotification());

        IntentFilter f = new IntentFilter();
        f.addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED);
        f.addAction(BluetoothAdapter.ACTION_STATE_CHANGED);
        f.addAction(Intent.ACTION_TIME_CHANGED);
        f.addAction(Intent.ACTION_TIMEZONE_CHANGED);
        if (Build.VERSION.SDK_INT >= 33)
            registerReceiver(receiver, f, Context.RECEIVER_EXPORTED);
        else
            registerReceiver(receiver, f);

        handler.post(weatherTick);
        connect();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }

    @Override
    public void onDestroy() {
        instance = null;
        handler.removeCallbacksAndMessages(null);
        try { unregisterReceiver(receiver); } catch (Exception ignored) {}
        stopMediaWatch();
        closeGatt();
        worker.shutdownNow();
        super.onDestroy();
    }

    private void log(String line) {
        Log.i(TAG, line);
        String t = new SimpleDateFormat("HH:mm:ss", Locale.US).format(new Date());
        log.add(t + "  " + line);
        while (log.size() > 60)
            log.remove(0);
    }

    private void setStatus(Status s) {
        if (status == s)
            return;
        status = s;
        log("status: " + s);
        updateNotification();
        notifyUi();
    }

    private void notifyUi() {
        Listener l = listener;
        if (l != null)
            handler.post(l::onStateChanged);
    }

    // ---- foreground notification -------------------------------------------------
    private Notification buildNotification() {
        String name = prefs.deviceName().isEmpty() ? "Watch" : prefs.deviceName();
        String text;
        switch (status) {
        case CONNECTED: text = "Connected" + (battery >= 0 ? " · battery " + battery + "%" : ""); break;
        case CONNECTING: text = "Connecting…"; break;
        case PAIRING: text = "Pairing — confirm the code on the watch"; break;
        case BLUETOOTH_OFF: text = "Bluetooth is off"; break;
        case NO_WATCH: text = "No watch set up"; break;
        default: text = "Waiting for the watch"; break;
        }
        PendingIntent open = PendingIntent.getActivity(this, 0, new Intent(this, MainActivity.class),
                PendingIntent.FLAG_IMMUTABLE);
        return new Notification.Builder(this, CHANNEL)
                .setSmallIcon(R.drawable.ic_stat_watch)
                .setContentTitle(name)
                .setContentText(text)
                .setContentIntent(open)
                .setOngoing(true)
                .setShowWhen(false)
                .build();
    }

    private void updateNotification() {
        getSystemService(NotificationManager.class).notify(FOREGROUND_ID, buildNotification());
    }

    // ---- receiver -----------------------------------------------------------------
    private final BroadcastReceiver receiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (BluetoothDevice.ACTION_BOND_STATE_CHANGED.equals(action)) {
                BluetoothDevice d = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                if (d == null || !d.getAddress().equals(prefs.address()))
                    return;
                int state = intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.BOND_NONE);
                log("bond state: " + state);
                if (state == BluetoothDevice.BOND_BONDED && gatt != null && needsResetup) {
                    needsResetup = false;
                    handler.postDelayed(() -> { ready = false; ops.clear(); currentOp = null; setUp(); }, 800);
                } else if (state == BluetoothDevice.BOND_BONDING) {
                    setStatus(Status.PAIRING);
                }
                else if (state == BluetoothDevice.BOND_NONE && status == Status.PAIRING) {
                    lastError = "Pairing was declined or failed";
                    setStatus(Status.DISCONNECTED);
                }
                notifyUi();
            } else if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
                int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.STATE_OFF);
                if (state == BluetoothAdapter.STATE_ON)
                    connect();
                else if (state == BluetoothAdapter.STATE_OFF) {
                    closeGatt();
                    setStatus(Status.BLUETOOTH_OFF);
                }
            } else if (Intent.ACTION_TIME_CHANGED.equals(action) || Intent.ACTION_TIMEZONE_CHANGED.equals(action)) {
                syncTime();
            }
        }
    };

    // ---- scanning -------------------------------------------------------------------
    private final ScanCallback scanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int type, ScanResult r) {
            BluetoothDevice d = r.getDevice();
            String name = r.getScanRecord() != null ? r.getScanRecord().getDeviceName() : null;
            if (name == null || name.isEmpty())
                name = d.getName();
            if (name == null || name.isEmpty())
                name = "Watch " + d.getAddress().substring(9);
            try {
                scanResults.put(d.getAddress(), new JSONObject()
                        .put("address", d.getAddress()).put("name", name).put("rssi", r.getRssi())
                        .put("bonded", d.getBondState() == BluetoothDevice.BOND_BONDED));
            } catch (Exception ignored) {
            }
            notifyUi();
        }

        @Override
        public void onScanFailed(int errorCode) {
            lastError = "Scan failed (" + errorCode + ")";
            scanning = false;
            notifyUi();
        }
    };

    void startScan() {
        if (adapter == null || !adapter.isEnabled()) {
            lastError = "Turn Bluetooth on first";
            notifyUi();
            return;
        }
        BluetoothLeScanner scanner = adapter.getBluetoothLeScanner();
        if (scanner == null || scanning)
            return;
        scanResults.clear();
        List<ScanFilter> filters = new ArrayList<>();
        filters.add(new ScanFilter.Builder().setServiceUuid(new ParcelUuid(Protocol.ADVERTISED)).build());
        scanner.startScan(filters, new ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(), scanCallback);
        scanning = true;
        log("scanning");
        notifyUi();
        handler.postDelayed(this::stopScan, 15000);
    }

    void stopScan() {
        if (!scanning)
            return;
        BluetoothLeScanner scanner = adapter.getBluetoothLeScanner();
        if (scanner != null)
            scanner.stopScan(scanCallback);
        scanning = false;
        notifyUi();
    }

    // ---- connection ----------------------------------------------------------------
    void chooseWatch(String address, String name) {
        stopScan();
        closeGatt();
        prefs.setDevice(address, name);
        lastError = "";
        background = false;
        connect();
    }

    void forgetWatch(boolean unpair) {
        String address = prefs.address();
        closeGatt();
        if (unpair && !address.isEmpty() && adapter != null)
            removeBond(adapter.getRemoteDevice(address));
        prefs.forgetDevice();
        battery = -1;
        setStatus(Status.NO_WATCH);
    }

    /** Drop the pairing on this phone and pair again (e.g. after the watch was reflashed). */
    void repair() {
        String address = prefs.address();
        if (address.isEmpty())
            return;
        closeGatt();
        removeBond(adapter.getRemoteDevice(address));
        background = false;
        handler.postDelayed(this::connect, 1500);
    }

    private boolean background;     // autoConnect mode after a direct attempt failed

    private void connect() {
        String address = prefs.address();
        if (address.isEmpty()) {
            setStatus(Status.NO_WATCH);
            return;
        }
        if (adapter == null || !adapter.isEnabled()) {
            setStatus(Status.BLUETOOTH_OFF);
            return;
        }
        if (gatt != null)
            return;
        BluetoothDevice device = adapter.getRemoteDevice(address);
        log("connecting to " + address + (background ? " (in background)" : ""));
        setStatus(Status.CONNECTING);
        // A direct connection is fast but gives up after ~30 s; background
        // (autoConnect) waits indefinitely and reconnects whenever the watch
        // comes back in range.
        gatt = device.connectGatt(this, background, gattCallback, BluetoothDevice.TRANSPORT_LE);
    }

    private void closeGatt() {
        ready = false;
        ops.clear();
        currentOp = null;
        handler.removeCallbacks(opTimeout);
        if (gatt != null) {
            gatt.disconnect();
            gatt.close();
            gatt = null;
        }
    }

    private void removeBond(BluetoothDevice device) {
        try {
            Method m = BluetoothDevice.class.getMethod("removeBond");
            m.invoke(device);
            log("removed pairing");
        } catch (Exception e) {
            log("cannot remove pairing: " + e);
        }
    }

    private final BluetoothGattCallback gattCallback = new BluetoothGattCallback() {
        @Override
        public void onConnectionStateChange(BluetoothGatt g, int st, int newState) {
            handler.post(() -> {
                if (g != gatt)
                    return;
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    log("link up");
                    background = true;
                    // No createBond(): on a dual-mode watch Android would pair over
                    // classic Bluetooth and derive LE keys, which the watch's stack
                    // can't. The first protected request makes Android pair over LE.
                    afterBonded();
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    log("link down (" + st + ")");
                    ready = false;
                    ops.clear();
                    currentOp = null;
                    handler.removeCallbacks(opTimeout);
                    if (st == 5 || st == 15 || st == 137) // auth/encryption failures
                        lastError = "The watch refused this phone's pairing — use “Pair again”";
                    setStatus(Status.DISCONNECTED);
                    if (!background) {
                        // Direct attempt over: wait in the background from now on.
                        background = true;
                        closeGatt();
                        handler.postDelayed(WatchService.this::connect, 1000);
                    }
                    // In background mode the same object keeps reconnecting.
                }
            });
        }

        @Override
        public void onMtuChanged(BluetoothGatt g, int newMtu, int st) {
            handler.post(() -> {
                if (st == BluetoothGatt.GATT_SUCCESS)
                    mtu = newMtu;
                log("mtu " + mtu);
                g.discoverServices();
            });
        }

        @Override
        public void onServicesDiscovered(BluetoothGatt g, int st) {
            handler.post(() -> {
                if (g != gatt)
                    return;
                if (st != BluetoothGatt.GATT_SUCCESS || g.getService(Protocol.NOTIFICATIONS) == null) {
                    lastError = "This watch does not offer the sync services (is watch-btsyncd running?)";
                    log("services missing (" + st + ")");
                    setStatus(Status.DISCONNECTED);
                    return;
                }
                setUp();
            });
        }

        @Override
        public void onCharacteristicWrite(BluetoothGatt g, BluetoothGattCharacteristic c, int st) {
            handler.post(() -> opDone(st, "write " + c.getUuid()));
        }

        @Override
        public void onDescriptorWrite(BluetoothGatt g, BluetoothGattDescriptor d, int st) {
            handler.post(() -> opDone(st, "subscribe " + d.getCharacteristic().getUuid()));
        }

        @Override
        public void onCharacteristicRead(BluetoothGatt g, BluetoothGattCharacteristic c, byte[] value, int st) {
            handler.post(() -> {
                if (st == BluetoothGatt.GATT_SUCCESS)
                    onValue(c.getUuid(), value);
                opDone(st, "read " + c.getUuid());
            });
        }

        @SuppressWarnings("deprecation")
        @Override
        public void onCharacteristicRead(BluetoothGatt g, BluetoothGattCharacteristic c, int st) {
            if (Build.VERSION.SDK_INT < 33)
                onCharacteristicRead(g, c, c.getValue(), st);
        }

        @Override
        public void onCharacteristicChanged(BluetoothGatt g, BluetoothGattCharacteristic c, byte[] value) {
            handler.post(() -> onValue(c.getUuid(), value));
        }

        @SuppressWarnings("deprecation")
        @Override
        public void onCharacteristicChanged(BluetoothGatt g, BluetoothGattCharacteristic c) {
            if (Build.VERSION.SDK_INT < 33)
                onCharacteristicChanged(g, c, c.getValue());
        }
    };

    private void afterBonded() {
        if (gatt == null || ready)
            return;
        setStatus(Status.CONNECTING);
        log("setting up");
        if (!gatt.requestMtu(247))
            gatt.discoverServices();
    }

    /** First sync after (re)connecting. */
    private void setUp() {
        ready = true;
        lastError = "";
        subscribe(Protocol.BATTERY, Protocol.BATTERY_LEVEL);
        subscribe(Protocol.MEDIA, Protocol.MEDIA_COMMANDS);
        read(Protocol.BATTERY, Protocol.BATTERY_LEVEL);
        syncTime();
        if (prefs.weather()) {
            if (weather != null)
                pushWeather();
            if (weather == null || System.currentTimeMillis() - weather.optLong("updated") > 30 * 60 * 1000L)
                refreshWeather();
        }
        startMediaWatch();
        synchronized (pendingNotifications) {
            for (byte[] n : pendingNotifications.values())
                writeLong(Protocol.NOTIFICATIONS, Protocol.NOTIFICATION_UPDATE, n);
            pendingNotifications.clear();
        }
        if (!needsResetup)
            setStatus(Status.CONNECTED);
    }

    private void onValue(UUID uuid, byte[] value) {
        if (value == null || value.length == 0)
            return;
        if (Protocol.BATTERY_LEVEL.equals(uuid)) {
            battery = value[0] & 0xff;
            updateNotification();
            notifyUi();
        } else if (Protocol.MEDIA_COMMANDS.equals(uuid)) {
            onMediaCommand(value);
        }
    }

    // ---- GATT operation queue --------------------------------------------------------
    // Android allows one GATT operation at a time; everything goes through here.
    private static final class Op {
        final int kind; // 0 write, 1 read, 2 subscribe
        final UUID service, characteristic;
        final byte[] value;
        Op(int kind, UUID service, UUID characteristic, byte[] value) {
            this.kind = kind; this.service = service; this.characteristic = characteristic; this.value = value;
        }
    }

    private final ArrayDeque<Op> ops = new ArrayDeque<>();
    private Op currentOp;
    private final Runnable opTimeout = () -> {
        log("operation timed out");
        currentOp = null;
        nextOp();
    };

    private void write(UUID service, UUID characteristic, byte[] value) {
        ops.add(new Op(0, service, characteristic, value));
        nextOp();
    }

    /** Values longer than one packet are sent as consecutive writes (the watch reassembles them). */
    private void writeLong(UUID service, UUID characteristic, byte[] value) {
        int chunk = Math.max(20, mtu - 3);
        for (int i = 0; i < value.length; i += chunk) {
            byte[] part = new byte[Math.min(chunk, value.length - i)];
            System.arraycopy(value, i, part, 0, part.length);
            ops.add(new Op(0, service, characteristic, part));
        }
        nextOp();
    }

    private void read(UUID service, UUID characteristic) {
        ops.add(new Op(1, service, characteristic, null));
        nextOp();
    }

    private void subscribe(UUID service, UUID characteristic) {
        ops.add(new Op(2, service, characteristic, null));
        nextOp();
    }

    @SuppressWarnings("deprecation")
    private void nextOp() {
        if (currentOp != null || gatt == null || !ready)
            return;
        Op op = ops.poll();
        if (op == null)
            return;
        BluetoothGattService s = gatt.getService(op.service);
        BluetoothGattCharacteristic c = s == null ? null : s.getCharacteristic(op.characteristic);
        if (c == null) {
            log("missing characteristic " + op.characteristic);
            nextOp();
            return;
        }
        boolean started;
        if (op.kind == 0) {
            if (Build.VERSION.SDK_INT >= 33) {
                started = gatt.writeCharacteristic(c, op.value, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT)
                        == BluetoothGatt.GATT_SUCCESS;
            } else {
                c.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
                c.setValue(op.value);
                started = gatt.writeCharacteristic(c);
            }
        } else if (op.kind == 1) {
            started = gatt.readCharacteristic(c);
        } else {
            gatt.setCharacteristicNotification(c, true);
            BluetoothGattDescriptor d = c.getDescriptor(Protocol.CCC_DESCRIPTOR);
            if (d == null) {
                nextOp();
                return;
            }
            if (Build.VERSION.SDK_INT >= 33) {
                started = gatt.writeDescriptor(d, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
                        == BluetoothGatt.GATT_SUCCESS;
            } else {
                d.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                started = gatt.writeDescriptor(d);
            }
        }
        if (!started) {
            log("could not start operation on " + op.characteristic);
            handler.postDelayed(this::nextOp, 200);
            return;
        }
        currentOp = op;
        handler.postDelayed(opTimeout, OP_TIMEOUT);
    }

    private void opDone(int st, String what) {
        handler.removeCallbacks(opTimeout);
        if (st != BluetoothGatt.GATT_SUCCESS)
            log(what + " failed: " + st);
        // 5 insufficient authentication, 8 authorization, 15 encryption, 137 auth fail:
        // Android starts LE pairing on its own; set up again once bonded.
        if ((st == 5 || st == 8 || st == 15 || st == 137) && gatt != null
                && gatt.getDevice().getBondState() != BluetoothDevice.BOND_BONDED) {
            needsResetup = true;
            setStatus(Status.PAIRING);
        }
        currentOp = null;
        nextOp();
    }

    // ---- time -----------------------------------------------------------------------------
    void syncTime() {
        if (!ready || !prefs.timeSync())
            return;
        write(Protocol.TIME, Protocol.TIME_SET, Protocol.time(Calendar.getInstance()));
        log("time sent");
    }

    // ---- notifications ------------------------------------------------------------------
    /** From NotificationForwarder. */
    void forwardNotification(String pkg, int id, String appName, String title, String text) {
        if (!prefs.notifications() || prefs.mutedApps().contains(pkg))
            return;
        byte[] data = Protocol.notificationInsert(pkg, id, appName, "", title, text, prefs.vibration());
        if (ready) {
            writeLong(Protocol.NOTIFICATIONS, Protocol.NOTIFICATION_UPDATE, data);
        } else {
            synchronized (pendingNotifications) {
                pendingNotifications.remove(id);
                pendingNotifications.put(id, data);
                while (pendingNotifications.size() > 15)
                    pendingNotifications.remove(pendingNotifications.keySet().iterator().next());
            }
        }
    }

    void removeNotification(int id) {
        synchronized (pendingNotifications) {
            pendingNotifications.remove(id);
        }
        if (ready)
            write(Protocol.NOTIFICATIONS, Protocol.NOTIFICATION_UPDATE, Protocol.notificationRemoved(id));
    }

    /** Test button in the app. */
    void sendTestNotification() {
        forwardNotification(getPackageName(), 1, "Watch Link", "Hello from your phone",
                "Notifications from the phone will appear like this.");
    }

    // ---- weather ---------------------------------------------------------------------------
    private final Runnable weatherTick = new Runnable() {
        @Override
        public void run() {
            if (prefs.weather())
                refreshWeather();
            handler.postDelayed(this, WEATHER_INTERVAL);
        }
    };

    JSONObject weather() { return weather; }

    @SuppressWarnings("deprecation")
    void refreshWeather() {
        if (weatherBusy)
            return;
        double lat, lon;
        String city;
        if ("city".equals(prefs.weatherMode()) && !Double.isNaN(prefs.lat())) {
            lat = prefs.lat();
            lon = prefs.lon();
            city = prefs.cityName();
        } else {
            Location loc = lastLocation();
            if (loc == null) {
                lastError = "No location yet — allow location or pick a city for weather";
                notifyUi();
                return;
            }
            lat = loc.getLatitude();
            lon = loc.getLongitude();
            city = "";
        }
        weatherBusy = true;
        final double fLat = lat, fLon = lon;
        final String fCity = city;
        worker.execute(() -> {
            try {
                String name = fCity;
                if (name.isEmpty())
                    name = placeName(fLat, fLon);
                JSONObject w = WeatherClient.forecast(fLat, fLon, name);
                handler.post(() -> {
                    weather = w;
                    prefs.setLastWeather(w.toString());
                    log("weather updated: " + w.optString("city"));
                    pushWeather();
                    notifyUi();
                });
            } catch (Exception e) {
                handler.post(() -> {
                    lastError = "Weather: " + e.getMessage();
                    log("weather failed: " + e);
                    notifyUi();
                });
            } finally {
                weatherBusy = false;
            }
        });
    }

    @SuppressWarnings("MissingPermission")
    private Location lastLocation() {
        LocationManager lm = (LocationManager) getSystemService(LOCATION_SERVICE);
        Location best = null;
        try {
            for (String provider : lm.getProviders(true)) {
                Location l = lm.getLastKnownLocation(provider);
                if (l != null && (best == null || l.getTime() > best.getTime()))
                    best = l;
            }
        } catch (SecurityException ignored) {
        }
        if (best == null || System.currentTimeMillis() - best.getTime() > 3 * 3600 * 1000L) {
            // Ask for a fresh fix for next time.
            try {
                String provider = lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
                        ? LocationManager.NETWORK_PROVIDER : LocationManager.GPS_PROVIDER;
                lm.requestSingleUpdate(provider, location -> refreshWeather(), Looper.getMainLooper());
            } catch (Exception ignored) {
            }
        }
        return best;
    }

    @SuppressWarnings("deprecation")
    private String placeName(double lat, double lon) {
        try {
            android.location.Geocoder g = new android.location.Geocoder(this, Locale.getDefault());
            List<android.location.Address> a = g.getFromLocation(lat, lon, 1);
            if (a != null && !a.isEmpty()) {
                String n = a.get(0).getLocality();
                if (n == null) n = a.get(0).getSubAdminArea();
                if (n != null) return n;
            }
        } catch (Exception ignored) {
        }
        return "";
    }

    private void pushWeather() {
        if (!ready || weather == null)
            return;
        try {
            JSONArray days = weather.getJSONArray("days");
            int[] ids = new int[5], max = new int[5], min = new int[5];
            for (int i = 0; i < 5 && i < days.length(); i++) {
                JSONObject d = days.getJSONObject(i);
                ids[i] = WeatherClient.owmId(d.getInt("code"));
                max[i] = Protocol.kelvin(d.getDouble("max"));
                min[i] = Protocol.kelvin(d.getDouble("min"));
            }
            write(Protocol.WEATHER, Protocol.WEATHER_CITY, Protocol.utf8(weather.optString("city", "")));
            write(Protocol.WEATHER, Protocol.WEATHER_MAX, Protocol.fiveShorts(max));
            write(Protocol.WEATHER, Protocol.WEATHER_MIN, Protocol.fiveShorts(min));
            // The watch stamps the forecast when the ids arrive, so they go last.
            write(Protocol.WEATHER, Protocol.WEATHER_IDS, Protocol.fiveShorts(ids));
            log("weather sent");
        } catch (Exception e) {
            log("weather encode failed: " + e);
        }
    }

    // ---- music ----------------------------------------------------------------------------
    private MediaSessionManager sessions;
    private MediaController controller;
    private String sentTitle = null, sentArtist = null, sentAlbum = null;
    private int sentPlaying = -1;

    private final MediaSessionManager.OnActiveSessionsChangedListener sessionsChanged = this::pickController;

    private final MediaController.Callback controllerCallback = new MediaController.Callback() {
        @Override public void onMetadataChanged(MediaMetadata metadata) { pushMedia(); }
        @Override public void onPlaybackStateChanged(PlaybackState state) { pushMedia(); }
        @Override public void onSessionDestroyed() { pickController(null); }
    };

    private void startMediaWatch() {
        if (!prefs.music() || sessions != null)
            return;
        try {
            sessions = (MediaSessionManager) getSystemService(MEDIA_SESSION_SERVICE);
            ComponentName listenerComponent = new ComponentName(this, NotificationForwarder.class);
            sessions.addOnActiveSessionsChangedListener(sessionsChanged, listenerComponent, handler);
            pickController(sessions.getActiveSessions(listenerComponent));
        } catch (SecurityException e) {
            // Needs notification access.
            sessions = null;
        }
    }

    private void stopMediaWatch() {
        if (sessions != null)
            sessions.removeOnActiveSessionsChangedListener(sessionsChanged);
        sessions = null;
        if (controller != null)
            controller.unregisterCallback(controllerCallback);
        controller = null;
    }

    /** Notification access was just granted. */
    void onListenerConnected() {
        if (ready)
            startMediaWatch();
        notifyUi();
    }

    private void pickController(List<MediaController> list) {
        if (list == null && sessions != null) {
            try {
                list = sessions.getActiveSessions(new ComponentName(this, NotificationForwarder.class));
            } catch (SecurityException e) {
                list = null;
            }
        }
        MediaController best = null;
        if (list != null) {
            for (MediaController c : list) {
                PlaybackState s = c.getPlaybackState();
                if (s != null && s.getState() == PlaybackState.STATE_PLAYING) { best = c; break; }
                if (best == null) best = c;
            }
        }
        if (controller != null && (best == null || !best.getSessionToken().equals(controller.getSessionToken())))
            controller.unregisterCallback(controllerCallback);
        if (best != null && (controller == null || !best.getSessionToken().equals(controller.getSessionToken())))
            best.registerCallback(controllerCallback, handler);
        controller = best;
        pushMedia();
    }

    private void pushMedia() {
        String title = "", artist = "", album = "";
        int playing = 0;
        if (controller != null) {
            MediaMetadata m = controller.getMetadata();
            if (m != null) {
                title = nz(m.getString(MediaMetadata.METADATA_KEY_TITLE));
                artist = nz(m.getString(MediaMetadata.METADATA_KEY_ARTIST));
                album = nz(m.getString(MediaMetadata.METADATA_KEY_ALBUM));
            }
            PlaybackState s = controller.getPlaybackState();
            playing = s != null && s.getState() == PlaybackState.STATE_PLAYING ? 1 : 0;
        }
        notifyUi();
        if (!ready || !prefs.music())
            return;
        if (!title.equals(sentTitle)) { write(Protocol.MEDIA, Protocol.MEDIA_TITLE, Protocol.utf8(title)); sentTitle = title; }
        if (!artist.equals(sentArtist)) { write(Protocol.MEDIA, Protocol.MEDIA_ARTIST, Protocol.utf8(artist)); sentArtist = artist; }
        if (!album.equals(sentAlbum)) { write(Protocol.MEDIA, Protocol.MEDIA_ALBUM, Protocol.utf8(album)); sentAlbum = album; }
        if (playing != sentPlaying) { write(Protocol.MEDIA, Protocol.MEDIA_PLAYING, new byte[] { (byte) playing }); sentPlaying = playing; }
    }

    private static String nz(String s) { return s == null ? "" : s; }

    private void onMediaCommand(byte[] v) {
        int cmd = v[0] & 0xff;
        log("watch media command " + cmd);
        if (cmd == Protocol.MEDIA_SET_VOLUME && v.length > 1) {
            AudioManager am = (AudioManager) getSystemService(AUDIO_SERVICE);
            int max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
            am.setStreamVolume(AudioManager.STREAM_MUSIC, Math.round((v[1] & 0xff) * max / 100f), 0);
            return;
        }
        if (controller == null)
            return;
        MediaController.TransportControls t = controller.getTransportControls();
        switch (cmd) {
        case Protocol.MEDIA_PREVIOUS: t.skipToPrevious(); break;
        case Protocol.MEDIA_NEXT: t.skipToNext(); break;
        case Protocol.MEDIA_PLAY: t.play(); break;
        case Protocol.MEDIA_PAUSE: t.pause(); break;
        }
    }

    // ---- state for the UI -------------------------------------------------------------------
    JSONObject state() {
        JSONObject s = new JSONObject();
        try {
            s.put("status", status.name().toLowerCase(Locale.US));
            s.put("address", prefs.address());
            s.put("name", prefs.deviceName());
            s.put("battery", battery);
            s.put("ready", ready);
            s.put("error", lastError);
            s.put("scanning", scanning);
            JSONArray found = new JSONArray();
            for (JSONObject o : scanResults.values())
                found.put(o);
            s.put("found", found);
            boolean bonded = false;
            if (!prefs.address().isEmpty() && adapter != null)
                bonded = adapter.getRemoteDevice(prefs.address()).getBondState() == BluetoothDevice.BOND_BONDED;
            s.put("bonded", bonded);
            s.put("weather", weather == null ? JSONObject.NULL : weather);
            JSONObject media = new JSONObject();
            if (controller != null) {
                MediaMetadata m = controller.getMetadata();
                PlaybackState ps = controller.getPlaybackState();
                media.put("title", m == null ? "" : nz(m.getString(MediaMetadata.METADATA_KEY_TITLE)));
                media.put("artist", m == null ? "" : nz(m.getString(MediaMetadata.METADATA_KEY_ARTIST)));
                media.put("app", controller.getPackageName());
                media.put("playing", ps != null && ps.getState() == PlaybackState.STATE_PLAYING);
            }
            s.put("media", media);
            JSONArray l = new JSONArray();
            synchronized (log) {
                for (int i = Math.max(0, log.size() - 30); i < log.size(); i++)
                    l.put(log.get(i));
            }
            s.put("log", l);
        } catch (Exception ignored) {
        }
        return s;
    }
}
