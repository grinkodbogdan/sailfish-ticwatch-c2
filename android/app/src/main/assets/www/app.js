/*
 * Watch Link web UI. Talks to window.Native (the Android app's bridge);
 * state arrives through window.onNativeState(state).
 */
'use strict';

const N = window.Native;
const $ = (id) => document.getElementById(id);
let state = null;
let tab = 'watch';

// ---- helpers ------------------------------------------------------------------
const WMO = {
  0: ['☀️', 'Clear'], 1: ['🌤️', 'Mainly clear'], 2: ['⛅', 'Partly cloudy'], 3: ['☁️', 'Overcast'],
  45: ['🌫️', 'Fog'], 48: ['🌫️', 'Rime fog'],
  51: ['🌦️', 'Light drizzle'], 53: ['🌦️', 'Drizzle'], 55: ['🌧️', 'Heavy drizzle'],
  56: ['🌧️', 'Freezing drizzle'], 57: ['🌧️', 'Freezing drizzle'],
  61: ['🌦️', 'Light rain'], 63: ['🌧️', 'Rain'], 65: ['🌧️', 'Heavy rain'],
  66: ['🌧️', 'Freezing rain'], 67: ['🌧️', 'Freezing rain'],
  71: ['🌨️', 'Light snow'], 73: ['🌨️', 'Snow'], 75: ['❄️', 'Heavy snow'], 77: ['🌨️', 'Snow grains'],
  80: ['🌦️', 'Showers'], 81: ['🌧️', 'Showers'], 82: ['⛈️', 'Violent showers'],
  85: ['🌨️', 'Snow showers'], 86: ['❄️', 'Snow showers'],
  95: ['⛈️', 'Thunderstorm'], 96: ['⛈️', 'Thunderstorm, hail'], 99: ['⛈️', 'Thunderstorm, hail'],
};
const wmo = (c) => WMO[c] || ['🌡️', 'Weather'];

function temp(c) {
  if (c === undefined || c === null || isNaN(c)) return '--°';
  const f = state && state.settings && state.settings.fahrenheit;
  return Math.round(f ? c * 9 / 5 + 32 : c) + '°';
}

function el(tag, attrs, ...children) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (k === 'class') e.className = v;
    else if (k.startsWith('on')) e.addEventListener(k.slice(2), v);
    else e.setAttribute(k, v);
  }
  for (const c of children) if (c !== null && c !== undefined) e.append(c);
  return e;
}

function ago(ms) {
  const m = Math.round((Date.now() - ms) / 60000);
  if (m < 1) return 'just now';
  if (m < 60) return m + ' min ago';
  return Math.round(m / 60) + ' h ago';
}

// ---- actions ------------------------------------------------------------------
const actions = {
  permissions: () => N.requestPermissions(),
  scan: () => N.scan(),
  bluetoothSettings: () => N.openBluetoothSettings(),
  notificationAccess: () => N.openNotificationAccess(),
  batterySettings: () => N.openBatterySettings(),
  tethering: () => N.openTethering(),
  testNotification: () => N.testNotification(),
  syncTime: () => N.syncTime(),
  refreshWeather: () => N.refreshWeather(),
  repair: () => {
    if (confirm('Remove the pairing on this phone and pair again? Confirm the code on the watch when asked.')) N.repair();
  },
  forget: () => {
    if (confirm('Forget this watch? You can set it up again later.')) N.forget(true);
  },
};

document.addEventListener('click', (e) => {
  const b = e.target.closest('[data-action]');
  if (b && N) actions[b.dataset.action]();
  const t = e.target.closest('[data-tab]');
  if (t) showTab(t.dataset.tab);
});

document.addEventListener('change', (e) => {
  const s = e.target.dataset && e.target.dataset.setting;
  if (s && N) N.setSetting(s, String(e.target.checked));
});

function showTab(name) {
  tab = name;
  for (const b of document.querySelectorAll('.tabbar button')) b.classList.toggle('active', b.dataset.tab === name);
  for (const t of document.querySelectorAll('.tab')) t.hidden = t.id !== 'tab-' + name;
  window.scrollTo(0, 0);
}

// Weather location
$('wxMode').addEventListener('click', (e) => {
  const b = e.target.closest('button');
  if (!b) return;
  if (b.dataset.mode === 'gps') N.useGpsWeather();
  else { $('citySearch').hidden = false; $('cityInput').focus(); }
  for (const x of $('wxMode').children) x.classList.toggle('on', x === b);
});

let searchTimer = null;
$('cityInput').addEventListener('input', (e) => {
  clearTimeout(searchTimer);
  const q = e.target.value.trim();
  if (q.length < 2) { $('cityResults').replaceChildren(); return; }
  searchTimer = setTimeout(() => N.searchCity(q), 350);
});

window.onCityResults = (results) => {
  $('cityResults').replaceChildren(...results.map((r) => el('li', { class: 'found', onclick: () => {
    N.setCity(r.name, r.lat, r.lon);
    $('cityInput').value = '';
    $('cityResults').replaceChildren();
    $('citySearch').hidden = true;
  } }, el('div', {}, el('b', {}, r.name), el('span', {}, r.detail)))));
  if (!results.length) $('cityResults').replaceChildren(el('li', {}, el('div', {}, el('span', {}, 'No places found'))));
};

$('vibration').addEventListener('click', (e) => {
  const b = e.target.closest('button');
  if (b) N.setSetting('vibration', b.dataset.vib);
});

// ---- rendering ----------------------------------------------------------------
const STATUS = {
  no_watch: ['No watch set up', ''],
  bluetooth_off: ['Bluetooth is off on this phone', 'bad'],
  connecting: ['Connecting…', 'busy'],
  pairing: ['Pairing — check the watch', 'busy'],
  connected: ['Connected', 'ok'],
  disconnected: ['Waiting for the watch…', 'busy'],
};

function render(s) {
  state = s;
  const perms = s.permissions || {};
  const settings = s.settings || {};
  const hasWatch = !!s.address;

  // hero
  const now = new Date();
  $('faceTime').textContent = now.toTimeString().slice(0, 5);
  const bat = s.battery >= 0 ? s.battery : null;
  $('faceBattery').textContent = bat !== null ? bat + '%' : '';
  $('batteryRing').style.strokeDashoffset = String(339.3 * (1 - (bat || 0) / 100));
  $('batteryRing').style.stroke = bat !== null && bat <= 15 ? 'var(--bad)' : 'var(--accent)';
  $('watchName').textContent = s.name || 'Watch Link';
  const [text, cls] = STATUS[s.status] || ['…', ''];
  $('statusText').textContent = text + (s.status === 'connected' && bat !== null ? ' · ' + bat + '% battery' : '');
  $('statusLine').className = 'status ' + cls;
  $('errorLine').hidden = !s.error;
  $('errorLine').textContent = s.error || '';

  // setup vs tabs
  $('setup').hidden = hasWatch;
  $('tabs').hidden = !hasWatch;
  $('tabbar').hidden = !hasWatch;
  $('stepPerm').classList.toggle('done', !!perms.bluetooth);
  $('scanBtn').textContent = s.scanning ? 'Searching…' : 'Search';
  $('scanBtn').disabled = !!s.scanning;
  const found = s.found || [];
  $('foundList').replaceChildren(...found.map((d) => el('li', { class: 'found', onclick: () => N.choose(d.address, d.name) },
    el('div', {}, el('b', {}, d.name), el('span', {}, d.address + (d.bonded ? ' · paired' : ''))),
    el('button', { class: 'btn small' }, 'Connect'))));
  $('scanHint').hidden = !(found.length === 0 && s.scanning === false && window._scanned);
  if (s.scanning) window._scanned = true;

  // watch tab
  $('pairingPanel').hidden = s.status !== 'pairing';
  $('chkListener').classList.toggle('done', !!perms.listener);
  $('chkBattery').classList.toggle('done', !!perms.battery);
  $('chkPerm').classList.toggle('done', !!perms.bluetooth && !!perms.location);
  $('checklist').hidden = perms.listener && perms.battery && perms.bluetooth && perms.location;
  const m = s.media || {};
  $('mediaTitle').textContent = m.title || 'Nothing playing';
  $('mediaArtist').textContent = m.title ? (m.artist || '') + (m.playing ? '' : ' · paused') : (perms.listener ? '' : 'Needs notification access');

  // weather tab
  const w = s.weather;
  if (w && w.current) {
    const [icon, label] = wmo(w.current.code);
    $('wxIcon').textContent = icon;
    $('wxTemp').textContent = temp(w.current.temp);
    $('wxCity').textContent = (w.city || 'Current location');
    $('wxMeta').textContent = `${label} · feels ${temp(w.current.feels)} · wind ${Math.round(w.current.wind)} km/h · ${w.current.humidity}% humidity`;
    const days = w.days || [];
    $('wxDays').replaceChildren(...days.map((d, i) => {
      const date = new Date(d.date + 'T12:00');
      const name = i === 0 ? 'Today' : date.toLocaleDateString(undefined, { weekday: 'short' });
      return el('li', {}, el('span', {}, name), el('span', { class: 'd-icon' }, wmo(d.code)[0]),
        el('span', { class: 'd-rain' }, d.rain ? '💧 ' + d.rain + '%' : ''),
        el('span', { class: 'd-temps' }, temp(d.max), el('span', {}, temp(d.min))));
    }));
    $('wxUpdated').textContent = 'Updated ' + ago(w.updated);
  }
  const mode = settings.weatherMode || 'gps';
  for (const b of $('wxMode').children) b.classList.toggle('on', b.dataset.mode === mode);
  if (mode === 'city' && settings.cityName) $('wxMode').children[1].textContent = settings.cityName;
  else $('wxMode').children[1].textContent = 'City';

  // alerts tab
  for (const b of $('vibration').children) b.classList.toggle('on', b.dataset.vib === settings.vibration);
  const apps = s.apps || [];
  $('appsHint').hidden = apps.length > 0;
  $('appList').replaceChildren(...apps.map((a) => {
    const box = el('input', { type: 'checkbox' });
    box.checked = !a.muted;
    box.addEventListener('change', () => N.setMuted(a.pkg, !box.checked));
    return el('li', {}, el('div', {}, el('b', {}, a.name), el('span', {}, a.pkg)), box);
  }));

  // settings switches
  for (const box of document.querySelectorAll('[data-setting]')) {
    const v = settings[box.dataset.setting];
    if (typeof v === 'boolean') box.checked = v;
  }

  // more tab
  $('infoName').textContent = s.name || '—';
  $('infoAddress').textContent = s.address || '—';
  $('infoBonded').textContent = s.bonded ? 'Yes' : 'No';
  $('log').textContent = (s.log || []).slice().reverse().join('\n');
}

window.onNativeState = render;

// ---- start ----------------------------------------------------------------------
if (N) {
  render(JSON.parse(N.getState()));
  setInterval(() => render(JSON.parse(N.getState())), 15000);   // clock, "updated … ago"
} else {
  $('browserNote').hidden = false;
  $('setup').hidden = true;
  $('statusText').textContent = 'Open in the Watch Link app';
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(() => {});
}
