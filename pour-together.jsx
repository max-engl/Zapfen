// Pour Together — a joint-pour feature for Pint.
// Lightweight co-author tagging: you capture a pour, tag a friend who's with you,
// and it appears as a single post credited to both — no approval gate.
//
// Built from Pint's existing system (window.THEMES / IOSDevice / ImgPH / Avatar / Ico).
// Three connected contexts, all clickable from one phone:
//   create    — describe step with a "Pour together" card → co-author picker
//   feed      — the resulting joint post (dual-avatar header, badge, stacked selfies)
//   coauthor  — what the tagged friend sees (keep / remove me)

const { useState: usePT, useEffect: usePTE, useRef: usePTR } = React;
const { ImgPH: ImgPHpt, Avatar: AvatarPt, Ico: IcoPt, BrandMark: BrandMarkPt } = window;

// ── extra glyphs (Pint stroke style) ──────────────────────────
const PT = {
  back:    (s = 20, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 6 9 12l6 6"/></svg>),
  chevron: (s = 16, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="m9 6 6 6-6 6"/></svg>),
  x:       (s = 20, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 6 18 18M18 6 6 18"/></svg>),
  check:   (s = 14, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12l5 5L20 7"/></svg>),
  search:  (s = 18, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/></svg>),
  glass:   (s = 14, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 3h12l-1.2 13a3 3 0 0 1-3 2.7H10.2a3 3 0 0 1-3-2.7z"/><path d="M7 8h10"/></svg>),
  pin:     (s = 14, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 22s7-6.5 7-12a7 7 0 1 0-14 0c0 5.5 7 12 7 12z"/><circle cx="12" cy="10" r="2.5"/></svg>),
  people:  (s = 16, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="9" cy="9" r="3.5"/><circle cx="17" cy="10" r="2.5"/><path d="M3 20c0-3 3-5 6-5s6 2 6 5"/><path d="M15 20c0-2.5 2-4 4-4"/></svg>),
  userPlus:(s = 16, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="9" cy="8" r="3.5"/><path d="M3 20c0-3.5 3-5.5 6-5.5s6 2 6 5.5"/><path d="M18 7v6M21 10h-6"/></svg>),
  trash:   (s = 15, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 7h16M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13"/></svg>),
  cheers:  (s = 14, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 4h6l-1 12a2 2 0 0 1-2 2 2 2 0 0 1-2-2L5 4z"/><path d="M13 4h6l-1 12a2 2 0 0 1-2 2 2 2 0 0 1-2-2L13 4z"/><path d="M11 8h2"/><path d="M3 21h18"/></svg>),
  comment: (s = 14, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 12a8 8 0 0 1-12.1 6.9L4 20l1.1-4.9A8 8 0 1 1 21 12z"/></svg>),
  bolt:    (s = 12, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill={c}><path d="M13 2 4 14h7l-1 8 9-12h-7z"/></svg>),
  dots:    (s = 18, c = "currentColor") => (<svg width={s} height={s} viewBox="0 0 24 24" fill={c}><circle cx="5" cy="12" r="1.6"/><circle cx="12" cy="12" r="1.6"/><circle cx="19" cy="12" r="1.6"/></svg>),
};

// ── people ────────────────────────────────────────────────────
const ME = { id: "you", name: "You", handle: "@you", tone: "selfie" };
const PT_FRIENDS = [
  { id: "maya",  name: "Maya Calderón",   handle: "@mayac",  tone: "avatar", here: true, status: "Here with you" },
  { id: "theo",  name: "Theo Park",       handle: "@theop",  tone: "selfie", here: true, status: "Here with you" },
  { id: "priya", name: "Priya Anand",     handle: "@priyaa", tone: "avatar", status: "Online now" },
  { id: "jonas", name: "Jonas Lindqvist", handle: "@jlind",  tone: "selfie", status: "Poured 1h ago" },
  { id: "sam",   name: "Sam Okafor",      handle: "@samok",  tone: "avatar", status: "In your circle" },
  { id: "hana",  name: "Hana Tsuji",      handle: "@hanat",  tone: "selfie", status: "In your circle" },
  { id: "lena",  name: "Lena Bauer",      handle: "@lenab",  tone: "selfie", status: "In your circle" },
];
const byId = (id) => PT_FRIENDS.find(f => f.id === id);

// ── label helpers (driven by tweaks) ──────────────────────────
function joinNames(names) {
  if (names.length === 1) return names[0];
  if (names.length === 2) return `${names[0]} & ${names[1]}`;
  return `${names.slice(0, -1).join(", ")} & ${names[names.length - 1]}`;
}
// format: "amp" → "You & Maya" · "with" → "You · with Maya" · "plus" → "You + Maya"
function coLabel(format, coNames, { firstOnly = false } = {}) {
  const others = firstOnly ? coNames.map(n => n.split(" ")[0]) : coNames;
  if (format === "with") return `You · with ${joinNames(others)}`;
  if (format === "plus") return `You + ${joinNames(others)}`;
  return joinNames(["You", ...others]);
}

// ── overlapping avatar stack ──────────────────────────────────
function AvatarStack({ tones, size = 34, overlap = 12, ring }) {
  const T = React.useContext(window.ThemeContext);
  return (
    <div style={{ display: "flex", flexDirection: "row-reverse", alignItems: "center" }}>
      {[...tones].reverse().map((tone, i) => (
        <div key={i} style={{
          width: size, height: size, borderRadius: "50%", overflow: "hidden",
          marginRight: i === tones.length - 1 ? 0 : -overlap,
          border: `2px solid ${ring || T.bg}`,
          position: "relative", zIndex: i,
          boxShadow: "0 1px 4px rgba(0,0,0,0.3)",
        }}>
          <ImgPHpt tone={tone} label="" style={{ width: "100%", height: "100%" }} />
        </div>
      ))}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// Co-author picker — slides up over the describe step
// ═══════════════════════════════════════════════════════════════
function CoAuthorPicker({ T, selectedIds, onToggle, onDone, onClose }) {
  const [query, setQuery] = usePT("");
  const q = query.trim().toLowerCase();
  const match = (f) => !q || f.name.toLowerCase().includes(q) || f.handle.toLowerCase().includes(q);

  const here   = PT_FRIENDS.filter(f => f.here && match(f));
  const others = PT_FRIENDS.filter(f => !f.here && match(f));
  const count = selectedIds.length;

  return (
    <div style={{
      position: "absolute", inset: 0, zIndex: 60, display: "flex", flexDirection: "column",
      background: "rgba(0,0,0,0.55)", backdropFilter: "blur(2px)",
    }} onClick={onClose}>
      <div style={{ flex: "0 0 56px" }} />
      <div onClick={(e) => e.stopPropagation()} style={{
        flex: 1, background: "#101012",
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        border: "1px solid rgba(255,255,255,0.08)", borderBottom: "none",
        display: "flex", flexDirection: "column", overflow: "hidden",
        boxShadow: "0 -20px 60px rgba(0,0,0,0.5)",
      }}>
        <div style={{ display: "grid", placeItems: "center", paddingTop: 10, paddingBottom: 4 }}>
          <div style={{ width: 38, height: 4, borderRadius: 999, background: "rgba(255,255,255,0.2)" }} />
        </div>

        {/* header */}
        <div style={{ padding: "8px 16px 12px", display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ flex: 1 }}>
            <div style={{ color: T.gold, fontSize: 10, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase" }}>Pour together</div>
            <div style={{ color: "#fff", fontSize: 18, fontWeight: 800, letterSpacing: "-0.02em", marginTop: 2 }}>Who's with you?</div>
          </div>
          <button onClick={onClose} style={iconBtn}>{PT.x(18)}</button>
        </div>

        {/* search */}
        <div style={{ padding: "0 16px 10px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "11px 14px", borderRadius: 14, background: "rgba(255,255,255,0.06)", border: "1px solid rgba(255,255,255,0.08)" }}>
            {PT.search(18, "rgba(255,255,255,0.5)")}
            <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search friends by name or @handle…" style={{ flex: 1, background: "transparent", border: "none", outline: "none", color: "#fff", fontSize: 15, fontFamily: "inherit" }} />
            {query && <button onClick={() => setQuery("")} style={{ background: "none", border: "none", color: "rgba(255,255,255,0.5)", cursor: "pointer", display: "grid", placeItems: "center", padding: 0 }}>{PT.x(16)}</button>}
          </div>
        </div>

        {/* list */}
        <div style={{ flex: 1, overflowY: "auto", padding: "2px 16px 8px" }}>
          {here.length > 0 && (
            <React.Fragment>
              <PickerSection T={T} dotted>Here with you · same place</PickerSection>
              {here.map(f => <FriendPick key={f.id} T={T} f={f} on={selectedIds.includes(f.id)} onClick={() => onToggle(f.id)} />)}
            </React.Fragment>
          )}
          {others.length > 0 && (
            <React.Fragment>
              <PickerSection T={T}>Your circle</PickerSection>
              {others.map(f => <FriendPick key={f.id} T={T} f={f} on={selectedIds.includes(f.id)} onClick={() => onToggle(f.id)} />)}
            </React.Fragment>
          )}
          {here.length === 0 && others.length === 0 && (
            <div style={{ textAlign: "center", padding: "30px 16px", color: "rgba(255,255,255,0.5)", fontSize: 14 }}>No friend matches “{query}”.</div>
          )}
        </div>

        {/* sticky done */}
        <div style={{ padding: "10px 16px calc(16px + env(safe-area-inset-bottom))", borderTop: "1px solid rgba(255,255,255,0.07)", background: "#101012" }}>
          <button onClick={onDone} disabled={count === 0} style={{
            width: "100%", padding: "15px", borderRadius: 18,
            background: count ? T.gold : "rgba(255,255,255,0.08)", border: "none",
            color: count ? T.goldInk : "rgba(255,255,255,0.35)",
            fontSize: 16, fontWeight: 800, letterSpacing: "-0.01em",
            cursor: count ? "pointer" : "default",
            display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
          }}>
            {count ? `Add ${count === 1 ? byId(selectedIds[0]).name.split(" ")[0] : count + " friends"}` : "Pick someone to pour with"}
          </button>
        </div>
      </div>
    </div>
  );
}

function PickerSection({ children, dotted }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "16px 4px 8px" }}>
      {dotted && <span style={{ width: 7, height: 7, borderRadius: "50%", background: "#F6B733", boxShadow: "0 0 0 3px rgba(246,183,51,0.18)" }} />}
      <span style={{ color: "rgba(255,255,255,0.45)", fontSize: 10, fontWeight: 700, letterSpacing: "0.16em", textTransform: "uppercase" }}>{children}</span>
    </div>
  );
}

function FriendPick({ T, f, on, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: "100%", display: "flex", alignItems: "center", gap: 12,
      padding: "9px 10px", borderRadius: 14, marginBottom: 2,
      background: on ? T.goldFaint : "transparent",
      border: `1px solid ${on ? T.goldBorder : "transparent"}`,
      cursor: "pointer", textAlign: "left",
    }}>
      <div style={{ width: 44, height: 44, borderRadius: "50%", overflow: "hidden", flexShrink: 0 }}>
        <ImgPHpt tone={f.tone} label="" style={{ width: "100%", height: "100%" }} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: "#fff", fontSize: 15, fontWeight: 600, letterSpacing: "-0.01em" }}>{f.name}</div>
        <div style={{ color: f.here ? T.gold : "rgba(255,255,255,0.5)", fontSize: 12, marginTop: 1, fontWeight: f.here ? 600 : 400 }}>{f.here ? "● " : ""}{f.status}</div>
      </div>
      <div style={{
        width: 24, height: 24, borderRadius: "50%", flexShrink: 0, display: "grid", placeItems: "center",
        background: on ? T.gold : "transparent",
        border: on ? "none" : "2px solid rgba(255,255,255,0.2)",
      }}>{on && PT.check(13, T.goldInk)}</div>
    </button>
  );
}

const iconBtn = { width: 34, height: 34, borderRadius: "50%", background: "rgba(255,255,255,0.08)", border: "none", color: "#fff", display: "grid", placeItems: "center", cursor: "pointer" };

// ═══════════════════════════════════════════════════════════════
// CREATE — describe step with the Pour Together card
// ═══════════════════════════════════════════════════════════════
function CreateScreen({ T, coIds, setCoIds, nameFormat, onPost }) {
  const [caption, setCaption] = usePT("");
  const [pickerOpen, setPickerOpen] = usePT(false);
  const [draft, setDraft] = usePT(coIds);          // selection inside the open picker
  const max = 140;
  const coFriends = coIds.map(byId).filter(Boolean);
  const hasCo = coFriends.length > 0;

  const openPicker = () => { setDraft(coIds); setPickerOpen(true); };
  const toggleDraft = (id) => setDraft(d => d.includes(id) ? d.filter(x => x !== id) : [...d, id]);
  const commitPicker = () => { setCoIds(draft); setPickerOpen(false); };

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%", color: "#fff", background: "#000" }}>
      {/* top bar */}
      <div style={{ padding: "8px 18px 14px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <button style={{ ...iconBtn, transform: "rotate(180deg)" }}>{PT.chevron(20)}</button>
        <div style={{ color: T.gold, fontSize: 11, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase", display: "inline-flex", alignItems: "center", gap: 6 }}>{PT.bolt(10, T.gold)} describe your pour</div>
        <div style={{ width: 34 }} />
      </div>

      <div style={{ flex: 1, overflowY: "auto", paddingBottom: 8 }}>
        {/* photo header */}
        <div style={{ padding: "0 18px", display: "flex", gap: 12, alignItems: "flex-start" }}>
          <div style={{ width: 84, height: 112, borderRadius: 14, overflow: "hidden", position: "relative", flexShrink: 0, background: "#000", border: "1px solid rgba(255,255,255,0.08)" }}>
            <ImgPHpt tone="pour" label="" style={{ position: "absolute", inset: 0 }} />
            <div style={{ position: "absolute", top: 5, left: 5, width: 28, height: 38, borderRadius: 6, overflow: "hidden", border: "1.5px solid #000", outline: "1px solid rgba(255,255,255,0.18)" }}>
              <ImgPHpt tone="selfie" label="" style={{ width: "100%", height: "100%" }} />
            </div>
          </div>
          <div style={{ flex: 1, paddingTop: 4 }}>
            <div style={{ color: "rgba(255,255,255,0.55)", fontSize: 11, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase" }}>Pour · just now</div>
            <div style={{ color: "#fff", fontSize: 18, fontWeight: 700, letterSpacing: "-0.02em", marginTop: 4, lineHeight: 1.2 }}>One glass,<br/>two names on it.</div>
          </div>
        </div>

        {/* ── POUR TOGETHER card (the feature) ── */}
        <div style={{ padding: "18px 18px 0" }}>
          {!hasCo ? (
            <button onClick={openPicker} style={{
              width: "100%", display: "flex", alignItems: "center", gap: 13,
              padding: "15px 16px", borderRadius: 18, textAlign: "left",
              background: T.goldFaint, border: `1.5px dashed ${T.goldBorderStrong}`,
              color: T.gold, cursor: "pointer",
            }}>
              <div style={{ width: 40, height: 40, borderRadius: 12, background: T.gold, display: "grid", placeItems: "center", flexShrink: 0 }}>{PT.userPlus(20, T.goldInk)}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 15, fontWeight: 800, letterSpacing: "-0.01em" }}>Pour together</div>
                <div style={{ fontSize: 12, color: "rgba(246,183,51,0.72)", marginTop: 2, lineHeight: 1.35 }}>Tag a friend who's here — the post lands on both your profiles.</div>
              </div>
              {PT.chevron(18, "rgba(246,183,51,0.7)")}
            </button>
          ) : (
            <div style={{ borderRadius: 18, background: T.goldFaint, border: `1px solid ${T.goldBorder}`, overflow: "hidden" }}>
              <div style={{ padding: "14px 16px", display: "flex", alignItems: "center", gap: 13 }}>
                <AvatarStack tones={[ME.tone, ...coFriends.map(f => f.tone)]} size={38} overlap={14} ring="#1a1407" />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ color: T.gold, fontSize: 10, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase" }}>Pouring together</div>
                  <div style={{ color: "#fff", fontSize: 15, fontWeight: 800, letterSpacing: "-0.01em", marginTop: 2, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{coLabel(nameFormat, coFriends.map(f => f.name))}</div>
                </div>
                <button onClick={openPicker} style={{ padding: "7px 12px", borderRadius: 999, background: "rgba(255,255,255,0.08)", border: "1px solid rgba(255,255,255,0.12)", color: "#fff", fontSize: 12, fontWeight: 700, cursor: "pointer" }}>Edit</button>
              </div>
              <div style={{ padding: "10px 16px", borderTop: `1px solid ${T.goldBorder}`, display: "flex", alignItems: "center", gap: 8, color: "rgba(246,183,51,0.85)", fontSize: 11.5, fontWeight: 600 }}>
                {PT.people(14, T.gold)} Appears on both your profiles · counts toward both streaks
              </div>
            </div>
          )}
        </div>

        {/* caption */}
        <div style={{ padding: "14px 18px 0" }}>
          <div style={{ padding: 16, borderRadius: 18, background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.08)" }}>
            <textarea value={caption} onChange={(e) => setCaption(e.target.value.slice(0, max))} placeholder={hasCo ? "Say something about this round…" : "Say something about this one…"} style={{ width: "100%", minHeight: 54, background: "transparent", border: "none", outline: "none", color: "#fff", fontSize: 16, lineHeight: 1.4, letterSpacing: "-0.01em", fontFamily: "inherit", resize: "none" }} />
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: 2 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 12, color: "rgba(255,255,255,0.5)" }}>
                <span>@mention</span><span style={{ width: 3, height: 3, borderRadius: "50%", background: "rgba(255,255,255,0.3)" }} /><span>#tag</span>
              </div>
              <div style={{ fontSize: 11, fontFamily: "ui-monospace, Menlo, monospace", color: caption.length > max - 20 ? T.gold : "rgba(255,255,255,0.4)" }}>{caption.length}/{max}</div>
            </div>
          </div>
        </div>

        {/* meta group */}
        <div style={{ padding: "14px 18px 0" }}>
          <div style={{ borderRadius: 18, background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.06)", overflow: "hidden" }}>
            <MetaRowPt T={T} icon={PT.glass(15, T.gold)} label="Drink" value="Half Acre Daisy Cutter" hint="APA · 5.2% · Half Acre" />
            <DividerPt />
            <MetaRowPt T={T} icon={PT.pin(15, T.gold)} label="Place" value="The Goose & Crown · SE15" hint="Auto · within 80m" />
            <DividerPt />
            <MetaRowPt T={T} icon={PT.people(15, T.gold)} label="Visible to" value="Friends only" hint="Both circles" trailing={
              <AvatarStack tones={["selfie", "avatar", "selfie"]} size={22} overlap={6} ring="#0c0c0e" />
            } />
          </div>
        </div>
      </div>

      {/* footer post button */}
      <div style={{ padding: "12px 18px calc(22px + env(safe-area-inset-bottom))", background: "#000" }}>
        <button onClick={() => onPost(caption)} style={{
          width: "100%", padding: "17px", borderRadius: 22,
          background: T.gold, border: "none", color: T.goldInk,
          fontSize: 17, fontWeight: 800, letterSpacing: "-0.01em", cursor: "pointer",
          display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 10,
        }}>
          {hasCo && <AvatarStack tones={[ME.tone, ...coFriends.map(f => f.tone)]} size={24} overlap={9} ring={T.gold} />}
          {hasCo ? "Pour it together" : "Pour it to your circle"}
        </button>
      </div>

      {pickerOpen && (
        <CoAuthorPicker T={T} selectedIds={draft} onToggle={toggleDraft} onDone={commitPicker} onClose={() => setPickerOpen(false)} />
      )}
    </div>
  );
}

function MetaRowPt({ T, icon, label, value, hint, trailing }) {
  return (
    <div style={{ width: "100%", display: "flex", alignItems: "center", gap: 12, padding: "13px 14px", color: "#fff" }}>
      <div style={{ width: 32, height: 32, borderRadius: 10, background: T.goldFaint, border: `1px solid ${T.goldBorder}`, display: "grid", placeItems: "center", flexShrink: 0 }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ color: "rgba(255,255,255,0.5)", fontSize: 10, fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase" }}>{label}</div>
        <div style={{ color: "#fff", fontSize: 14, fontWeight: 600, letterSpacing: "-0.01em", marginTop: 2, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{value}</div>
        {hint && <div style={{ color: "rgba(255,255,255,0.4)", fontSize: 11, marginTop: 1 }}>{hint}</div>}
      </div>
      {trailing || <div style={{ color: "rgba(255,255,255,0.35)" }}>{PT.chevron(16)}</div>}
    </div>
  );
}
function DividerPt() { return <div style={{ height: 1, background: "rgba(255,255,255,0.05)", marginLeft: 58 }} />; }

window.PourTogether = { PT, ME, PT_FRIENDS, byId, coLabel, joinNames, AvatarStack, CreateScreen, MetaRowPt, DividerPt, iconBtn };
