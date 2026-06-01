// Notifications screen — fits the Pint. design system.
// Standalone screen (no bottom nav), opened from the bell in the top bar.
// Groups recent activity by time, marks unread with a gold accent.
// Themes via window.THEMES tokens.

const { useState: useStateNo } = React;

const useTNo = () => React.useContext(window.ThemeContext);

const { ImgPH: ImgPHNo, Ico: IcoNo } = window;

// ───────────────────────────────────────────
// Extra icons
// ───────────────────────────────────────────
const IcoNo2 = {
  back: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 6 9 12l6 6"/>
    </svg>
  ),
  check: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12.5 10 17l9-10"/>
    </svg>
  ),
  trophy: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M7 4h10v4a5 5 0 0 1-10 0z"/>
      <path d="M7 6H4v1a3 3 0 0 0 3 3"/><path d="M17 6h3v1a3 3 0 0 1-3 3"/>
      <path d="M12 13v3"/><path d="M9 20h6"/><path d="M10 20a2 2 0 0 1 4 0"/>
    </svg>
  ),
  userPlus: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="9" cy="8" r="3.5"/><path d="M3 20c0-3.5 3-5.5 6-5.5s6 2 6 5.5"/>
      <path d="M18 7v6M21 10h-6"/>
    </svg>
  ),
};

// ───────────────────────────────────────────
// Notification data
// type → drives the leading badge icon + accent
//   cheers   · someone cheered your pour
//   comment  · someone replied
//   request  · incoming friend request (actionable)
//   accepted · friend request accepted
//   poured   · a friend just poured
//   rank     · leaderboard movement
//   streak   · streak / milestone nudge
//   prompt   · daily prompt dropped
// thumb = small pour photo on the right (optional)
// ───────────────────────────────────────────
const NOTIFS = [
  // ── Today ──
  { id: 1, group: "Today", type: "prompt", unread: true,
    title: "Time to pour", body: "today's prompt just dropped — you've got 58m to post.",
    time: "2m" },
  { id: 2, group: "Today", type: "cheers", unread: true,
    who: "Maya Calderón", tone: "avatar",
    body: "and 4 others cheered your Hazy Pale.", time: "14m", thumb: "beer" },
  { id: 3, group: "Today", type: "comment", unread: true,
    who: "Theo Park", tone: "selfie",
    body: "commented: “that head retention is unreal 🍺”", time: "31m", thumb: "beer" },
  { id: 4, group: "Today", type: "request", unread: true,
    who: "Sam Okafor", tone: "avatar", sub: "3 mutual friends",
    body: "wants to be your friend.", time: "1h", actionable: true },
  { id: 5, group: "Today", type: "poured", unread: false,
    who: "Jonas Lindqvist", tone: "selfie",
    body: "poured an Imperial Stout at Mikkeller.", time: "1h", thumb: "night" },

  // ── This week ──
  { id: 6, group: "This week", type: "rank", unread: false,
    title: "You climbed to #4", body: "you passed Priya in your circle's leaderboard.",
    time: "Mon" },
  { id: 7, group: "This week", type: "accepted", unread: false,
    who: "Hana Tsuji", tone: "selfie",
    body: "accepted your friend request. say cheers 🍻", time: "Mon" },
  { id: 8, group: "This week", type: "cheers", unread: false,
    who: "Priya Anand", tone: "avatar",
    body: "cheered your Pilsner Urquell.", time: "Sun", thumb: "sky" },
  { id: 9, group: "This week", type: "streak", unread: false,
    title: "7-day streak 🔥", body: "you've poured 7 days straight. don't break it tonight.",
    time: "Sun" },

  // ── Earlier ──
  { id: 10, group: "Earlier", type: "comment", unread: false,
    who: "Lena Bauer", tone: "selfie",
    body: "commented: “where is this place??”", time: "May 28", thumb: "bar" },
  { id: 11, group: "Earlier", type: "poured", unread: false,
    who: "Rafael Costa", tone: "avatar",
    body: "poured a Triple Belgian after a long hiatus.", time: "May 27", thumb: "beer" },
  { id: 12, group: "Earlier", type: "request", unread: false,
    who: "Cask Casey", tone: "selfie", sub: "1 mutual friend",
    body: "wants to be your friend.", time: "May 26", actionable: true, resolved: "accepted" },
];

// type → badge styling
function badgeFor(type, T) {
  switch (type) {
    case "cheers":   return { icon: IcoNo.cheers, bg: T.goldSoft, fg: T.goldText };
    case "comment":  return { icon: IcoNo.comment, bg: T.surfaceWeak, fg: T.text };
    case "request":  return { icon: IcoNo2.userPlus, bg: T.goldSoft, fg: T.goldText };
    case "accepted": return { icon: IcoNo2.check, bg: T.goldSoft, fg: T.goldText };
    case "poured":   return { icon: IcoNo.cheers, bg: T.surfaceWeak, fg: T.text };
    case "rank":     return { icon: IcoNo2.trophy, bg: T.goldSoft, fg: T.goldText };
    case "streak":   return { icon: IcoNo.bolt, bg: T.goldSoft, fg: T.goldText };
    case "prompt":   return { icon: IcoNo.bolt, bg: T.gold, fg: T.goldInk };
    default:         return { icon: IcoNo.bell, bg: T.surfaceWeak, fg: T.text };
  }
}

// ───────────────────────────────────────────
// Header
// ───────────────────────────────────────────
function NoHeader({ unreadCount, onClose, onMarkAll }) {
  const T = useTNo();
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "8px 14px 14px",
    }}>
      <button onClick={onClose} style={{
        width: 36, height: 36, borderRadius: "50%",
        background: T.surfaceWeak, border: `1px solid ${T.border}`,
        color: T.text, display: "grid", placeItems: "center", cursor: "pointer",
      }}>{IcoNo2.back(20)}</button>

      <div style={{ display: "flex", alignItems: "center", gap: 8, color: T.text }}>
        <span style={{ fontWeight: 700, fontSize: 16, letterSpacing: "-0.02em" }}>Notifications</span>
        {unreadCount > 0 && (
          <span style={{
            minWidth: 20, height: 20, padding: "0 6px", borderRadius: 999,
            background: T.gold, color: T.goldInk, fontSize: 11, fontWeight: 800,
            display: "grid", placeItems: "center",
          }}>{unreadCount}</span>
        )}
      </div>

      <button onClick={onMarkAll} disabled={unreadCount === 0} style={{
        padding: "7px 10px", borderRadius: 999, border: "none", background: "transparent",
        color: unreadCount === 0 ? T.textFaint : T.goldText,
        fontSize: 12, fontWeight: 700, cursor: unreadCount === 0 ? "default" : "pointer",
        display: "inline-flex", alignItems: "center", gap: 4,
      }}>
        {IcoNo2.check(14, unreadCount === 0 ? T.textFaint : T.goldText)} Read all
      </button>
    </div>
  );
}

// ───────────────────────────────────────────
// Single notification row
// ───────────────────────────────────────────
function NotifRow({ n, onRead, onResolve }) {
  const T = useTNo();
  const b = badgeFor(n.type, T);
  const heading = n.who || n.title;

  return (
    <button
      onClick={() => n.unread && onRead(n.id)}
      style={{
        width: "100%", textAlign: "left", border: "none", cursor: n.unread ? "pointer" : "default",
        display: "flex", alignItems: "flex-start", gap: 12,
        padding: "13px 16px 13px 14px",
        background: n.unread ? T.goldFaint : "transparent",
        position: "relative",
        borderBottom: `1px solid ${T.divider}`,
      }}>

      {/* unread dot */}
      <div style={{
        position: "absolute", left: 5, top: "50%", transform: "translateY(-50%)",
        width: 6, height: 6, borderRadius: "50%",
        background: n.unread ? T.gold : "transparent",
      }} />

      {/* avatar (people) or icon tile (system) */}
      <div style={{ position: "relative", flexShrink: 0 }}>
        {n.who ? (
          <div style={{ width: 44, height: 44, borderRadius: "50%", overflow: "hidden" }}>
            <ImgPHNo tone={n.tone} label="" style={{ width: "100%", height: "100%" }} />
          </div>
        ) : (
          <div style={{
            width: 44, height: 44, borderRadius: 14, background: b.bg,
            display: "grid", placeItems: "center", color: b.fg,
          }}>{b.icon(20, b.fg)}</div>
        )}
        {/* type badge corner (only for people-rows) */}
        {n.who && (
          <div style={{
            position: "absolute", right: -3, bottom: -3,
            width: 20, height: 20, borderRadius: "50%",
            background: b.bg, color: b.fg,
            border: `2px solid ${T.bg}`,
            display: "grid", placeItems: "center",
          }}>{b.icon(11, b.fg)}</div>
        )}
      </div>

      {/* text */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, lineHeight: 1.35, color: T.text }}>
          <span style={{ fontWeight: 700, letterSpacing: "-0.01em" }}>{heading}</span>
          {n.sub && <span style={{ color: T.textMuted, fontWeight: 500 }}> · {n.sub}</span>}
          <span style={{ color: T.textMuted, fontWeight: 500 }}> {n.body}</span>
        </div>
        <div style={{ fontSize: 11.5, color: T.textFaint, marginTop: 3, fontWeight: 600 }}>{n.time} ago</div>

        {/* friend-request actions */}
        {n.actionable && (
          <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
            {n._state === "accepted" || n.resolved === "accepted" ? (
              <div style={{
                padding: "7px 14px", borderRadius: 999, background: T.surfaceWeak,
                border: `1px solid ${T.border}`, color: T.textMuted,
                fontSize: 12.5, fontWeight: 700, display: "inline-flex", alignItems: "center", gap: 5,
              }}>{IcoNo2.check(13, T.textMuted)} Friends</div>
            ) : n._state === "declined" ? (
              <div style={{
                padding: "7px 14px", borderRadius: 999, background: T.surfaceWeak,
                border: `1px solid ${T.border}`, color: T.textFaint,
                fontSize: 12.5, fontWeight: 700,
              }}>Declined</div>
            ) : (
              <React.Fragment>
                <div role="button" onClick={(e) => { e.stopPropagation(); onResolve(n.id, "accepted"); }} style={{
                  padding: "7px 16px", borderRadius: 999, background: T.gold,
                  color: T.goldInk, fontSize: 12.5, fontWeight: 800, cursor: "pointer",
                }}>Accept</div>
                <div role="button" onClick={(e) => { e.stopPropagation(); onResolve(n.id, "declined"); }} style={{
                  padding: "7px 16px", borderRadius: 999, background: T.surfaceWeak,
                  border: `1px solid ${T.border}`, color: T.text, fontSize: 12.5, fontWeight: 700, cursor: "pointer",
                }}>Decline</div>
              </React.Fragment>
            )}
          </div>
        )}
      </div>

      {/* pour thumbnail */}
      {n.thumb && (
        <div style={{
          width: 46, height: 46, borderRadius: 12, overflow: "hidden", flexShrink: 0,
          boxShadow: `0 0 0 1px ${T.border}`,
        }}>
          <ImgPHNo tone={n.thumb} label="" style={{ width: "100%", height: "100%" }} />
        </div>
      )}
    </button>
  );
}

// ───────────────────────────────────────────
// Screen
// ───────────────────────────────────────────
function NotificationsScreen({ theme = "dark" }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [items, setItems] = useStateNo(NOTIFS);

  const markRead = (id) => setItems(xs => xs.map(n => n.id === id ? { ...n, unread: false } : n));
  const markAll  = () => setItems(xs => xs.map(n => ({ ...n, unread: false })));
  const resolve  = (id, state) => setItems(xs => xs.map(n => n.id === id ? { ...n, _state: state, unread: false } : n));

  const unreadCount = items.filter(n => n.unread).length;

  // preserve group order
  const groups = ["Today", "This week", "Earlier"];
  const byGroup = groups
    .map(g => ({ g, rows: items.filter(n => n.group === g) }))
    .filter(x => x.rows.length);

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        <div data-screen-label={`Notifications · ${theme}`} style={{
          height: "100%", background: T.bg, color: T.text,
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          position: "relative", paddingTop: 54,
        }}>
          <NoHeader unreadCount={unreadCount} onClose={() => {}} onMarkAll={markAll} />

          <div style={{ height: "calc(100% - 54px - 64px)", overflow: "auto", paddingBottom: 24 }}>
            {byGroup.map(({ g, rows }) => (
              <div key={g}>
                <div style={{
                  padding: "14px 16px 8px", display: "flex", alignItems: "center", gap: 10,
                  color: T.textMuted, fontSize: 11, fontWeight: 700,
                  letterSpacing: "0.16em", textTransform: "uppercase",
                  position: "sticky", top: 0, zIndex: 2,
                  background: T.bg,
                }}>
                  {g}
                  <div style={{ flex: 1, height: 1, background: T.border }} />
                </div>
                {rows.map(n => (
                  <NotifRow key={n.id} n={n} onRead={markRead} onResolve={resolve} />
                ))}
              </div>
            ))}

            {/* end cap */}
            <div style={{
              textAlign: "center", color: T.textFaint, fontSize: 12,
              padding: "22px 16px 8px", fontWeight: 600,
            }}>
              that's everything from the last 30 days 🍻
            </div>
          </div>
        </div>
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

Object.assign(window, { NotificationsScreen });
