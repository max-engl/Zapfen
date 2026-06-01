// Leaderboard screen — fits the Pint. design system.
// Standalone screen, no bottom nav. Friends + Global boards, sortable by
// total drinks (all-time) or This-week cheers. Themes via window.THEMES tokens.

const { useState: useStateLB } = React;

const useTLB = () => React.useContext(window.ThemeContext);

// Reuse atoms from app.jsx
const { ImgPH: ImgPHLB, Avatar: AvatarLB, Ico: IcoLB, BrandMark: BrandMarkLB } = window;

// ───────────────────────────────────────────
// Extra icons specific to this screen
// ───────────────────────────────────────────
const IcoLB2 = {
  back: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 6 9 12l6 6"/>
    </svg>
  ),
  trophy: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M7 4h10v4a5 5 0 0 1-10 0z"/>
      <path d="M7 6H4v1a3 3 0 0 0 3 3"/><path d="M17 6h3v1a3 3 0 0 1-3 3"/>
      <path d="M12 13v3"/><path d="M9 20h6"/><path d="M10 20a2 2 0 0 1 4 0"/>
    </svg>
  ),
  crown: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M3 8l3.5 3L12 5l5.5 6L21 8l-1.5 9h-15L3 8z"/>
    </svg>
  ),
  up: (s = 12, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 14l6-6 6 6"/>
    </svg>
  ),
  down: (s = 12, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 10l6 6 6-6"/>
    </svg>
  ),
  globe: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9"/><path d="M3 12h18"/>
      <path d="M12 3c2.5 2.5 2.5 15 0 18"/><path d="M12 3c-2.5 2.5-2.5 15 0 18"/>
    </svg>
  ),
  glass: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M7 3h8l-.6 16a2 2 0 0 1-2 1.9H9.6a2 2 0 0 1-2-1.9L7 3z"/>
      <path d="M15 7h2a2.5 2.5 0 0 1 0 5h-2.2"/><path d="M7 8h8"/>
    </svg>
  ),
};

// ───────────────────────────────────────────
// Sample data — each entry carries both metrics
// pints   = total drinks logged (all-time) · cheersWk = cheers received this week
// move    = rank change vs last period (number, 0, or "new")
// ───────────────────────────────────────────
const LB_FRIENDS = [
  { name: "Theo Park",       handle: "@theop",  sub: "Portland",       pints: 1204, cheersWk: 241, tone: "selfie", move: 2 },
  { name: "Jonas Lindqvist", handle: "@jlind",  sub: "Reykjavík",      pints: 842,  cheersWk: 198, tone: "selfie", move: 1 },
  { name: "Maya Calderón",   handle: "@mayac",  sub: "SE15, London",   pints: 776,  cheersWk: 176, tone: "avatar", move: -1 },
  { name: "You",             handle: "@you",    sub: "Brooklyn",       pints: 631,  cheersWk: 132, tone: "selfie", move: 3, you: true },
  { name: "Priya Anand",     handle: "@priyaa", sub: "Brooklyn",       pints: 588,  cheersWk: 154, tone: "avatar", move: 0 },
  { name: "Hana Tsuji",      handle: "@hanat",  sub: "Osaka",          pints: 455,  cheersWk: 112, tone: "selfie", move: 1 },
  { name: "Lena Bauer",      handle: "@lenab",  sub: "Berlin",         pints: 312,  cheersWk: 88,  tone: "selfie", move: -2 },
  { name: "Sam Okafor",      handle: "@samok",  sub: "Lagos",          pints: 209,  cheersWk: 67,  tone: "avatar", move: "new" },
  { name: "Rafael Costa",    handle: "@rafac",  sub: "Lisbon",         pints: 198,  cheersWk: 41,  tone: "avatar", move: -3 },
];

const LB_GLOBAL = [
  { name: "Lager Lady",      handle: "@lagerlady",  sub: "Munich",       pints: 11260, cheersWk: 2104, tone: "avatar", move: -1 },
  { name: "Hopwitch",        handle: "@hopwitch",   sub: "Brussels",     pints: 9840,  cheersWk: 1840, tone: "avatar", move: 0 },
  { name: "Sour Saoirse",    handle: "@saoirse",    sub: "Dublin",       pints: 8450,  cheersWk: 1450, tone: "selfie", move: 4 },
  { name: "Marta Q.",        handle: "@brewdad",    sub: "Denver",       pints: 8120,  cheersWk: 1622, tone: "selfie", move: 1 },
  { name: "Dunkel Dan",      handle: "@dunkeldan",  sub: "Bamberg",      pints: 7330,  cheersWk: 1330, tone: "avatar", move: 0 },
  { name: "Nic Nightcap",    handle: "@nightcap",   sub: "Melbourne",    pints: 6980,  cheersWk: 980,  tone: "selfie", move: 2 },
  { name: "Cask Casey",      handle: "@caskcasey",  sub: "Edinburgh",    pints: 6190,  cheersWk: 1190, tone: "selfie", move: 1 },
  { name: "Pilsner Pia",     handle: "@pilspia",    sub: "Plzeň",        pints: 5845,  cheersWk: 845,  tone: "avatar", move: "new" },
  { name: "Trappist Tom",    handle: "@trappistt",  sub: "Westvleteren", pints: 5690,  cheersWk: 690,  tone: "selfie", move: -1 },
  { name: "Ferment Femi",    handle: "@fermentf",   sub: "Lagos",        pints: 4760,  cheersWk: 760,  tone: "avatar", move: -2 },
];

// Where "you" sit globally (far down the list)
const YOU_GLOBAL = { rank: 4182, totalPct: "top 9%" };

// ───────────────────────────────────────────
// Helpers
// ───────────────────────────────────────────
function fmt(n) {
  return n >= 1000 ? (n / 1000).toFixed(n % 1000 === 0 ? 0 : 1) + "k" : String(n);
}

function metricValue(p, metric) {
  return metric === "pints" ? p.pints : p.cheersWk;
}

function sortedBoard(board, metric) {
  return [...board].sort((a, b) => metricValue(b, metric) - metricValue(a, metric));
}

// ───────────────────────────────────────────
// Header
// ───────────────────────────────────────────
function LBHeader({ onClose }) {
  const T = useTLB();
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "8px 18px 14px",
    }}>
      <button onClick={onClose} style={{
        width: 36, height: 36, borderRadius: "50%",
        background: T.surfaceWeak, border: `1px solid ${T.border}`,
        color: T.text, display: "grid", placeItems: "center", cursor: "pointer",
      }}>{IcoLB2.back(20)}</button>
      <div style={{
        display: "flex", alignItems: "center", gap: 7,
        color: T.text, fontWeight: 700, fontSize: 16, letterSpacing: "-0.02em",
      }}>
        <span style={{ display: "inline-flex", color: T.goldText }}>{IcoLB2.trophy(17, T.goldText)}</span>
        Leaderboard
      </div>
      <div style={{ width: 36, height: 36 }} />
    </div>
  );
}

// ───────────────────────────────────────────
// Board toggle (Friends / Global) — segmented
// ───────────────────────────────────────────
function BoardToggle({ board, setBoard }) {
  const T = useTLB();
  const opts = [
    { id: "friends", label: "Your circle", icon: IcoLB.friends },
    { id: "global",  label: "Global",      icon: IcoLB2.globe },
  ];
  return (
    <div style={{
      margin: "0 16px 14px",
      display: "flex", gap: 4, padding: 4, borderRadius: 14,
      background: T.surfaceWeaker, border: `1px solid ${T.borderWeak}`,
    }}>
      {opts.map(o => {
        const active = board === o.id;
        return (
          <button key={o.id} onClick={() => setBoard(o.id)} style={{
            flex: 1, padding: "10px 0", borderRadius: 10, border: "none",
            background: active ? T.gold : "transparent",
            color: active ? T.goldInk : T.textMuted,
            fontSize: 13.5, fontWeight: 700, letterSpacing: "-0.01em",
            cursor: "pointer", display: "inline-flex", alignItems: "center",
            justifyContent: "center", gap: 7, transition: "all .18s",
          }}>
            {o.icon(15, active ? T.goldInk : T.textMuted)} {o.label}
          </button>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────
// Metric chips (Total drinks / This week)
// ───────────────────────────────────────────
function MetricChips({ metric, setMetric }) {
  const T = useTLB();
  const opts = [
    { id: "pints",    label: "Total drinks" },
    { id: "cheersWk", label: "Cheers · this week" },
  ];
  return (
    <div style={{ display: "flex", gap: 8, padding: "0 16px 16px" }}>
      {opts.map(o => {
        const active = metric === o.id;
        return (
          <button key={o.id} onClick={() => setMetric(o.id)} style={{
            padding: "7px 14px", borderRadius: 999,
            background: active ? T.goldSoft : T.surfaceWeak,
            border: `1px solid ${active ? T.goldBorder : T.border}`,
            color: active ? T.goldText : T.textMuted,
            fontSize: 12, fontWeight: 700, letterSpacing: "-0.01em", cursor: "pointer",
          }}>{o.label}</button>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────
// Metric value display (icon + number + unit)
// ───────────────────────────────────────────
function MetricValue({ p, metric, big = false }) {
  const T = useTLB();
  const isPints = metric === "pints";
  const val = isPints ? p.pints : p.cheersWk;
  const icon = isPints ? IcoLB2.glass : IcoLB.cheers;
  return (
    <div style={{ display: "inline-flex", alignItems: "baseline", gap: 4 }}>
      <span style={{ display: "inline-flex", alignSelf: "center", color: T.goldText }}>
        {icon(big ? 13 : 12, T.goldText)}
      </span>
      <span style={{ color: T.text, fontWeight: 800, fontSize: big ? 17 : 15, letterSpacing: "-0.02em" }}>
        {fmt(val)}
      </span>
      <span style={{ color: T.textFaint, fontSize: big ? 11 : 10, fontWeight: 600 }}>
        {isPints ? "pints" : "🍻"}
      </span>
    </div>
  );
}

// ───────────────────────────────────────────
// Movement delta indicator
// ───────────────────────────────────────────
function MoveDelta({ move }) {
  const T = useTLB();
  if (move === "new") {
    return (
      <div style={{
        fontSize: 9, fontWeight: 800, letterSpacing: "0.08em",
        color: T.goldText, padding: "2px 5px", borderRadius: 5,
        background: T.goldFaint, border: `1px solid ${T.goldBorder}`,
      }}>NEW</div>
    );
  }
  if (move === 0) {
    return <div style={{ color: T.textFaint, fontSize: 11, fontWeight: 800, width: 22, textAlign: "center" }}>–</div>;
  }
  const upd = move > 0;
  const col = upd ? "#22c55e" : "#c2511e";
  return (
    <div style={{ display: "inline-flex", alignItems: "center", gap: 1, color: col, width: 22, justifyContent: "center" }}>
      {upd ? IcoLB2.up(11, col) : IcoLB2.down(11, col)}
      <span style={{ fontSize: 11, fontWeight: 800 }}>{Math.abs(move)}</span>
    </div>
  );
}

// ───────────────────────────────────────────
// Podium (top 3) — orders 2 · 1 · 3
// ───────────────────────────────────────────
function Podium({ top3, metric }) {
  const T = useTLB();
  // visual order: 2nd, 1st, 3rd
  const slots = [
    { p: top3[1], rank: 2, av: 60, ped: 64,  ring: T.selfieOutline },
    { p: top3[0], rank: 1, av: 78, ped: 92,  ring: T.gold },
    { p: top3[2], rank: 3, av: 60, ped: 50,  ring: T.selfieOutline },
  ];
  return (
    <div style={{
      display: "flex", alignItems: "flex-end", justifyContent: "center", gap: 10,
      padding: "6px 16px 0",
    }}>
      {slots.map((s, i) => {
        if (!s.p) return null;
        const first = s.rank === 1;
        return (
          <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center" }}>
            {/* avatar + crown + rank badge */}
            <div style={{ position: "relative", marginBottom: 8 }}>
              {first && (
                <div style={{
                  position: "absolute", top: -20, left: "50%", transform: "translateX(-50%)",
                  color: T.gold,
                }}>{IcoLB2.crown(24, T.gold)}</div>
              )}
              <div style={{
                width: s.av, height: s.av, borderRadius: "50%", overflow: "hidden",
                boxShadow: `0 0 0 ${first ? 3 : 2}px ${s.ring}`,
              }}>
                <ImgPHLB tone={s.p.tone} label="" style={{ width: "100%", height: "100%" }} />
              </div>
              <div style={{
                position: "absolute", bottom: -4, left: "50%", transform: "translateX(-50%)",
                width: 22, height: 22, borderRadius: "50%",
                background: first ? T.gold : T.surface,
                border: `2px solid ${T.bg}`,
                color: first ? T.goldInk : T.text,
                fontSize: 11, fontWeight: 800,
                display: "grid", placeItems: "center",
              }}>{s.rank}</div>
            </div>
            <div style={{
              color: T.text, fontSize: 12.5, fontWeight: 700, letterSpacing: "-0.01em",
              maxWidth: "100%", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
              textAlign: "center", marginTop: 2,
            }}>{s.p.name.split(" ")[0]}{s.p.you ? "" : ""}</div>
            <div style={{ marginTop: 3, marginBottom: 10 }}>
              <MetricValue p={s.p} metric={metric} big={first} />
            </div>
            {/* pedestal */}
            <div style={{
              width: "100%", height: s.ped, borderRadius: "12px 12px 0 0",
              background: first ? T.gold : T.surfaceWeak,
              border: `1px solid ${first ? "transparent" : T.border}`,
              borderBottom: "none",
              display: "grid", placeItems: "start center", paddingTop: 8,
            }}>
              <span style={{
                fontSize: first ? 30 : 22, fontWeight: 900, letterSpacing: "-0.04em",
                color: first ? T.goldInk : T.textFaint,
                opacity: first ? 0.55 : 0.7,
              }}>{s.rank}</span>
            </div>
          </div>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────
// Rank row (4th onward)
// ───────────────────────────────────────────
function RankRow({ p, rank, metric }) {
  const T = useTLB();
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 12,
      padding: "10px 16px",
      margin: p.you ? "2px 10px" : "0",
      borderRadius: p.you ? 14 : 0,
      background: p.you ? T.goldFaint : "transparent",
      border: p.you ? `1px solid ${T.goldBorder}` : "none",
      borderBottom: p.you ? `1px solid ${T.goldBorder}` : `1px solid ${T.divider}`,
    }}>
      <div style={{
        width: 22, textAlign: "center", flexShrink: 0,
        color: p.you ? T.goldText : T.textMuted, fontSize: 14, fontWeight: 800,
        letterSpacing: "-0.02em",
      }}>{rank}</div>
      <div style={{ position: "relative", flexShrink: 0 }}>
        <div style={{ width: 42, height: 42, borderRadius: "50%", overflow: "hidden",
          boxShadow: p.you ? `0 0 0 2px ${T.gold}` : "none" }}>
          <ImgPHLB tone={p.tone} label="" style={{ width: "100%", height: "100%" }} />
        </div>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          color: T.text, fontSize: 14.5, fontWeight: 600, letterSpacing: "-0.01em",
          whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
        }}>{p.name}{p.you && <span style={{ color: T.goldText, fontWeight: 700 }}> · you</span>}</div>
        <div style={{ color: T.textMuted, fontSize: 12, marginTop: 1 }}>{p.handle} · {p.sub}</div>
      </div>
      <MoveDelta move={p.move} />
      <div style={{ width: 64, textAlign: "right" }}>
        <MetricValue p={p} metric={metric} />
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Pinned "your rank" bar
// ───────────────────────────────────────────
function YouBar({ board, rank, you, metric }) {
  const T = useTLB();
  return (
    <div style={{
      position: "absolute", left: 0, right: 0, bottom: 0,
      padding: "10px 14px 26px",
      background: `linear-gradient(180deg, transparent, ${T.bg} 38%)`,
      zIndex: 40,
    }}>
      <div style={{
        display: "flex", alignItems: "center", gap: 12,
        padding: "11px 14px", borderRadius: 16,
        background: T.gold,
        boxShadow: "0 8px 24px rgba(0,0,0,0.18)",
      }}>
        <div style={{
          fontSize: 14, fontWeight: 900, color: T.goldInk, letterSpacing: "-0.02em",
          minWidth: 44,
        }}>
          {board === "global" ? `#${fmt(rank)}` : `#${rank}`}
        </div>
        <div style={{ width: 38, height: 38, borderRadius: "50%", overflow: "hidden",
          boxShadow: "0 0 0 2px rgba(0,0,0,0.25)", flexShrink: 0 }}>
          <ImgPHLB tone="selfie" label="" style={{ width: "100%", height: "100%" }} />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ color: T.goldInk, fontSize: 14, fontWeight: 800, letterSpacing: "-0.01em" }}>
            Your rank
          </div>
          <div style={{ color: "rgba(58,31,2,0.7)", fontSize: 11.5, fontWeight: 600, marginTop: 1 }}>
            {board === "global"
              ? `${YOU_GLOBAL.totalPct} of all pourers worldwide`
              : "pour more to climb your circle"}
          </div>
        </div>
        <div style={{
          display: "inline-flex", alignItems: "baseline", gap: 4,
          padding: "5px 11px", borderRadius: 999, background: "rgba(58,31,2,0.14)",
        }}>
          <span style={{ display: "inline-flex", alignSelf: "center" }}>
            {(metric === "pints" ? IcoLB2.glass : IcoLB.cheers)(13, T.goldInk)}
          </span>
          <span style={{ color: T.goldInk, fontSize: 16, fontWeight: 900, letterSpacing: "-0.02em" }}>
            {fmt(metric === "pints" ? you.pints : you.cheersWk)}
          </span>
          <span style={{ color: "rgba(58,31,2,0.6)", fontSize: 10, fontWeight: 700 }}>
            {metric === "pints" ? "pints" : "🍻"}
          </span>
        </div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Screen
// ───────────────────────────────────────────
function LeaderboardScreen({ theme = "dark", initialBoard = "friends" }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [board, setBoard] = useStateLB(initialBoard);
  const [metric, setMetric] = useStateLB("pints");

  const data = board === "friends" ? LB_FRIENDS : LB_GLOBAL;
  const ranked = sortedBoard(data, metric);
  const top3 = ranked.slice(0, 3);
  const rest = ranked.slice(3);

  const youEntry = LB_FRIENDS.find(p => p.you);
  const youRankFriends = ranked.findIndex(p => p.you) + 1;
  const youRank = board === "friends" ? (youRankFriends || ranked.length) : YOU_GLOBAL.rank;

  const periodLabel = metric === "pints" ? "total drinks" : "this week";
  const countLabel = board === "friends" ? `${LB_FRIENDS.length} in your circle` : "2.4M pourers";

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        <div data-screen-label={`Leaderboard · ${board} · ${theme}`} style={{
          height: "100%", background: T.bg, color: T.text,
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          position: "relative", paddingTop: 54,
        }}>
          <LBHeader onClose={() => {}} />

          <div style={{ height: "calc(100% - 54px - 42px)", overflow: "auto", paddingBottom: 130 }}>
            <BoardToggle board={board} setBoard={setBoard} />

            {/* subtitle line */}
            <div style={{
              padding: "0 18px 12px", display: "flex", alignItems: "center", gap: 8,
              color: T.textMuted, fontSize: 11.5, fontWeight: 600,
              letterSpacing: "0.02em",
            }}>
              <span style={{ display: "inline-flex", color: T.goldText }}>
                {board === "friends" ? IcoLB.friends(14, T.goldText) : IcoLB2.globe(14, T.goldText)}
              </span>
              {countLabel} · ranked by {periodLabel}
            </div>

            <MetricChips metric={metric} setMetric={setMetric} />

            <Podium top3={top3} metric={metric} />

            {/* divider before list */}
            <div style={{
              padding: "18px 18px 8px", display: "flex", alignItems: "center", gap: 10,
              color: T.textMuted, fontSize: 11, fontWeight: 700,
              letterSpacing: "0.16em", textTransform: "uppercase",
            }}>
              The rest
              <div style={{ flex: 1, height: 1, background: T.border }} />
            </div>

            {rest.map((p, i) => (
              <RankRow key={p.handle} p={p} rank={i + 4} metric={metric} />
            ))}

            {/* season note */}
            <div style={{
              margin: "18px 16px 0", padding: "12px 14px", borderRadius: 14,
              background: T.surfaceWeaker, border: `1px dashed ${T.border}`,
              display: "flex", alignItems: "center", gap: 10,
              color: T.textMuted, fontSize: 12,
            }}>
              <span style={{ display: "inline-flex", color: T.goldText }}>{IcoLB2.trophy(16, T.goldText)}</span>
              <div style={{ flex: 1 }}>
                Season ends sunday. top 3 of your circle get a golden glass on their profile.
              </div>
            </div>
          </div>

          <YouBar board={board} rank={youRank} you={youEntry} metric={metric} />
        </div>
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

Object.assign(window, { LeaderboardScreen });
