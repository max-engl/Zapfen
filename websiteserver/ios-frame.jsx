// iOS device shell — wraps app content in a phone mockup frame
function IOSDevice({ width = 402, height = 874, dark = true, children }) {
  const BORDER = 14;
  const RADIUS = 52;

  const shellColor    = dark ? "#1c1c1e" : "#e8e8ed";
  const buttonColor   = dark ? "#2a2a2c" : "#d0d0d8";
  const statusColor   = dark ? "#fff"    : "#000";
  const statusOpacity = dark ? 1         : 0.85;

  return (
    <div style={{
      width, height, position: "relative", flexShrink: 0,
      borderRadius: RADIUS,
      background: shellColor,
      boxShadow: dark
        ? "0 0 0 1px rgba(255,255,255,0.08), 0 32px 90px rgba(0,0,0,0.7), inset 0 0 0 1px rgba(255,255,255,0.04)"
        : "0 0 0 1px rgba(0,0,0,0.14), 0 32px 90px rgba(0,0,0,0.28), inset 0 0 0 1px rgba(0,0,0,0.06)",
    }}>

      {/* ── Screen ── */}
      <div style={{
        position: "absolute",
        top: BORDER, left: BORDER, right: BORDER, bottom: BORDER,
        borderRadius: RADIUS - BORDER,
        overflow: "hidden",
        background: dark ? "#000" : "#fff",
        isolation: "isolate",
      }}>
        {children}

        {/* Status bar */}
        <div style={{
          position: "absolute", top: 0, left: 0, right: 0, height: 54,
          display: "flex", alignItems: "flex-start",
          justifyContent: "space-between",
          padding: "14px 24px 0",
          pointerEvents: "none", zIndex: 999,
          color: statusColor, opacity: statusOpacity,
        }}>
          <span style={{ fontSize: 15, fontWeight: 600, letterSpacing: "-0.01em" }}>9:41</span>

          {/* Dynamic Island */}
          <div style={{
            position: "absolute", top: 13, left: "50%",
            transform: "translateX(-50%)",
            width: 120, height: 34,
            background: "#000", borderRadius: 22,
          }} />

          {/* Right icons */}
          <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
            {/* Signal */}
            <svg width="17" height="12" viewBox="0 0 17 12">
              <rect x="0"    y="7" width="3" height="5" rx="1" fill={statusColor}/>
              <rect x="4.7"  y="4.5" width="3" height="7.5" rx="1" fill={statusColor}/>
              <rect x="9.4"  y="2" width="3" height="10" rx="1" fill={statusColor}/>
              <rect x="14.1" y="0" width="3" height="12" rx="1" fill={statusColor} opacity="0.28"/>
            </svg>
            {/* Wi-Fi */}
            <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
              <circle cx="8" cy="10.5" r="1.5" fill={statusColor}/>
              <path d="M5 7.5C6.1 6.4 7 6 8 6s1.9.4 3 1.5" stroke={statusColor} strokeWidth="1.5" strokeLinecap="round"/>
              <path d="M2.5 5C4.4 3 6.2 2 8 2s3.6 1 5.5 3" stroke={statusColor} strokeWidth="1.5" strokeLinecap="round" opacity="0.55"/>
            </svg>
            {/* Battery */}
            <div style={{ position: "relative", width: 26, height: 13, display: "flex", alignItems: "center" }}>
              <div style={{ flex: 1, height: 13, border: `1.5px solid ${dark ? "rgba(255,255,255,0.5)" : "rgba(0,0,0,0.5)"}`, borderRadius: 3.5, position: "relative", overflow: "hidden" }}>
                <div style={{ position: "absolute", inset: "1.5px 1.5px 1.5px 1.5px", background: statusColor, borderRadius: 1.5 }} />
              </div>
              <div style={{ width: 2.5, height: 5, background: dark ? "rgba(255,255,255,0.4)" : "rgba(0,0,0,0.35)", borderRadius: "0 1.5px 1.5px 0", marginLeft: 1 }} />
            </div>
          </div>
        </div>

        {/* Home indicator */}
        <div style={{
          position: "absolute", bottom: 9, left: "50%",
          transform: "translateX(-50%)",
          width: 134, height: 5,
          background: dark ? "rgba(255,255,255,0.28)" : "rgba(0,0,0,0.18)",
          borderRadius: 3,
          pointerEvents: "none", zIndex: 999,
        }} />
      </div>

      {/* ── Side buttons ── */}
      {/* Mute */}
      <div style={{ position: "absolute", left: -4, top: 84,  width: 4, height: 28, background: buttonColor, borderRadius: "2px 0 0 2px" }} />
      {/* Volume + */}
      <div style={{ position: "absolute", left: -4, top: 124, width: 4, height: 34, background: buttonColor, borderRadius: "2px 0 0 2px" }} />
      {/* Volume - */}
      <div style={{ position: "absolute", left: -4, top: 168, width: 4, height: 34, background: buttonColor, borderRadius: "2px 0 0 2px" }} />
      {/* Power */}
      <div style={{ position: "absolute", right: -4, top: 150, width: 4, height: 62, background: buttonColor, borderRadius: "0 2px 2px 0" }} />
    </div>
  );
}

Object.assign(window, { IOSDevice });
