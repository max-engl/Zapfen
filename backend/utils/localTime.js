// Returns the UTC offset in minutes for Europe/Berlin at the given date, accounting for DST.
// e.g. CEST (summer) → 120, CET (winter) → 60
function getBerlinOffsetMinutes(date = new Date()) {
  const d = new Date(date);
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Berlin',
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hour12: false,
  }).formatToParts(d).reduce((acc, p) => { acc[p.type] = p.value; return acc; }, {});
  const berlinAsUtc = new Date(`${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}Z`);
  return Math.round((berlinAsUtc - d) / 60000);
}

// UTC Date representing the start of the user's local calendar day (local midnight).
function localDayStart(utcDate, offsetMinutes) {
  const shifted = new Date(utcDate.getTime() + offsetMinutes * 60 * 1000);
  return new Date(
    Date.UTC(shifted.getUTCFullYear(), shifted.getUTCMonth(), shifted.getUTCDate())
    - offsetMinutes * 60 * 1000,
  );
}

// YYYY-MM-DD string in the user's local timezone, for grouping posts by day.
function localDayKey(utcDate, offsetMinutes) {
  const s = new Date(utcDate.getTime() + offsetMinutes * 60 * 1000);
  return `${s.getUTCFullYear()}-${String(s.getUTCMonth() + 1).padStart(2, '0')}-${String(s.getUTCDate()).padStart(2, '0')}`;
}

// User's local hour (0–23) for a UTC timestamp.
function localHour(utcDate, offsetMinutes) {
  return new Date(utcDate.getTime() + offsetMinutes * 60 * 1000).getUTCHours();
}

// User's local day-of-week (0 = Sun … 6 = Sat) for a UTC timestamp.
function localDow(utcDate, offsetMinutes) {
  return new Date(utcDate.getTime() + offsetMinutes * 60 * 1000).getUTCDay();
}

// Local UTC-noon representation used for timeline slot comparisons (strips time part).
function localDayOf(utcDate, offsetMinutes) {
  const s = new Date(utcDate.getTime() + offsetMinutes * 60 * 1000);
  return new Date(Date.UTC(s.getUTCFullYear(), s.getUTCMonth(), s.getUTCDate()));
}

// Format a UTC date as a naive ISO-8601 string in the Europe/Berlin timezone (no Z suffix).
// Dart/Flutter parses strings without a timezone suffix as local device time, so this
// ensures the displayed time matches German local time regardless of DST.
function toGermanLocalIso(date) {
  const d = new Date(date);
  const parts = new Intl.DateTimeFormat('en', {
    timeZone: 'Europe/Berlin',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    fractionalSecondDigits: 3,
    hour12: false,
  }).formatToParts(d);
  const p = {};
  for (const { type, value } of parts) p[type] = value;
  return `${p.year}-${p.month}-${p.day}T${p.hour}:${p.minute}:${p.second}.${p.fractionalSecond}`;
}

module.exports = { getBerlinOffsetMinutes, localDayStart, localDayKey, localHour, localDow, localDayOf, toGermanLocalIso };
