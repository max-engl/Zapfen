/**
 * Generates a deterministic color from username
 * Returns a hex color string that will always be the same for the same username
 * @param {string} username - The username to generate color for
 * @returns {string} Hex color string (e.g., "#FF5733")
 */
function generateAvatarColor(username) {
  // Use simple hash function for deterministic color generation
  let hash = 0;
  for (let i = 0; i < username.length; i++) {
    const char = username.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }

  // Convert hash to hex color (ensure it's in valid RGB range)
  const hue = Math.abs(hash % 360);
  const saturation = 70 + (Math.abs(hash) % 20); // 70-90%
  const lightness = 45 + (Math.abs(hash) % 15); // 45-60%

  // Convert HSL to RGB then to hex
  const rgb = hslToRgb(hue, saturation, lightness);
  return `#${rgb.map((x) => x.toString(16).padStart(2, "0").toUpperCase()).join("")}`;
}

/**
 * Converts HSL to RGB
 * @param {number} h - Hue (0-360)
 * @param {number} s - Saturation (0-100)
 * @param {number} l - Lightness (0-100)
 * @returns {number[]} RGB values as [r, g, b]
 */
function hslToRgb(h, s, l) {
  h = h / 360;
  s = s / 100;
  l = l / 100;

  let r, g, b;

  if (s === 0) {
    r = g = b = l;
  } else {
    const hue2rgb = (p, q, t) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    };

    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue2rgb(p, q, h + 1 / 3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1 / 3);
  }

  return [
    Math.round(r * 255),
    Math.round(g * 255),
    Math.round(b * 255),
  ];
}

/**
 * Gets the first letter of username in uppercase
 * @param {string} username - The username
 * @returns {string} First letter in uppercase
 */
function getAvatarInitial(username) {
  return (username && username.length > 0 ? username[0] : "U").toUpperCase();
}

module.exports = {
  generateAvatarColor,
  getAvatarInitial,
};
