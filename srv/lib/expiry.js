const DAY = 24 * 60 * 60 * 1000; // milliseconds in one day

// '2026-03-15' -> milliseconds since 1970, at midnight UTC
function toUtc(dateStr) {
  const [y, m, d] = dateStr.split('-').map(Number);
  return Date.UTC(y, m - 1, d); // months are 0-based in JS: January = 0
}

// Today's date in local time, as 'YYYY-MM-DD'
function today() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

// '2026-03-15' -> '2027-03-15'; 29 Feb -> 28 Feb of the next year
function addOneYear(dateStr) {
  const [y, m, d] = dateStr.split('-').map(Number);
  const next = new Date(Date.UTC(y + 1, m - 1, d));
  if (next.getUTCMonth() !== m - 1) next.setUTCDate(0); // rolled into March -> back to last day of Feb
  return next.toISOString().slice(0, 10);
}

// Days from todayStr until dateStr (negative = already expired)
function daysUntil(dateStr, todayStr) {
  return Math.round((toUtc(dateStr) - toUtc(todayStr)) / DAY);
}

// Fiori criticality: 3 green, 0 neutral, 2 orange, 1 red
function criticality(days) {
  if (days > 90) return 3; // more than 90 days left
  if (days > 45) return 0; // 46-90
  if (days > 15) return 2; // 16-45
  return 1;                // 15 or fewer, or expired
}

module.exports = { today, addOneYear, daysUntil, criticality };
