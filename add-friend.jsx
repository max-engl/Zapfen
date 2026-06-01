// Add Friend screen — fits the Pint. design system.
// Themes via THEMES tokens from app.jsx (window.THEMES, window.ThemeContext, window.useT, etc.)

const { useState: useStateAF } = React;

// We re-pull theme + atoms from the global namespace so this file can sit
// next to app.jsx without re-declaring them.
const T_CTX = window.ThemeContext;
const useTAF = () => React.useContext(T_CTX);

// Reuse ImgPH/Avatar/Ico/BrandMark from app.jsx
const { ImgPH: ImgPHAF, Avatar: AvatarAF, Ico: IcoAF, BrandMark: BrandMarkAF } = window;

// Extra icons specific to this screen
const IcoAF2 = {
  back: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 6 9 12l6 6"/>
    </svg>
  ),
  search: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>
    </svg>
  ),
  qr: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7" rx="1"/>
      <rect x="14" y="3" width="7" height="7" rx="1"/>
      <rect x="3" y="14" width="7" height="7" rx="1"/>
      <path d="M14 14h3v3h-3z"/><path d="M20 14v3"/><path d="M14 20h3"/><path d="M20 20h1"/>
    </svg>
  ),
  share: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3v13"/><path d="m7 8 5-5 5 5"/><path d="M5 14v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5"/>
    </svg>
  ),
  copy: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="8" y="8" width="12" height="12" rx="2"/>
      <path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/>
    </svg>
  ),
  contacts: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="3" width="16" height="18" rx="2"/>
      <circle cx="12" cy="11" r="3"/>
      <path d="M7 18c1-2 3-3 5-3s4 1 5 3"/>
      <path d="M3 7h2"/><path d="M3 12h2"/><path d="M3 17h2"/>
    </svg>
  ),
  check: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="m5 12 5 5 9-11"/>
    </svg>
  ),
  plus: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 5v14M5 12h14"/>
    </svg>
  ),
  x2: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 6 18 18M18 6 6 18"/>
    </svg>
  ),
  link: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M10 14a4 4 0 0 0 5.66 0l3-3a4 4 0 1 0-5.66-5.66l-1.5 1.5"/>
      <path d="M14 10a4 4 0 0 0-5.66 0l-3 3a4 4 0 1 0 5.66 5.66l1.5-1.5"/>
    </svg>
  ),
  scan: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 8V6a2 2 0 0 1 2-2h2"/><path d="M20 8V6a2 2 0 0 0-2-2h-2"/>
      <path d="M4 16v2a2 2 0 0 0 2 2h2"/><path d="M20 16v2a2 2 0 0 1-2 2h-2"/>
      <path d="M4 12h16"/>
    </svg>
  ),
};

// ───────────────────────────────────────────
// Deterministic QR-ish placeholder
// ───────────────────────────────────────────
function FakeQR({ size = 132, fg = "#0a0a0a", bg = "#fff", seed = "you-pour-7G4K" }) {
  const N = 21;
  // Hash-ish: turn seed into deterministic boolean grid
  const cells = [];
  let h = 2166136261;
  for (let i = 0; i < seed.length; i++) h = (h ^ seed.charCodeAt(i)) * 16777619 >>> 0;
  for (let i = 0; i < N * N; i++) {
    h = (h * 1103515245 + 12345) >>> 0;
    cells.push((h & 7) > 2);
  }
  // Force three corner finders + alignment marker
  const isFinder = (r, c) => {
    const inBox = (R, C) => r >= R && r < R + 7 && c >= C && c < C + 7;
    return inBox(0, 0) || inBox(0, N - 7) || inBox(N - 7, 0);
  };
  const finderOn = (r, c) => {
    const within = (R, C) => {
      const rr = r - R, cc = c - C;
      if (rr === 0 || rr === 6 || cc === 0 || cc === 6) return true;
      if (rr >= 2 && rr <= 4 && cc >= 2 && cc <= 4) return true;
      return false;
    };
    if (r < 7 && c < 7) return within(0, 0);
    if (r < 7 && c >= N - 7) return within(0, N - 7);
    if (r >= N - 7 && c < 7) return within(N - 7, 0);
    return false;
  };
  const step = size / N;
  return (
    <div style={{
      width: size, height: size, background: bg, borderRadius: 10,
      padding: 6, boxSizing: "border-box", position: "relative",
    }}>
      <svg width={size - 12} height={size - 12} viewBox={`0 0 ${N} ${N}`}>
        {Array.from({ length: N * N }).map((_, i) => {
          const r = Math.floor(i / N), c = i % N;
          const on = isFinder(r, c) ? finderOn(r, c) : cells[i];
          if (!on) return null;
          return <rect key={i} x={c} y={r} width={1} height={1} fill={fg}/>;
        })}
      </svg>
      {/* center brand badge */}
      <div style={{
        position: "absolute", left: "50%", top: "50%",
        transform: "translate(-50%, -50%)",
        width: size * 0.24, height: size * 0.24,
        background: bg, borderRadius: 8,
        display: "grid", placeItems: "center",
        boxShadow: `0 0 0 3px ${bg}`,
      }}>
        <BrandMarkAF size={size * 0.2} />
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Sample data
// ───────────────────────────────────────────
const AF_REQUESTS = [
  { name: "Iris Holloway", handle: "@irish", mutuals: 3, tone: "selfie" },
];

const AF_SUGGESTED = [
  { name: "Marco Beltrán",   handle: "@marcob",   mutuals: 7, via: "Maya, Theo +5", tone: "avatar" },
  { name: "Asha Devereaux",  handle: "@ashad",    mutuals: 4, via: "Priya, Jonas +2", tone: "selfie" },
  { name: "Quentin Roe",     handle: "@qroe",     mutuals: 2, via: "Theo, Sam",       tone: "avatar" },
  { name: "Béa Marchetti",   handle: "@beam",     mutuals: 2, via: "Lena, Hana",      tone: "selfie" },
];

const AF_CONTACTS = [
  { name: "Dad",            sub: "in contacts · not on Pint", tone: "avatar" },
  { name: "Wesley Tan",     sub: "in contacts · @wes", on: true, tone: "selfie" },
  { name: "Nora Aldridge",  sub: "in contacts · not on Pint", tone: "avatar" },
];

// ───────────────────────────────────────────
// Components
// ───────────────────────────────────────────
function AFHeader({ requestCount, onClose }) {
  const T = useTAF();
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "8px 18px 14px",
    }}>
      <button onClick={onClose} style={{
        width: 36, height: 36, borderRadius: "50%",
        background: T.surfaceWeak,
        border: `1px solid ${T.border}`,
        color: T.text, display: "grid", placeItems: "center",
        cursor: "pointer",
      }}>{IcoAF2.back(20)}</button>
      <div style={{
        color: T.text, fontWeight: 700, fontSize: 16, letterSpacing: "-0.02em",
      }}>Add to your circle</div>
      <button style={{
        width: 36, height: 36, borderRadius: "50%",
        background: T.surfaceWeak,
        border: `1px solid ${T.border}`,
        color: T.text, display: "grid", placeItems: "center",
        cursor: "pointer", position: "relative",
      }}>
        {IcoAF2.scan(18)}
      </button>
    </div>
  );
}

function YourCodeCard({ onShare, copied, onCopy }) {
  const T = useTAF();
  return (
    <div style={{
      margin: "0 16px 18px",
      borderRadius: 22, padding: 18,
      background: T.goldFaint,
      border: `1px solid ${T.goldBorder}`,
      position: "relative", overflow: "hidden",
    }}>
      <div style={{
        display: "flex", alignItems: "center", gap: 14,
      }}>
        <div style={{
          flexShrink: 0,
          padding: 6, borderRadius: 14,
          background: "#fff",
          boxShadow: `0 8px 24px rgba(0,0,0,0.18), 0 0 0 1px ${T.goldBorder}`,
        }}>
          <FakeQR size={108} fg="#0a0a0a" bg="#fff" seed="you-pour-7G4K" />
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            color: T.goldText, fontSize: 11, fontWeight: 700,
            letterSpacing: "0.14em", textTransform: "uppercase",
            display: "inline-flex", alignItems: "center", gap: 6,
          }}>
            {IcoAF.bolt(10, T.goldText)} your pint code
          </div>
          <div style={{
            color: T.text, fontWeight: 800, fontSize: 22,
            letterSpacing: "-0.02em", marginTop: 4,
          }}>@you</div>
          <div style={{
            display: "inline-flex", alignItems: "center", gap: 6,
            marginTop: 4,
            padding: "4px 10px", borderRadius: 8,
            background: T.surfaceWeak,
            border: `1px solid ${T.border}`,
            fontFamily: "ui-monospace, Menlo, monospace",
            color: T.text, fontSize: 13, fontWeight: 600, letterSpacing: "0.08em",
          }}>POUR-7G4K</div>
        </div>
      </div>

      <div style={{ display: "flex", gap: 8, marginTop: 14 }}>
        <button onClick={onShare} style={{
          flex: 1, padding: "11px 12px", borderRadius: 12,
          background: T.gold, border: "none", color: T.goldInk,
          fontSize: 13, fontWeight: 700,
          display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 6,
          cursor: "pointer", letterSpacing: "-0.01em",
        }}>
          {IcoAF2.share(15, T.goldInk)} Share invite
        </button>
        <button onClick={onCopy} style={{
          flex: 1, padding: "11px 12px", borderRadius: 12,
          background: T.surfaceWeak,
          border: `1px solid ${T.border}`,
          color: T.text, fontSize: 13, fontWeight: 600,
          display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 6,
          cursor: "pointer", letterSpacing: "-0.01em",
        }}>
          {copied
            ? <>{IcoAF2.check(15, T.goldText)} <span style={{ color: T.goldText }}>Copied</span></>
            : <>{IcoAF2.copy(15)} Copy code</>}
        </button>
      </div>
    </div>
  );
}

function SearchField({ value, onChange }) {
  const T = useTAF();
  return (
    <div style={{ padding: "0 16px 14px" }}>
      <div style={{
        display: "flex", alignItems: "center", gap: 10,
        padding: "12px 14px", borderRadius: 14,
        background: T.surfaceWeak,
        border: `1px solid ${T.border}`,
      }}>
        <span style={{ color: T.textMuted, display: "inline-flex" }}>{IcoAF2.search(18, T.textMuted)}</span>
        <input
          value={value}
          onChange={e => onChange(e.target.value)}
          placeholder="Search @handle, name, or pint code"
          style={{
            flex: 1, background: "transparent", border: "none", outline: "none",
            color: T.text, fontSize: 14, fontFamily: "inherit",
            letterSpacing: "-0.01em",
          }}
        />
        {value && (
          <button onClick={() => onChange("")} style={{
            background: "transparent", border: "none", color: T.textMuted, cursor: "pointer", padding: 0,
            display: "inline-flex",
          }}>{IcoAF2.x2(16, T.textMuted)}</button>
        )}
      </div>
    </div>
  );
}

function SectionLabel({ children, right }) {
  const T = useTAF();
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 8,
      padding: "0 18px 10px",
    }}>
      <div style={{
        color: T.textMuted, fontSize: 11,
        fontWeight: 700, letterSpacing: "0.16em", textTransform: "uppercase",
      }}>{children}</div>
      <div style={{ flex: 1, height: 1, background: T.border }} />
      {right && <div style={{ color: T.textMuted, fontSize: 12 }}>{right}</div>}
    </div>
  );
}

function RequestRow({ person, onAccept, onDecline, state }) {
  const T = useTAF();
  return (
    <div style={{
      margin: "0 16px 10px",
      padding: 14, borderRadius: 16,
      background: T.surfaceWeaker,
      border: `1px solid ${T.border}`,
      display: "flex", alignItems: "center", gap: 12,
    }}>
      <AvatarAF tone={person.tone} size={46} ring />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: T.text, fontSize: 15, fontWeight: 600, letterSpacing: "-0.01em" }}>
          {person.name}
        </div>
        <div style={{ color: T.textMuted, fontSize: 12, marginTop: 2 }}>
          {person.handle} · {person.mutuals} mutual{person.mutuals === 1 ? "" : "s"}
        </div>
      </div>
      {state === "accepted" ? (
        <div style={{
          padding: "8px 12px", borderRadius: 999,
          background: T.goldSoft, color: T.goldText,
          border: `1px solid ${T.goldBorder}`,
          fontSize: 12, fontWeight: 700,
          display: "inline-flex", alignItems: "center", gap: 4,
        }}>{IcoAF2.check(13, T.goldText)} In your circle</div>
      ) : state === "declined" ? (
        <div style={{
          padding: "8px 12px", borderRadius: 999,
          background: "transparent", color: T.textMuted,
          border: `1px solid ${T.border}`,
          fontSize: 12, fontWeight: 600,
        }}>Declined</div>
      ) : (
        <div style={{ display: "flex", gap: 6 }}>
          <button onClick={onDecline} style={{
            width: 36, height: 36, borderRadius: "50%",
            background: T.surfaceWeak, border: `1px solid ${T.border}`,
            color: T.text, display: "grid", placeItems: "center", cursor: "pointer",
          }}>{IcoAF2.x2(15)}</button>
          <button onClick={onAccept} style={{
            padding: "8px 14px", borderRadius: 999,
            background: T.gold, border: "none", color: T.goldInk,
            fontSize: 12, fontWeight: 700, cursor: "pointer",
            letterSpacing: "-0.01em",
          }}>Accept</button>
        </div>
      )}
    </div>
  );
}

function SuggestedRow({ person, state, onAdd }) {
  const T = useTAF();
  const requested = state === "requested";
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 12,
      padding: "12px 18px",
      borderBottom: `1px solid ${T.divider}`,
    }}>
      <AvatarAF tone={person.tone} size={44} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          color: T.text, fontSize: 15, fontWeight: 600, letterSpacing: "-0.01em",
        }}>{person.name}</div>
        <div style={{
          color: T.textMuted, fontSize: 12, marginTop: 2,
          whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
        }}>{person.handle} · {person.mutuals} mutual · {person.via}</div>
      </div>
      <button onClick={onAdd} disabled={requested} style={{
        padding: requested ? "8px 12px" : "8px 12px 8px 10px",
        borderRadius: 999,
        background: requested ? T.surfaceWeak : T.goldSoft,
        border: `1px solid ${requested ? T.border : T.goldBorder}`,
        color: requested ? T.textMuted : T.goldText,
        fontSize: 12, fontWeight: 700,
        display: "inline-flex", alignItems: "center", gap: 4,
        cursor: requested ? "default" : "pointer",
        letterSpacing: "-0.01em",
      }}>
        {requested
          ? <>{IcoAF2.check(13)} Requested</>
          : <>{IcoAF2.plus(13, T.goldText)} Add</>}
      </button>
    </div>
  );
}

function ContactRow({ person, state, onInvite }) {
  const T = useTAF();
  const isOnPint = !!person.on;
  const invited = state === "invited";
  const added = state === "added";
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 12,
      padding: "12px 18px",
      borderBottom: `1px solid ${T.divider}`,
    }}>
      <div style={{
        width: 40, height: 40, borderRadius: "50%",
        background: T.surfaceWeak,
        border: `1px solid ${T.border}`,
        display: "grid", placeItems: "center",
        color: T.textMuted, fontWeight: 700, fontSize: 15,
        letterSpacing: "-0.01em",
      }}>{person.name.split(" ").map(s => s[0]).join("").slice(0,2).toUpperCase()}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: T.text, fontSize: 15, fontWeight: 600, letterSpacing: "-0.01em" }}>{person.name}</div>
        <div style={{ color: T.textMuted, fontSize: 12, marginTop: 2 }}>{person.sub}</div>
      </div>
      {isOnPint ? (
        <button onClick={onInvite} disabled={added} style={{
          padding: "8px 12px", borderRadius: 999,
          background: added ? T.surfaceWeak : T.goldSoft,
          border: `1px solid ${added ? T.border : T.goldBorder}`,
          color: added ? T.textMuted : T.goldText,
          fontSize: 12, fontWeight: 700,
          display: "inline-flex", alignItems: "center", gap: 4,
          cursor: added ? "default" : "pointer",
        }}>
          {added
            ? <>{IcoAF2.check(13)} Requested</>
            : <>{IcoAF2.plus(13, T.goldText)} Add</>}
        </button>
      ) : (
        <button onClick={onInvite} disabled={invited} style={{
          padding: "8px 12px", borderRadius: 999,
          background: "transparent",
          border: `1px dashed ${invited ? T.border : T.goldBorderStrong}`,
          color: invited ? T.textMuted : T.goldText,
          fontSize: 12, fontWeight: 700,
          cursor: invited ? "default" : "pointer",
          display: "inline-flex", alignItems: "center", gap: 4,
        }}>
          {invited ? "Invited" : <>{IcoAF2.share(13, T.goldText)} Invite</>}
        </button>
      )}
    </div>
  );
}

function Toast({ msg }) {
  const T = useTAF();
  if (!msg) return null;
  return (
    <div style={{
      position: "absolute", left: 0, right: 0, bottom: 28,
      display: "flex", justifyContent: "center", pointerEvents: "none",
      zIndex: 60,
    }}>
      <div style={{
        padding: "10px 16px", borderRadius: 999,
        background: T.gold, color: T.goldInk,
        fontSize: 13, fontWeight: 700, letterSpacing: "-0.01em",
        boxShadow: "0 14px 28px rgba(0,0,0,0.35)",
        display: "inline-flex", alignItems: "center", gap: 6,
      }}>
        {IcoAF2.check(15, T.goldInk)} {msg}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Main Add Friend screen
// ───────────────────────────────────────────
function AddFriendScreen({ theme = "dark" }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [query, setQuery] = useStateAF("");
  const [copied, setCopied] = useStateAF(false);
  const [toast, setToast] = useStateAF("");
  const [reqState, setReqState] = useStateAF({}); // name -> accepted|declined
  const [suggState, setSuggState] = useStateAF({}); // handle -> requested
  const [contactState, setContactState] = useStateAF({}); // name -> invited|added

  const showToast = (m) => {
    setToast(m);
    setTimeout(() => setToast(""), 1600);
  };

  const handleCopy = () => {
    setCopied(true);
    showToast("Code copied · POUR-7G4K");
    setTimeout(() => setCopied(false), 1800);
  };

  // Filter rows by query
  const q = query.trim().toLowerCase();
  const matches = (p) => !q || p.name.toLowerCase().includes(q) || p.handle.toLowerCase().includes(q);
  const filteredSuggested = AF_SUGGESTED.filter(matches);
  const filteredContacts = AF_CONTACTS.filter(p => !q || p.name.toLowerCase().includes(q) || (p.sub || "").toLowerCase().includes(q));

  const incomingCount = AF_REQUESTS.filter(r => !reqState[r.name] || reqState[r.name] === "pending").length;

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        <div data-screen-label={`Add Friend · ${theme}`} style={{
          height: "100%",
          background: T.bg,
          color: T.text,
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          position: "relative",
          paddingTop: 54,
        }}>
          <AFHeader requestCount={incomingCount} onClose={() => {}} />

          <div style={{ height: "calc(100% - 54px - 52px)", overflow: "auto", paddingBottom: 28 }}>

            <YourCodeCard onShare={() => showToast("Invite link ready to share")} copied={copied} onCopy={handleCopy} />

            <SearchField value={query} onChange={setQuery} />

            {AF_REQUESTS.length > 0 && incomingCount > 0 && (
              <>
                <SectionLabel right={`${incomingCount} pending`}>Requests for you</SectionLabel>
                {AF_REQUESTS.map((p, i) => (
                  <RequestRow
                    key={i}
                    person={p}
                    state={reqState[p.name] || "pending"}
                    onAccept={() => { setReqState(s => ({...s, [p.name]: "accepted"})); showToast(`Cheers — ${p.name.split(" ")[0]} is in`); }}
                    onDecline={() => setReqState(s => ({...s, [p.name]: "declined"}))}
                  />
                ))}
                <div style={{ height: 18 }} />
              </>
            )}

            <SectionLabel right={`${filteredSuggested.length} via mutuals`}>
              Suggested · friends of friends
            </SectionLabel>
            {filteredSuggested.length === 0 ? (
              <div style={{ padding: "0 18px 18px", color: T.textMuted, fontSize: 13 }}>
                No one matches "{query}". Try a pint code instead.
              </div>
            ) : (
              filteredSuggested.map((p, i) => (
                <SuggestedRow
                  key={i}
                  person={p}
                  state={suggState[p.handle]}
                  onAdd={() => { setSuggState(s => ({...s, [p.handle]: "requested"})); showToast(`Request sent to ${p.name.split(" ")[0]}`); }}
                />
              ))
            )}

            <div style={{ height: 18 }} />
            <SectionLabel right={`${filteredContacts.length}`}>From your contacts</SectionLabel>
            <div style={{
              margin: "0 16px 4px",
              padding: "10px 14px", borderRadius: 14,
              background: T.goldFaint, border: `1px solid ${T.goldBorder}`,
              display: "flex", alignItems: "center", gap: 10,
              color: T.text, fontSize: 12,
            }}>
              <span style={{ display: "inline-flex", color: T.goldText }}>{IcoAF2.contacts(16, T.goldText)}</span>
              <div style={{ flex: 1, color: T.textMuted }}>
                We only match handles you already know. Numbers stay on your phone.
              </div>
            </div>
            <div style={{ height: 8 }} />
            {filteredContacts.map((p, i) => (
              <ContactRow
                key={i}
                person={p}
                state={contactState[p.name]}
                onInvite={() => {
                  setContactState(s => ({...s, [p.name]: p.on ? "added" : "invited"}));
                  showToast(p.on ? `Request sent to ${p.name.split(" ")[0]}` : `Invite sent to ${p.name.split(" ")[0]}`);
                }}
              />
            ))}

            <div style={{ height: 24 }} />
            <div style={{
              margin: "0 16px",
              padding: "14px 16px", borderRadius: 16,
              background: T.surfaceWeaker,
              border: `1px dashed ${T.border}`,
              display: "flex", alignItems: "center", gap: 12,
            }}>
              <div style={{
                width: 36, height: 36, borderRadius: 10,
                background: T.surfaceWeak,
                display: "grid", placeItems: "center", color: T.textMuted,
              }}>{IcoAF2.link(16, T.textMuted)}</div>
              <div style={{ flex: 1 }}>
                <div style={{ color: T.text, fontSize: 13, fontWeight: 600 }}>pint.so/u/you</div>
                <div style={{ color: T.textMuted, fontSize: 11, marginTop: 1 }}>
                  Anyone with this link can request to join your circle.
                </div>
              </div>
              <button onClick={() => { handleCopy(); }} style={{
                padding: "8px 12px", borderRadius: 999,
                background: T.surfaceWeak, border: `1px solid ${T.border}`,
                color: T.text, fontSize: 12, fontWeight: 600, cursor: "pointer",
              }}>Copy</button>
            </div>
          </div>

          {/* Sticky bottom bar */}
          <div style={{
            position: "absolute", left: 0, right: 0, bottom: 0,
            padding: "12px 16px 26px",
            background: `linear-gradient(180deg, transparent, ${T.bg} 40%)`,
            zIndex: 40,
          }}>
            <button style={{
              width: "100%", padding: "14px", borderRadius: 16,
              background: T.gold, color: T.goldInk,
              border: "none", fontWeight: 800, fontSize: 15,
              letterSpacing: "-0.01em", cursor: "pointer",
              display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
            }}>
              {IcoAF2.contacts(18, T.goldInk)} Find friends from contacts
            </button>
          </div>

          <Toast msg={toast} />
        </div>
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

Object.assign(window, { AddFriendScreen });
