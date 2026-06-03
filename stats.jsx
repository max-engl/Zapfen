// Stats / Insights screen — fits the Pint. design system.
// Reached from the Leaderboard (chart button in its header).
// Drinks-over-time analytics, scoped to Your circle or Global.
// Hand-rolled SVG charts (no libs). Themes via window.THEMES tokens.

const { useState: useStateSt, useMemo: useMemoSt } = React;

const useTSt = () => React.useContext(window.ThemeContext);

const { Ico: IcoSt } = window;

// ───────────────────────────────────────────
// Icons
// ───────────────────────────────────────────
const IcoSt2 = {
  back: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 6 9 12l6 6"/>
    </svg>
  ),
  globe: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9"/><path d="M3 12h18"/>
      <path d="M12 3c2.5 2.5 2.5 15 0 18"/><path d="M12 3c-2.5 2.5-2.5 15 0 18"/>
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
  glass: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M7 3h8l-.6 16a2 2 0 0 1-2 1.9H9.6a2 2 0 0 1-2-1.9L7 3z"/>
      <path d="M15 7h2a2.5 2.5 0 0 1 0 5h-2.2"/><path d="M7 8h8"/>
    </svg>
  ),
  clock: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>
    </svg>
  ),
};

// ───────────────────────────────────────────
// Data — per scope, per range.
// series  : timeline points (drinks logged)
// dow     : drinks by day of week (Mon..Sun)
// styles  : top styles share
// peak    : busiest hour
// kpis     are derived
// ───────────────────────────────────────────
const RANGES = [
  { id: "week",  label: "Week" },
  { id: "month", label: "Month" },
  { id: "year",  label: "Year" },
];

const DATA = {
  friends: {
    week: {
      axis: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      series: [9, 6, 11, 14, 28, 41, 22],
      total: 131, deltaPct: 12,
      dow: [9, 6, 11, 14, 28, 41, 22],
      avgPerHead: 14.6,
    },
    month: {
      axis: ["W1", "W2", "W3", "W4"],
      series: [128, 142, 119, 168],
      total: 557, deltaPct: 8,
      dow: [54, 41, 62, 73, 121, 138, 68],
      avgPerHead: 61.9,
    },
    year: {
      axis: ["J","F","M","A","M","J","J","A","S","O","N","D"],
      series: [402, 366, 451, 478, 532, 611, 705, 668, 590, 540, 498, 612],
      total: 6453, deltaPct: 21,
      dow: [712, 540, 798, 905, 1410, 1620, 468],
      avgPerHead: 717,
    },
  },
  global: {
    week: {
      axis: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      series: [184, 142, 196, 233, 388, 512, 301],
      total: 1956, deltaPct: 5,
      dow: [184, 142, 196, 233, 388, 512, 301],
      avgPerHead: 0.81,
    },
    month: {
      axis: ["W1", "W2", "W3", "W4"],
      series: [1820, 1944, 1766, 2210],
      total: 7740, deltaPct: 3,
      dow: [820, 690, 940, 1180, 1610, 1880, 620],
      avgPerHead: 3.2,
    },
    year: {
      axis: ["J","F","M","A","M","J","J","A","S","O","N","D"],
      series: [6200, 5800, 6900, 7400, 8800, 10200, 12400, 11800, 9600, 8200, 7600, 9900],
      total: 104800, deltaPct: 14,
      dow: [11200, 9400, 12800, 15600, 22100, 24800, 8900],
      avgPerHead: 43,
    },
  },
};

const STYLES = {
  friends: [
    { name: "Hazy IPA",     pct: 31 },
    { name: "Lager",        pct: 22 },
    { name: "Stout",        pct: 16 },
    { name: "Pilsner",      pct: 13 },
    { name: "Sour",         pct: 10 },
    { name: "Other",        pct: 8  },
  ],
  global: [
    { name: "Lager",        pct: 34 },
    { name: "IPA",          pct: 24 },
    { name: "Pilsner",      pct: 14 },
    { name: "Wheat",        pct: 11 },
    { name: "Stout",        pct: 9  },
    { name: "Other",        pct: 8  },
  ],
};

const DOW_LABELS = ["M", "T", "W", "T", "F", "S", "S"];
const PEAK = { friends: "Fri · 9pm", global: "Sat · 10pm" };

function fmtSt(n) {
  if (n >= 1000) return (n / 1000).toFixed(n % 1000 === 0 ? 0 : 1) + "k";
  return String(n);
}

// ───────────────────────────────────────────
// Header
// ───────────────────────────────────────────
function StHeader({ onClose }) {
  const T = useTSt();
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "8px 16px 14px",
    }}>
      <button onClick={onClose} style={{
        width: 36, height: 36, borderRadius: "50%",
        background: T.surfaceWeak, border: `1px solid ${T.border}`,
        color: T.text, display: "grid", placeItems: "center", cursor: "pointer",
      }}>{IcoSt2.back(20)}</button>
      <div style={{ color: T.text, fontWeight: 700, fontSize: 16, letterSpacing: "-0.02em" }}>
        Pour stats
      </div>
      <div style={{ width: 36, height: 36 }} />
    </div>
  );
}

// ───────────────────────────────────────────
// Scope toggle (Your circle / Global)
// ───────────────────────────────────────────
function ScopeToggle({ scope, setScope }) {
  const T = useTSt();
  const opts = [
    { id: "friends", label: "Your circle", icon: IcoSt.friends },
    { id: "global",  label: "Global",      icon: IcoSt2.globe },
  ];
  return (
    <div style={{
      margin: "0 16px 16px",
      display: "flex", gap: 4, padding: 4, borderRadius: 14,
      background: T.surfaceWeaker, border: `1px solid ${T.borderWeak}`,
    }}>
      {opts.map(o => {
        const active = scope === o.id;
        return (
          <button key={o.id} onClick={() => setScope(o.id)} style={{
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
// Range chips
// ───────────────────────────────────────────
function RangeChips({ range, setRange }) {
  const T = useTSt();
  return (
    <div style={{ display: "flex", gap: 8, padding: "0 16px 16px" }}>
      {RANGES.map(r => {
        const active = range === r.id;
        return (
          <button key={r.id} onClick={() => setRange(r.id)} style={{
            flex: 1, padding: "8px 0", borderRadius: 999,
            background: active ? T.goldSoft : T.surfaceWeak,
            border: `1px solid ${active ? T.goldBorder : T.border}`,
            color: active ? T.goldText : T.textMuted,
            fontSize: 12.5, fontWeight: 700, cursor: "pointer",
          }}>{r.label}</button>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────
// Hero KPI + delta
// ───────────────────────────────────────────
function HeroKPI({ d, range }) {
  const T = useTSt();
  const up = d.deltaPct >= 0;
  const col = up ? "#22c55e" : "#c2511e";
  const periodWord = range === "week" ? "this week" : range === "month" ? "this month" : "this year";
  return (
    <div style={{ padding: "0 18px 18px" }}>
      <div style={{ color: T.textMuted, fontSize: 12, fontWeight: 600, letterSpacing: "0.02em", marginBottom: 6 }}>
        Drinks logged · {periodWord}
      </div>
      <div style={{ display: "flex", alignItems: "flex-end", gap: 12 }}>
        <div style={{ display: "inline-flex", alignItems: "baseline", gap: 6 }}>
          <span style={{ display: "inline-flex", alignSelf: "center", color: T.goldText }}>{IcoSt2.glass(20, T.goldText)}</span>
          <span style={{ color: T.text, fontSize: 40, fontWeight: 900, letterSpacing: "-0.04em", lineHeight: 1 }}>
            {fmtSt(d.total)}
          </span>
        </div>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 2, color: col,
          fontSize: 13, fontWeight: 800, marginBottom: 4,
        }}>
          {up ? IcoSt2.up(13, col) : IcoSt2.down(13, col)}{Math.abs(d.deltaPct)}%
        </div>
      </div>
      <div style={{ color: T.textFaint, fontSize: 11.5, fontWeight: 600, marginTop: 5 }}>
        vs the previous {range}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Card shell
// ───────────────────────────────────────────
function Card({ title, hint, children }) {
  const T = useTSt();
  return (
    <div style={{
      margin: "0 16px 14px", padding: "15px 15px 13px", borderRadius: 18,
      background: T.surface, border: `1px solid ${T.border}`,
    }}>
      <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 14 }}>
        <div style={{ color: T.text, fontSize: 13.5, fontWeight: 700, letterSpacing: "-0.01em" }}>{title}</div>
        {hint && <div style={{ color: T.textFaint, fontSize: 11, fontWeight: 600 }}>{hint}</div>}
      </div>
      {children}
    </div>
  );
}

// ───────────────────────────────────────────
// Area + line timeline chart (SVG)
// ───────────────────────────────────────────
function TimelineChart({ d }) {
  const T = useTSt();
  const W = 326, H = 150, padB = 22, padT = 8, padX = 4;
  const vals = d.series;
  const max = Math.max(...vals);
  const n = vals.length;
  const innerW = W - padX * 2;
  const x = (i) => padX + (n === 1 ? innerW / 2 : (i / (n - 1)) * innerW);
  const y = (v) => padT + (1 - v / max) * (H - padT - padB);

  const pts = vals.map((v, i) => [x(i), y(v)]);

  // smooth path
  const line = pts.map((p, i) => {
    if (i === 0) return `M ${p[0]} ${p[1]}`;
    const prev = pts[i - 1];
    const cx = (prev[0] + p[0]) / 2;
    return `C ${cx} ${prev[1]} ${cx} ${p[1]} ${p[0]} ${p[1]}`;
  }).join(" ");
  const area = `${line} L ${pts[n - 1][0]} ${H - padB} L ${pts[0][0]} ${H - padB} Z`;

  const gid = "stGrad_" + (T.name || "x");
  const maxI = vals.indexOf(max);

  return (
    <div>
      <svg width="100%" viewBox={`0 0 ${W} ${H}`} style={{ display: "block", overflow: "visible" }}>
        <defs>
          <linearGradient id={gid} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%"   stopColor={T.gold} stopOpacity="0.32" />
            <stop offset="100%" stopColor={T.gold} stopOpacity="0" />
          </linearGradient>
        </defs>
        {/* baseline */}
        <line x1={padX} y1={H - padB} x2={W - padX} y2={H - padB} stroke={T.border} strokeWidth="1" />
        <path d={area} fill={`url(#${gid})`} />
        <path d={line} fill="none" stroke={T.gold} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
        {/* points */}
        {pts.map((p, i) => (
          <circle key={i} cx={p[0]} cy={p[1]} r={i === maxI ? 4 : 2.5}
            fill={i === maxI ? T.gold : T.bg} stroke={T.gold} strokeWidth="2" />
        ))}
        {/* peak label */}
        <text x={pts[maxI][0]} y={y(max) - 9} textAnchor="middle"
          fontSize="10.5" fontWeight="800" fill={T.goldText}>{fmtSt(max)}</text>
        {/* axis */}
        {d.axis.map((lab, i) => (
          <text key={i} x={x(i)} y={H - 6} textAnchor="middle"
            fontSize="9.5" fontWeight="600" fill={T.textFaint}>{lab}</text>
        ))}
      </svg>
    </div>
  );
}

// ───────────────────────────────────────────
// Day-of-week bar chart
// ───────────────────────────────────────────
function DowChart({ dow }) {
  const T = useTSt();
  const max = Math.max(...dow);
  const maxI = dow.indexOf(max);
  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 8, height: 116 }}>
      {dow.map((v, i) => {
        const hot = i === maxI;
        const h = Math.max(6, (v / max) * 92);
        return (
          <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 7 }}>
            <div style={{ color: hot ? T.goldText : T.textFaint, fontSize: 9.5, fontWeight: 800 }}>{fmtSt(v)}</div>
            <div style={{
              width: "100%", maxWidth: 26, height: h, borderRadius: 7,
              background: hot ? T.gold : T.surfaceWeak,
              border: hot ? "none" : `1px solid ${T.border}`,
            }} />
            <div style={{ color: hot ? T.text : T.textMuted, fontSize: 10.5, fontWeight: 700 }}>{DOW_LABELS[i]}</div>
          </div>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────
// Styles breakdown (horizontal bars)
// ───────────────────────────────────────────
function StylesBreakdown({ styles }) {
  const T = useTSt();
  const max = Math.max(...styles.map(s => s.pct));
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 11 }}>
      {styles.map((s, i) => (
        <div key={s.name} style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ width: 74, color: T.text, fontSize: 12.5, fontWeight: 600, flexShrink: 0 }}>{s.name}</div>
          <div style={{ flex: 1, height: 10, borderRadius: 999, background: T.surfaceWeak, overflow: "hidden" }}>
            <div style={{
              width: `${(s.pct / max) * 100}%`, height: "100%", borderRadius: 999,
              background: i === 0 ? T.gold : T.goldStrong,
            }} />
          </div>
          <div style={{ width: 34, textAlign: "right", color: i === 0 ? T.goldText : T.textMuted, fontSize: 12, fontWeight: 800 }}>{s.pct}%</div>
        </div>
      ))}
    </div>
  );
}

// ───────────────────────────────────────────
// Small stat tiles
// ───────────────────────────────────────────
function StatTiles({ d, scope }) {
  const T = useTSt();
  const tiles = [
    { icon: IcoSt2.clock, label: "Peak pour", value: PEAK[scope] },
    { icon: IcoSt2.glass, label: scope === "friends" ? "Avg / friend" : "Avg / pourer", value: fmtSt(d.avgPerHead) },
  ];
  return (
    <div style={{ display: "flex", gap: 12, margin: "0 16px 14px" }}>
      {tiles.map((t, i) => (
        <div key={i} style={{
          flex: 1, padding: "13px 14px", borderRadius: 16,
          background: T.surface, border: `1px solid ${T.border}`,
        }}>
          <div style={{ display: "inline-flex", color: T.goldText, marginBottom: 8 }}>{t.icon(16, T.goldText)}</div>
          <div style={{ color: T.text, fontSize: 18, fontWeight: 900, letterSpacing: "-0.03em" }}>{t.value}</div>
          <div style={{ color: T.textMuted, fontSize: 11.5, fontWeight: 600, marginTop: 2 }}>{t.label}</div>
        </div>
      ))}
    </div>
  );
}

// ───────────────────────────────────────────
// Screen
// ───────────────────────────────────────────
function StatsScreen({ theme = "dark", initialScope = "friends" }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [scope, setScope] = useStateSt(initialScope);
  const [range, setRange] = useStateSt("week");

  const d = DATA[scope][range];
  const styles = STYLES[scope];

  const goBack = () => { try { window.location.href = "Leaderboard.html"; } catch (e) {} };

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        <div data-screen-label={`Stats · ${scope} · ${theme}`} style={{
          height: "100%", background: T.bg, color: T.text,
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          position: "relative", paddingTop: 54,
        }}>
          <StHeader onClose={goBack} />

          <div style={{ height: "calc(100% - 54px - 50px)", overflow: "auto", paddingBottom: 28 }}>
            <ScopeToggle scope={scope} setScope={setScope} />
            <RangeChips range={range} setRange={setRange} />
            <HeroKPI d={d} range={range} />

            <Card title="Drinks over time" hint={range === "week" ? "by day" : range === "month" ? "by week" : "by month"}>
              <TimelineChart d={d} />
            </Card>

            <StatTiles d={d} scope={scope} />

            <Card title="When the pours happen" hint="by weekday">
              <DowChart dow={d.dow} />
            </Card>

            <Card title="Top styles" hint={scope === "friends" ? "your circle" : "worldwide"}>
              <StylesBreakdown styles={styles} />
            </Card>

            <div style={{
              textAlign: "center", color: T.textFaint, fontSize: 11.5,
              padding: "6px 16px 0", fontWeight: 600,
            }}>
              {scope === "friends" ? "based on 9 friends' pours" : "based on 2.4M pourers"} 🍻
            </div>
          </div>
        </div>
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

Object.assign(window, { StatsScreen });
