// Pint. — A daily beer-moment social app
// Brand: golden monogram "B" on black, warm gold accents.
// Supports light + dark themes via T tokens.

const { useState, useEffect, useRef, useContext, createContext } = React;

// ───────────────────────────────────────────
// Theme tokens
// ───────────────────────────────────────────
const THEMES = {
  dark: {
    name: "dark",
    bg: "#0a0a0a",
    surface: "#141414",
    surfaceWeak: "rgba(255,255,255,0.06)",
    surfaceWeaker: "rgba(255,255,255,0.04)",
    text: "#fff",
    textMuted: "rgba(255,255,255,0.55)",
    textFaint: "rgba(255,255,255,0.4)",
    border: "rgba(255,255,255,0.08)",
    borderWeak: "rgba(255,255,255,0.04)",
    divider: "rgba(255,255,255,0.04)",
    iosDark: true,

    gold: "#F6B733",
    goldInk: "#3a1f02",
    goldText: "#F6B733",      // gold color for text on the bg
    goldFaint: "rgba(246,183,51,0.08)",
    goldSoft: "rgba(246,183,51,0.15)",
    goldStrong: "rgba(246,183,51,0.25)",
    goldBorder: "rgba(246,183,51,0.3)",
    goldBorderStrong: "rgba(246,183,51,0.4)",

    chipBg: "rgba(0,0,0,0.7)",
    chipBorder: "rgba(255,255,255,0.12)",
    pinBg: "rgba(0,0,0,0.85)",
    selfieBorder: "#000",
    selfieOutline: "rgba(255,255,255,0.18)",
    onlineDotRing: "#0a0a0a",
    streakCell: [
      "rgba(255,255,255,0.04)",
      "rgba(246,183,51,0.25)",
      "rgba(246,183,51,0.55)",
      "rgba(246,183,51,0.95)",
    ],
    captureBg: "#000",
    captureText: "#fff",
    brandBoxBg: "#000",
  },
  light: {
    name: "light",
    bg: "#f6f2ea",
    surface: "#ffffff",
    surfaceWeak: "rgba(0,0,0,0.04)",
    surfaceWeaker: "rgba(0,0,0,0.025)",
    text: "#0a0a0a",
    textMuted: "rgba(0,0,0,0.55)",
    textFaint: "rgba(0,0,0,0.4)",
    border: "rgba(0,0,0,0.09)",
    borderWeak: "rgba(0,0,0,0.06)",
    divider: "rgba(0,0,0,0.05)",
    iosDark: false,

    gold: "#F6B733",
    goldInk: "#3a1f02",
    goldText: "#9C6610",       // readable gold for text on light bg
    goldFaint: "rgba(246,183,51,0.12)",
    goldSoft: "rgba(246,183,51,0.2)",
    goldStrong: "rgba(246,183,51,0.28)",
    goldBorder: "rgba(217,138,20,0.5)",
    goldBorderStrong: "rgba(217,138,20,0.7)",

    chipBg: "rgba(0,0,0,0.7)",   // photo overlay chip stays dark
    chipBorder: "rgba(255,255,255,0.18)",
    pinBg: "#0a0a0a",
    selfieBorder: "#fff",
    selfieOutline: "rgba(0,0,0,0.18)",
    onlineDotRing: "#f6f2ea",
    streakCell: [
      "rgba(0,0,0,0.05)",
      "rgba(246,183,51,0.3)",
      "rgba(246,183,51,0.6)",
      "rgba(217,138,20,0.95)",
    ],
    captureBg: "#000",         // capture screen stays dark (camera UI convention)
    captureText: "#fff",
    brandBoxBg: "#000",
  },
};

const ThemeContext = createContext(THEMES.dark);
const useT = () => useContext(ThemeContext);

// ───────────────────────────────────────────
// Brand mark (the golden B with foam dots) — same on both themes
// ───────────────────────────────────────────
function BrandMark({ size = 28 }) {
  const f = size / 32;
  return (
    <div style={{
      width: size, height: size, position: "relative",
      display: "inline-block",
    }}>
      <div style={{
        position: "absolute", inset: 0,
        background: "#000",
        borderRadius: size * 0.2237,
        overflow: "hidden",
      }}>
        <div style={{
          position: "absolute", inset: 0,
          display: "flex", alignItems: "center", justifyContent: "center",
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          fontWeight: 900,
          fontSize: size * 0.95,
          lineHeight: 0.82,
          letterSpacing: "-0.06em",
          background: "linear-gradient(180deg, #ffe89a 0%, #f6b733 30%, #d98a14 65%, #7a3f06 100%)",
          WebkitBackgroundClip: "text",
          backgroundClip: "text",
          color: "transparent",
          paddingBottom: size * 0.02,
        }}>B</div>
        <span style={{ position: "absolute", left: "38%", top: "10%", width: 3.5*f, height: 3.5*f, borderRadius: "50%", background: "#fff" }} />
        <span style={{ position: "absolute", left: "55%", top: "6%",  width: 2.4*f, height: 2.4*f, borderRadius: "50%", background: "#fff" }} />
        <span style={{ position: "absolute", left: "66%", top: "14%", width: 1.8*f, height: 1.8*f, borderRadius: "50%", background: "#f0ebde" }} />
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Placeholder image — visual content, stays the same across themes
// ───────────────────────────────────────────
function ImgPH({ tone = "beer", label = "drink photo", style = {} }) {
  const tones = {
    beer:    "repeating-linear-gradient(135deg, #c98014 0 10px, #b87509 10px 20px), linear-gradient(180deg, #ffd97a, #6a3a05)",
    night:   "repeating-linear-gradient(135deg, #1a1a22 0 10px, #15151c 10px 20px)",
    bar:     "repeating-linear-gradient(135deg, #3a2410 0 10px, #2e1d0a 10px 20px)",
    sky:     "repeating-linear-gradient(135deg, #5a4a2a 0 10px, #4a3a1a 10px 20px)",
    selfie:  "repeating-linear-gradient(135deg, #4a3a2a 0 8px, #3a2a1a 8px 16px)",
    avatar:  "repeating-linear-gradient(135deg, #6a4a2a 0 6px, #5a3a1a 6px 12px)",
    map:     "repeating-linear-gradient(135deg, #1a1810 0 12px, #14120b 12px 24px)",
    mapLight:"repeating-linear-gradient(135deg, #ece5d6 0 12px, #e2dac8 12px 24px)",
    pour:    "linear-gradient(180deg, #f6b733 0%, #b87509 60%, #2a1502 100%)",
  };
  return (
    <div style={{
      background: tones[tone] || tones.beer,
      position: "relative",
      overflow: "hidden",
      ...style,
    }}>
      <div style={{
        position: "absolute", inset: 0,
        display: "flex", alignItems: "center", justifyContent: "center",
        fontFamily: "ui-monospace, Menlo, monospace",
        fontSize: 10,
        color: "rgba(255,255,255,0.45)",
        textTransform: "uppercase",
        letterSpacing: "0.08em",
        textAlign: "center",
        padding: 8,
      }}>{label}</div>
    </div>
  );
}

// ───────────────────────────────────────────
// Icons (single-color glyphs, stroke-style)
// ───────────────────────────────────────────
const Ico = {
  feed: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="4" width="16" height="16" rx="3"/><path d="M4 10h16"/>
    </svg>
  ),
  map: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 3 3 5v16l6-2 6 2 6-2V3l-6 2z"/><path d="M9 3v16"/><path d="M15 5v16"/>
    </svg>
  ),
  cam: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 7h3l2-2h4l2 2h3a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z"/><circle cx="12" cy="13" r="4"/>
    </svg>
  ),
  friends: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="9" cy="8" r="3.5"/><circle cx="17" cy="9" r="2.5"/><path d="M3 20c0-3 3-5 6-5s6 2 6 5"/><path d="M15 20c0-2.5 2-4 4-4"/>
    </svg>
  ),
  user: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.5 4-7 8-7s8 2.5 8 7"/>
    </svg>
  ),
  cheers: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 4h6l-1 12a2 2 0 0 1-2 2 2 2 0 0 1-2-2L5 4z"/>
      <path d="M13 4h6l-1 12a2 2 0 0 1-2 2 2 2 0 0 1-2-2L13 4z"/>
      <path d="M11 8h2"/><path d="M3 21h18"/>
    </svg>
  ),
  comment: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 12a8 8 0 0 1-12.1 6.9L4 20l1.1-4.9A8 8 0 1 1 21 12z"/>
    </svg>
  ),
  pin: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s7-6.5 7-12a7 7 0 1 0-14 0c0 5.5 7 12 7 12z"/><circle cx="12" cy="10" r="2.5"/>
    </svg>
  ),
  swap: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 7h14l-3-3"/><path d="M21 17H7l3 3"/>
    </svg>
  ),
  flash: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M13 2 4 14h7l-1 8 9-12h-7z"/>
    </svg>
  ),
  x: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 6 18 18M18 6 6 18"/>
    </svg>
  ),
  bolt: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M13 2 4 14h7l-1 8 9-12h-7z"/>
    </svg>
  ),
  dots: (s = 20, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/>
    </svg>
  ),
  bell: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 8a6 6 0 1 1 12 0c0 7 3 8 3 8H3s3-1 3-8z"/><path d="M10 21a2 2 0 0 0 4 0"/>
    </svg>
  ),
};

// ───────────────────────────────────────────
// Sample data
// ───────────────────────────────────────────
const FRIENDS_FEED = [
  {
    id: "p1", name: "Maya Calderón", handle: "@mayac", time: "12m",
    place: "The Goose & Crown · SE15", drink: "Hazy Pale · 5.2%",
    caption: "first one after the marathon. earned.",
    cheers: 24, comments: 6, mine: false,
    tone: "beer", selfieTone: "selfie", late: false,
  },
  {
    id: "p2", name: "Theo Park", handle: "@theop", time: "31m",
    place: "Allagash Taproom · Portland", drink: "Triple Belgian · 9.5%",
    caption: "research purposes.",
    cheers: 41, comments: 12, mine: false,
    tone: "bar", selfieTone: "selfie", late: false,
  },
  {
    id: "p3", name: "Priya Anand", handle: "@priyaa", time: "1h 02m",
    place: "Home · Brooklyn", drink: "Pilsner Urquell",
    caption: "tuesday. you know how it is.",
    cheers: 18, comments: 3, mine: false,
    tone: "sky", selfieTone: "selfie", late: true,
  },
  {
    id: "p4", name: "Jonas Lindqvist", handle: "@jlind", time: "1h 47m",
    place: "Mikkeller · Reykjavík", drink: "Imperial Stout · 11%",
    caption: "the menu has 87 entries. i have all night.",
    cheers: 67, comments: 21, mine: false,
    tone: "night", selfieTone: "selfie", late: true,
  },
];

const FRIENDS_LIST = [
  { name: "Maya Calderón", status: "Poured · 12m ago", on: true,  tone: "avatar" },
  { name: "Theo Park",      status: "Poured · 31m ago", on: true,  tone: "selfie" },
  { name: "Priya Anand",    status: "Poured · 1h ago",  on: false, tone: "avatar" },
  { name: "Jonas Lindqvist", status: "Poured · 1h ago",  on: true,  tone: "selfie" },
  { name: "Sam Okafor",     status: "Waiting for prompt", on: true, tone: "avatar" },
  { name: "Hana Tsuji",     status: "Waiting for prompt", on: false, tone: "selfie" },
  { name: "Rafael Costa",   status: "Last poured · yesterday", on: false, tone: "avatar" },
  { name: "Lena Bauer",     status: "Last poured · 2d ago", on: true, tone: "selfie" },
];

const MAP_PINS = [
  { x: 24, y: 32, label: "Maya", drink: "Hazy Pale" },
  { x: 62, y: 28, label: "Theo", drink: "Triple" },
  { x: 78, y: 58, label: "Priya", drink: "Pilsner" },
  { x: 35, y: 62, label: "Jonas", drink: "Stout" },
  { x: 52, y: 75, label: "you",   drink: "—", you: true },
];

const STREAK_GRID = (() => {
  const out = [];
  for (let i = 0; i < 84; i++) {
    const r = (i * 37 + 13) % 100;
    let v = 0;
    if (r > 70) v = 3;
    else if (r > 50) v = 2;
    else if (r > 30) v = 1;
    if (i >= 78 && r > 40) v = Math.max(v, 2);
    if (i === 83) v = 0;
    out.push(v);
  }
  return out;
})();

// ───────────────────────────────────────────
// Shared atoms
// ───────────────────────────────────────────
function Avatar({ tone = "avatar", size = 40, ring = false }) {
  const T = useT();
  return (
    <div style={{
      width: size, height: size, borderRadius: "50%",
      overflow: "hidden", flexShrink: 0,
      boxShadow: ring ? `0 0 0 2px ${T.gold}` : "none",
    }}>
      <ImgPH tone={tone} label="" style={{ width: "100%", height: "100%" }} />
    </div>
  );
}

function GoldPill({ children, style = {} }) {
  const T = useT();
  return (
    <div style={{
      display: "inline-flex", alignItems: "center", gap: 6,
      padding: "6px 12px",
      borderRadius: 999,
      background: T.gold,
      color: T.goldInk,
      fontWeight: 700,
      fontSize: 13,
      letterSpacing: "-0.01em",
      ...style,
    }}>{children}</div>
  );
}

// ───────────────────────────────────────────
// Top bar
// ───────────────────────────────────────────
function TopBar({ streak, onBell }) {
  const T = useT();
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "8px 18px 14px",
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <BrandMark size={30} />
        <div style={{
          fontWeight: 800, fontSize: 22, letterSpacing: "-0.03em", color: T.text,
        }}>Pint<span style={{ color: T.goldText }}>.</span></div>
      </div>
      <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
        <GoldPill style={{ padding: "5px 10px", fontSize: 12 }}>
          <span style={{ display: "inline-flex" }}>{Ico.bolt(11, T.goldInk)}</span>
          {streak}-day streak
        </GoldPill>
        <button onClick={onBell} style={{
          width: 36, height: 36, borderRadius: "50%",
          background: T.surfaceWeak,
          border: `1px solid ${T.border}`,
          color: T.text, display: "grid", placeItems: "center",
          cursor: "pointer",
        }}>{Ico.bell(18)}</button>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Prompt banner
// ───────────────────────────────────────────
function PromptBanner({ minsLeft, onCapture, posted }) {
  const T = useT();
  if (posted) {
    return (
      <div style={{
        margin: "0 16px 14px", borderRadius: 18, padding: "14px 16px",
        background: T.goldFaint,
        border: `1px solid ${T.goldBorder}`,
        display: "flex", alignItems: "center", gap: 12,
      }}>
        <div style={{
          width: 36, height: 36, borderRadius: 12,
          background: T.goldSoft,
          display: "grid", placeItems: "center", color: T.goldText,
        }}>{Ico.cheers(18, T.goldText)}</div>
        <div style={{ flex: 1 }}>
          <div style={{ color: T.text, fontWeight: 600, fontSize: 14 }}>You poured today.</div>
          <div style={{ color: T.textMuted, fontSize: 12, marginTop: 2 }}>
            Next prompt drops tomorrow, random time.
          </div>
        </div>
      </div>
    );
  }
  return (
    <div style={{
      margin: "0 16px 14px",
      borderRadius: 18,
      padding: "16px 16px 16px 18px",
      background: T.goldFaint,
      border: `1px solid ${T.goldBorder}`,
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
        <div style={{ flex: 1 }}>
          <div style={{
            color: T.goldText, fontSize: 11, fontWeight: 700,
            letterSpacing: "0.14em", textTransform: "uppercase",
            display: "flex", alignItems: "center", gap: 6,
          }}>
            {Ico.bolt(10, T.goldText)} Time to pour
          </div>
          <div style={{
            color: T.text, fontWeight: 700, fontSize: 19,
            letterSpacing: "-0.02em", marginTop: 4,
          }}>Show your friends what's<br/>in your glass.</div>
          <div style={{ color: T.textMuted, fontSize: 12, marginTop: 6 }}>
            {minsLeft}m left · post late and it'll show.
          </div>
        </div>
        <button onClick={onCapture} style={{
          width: 60, height: 60, borderRadius: "50%",
          background: T.gold,
          border: "none",
          display: "grid", placeItems: "center",
          cursor: "pointer", color: T.goldInk,
        }}>{Ico.cam(26, T.goldInk)}</button>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Feed Post
// ───────────────────────────────────────────
function Post({ p, onCheers, cheered, onOpen }) {
  const T = useT();
  return (
    <div style={{ margin: "0 16px 20px" }}>
      <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 10 }}>
        <Avatar tone={p.selfieTone} size={36} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ color: T.text, fontSize: 14, fontWeight: 600, letterSpacing: "-0.01em" }}>
            {p.name}
          </div>
          <div style={{
            color: T.textMuted, fontSize: 12, marginTop: 1,
            display: "flex", alignItems: "center", gap: 6,
            whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
          }}>
            {p.place} · {p.time}
            {p.late && <span style={{
              color: "#c2511e", fontSize: 10, fontWeight: 700,
              padding: "1px 6px", borderRadius: 4,
              background: "rgba(194,81,30,0.12)", letterSpacing: "0.04em",
            }}>LATE</span>}
          </div>
        </div>
        <button style={{
          background: "transparent", border: "none", color: T.textMuted,
          cursor: "pointer", padding: 4,
        }}>{Ico.dots(20)}</button>
      </div>

      <div onClick={() => onOpen && onOpen(p)} style={{
        position: "relative",
        borderRadius: 22,
        overflow: "hidden",
        aspectRatio: "3 / 4",
        background: "#000",
        cursor: "pointer",
      }}>
        <ImgPH tone={p.tone} label={p.drink} style={{ position: "absolute", inset: 0 }} />
        <div style={{
          position: "absolute", top: 12, left: 12,
          width: 96, height: 128, borderRadius: 14,
          overflow: "hidden",
          border: `2px solid ${T.selfieBorder}`,
          outline: `1px solid ${T.selfieOutline}`,
        }}>
          <ImgPH tone={p.selfieTone} label="selfie" style={{ width: "100%", height: "100%" }} />
        </div>
        <div style={{
          position: "absolute", left: 12, bottom: 12,
          display: "inline-flex", alignItems: "center", gap: 6,
          padding: "6px 10px", borderRadius: 999,
          background: T.chipBg,
          color: "#fff", fontSize: 11, fontWeight: 600,
          letterSpacing: "-0.01em",
          border: `1px solid ${T.chipBorder}`,
        }}>
          {Ico.cheers(12, T.gold)} {p.drink}
        </div>
      </div>

      {p.caption && (
        <div style={{
          color: T.text, fontSize: 14,
          lineHeight: 1.35, marginTop: 12, letterSpacing: "-0.01em",
          opacity: 0.9,
        }}>
          <span style={{ fontWeight: 600 }}>{p.handle}</span>{" "}{p.caption}
        </div>
      )}

      <div style={{
        display: "flex", alignItems: "center", gap: 10, marginTop: 12,
      }}>
        <button onClick={() => onCheers(p.id)} style={{
          display: "inline-flex", alignItems: "center", gap: 6,
          padding: "8px 14px", borderRadius: 999,
          background: cheered ? T.goldSoft : T.surfaceWeak,
          border: `1px solid ${cheered ? T.goldBorderStrong : T.border}`,
          color: cheered ? T.goldText : T.text,
          fontSize: 13, fontWeight: 600,
          cursor: "pointer",
          transition: "all 0.2s",
        }}>
          {Ico.cheers(14, cheered ? T.goldText : T.text)} {p.cheers + (cheered ? 1 : 0)}
        </button>
        <button style={{
          display: "inline-flex", alignItems: "center", gap: 6,
          padding: "8px 14px", borderRadius: 999,
          background: T.surfaceWeak,
          border: `1px solid ${T.border}`,
          color: T.text, fontSize: 13, fontWeight: 600,
          cursor: "pointer",
        }}>
          {Ico.comment(14)} {p.comments}
        </button>
        <div style={{ flex: 1 }} />
        <div style={{
          fontSize: 11, color: T.textFaint,
          display: "inline-flex", alignItems: "center", gap: 4,
        }}>
          {Ico.pin(12, T.textFaint)} {p.place.split(" · ")[1]}
        </div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Feed Screen
// ───────────────────────────────────────────
function FeedScreen({ minsLeft, posted, onCapture, cheersSet, toggleCheer, myPost, onOpenPost }) {
  const T = useT();
  return (
    <div style={{ paddingBottom: 100 }}>
      {posted && myPost && (
        <Post p={myPost} onCheers={() => {}} cheered={false} onOpen={onOpenPost} />
      )}
      <PromptBanner minsLeft={minsLeft} onCapture={onCapture} posted={posted} />
      <div style={{
        display: "flex", alignItems: "center", gap: 8,
        padding: "0 18px 12px",
      }}>
        <div style={{
          color: T.textMuted, fontSize: 11,
          fontWeight: 700, letterSpacing: "0.16em", textTransform: "uppercase",
        }}>Friends · today</div>
        <div style={{ flex: 1, height: 1, background: T.border }} />
        <div style={{ color: T.textMuted, fontSize: 12 }}>{FRIENDS_FEED.length}</div>
      </div>
      {FRIENDS_FEED.map(p => (
        <Post key={p.id} p={p} onCheers={toggleCheer} cheered={cheersSet.has(p.id)} onOpen={onOpenPost} />
      ))}
    </div>
  );
}

// ───────────────────────────────────────────
// Capture Screen — stays dark (camera-UI convention)
// ───────────────────────────────────────────
function CaptureScreen({ onClose, onCapture }) {
  const T = useT();
  const [stage, setStage] = useState("aim");
  const [caption, setCaption] = useState("");

  const shutter = () => {
    setStage("flash");
    setTimeout(() => setStage("review"), 180);
  };

  return (
    <div style={{
      position: "absolute", inset: 0, background: "#000",
      zIndex: 100, display: "flex", flexDirection: "column",
      color: "#fff",
    }}>
      <div style={{
        padding: "60px 18px 14px",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <button onClick={onClose} style={{
          width: 38, height: 38, borderRadius: "50%",
          background: "rgba(255,255,255,0.1)",
          border: "none", color: "#fff", display: "grid", placeItems: "center",
          cursor: "pointer",
        }}>{Ico.x(20)}</button>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 6,
          color: T.gold, fontSize: 11, fontWeight: 700,
          letterSpacing: "0.14em", textTransform: "uppercase",
        }}>{Ico.bolt(10, T.gold)} pour now</div>
        <button style={{
          width: 38, height: 38, borderRadius: "50%",
          background: "rgba(255,255,255,0.1)",
          border: "none", color: "#fff", display: "grid", placeItems: "center",
          cursor: "pointer",
        }}>{Ico.flash(18)}</button>
      </div>

      <div style={{ flex: 1, padding: "0 18px", position: "relative" }}>
        <div style={{
          position: "relative",
          width: "100%", aspectRatio: "3 / 4",
          borderRadius: 28, overflow: "hidden",
          background: "#000",
        }}>
          <ImgPH tone="pour" label="point at your drink" style={{ position: "absolute", inset: 0 }} />
          <div style={{
            position: "absolute", inset: 28,
            border: "1.5px dashed rgba(255,255,255,0.35)",
            borderRadius: 22,
          }} />
          {[
            { top: 16, left: 16, borderTop: 0, borderLeft: 0 },
            { top: 16, right: 16, borderTop: 0, borderRight: 0 },
            { bottom: 16, left: 16, borderBottom: 0, borderLeft: 0 },
            { bottom: 16, right: 16, borderBottom: 0, borderRight: 0 },
          ].map((s, i) => (
            <div key={i} style={{
              position: "absolute", width: 22, height: 22,
              border: "2.5px solid #fff",
              borderRadius: 4,
              ...s,
            }} />
          ))}
          <div style={{
            position: "absolute", top: 14, left: 14,
            width: 96, height: 128, borderRadius: 14, overflow: "hidden",
            border: "2px solid #000",
            outline: "1px solid rgba(255,255,255,0.18)",
          }}>
            <ImgPH tone="selfie" label="you" style={{ width: "100%", height: "100%" }} />
          </div>

          {stage === "flash" && (
            <div style={{
              position: "absolute", inset: 0, background: "#fff",
              animation: "flash 180ms",
            }} />
          )}

          {stage === "review" && (
            <div style={{
              position: "absolute", left: 16, right: 16, bottom: 16,
              padding: "10px 14px", borderRadius: 14,
              background: "rgba(0,0,0,0.75)",
              border: "1px solid rgba(255,255,255,0.1)",
            }}>
              <input
                value={caption}
                onChange={e => setCaption(e.target.value)}
                placeholder="What are you drinking?"
                style={{
                  width: "100%", background: "transparent", border: "none",
                  color: "#fff", outline: "none", fontSize: 14,
                  fontFamily: "inherit",
                }}
              />
            </div>
          )}
        </div>
      </div>

      <div style={{
        padding: "20px 32px 40px",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <button style={{
          width: 48, height: 48, borderRadius: "50%",
          background: "rgba(255,255,255,0.08)", border: "none", color: "#fff",
          display: "grid", placeItems: "center", cursor: "pointer",
        }}>{Ico.swap(22)}</button>

        {stage === "review" ? (
          <button onClick={() => onCapture(caption)} style={{
            padding: "16px 36px", borderRadius: 999,
            background: T.gold,
            border: "none", color: T.goldInk,
            fontWeight: 800, fontSize: 16, letterSpacing: "-0.01em",
            cursor: "pointer",
          }}>Pour it</button>
        ) : (
          <button onClick={shutter} style={{
            width: 84, height: 84, borderRadius: "50%",
            background: "transparent",
            border: "4px solid #fff",
            cursor: "pointer", position: "relative",
            padding: 0,
          }}>
            <div style={{
              position: "absolute", inset: 6, borderRadius: "50%",
              background: T.gold,
            }}/>
          </button>
        )}

        <button style={{
          width: 48, height: 48, borderRadius: "50%",
          background: "rgba(255,255,255,0.08)", border: "none", color: "#fff",
          display: "grid", placeItems: "center", cursor: "pointer",
        }}>{Ico.bolt(20, "#fff")}</button>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Map Screen
// ───────────────────────────────────────────
function MapScreen() {
  const T = useT();
  const [selected, setSelected] = useState(MAP_PINS[0]);
  return (
    <div style={{ position: "relative", height: "100%" }}>
      <div style={{ position: "absolute", inset: 0 }}>
        <ImgPH tone={T.name === "light" ? "mapLight" : "map"} label="" style={{ width: "100%", height: "100%" }} />
        <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none" style={{
          position: "absolute", inset: 0, opacity: T.name === "light" ? 0.45 : 0.3,
        }}>
          <path d="M0 40 Q 30 30, 50 50 T 100 60" stroke={T.gold} strokeWidth="0.5" fill="none"/>
          <path d="M20 0 Q 25 40, 35 60 T 50 100" stroke={T.gold} strokeWidth="0.4" fill="none"/>
          <path d="M0 80 L 100 75" stroke={T.gold} strokeWidth="0.3" fill="none"/>
          <path d="M70 0 L 65 100" stroke={T.gold} strokeWidth="0.3" fill="none"/>
        </svg>
        {MAP_PINS.map((m, i) => (
          <button key={i} onClick={() => setSelected(m)} style={{
            position: "absolute", left: `${m.x}%`, top: `${m.y}%`,
            transform: "translate(-50%, -100%)",
            background: "transparent", border: "none", cursor: "pointer",
            padding: 0,
          }}>
            <div style={{
              padding: "4px 10px 4px 6px", borderRadius: 999,
              background: m.you ? T.gold : T.pinBg,
              color: m.you ? T.goldInk : "#fff",
              border: `2px solid ${m.you ? "#fff" : T.gold}`,
              display: "flex", alignItems: "center", gap: 4,
              fontSize: 11, fontWeight: 700,
              whiteSpace: "nowrap",
            }}>
              {Ico.cheers(11, m.you ? T.goldInk : T.gold)} {m.label}
            </div>
            <div style={{
              width: 0, height: 0, marginLeft: 8,
              borderLeft: "5px solid transparent",
              borderRight: "5px solid transparent",
              borderTop: `7px solid ${m.you ? "#fff" : T.gold}`,
            }} />
          </button>
        ))}
      </div>

      <div style={{
        position: "absolute", left: 14, right: 14, bottom: 100,
        borderRadius: 18, padding: 16,
        background: T.surface,
        border: `1px solid ${T.border}`,
      }}>
        <div style={{
          color: T.textMuted, fontSize: 11, fontWeight: 700,
          letterSpacing: "0.14em", textTransform: "uppercase",
        }}>Selected pin</div>
        <div style={{
          color: T.text, fontSize: 22, fontWeight: 700, marginTop: 4,
          letterSpacing: "-0.02em",
        }}>{selected.label}{selected.you ? " (you)" : ""}</div>
        <div style={{ color: T.goldText, fontSize: 13, fontWeight: 600, marginTop: 2 }}>
          {selected.drink === "—" ? "haven't poured yet today" : `pouring ${selected.drink}`}
        </div>
        <div style={{
          marginTop: 12, display: "flex", gap: 8,
        }}>
          <button style={{
            flex: 1, padding: "10px 12px", borderRadius: 12,
            background: T.surfaceWeak, border: `1px solid ${T.border}`,
            color: T.text, fontSize: 13, fontWeight: 600, cursor: "pointer",
          }}>Directions</button>
          <button style={{
            flex: 1, padding: "10px 12px", borderRadius: 12,
            background: T.gold, border: "none", color: T.goldInk,
            fontSize: 13, fontWeight: 700, cursor: "pointer",
          }}>Cheers 🍻</button>
        </div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Friends Screen
// ───────────────────────────────────────────
function FriendsScreen() {
  const T = useT();
  return (
    <div style={{ padding: "0 0 100px" }}>
      <div style={{ padding: "0 18px 16px" }}>
        <div style={{
          padding: "12px 14px", borderRadius: 14,
          background: T.surfaceWeak,
          border: `1px solid ${T.border}`,
          color: T.textMuted, fontSize: 14,
        }}>Search by name or @handle</div>
      </div>

      <div style={{
        padding: "0 18px 8px",
        color: T.textMuted, fontSize: 11, fontWeight: 700,
        letterSpacing: "0.16em", textTransform: "uppercase",
      }}>Your circle · 8</div>

      {FRIENDS_LIST.map((f, i) => {
        const poured = f.status.startsWith("Poured");
        return (
          <div key={i} style={{
            display: "flex", alignItems: "center", gap: 12,
            padding: "12px 18px",
            borderBottom: `1px solid ${T.divider}`,
          }}>
            <div style={{ position: "relative" }}>
              <Avatar tone={f.tone} size={46} ring={poured} />
              {f.on && (
                <div style={{
                  position: "absolute", bottom: 0, right: 0,
                  width: 12, height: 12, borderRadius: "50%",
                  background: "#22c55e",
                  border: `2px solid ${T.onlineDotRing}`,
                }} />
              )}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ color: T.text, fontSize: 15, fontWeight: 600, letterSpacing: "-0.01em" }}>{f.name}</div>
              <div style={{ color: poured ? T.goldText : T.textMuted, fontSize: 12, marginTop: 2 }}>{f.status}</div>
            </div>
            <button style={{
              padding: "8px 14px", borderRadius: 999,
              background: poured ? T.goldSoft : T.surfaceWeak,
              border: `1px solid ${poured ? T.goldBorder : T.border}`,
              color: poured ? T.goldText : T.text,
              fontSize: 12, fontWeight: 600, cursor: "pointer",
            }}>{poured ? "Cheers" : "Nudge"}</button>
          </div>
        );
      })}

      <div style={{ padding: "20px 18px" }}>
        <button style={{
          width: "100%", padding: "14px", borderRadius: 16,
          background: "transparent",
          border: `1.5px dashed ${T.goldBorderStrong}`,
          color: T.goldText, fontSize: 14, fontWeight: 700, cursor: "pointer",
        }}>+ Invite a friend</button>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Profile Screen
// ───────────────────────────────────────────
function ProfileScreen({ streak, totalPints, posted, myPost, onOpenPost }) {
  const T = useT();
  const colorFor = (v) => T.streakCell[v];
  return (
    <div style={{ padding: "0 0 100px" }}>
      <div style={{ padding: "0 18px", display: "flex", gap: 14, alignItems: "center" }}>
        <Avatar tone="selfie" size={72} ring />
        <div style={{ flex: 1 }}>
          <div style={{ color: T.text, fontSize: 22, fontWeight: 700, letterSpacing: "-0.02em" }}>You</div>
          <div style={{ color: T.textMuted, fontSize: 13 }}>@you · joined 14w ago</div>
        </div>
      </div>

      <div style={{ padding: "18px", display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
        {[
          { v: streak, l: "streak", gold: true },
          { v: totalPints, l: "pints" },
          { v: 14, l: "spots" },
        ].map((s, i) => (
          <div key={i} style={{
            padding: "14px 12px", borderRadius: 14,
            background: s.gold ? T.goldFaint : T.surfaceWeaker,
            border: `1px solid ${s.gold ? T.goldBorder : T.border}`,
          }}>
            <div style={{
              color: s.gold ? T.goldText : T.text, fontSize: 26, fontWeight: 800,
              letterSpacing: "-0.03em",
            }}>{s.v}</div>
            <div style={{ color: T.textMuted, fontSize: 11, fontWeight: 600, letterSpacing: "0.08em", textTransform: "uppercase", marginTop: 2 }}>{s.l}</div>
          </div>
        ))}
      </div>

      <div style={{ padding: "0 18px 18px" }}>
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          marginBottom: 10,
        }}>
          <div style={{
            color: T.textMuted, fontSize: 11, fontWeight: 700,
            letterSpacing: "0.16em", textTransform: "uppercase",
          }}>12 weeks</div>
          <div style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 11, color: T.textMuted }}>
            less {[0,1,2,3].map(v => (
              <div key={v} style={{ width: 10, height: 10, background: colorFor(v), borderRadius: 2 }} />
            ))} more
          </div>
        </div>
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(12, 1fr)",
          gridAutoFlow: "column",
          gridTemplateRows: "repeat(7, 1fr)",
          gap: 4,
          padding: 14,
          borderRadius: 16,
          background: T.surfaceWeaker,
          border: `1px solid ${T.borderWeak}`,
        }}>
          {STREAK_GRID.map((v, i) => (
            <div key={i} style={{
              aspectRatio: "1", borderRadius: 3,
              background: colorFor(v),
            }} />
          ))}
        </div>
      </div>

      <div style={{ padding: "0 18px" }}>
        <div style={{
          color: T.textMuted, fontSize: 11, fontWeight: 700,
          letterSpacing: "0.16em", textTransform: "uppercase", marginBottom: 10,
        }}>Recent pours</div>
        <div style={{
          display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6,
        }}>
          {(posted && myPost ? [myPost] : []).concat(Array(11).fill(0).map((_, i) => ({
            id: `profile-grid-${i}`,
            name: "You", handle: "@you", time: `${i + 1}d ago`,
            place: "Home · Brooklyn", drink: ["IPA", "Stout", "Lager", "Sour", "Pils", "Hazy"][i % 6],
            caption: "", cheers: 0, comments: 0,
            tone: ["beer", "bar", "night", "sky"][i % 4], selfieTone: "selfie", late: false, views: 0,
          }))).slice(0, 12).map((p, i) => (
            <div key={i} onClick={() => onOpenPost && onOpenPost(p)} style={{
              aspectRatio: "1", borderRadius: 10, overflow: "hidden",
              position: "relative", cursor: "pointer",
            }}>
              <ImgPH tone={p.tone} label={p.drink} style={{ position: "absolute", inset: 0 }} />
              {i === 0 && posted && (
                <div style={{
                  position: "absolute", top: 4, left: 4,
                  padding: "2px 6px", borderRadius: 4,
                  background: T.gold, color: T.goldInk,
                  fontSize: 9, fontWeight: 800, letterSpacing: "0.08em",
                }}>TODAY</div>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Bottom nav — flat, no glow
// ───────────────────────────────────────────
function BottomNav({ screen, setScreen, onCapture, posted }) {
  const T = useT();
  const tabs = [
    { id: "feed", icon: Ico.feed, label: "Feed" },
    { id: "map",  icon: Ico.map,  label: "Map" },
    { id: "cam",  icon: Ico.cam,  label: "Pour", center: true },
    { id: "friends", icon: Ico.friends, label: "Friends" },
    { id: "profile", icon: Ico.user, label: "You" },
  ];
  return (
    <div style={{
      position: "absolute", left: 0, right: 0, bottom: 0,
      paddingBottom: 24,
      background: T.bg,
      borderTop: `1px solid ${T.border}`,
      display: "flex", alignItems: "center", justifyContent: "space-between",
      zIndex: 50,
    }}>
      {tabs.map(t => {
        if (t.center) {
          return (
            <button key={t.id} onClick={onCapture} style={{
              flex: 1, background: "transparent", border: "none",
              display: "flex", flexDirection: "column", alignItems: "center", gap: 3,
              padding: "10px 0", cursor: "pointer", position: "relative",
              color: T.goldText,
            }}>
              {t.icon(24, T.goldText)}
              <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: "-0.01em", color: T.goldText }}>{t.label}</div>
              {!posted && (
                <div style={{
                  position: "absolute", top: 8, right: "30%",
                  width: 8, height: 8, borderRadius: "50%",
                  background: "#ef4444",
                }} />
              )}
            </button>
          );
        }
        const active = screen === t.id;
        return (
          <button key={t.id} onClick={() => setScreen(t.id)} style={{
            flex: 1, background: "transparent", border: "none",
            display: "flex", flexDirection: "column", alignItems: "center", gap: 3,
            padding: "10px 0", cursor: "pointer",
            color: active ? T.text : T.textMuted,
          }}>
            {t.icon(24, active ? T.text : T.textMuted)}
            <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: "-0.01em" }}>{t.label}</div>
          </button>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────
// Main app
// ───────────────────────────────────────────
function PintApp({ initialScreen = "feed", initialPosted = false, theme = "dark" }) {
  const T = THEMES[theme] || THEMES.dark;
  const [screen, setScreen] = useState(initialScreen);
  const [posted, setPosted] = useState(initialPosted);
  const [captureOpen, setCaptureOpen] = useState(false);
  const [cheersSet, setCheersSet] = useState(new Set());
  const [myPost, setMyPost] = useState(null);
  const [openPost, setOpenPost] = useState(null);

  const toggleCheer = (id) => {
    setCheersSet(prev => {
      const s = new Set(prev);
      s.has(id) ? s.delete(id) : s.add(id);
      return s;
    });
  };

  const onCapture = () => setCaptureOpen(true);
  const onPosted = (caption) => {
    setCaptureOpen(false);
    setPosted(true);
    setMyPost({
      id: "me", name: "You", handle: "@you", time: "just now",
      place: "Home · Brooklyn", drink: "Half Acre Daisy Cutter",
      caption: caption || "first one of the day.",
      cheers: 0, comments: 0, mine: true,
      tone: "beer", selfieTone: "selfie",
    });
    setScreen("feed");
  };

  return (
    <ThemeContext.Provider value={T}>
      <IOSDevice width={402} height={874} dark={T.iosDark}>
        <div data-screen-label={`Pint App · ${theme} · ${screen}`} style={{
          height: "100%",
          background: T.bg,
          color: T.text,
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          position: "relative",
          paddingTop: 54,
        }}>
          <TopBar streak={7} onBell={() => {}} />

          <div style={{ height: "calc(100% - 90px)", overflow: "auto" }}>
            {screen === "feed" && (
              <FeedScreen
                minsLeft={84} posted={posted} onCapture={onCapture}
                cheersSet={cheersSet} toggleCheer={toggleCheer}
                myPost={myPost} onOpenPost={setOpenPost}
              />
            )}
            {screen === "map" && <MapScreen />}
            {screen === "friends" && <FriendsScreen />}
            {screen === "profile" && (
              <ProfileScreen
                streak={posted ? 8 : 7}
                totalPints={posted ? 142 : 141}
                posted={posted}
                myPost={myPost}
                onOpenPost={setOpenPost}
              />
            )}
          </div>

          <BottomNav
            screen={screen}
            setScreen={setScreen}
            onCapture={onCapture}
            posted={posted}
          />

          {captureOpen && (
            <CaptureScreen onClose={() => setCaptureOpen(false)} onCapture={onPosted} />
          )}

          {openPost && window.PostDetailScreen && (
            <div style={{ position: "absolute", inset: 0, zIndex: 200 }}>
              <window.PostDetailScreen
                theme={theme}
                post={openPost}
                onClose={() => setOpenPost(null)}
                embedded
              />
            </div>
          )}
        </div>
      </IOSDevice>
    </ThemeContext.Provider>
  );
}

Object.assign(window, { PintApp, THEMES, ThemeContext, Ico, ImgPH, Avatar, BrandMark });
