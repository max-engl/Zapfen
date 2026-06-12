// UTC offset in minutes from X-Tz-Offset request header; defaults to 0 (UTC).
function getTzOffset(req) {
  const n = parseInt(req.headers['x-tz-offset'], 10);
  return (Number.isFinite(n) && n >= -720 && n <= 840) ? n : 0;
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

module.exports = { getTzOffset, localDayStart, localDayKey, localHour, localDow, localDayOf };
