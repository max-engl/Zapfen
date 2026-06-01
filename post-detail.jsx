// Post detail / full-screen viewer for Pint.
// Opens when you tap a post. Features:
//   • Full-bleed photo with pinch + double-tap to zoom (mouse-wheel + drag also work)
//   • Selfie inset overlay (BeReal-style, like the feed)
//   • Floating reactions bar
//   • Threaded comments + composer

const { useState: useStatePD, useRef: useRefPD, useEffect: useEffectPD } = React;
const useTPD = () => React.useContext(window.ThemeContext);
const { Ico: IcoPD, ImgPH: ImgPHPD, Avatar: AvatarPD, BrandMark: BrandMarkPD } = window;

const IcoPD2 = {
  close: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 6 18 18M18 6 6 18"/>
    </svg>
  ),
  dots: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <circle cx="5" cy="12" r="1.7"/><circle cx="12" cy="12" r="1.7"/><circle cx="19" cy="12" r="1.7"/>
    </svg>
  ),
  cheers: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 4h6l-1 12a2 2 0 0 1-2 2 2 2 0 0 1-2-2L5 4z"/>
      <path d="M13 4h6l-1 12a2 2 0 0 1-2 2 2 2 0 0 1-2-2L13 4z"/>
      <path d="M11 8h2"/><path d="M3 21h18"/>
    </svg>
  ),
  send: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 2 11 13"/><path d="M22 2 15 22l-4-9-9-4 20-7z"/>
    </svg>
  ),
  pin: (s = 13, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s7-6.5 7-12a7 7 0 1 0-14 0c0 5.5 7 12 7 12z"/><circle cx="12" cy="10" r="2.5"/>
    </svg>
  ),
  zoomIn: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/><path d="M11 8v6M8 11h6"/>
    </svg>
  ),
  zoomOut: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/><path d="M8 11h6"/>
    </svg>
  ),
  reset: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/>
    </svg>
  ),
  flame: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22a6 6 0 0 0 6-6c0-4-3-6-3-9 0-1.5-1.5-3-3-3 0 4-6 6-6 12a6 6 0 0 0 6 6z"/>
    </svg>
  ),
  drop: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3s7 8 7 12a7 7 0 0 1-14 0c0-4 7-12 7-12z"/>
    </svg>
  ),
  laugh: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9"/>
      <path d="M8 14s1.5 3 4 3 4-3 4-3"/>
      <path d="M9 9h.01"/><path d="M15 9h.01"/>
    </svg>
  ),
  eye: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>
    </svg>
  ),
};

// ───────────────────────────────────────────
// Zoomable image area
// ───────────────────────────────────────────
function ZoomableImage({ post }) {
  const T = useTPD();
  const wrapRef = useRefPD(null);
  const [scale, setScale] = useStatePD(1);
  const [offset, setOffset] = useStatePD({ x: 0, y: 0 });
  const [dragging, setDragging] = useStatePD(false);
  const dragStart = useRefPD({ x: 0, y: 0, ox: 0, oy: 0 });
  const lastTap = useRefPD(0);
  const pinchRef = useRefPD(null);

  const MIN_S = 1, MAX_S = 4;
  const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

  const setScaleAround = (newScale, cx, cy) => {
    if (!wrapRef.current) return;
    const rect = wrapRef.current.getBoundingClientRect();
    const localX = (cx - rect.left) - rect.width / 2;
    const localY = (cy - rect.top) - rect.height / 2;
    const s = clamp(newScale, MIN_S, MAX_S);
    // adjust offset so the point under the cursor stays under it
    setOffset(prev => {
      const dx = (localX - prev.x) * (s / scale - 1);
      const dy = (localY - prev.y) * (s / scale - 1);
      let nx = prev.x - dx, ny = prev.y - dy;
      // constrain
      const maxOff = (rect.width * (s - 1)) / 2;
      const maxOffY = (rect.height * (s - 1)) / 2;
      nx = clamp(nx, -maxOff, maxOff);
      ny = clamp(ny, -maxOffY, maxOffY);
      if (s === 1) return { x: 0, y: 0 };
      return { x: nx, y: ny };
    });
    setScale(s);
  };

  const reset = () => { setScale(1); setOffset({ x: 0, y: 0 }); };

  const onWheel = (e) => {
    e.preventDefault();
    const delta = -e.deltaY * 0.003;
    setScaleAround(scale * (1 + delta), e.clientX, e.clientY);
  };

  const onDoubleTap = (e) => {
    if (scale > 1) reset();
    else setScaleAround(2.5, e.clientX, e.clientY);
  };

  const onPointerDown = (e) => {
    // detect double-tap
    const now = Date.now();
    if (now - lastTap.current < 280 && scale === 1) {
      onDoubleTap(e);
      lastTap.current = 0;
      return;
    }
    lastTap.current = now;
    if (scale === 1) return;
    setDragging(true);
    dragStart.current = { x: e.clientX, y: e.clientY, ox: offset.x, oy: offset.y };
    e.currentTarget.setPointerCapture && e.currentTarget.setPointerCapture(e.pointerId);
  };
  const onPointerMove = (e) => {
    if (!dragging || !wrapRef.current) return;
    const rect = wrapRef.current.getBoundingClientRect();
    const maxOff = (rect.width * (scale - 1)) / 2;
    const maxOffY = (rect.height * (scale - 1)) / 2;
    setOffset({
      x: clamp(dragStart.current.ox + (e.clientX - dragStart.current.x), -maxOff, maxOff),
      y: clamp(dragStart.current.oy + (e.clientY - dragStart.current.y), -maxOffY, maxOffY),
    });
  };
  const onPointerUp = () => setDragging(false);

  return (
    <div style={{
      position: "relative",
      background: "#000",
      width: "100%", height: "100%",
      overflow: "hidden",
      touchAction: scale > 1 ? "none" : "pan-y",
    }} ref={wrapRef}
       onWheel={onWheel}
       onPointerDown={onPointerDown}
       onPointerMove={onPointerMove}
       onPointerUp={onPointerUp}
       onPointerCancel={onPointerUp}
    >
      <div style={{
        position: "absolute", inset: 0,
        transform: `translate(${offset.x}px, ${offset.y}px) scale(${scale})`,
        transformOrigin: "center center",
        transition: dragging ? "none" : "transform 0.22s cubic-bezier(.2,.8,.2,1)",
        willChange: "transform",
      }}>
        <ImgPHPD tone={post.tone || "beer"} label={post.drink} style={{ width: "100%", height: "100%" }}/>
      </div>

      {/* Selfie inset (BeReal style) — hide while zoomed in */}
      <div style={{
        position: "absolute", top: 14, right: 14,
        width: 88, height: 116, borderRadius: 14,
        overflow: "hidden",
        border: "2px solid rgba(255,255,255,0.85)",
        boxShadow: "0 10px 24px rgba(0,0,0,0.55)",
        opacity: scale > 1.05 ? 0 : 1,
        transform: scale > 1.05 ? "scale(0.9)" : "scale(1)",
        transition: "opacity 0.2s, transform 0.2s",
        pointerEvents: scale > 1.05 ? "none" : "auto",
      }}>
        <ImgPHPD tone={post.selfieTone || "selfie"} label="selfie" style={{ width: "100%", height: "100%" }}/>
      </div>

      {/* Late pour ribbon */}
      {post.late && (
        <div style={{
          position: "absolute", top: 14, left: 14,
          padding: "5px 10px", borderRadius: 999,
          background: "rgba(0,0,0,0.6)",
          backdropFilter: "blur(8px)",
          WebkitBackdropFilter: "blur(8px)",
          color: "#f6b733", fontSize: 11, fontWeight: 700,
          letterSpacing: "0.12em", textTransform: "uppercase",
          display: "inline-flex", alignItems: "center", gap: 5,
          opacity: scale > 1.05 ? 0 : 1, transition: "opacity 0.2s",
        }}>{IcoPD.bolt(10, "#f6b733")} late pour</div>
      )}

      {/* Zoom controls */}
      <div style={{
        position: "absolute", left: 14, bottom: 14,
        display: "flex", flexDirection: "column", gap: 8,
        zIndex: 5,
      }}>
        <button onClick={() => setScale(s => clamp(s + 0.5, MIN_S, MAX_S))} style={zoomBtnStyle}>{IcoPD2.zoomIn(16, "#fff")}</button>
        <button onClick={() => { const ns = clamp(scale - 0.5, MIN_S, MAX_S); setScale(ns); if (ns === 1) setOffset({x:0, y:0}); }} style={zoomBtnStyle}>{IcoPD2.zoomOut(16, "#fff")}</button>
        {scale > 1 && (
          <button onClick={reset} style={zoomBtnStyle}>{IcoPD2.reset(16, "#fff")}</button>
        )}
      </div>

      {/* Zoom level indicator */}
      {scale > 1 && (
        <div style={{
          position: "absolute", right: 14, bottom: 14,
          padding: "5px 10px", borderRadius: 999,
          background: "rgba(0,0,0,0.6)",
          backdropFilter: "blur(8px)",
          WebkitBackdropFilter: "blur(8px)",
          color: "#fff", fontSize: 11, fontWeight: 700,
          fontFamily: "ui-monospace, Menlo, monospace",
          letterSpacing: "0.06em",
        }}>{scale.toFixed(1)}×</div>
      )}

      {/* hint on first view */}
      {scale === 1 && (
        <div style={{
          position: "absolute", bottom: 14, left: "50%", transform: "translateX(-50%)",
          padding: "6px 10px", borderRadius: 999,
          background: "rgba(0,0,0,0.55)",
          backdropFilter: "blur(8px)",
          WebkitBackdropFilter: "blur(8px)",
          color: "rgba(255,255,255,0.85)", fontSize: 11, fontWeight: 600,
          letterSpacing: "0.04em",
          display: "inline-flex", alignItems: "center", gap: 5,
        }}>
          {IcoPD2.zoomIn(12, "rgba(255,255,255,0.85)")}
          double-tap or scroll to zoom
        </div>
      )}
    </div>
  );
}

const zoomBtnStyle = {
  width: 36, height: 36, borderRadius: "50%",
  background: "rgba(0,0,0,0.55)",
  backdropFilter: "blur(8px)",
  WebkitBackdropFilter: "blur(8px)",
  border: "1px solid rgba(255,255,255,0.18)",
  color: "#fff", display: "grid", placeItems: "center",
  cursor: "pointer", padding: 0,
};

// ───────────────────────────────────────────
// Reactions
// ───────────────────────────────────────────
const REACTIONS = [
  { id: "cheers", label: "Cheers", icon: IcoPD2.cheers,  color: "#F6B733" },
  { id: "fire",   label: "Fire",   icon: IcoPD2.flame,   color: "#F2742A" },
  { id: "drop",   label: "Refresh",icon: IcoPD2.drop,    color: "#5BC0EB" },
  { id: "lol",    label: "Lol",    icon: IcoPD2.laugh,   color: "#E6C24B" },
];

function ReactionBar({ counts, mine, onReact }) {
  const T = useTPD();
  return (
    <div style={{
      display: "flex", gap: 8, padding: "12px 16px",
      borderBottom: `1px solid ${T.divider}`,
      overflowX: "auto",
    }}>
      {REACTIONS.map(r => {
        const isMine = mine[r.id];
        const count = counts[r.id] || 0;
        return (
          <button key={r.id} onClick={() => onReact(r.id)} style={{
            padding: "9px 12px", borderRadius: 999,
            background: isMine ? r.color + "26" : T.surfaceWeak,
            border: `1px solid ${isMine ? r.color : T.border}`,
            color: isMine ? r.color : T.text,
            fontSize: 13, fontWeight: 700,
            display: "inline-flex", alignItems: "center", gap: 6,
            cursor: "pointer", fontFamily: "inherit",
            flexShrink: 0,
            transition: "all 0.15s",
            transform: isMine ? "translateY(-1px)" : "none",
          }}>
            {r.icon(16, isMine ? r.color : T.text)}
            <span>{r.label}</span>
            {count > 0 && (
              <span style={{
                padding: "1px 7px", borderRadius: 999,
                background: isMine ? r.color : T.surfaceWeaker,
                color: isMine ? "#241600" : T.textMuted,
                fontSize: 11, fontWeight: 800,
              }}>{count}</span>
            )}
          </button>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────
// Comments
// ───────────────────────────────────────────
const SEED_COMMENTS = [
  { id: "c1", name: "Theo Park",      handle: "@theop",   time: "8m",  text: "ok the lacing on that head. respect.", tone: "selfie", cheers: 3, mine: false },
  { id: "c2", name: "Priya Anand",    handle: "@priyaa",  time: "6m",  text: "i refuse to believe this is your first one.", tone: "avatar", cheers: 1, mine: false },
  { id: "c3", name: "Jonas Lindqvist",handle: "@jlind",   time: "4m",  text: "Goose & Crown >>>", tone: "selfie", cheers: 0, mine: false },
  { id: "c4", name: "Maya Calderón",  handle: "@mayac",   time: "3m",  text: "the run earned at least three.", tone: "avatar", cheers: 5, mine: false, pinned: true },
];

function CommentRow({ c, onCheers, mineCheered }) {
  const T = useTPD();
  return (
    <div style={{
      padding: "12px 16px",
      display: "flex", gap: 10,
      borderBottom: `1px solid ${T.divider}`,
    }}>
      <AvatarPD tone={c.tone} size={34}/>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 6 }}>
          <span style={{ color: T.text, fontSize: 13, fontWeight: 700, letterSpacing: "-0.01em" }}>{c.name}</span>
          {c.pinned && (
            <span style={{
              padding: "1px 6px", borderRadius: 6,
              background: T.goldSoft, color: T.goldText,
              fontSize: 9, fontWeight: 800, letterSpacing: "0.1em", textTransform: "uppercase",
            }}>OP</span>
          )}
          <span style={{ color: T.textFaint, fontSize: 11 }}>· {c.time}</span>
        </div>
        <div style={{
          color: T.text, fontSize: 14, marginTop: 3, lineHeight: 1.45,
          letterSpacing: "-0.01em",
        }}>{c.text}</div>
        <div style={{
          display: "flex", alignItems: "center", gap: 14,
          marginTop: 6,
        }}>
          <button onClick={() => onCheers(c.id)} style={{
            background: "transparent", border: "none", padding: 0,
            color: mineCheered ? "#F6B733" : T.textMuted,
            fontSize: 12, fontWeight: 700, cursor: "pointer",
            display: "inline-flex", alignItems: "center", gap: 4,
            fontFamily: "inherit",
          }}>
            {IcoPD2.cheers(13, mineCheered ? "#F6B733" : T.textMuted)}
            {(c.cheers + (mineCheered ? 1 : 0)) || ""}
          </button>
          <button style={{
            background: "transparent", border: "none", padding: 0,
            color: T.textMuted, fontSize: 12, fontWeight: 600, cursor: "pointer",
            fontFamily: "inherit",
          }}>Reply</button>
        </div>
      </div>
    </div>
  );
}

function Composer({ onSend }) {
  const T = useTPD();
  const [text, setText] = useStatePD("");
  const send = () => {
    if (!text.trim()) return;
    onSend(text.trim());
    setText("");
  };
  return (
    <div style={{
      padding: "10px 14px 24px",
      borderTop: `1px solid ${T.border}`,
      background: T.bg,
      display: "flex", alignItems: "center", gap: 10,
    }}>
      <AvatarPD tone="avatar" size={32}/>
      <div style={{
        flex: 1, display: "flex", alignItems: "center", gap: 6,
        padding: "10px 14px", borderRadius: 999,
        background: T.surfaceWeak,
        border: `1px solid ${T.border}`,
      }}>
        <input
          value={text}
          onChange={e => setText(e.target.value)}
          onKeyDown={e => e.key === "Enter" && send()}
          placeholder="Pour a comment…"
          style={{
            flex: 1, border: "none", outline: "none",
            background: "transparent",
            color: T.text, fontSize: 14, fontWeight: 500,
            letterSpacing: "-0.01em", fontFamily: "inherit",
          }}
        />
      </div>
      <button onClick={send} disabled={!text.trim()} style={{
        width: 40, height: 40, borderRadius: "50%",
        background: text.trim() ? T.gold : T.surfaceWeak,
        border: text.trim() ? "none" : `1px solid ${T.border}`,
        color: text.trim() ? T.goldInk : T.textFaint,
        display: "grid", placeItems: "center",
        cursor: text.trim() ? "pointer" : "not-allowed",
        flexShrink: 0,
      }}>{IcoPD2.send(17, text.trim() ? T.goldInk : T.textFaint)}</button>
    </div>
  );
}

// ───────────────────────────────────────────
// Floating header
// ───────────────────────────────────────────
function PostHeader({ post, onClose }) {
  const T = useTPD();
  return (
    <div style={{
      position: "absolute", top: 0, left: 0, right: 0,
      paddingTop: 54, zIndex: 20,
      background: "linear-gradient(180deg, rgba(0,0,0,0.55), transparent)",
      pointerEvents: "none",
    }}>
      <div style={{
        display: "flex", alignItems: "center", gap: 10,
        padding: "10px 12px 18px",
        pointerEvents: "auto",
      }}>
        <button onClick={onClose} style={{
          width: 38, height: 38, borderRadius: "50%",
          background: "rgba(0,0,0,0.5)",
          backdropFilter: "blur(8px)",
          WebkitBackdropFilter: "blur(8px)",
          border: "1px solid rgba(255,255,255,0.18)",
          color: "#fff", display: "grid", placeItems: "center",
          cursor: "pointer", flexShrink: 0,
        }}>{IcoPD2.close(20, "#fff")}</button>
        <div style={{ flex: 1, display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}>
          <AvatarPD tone={post.selfieTone || "selfie"} size={38} ring/>
          <div style={{ minWidth: 0, flex: 1 }}>
            <div style={{
              color: "#fff", fontSize: 14, fontWeight: 700, letterSpacing: "-0.01em",
              textShadow: "0 2px 6px rgba(0,0,0,0.6)",
              whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
            }}>{post.name}</div>
            <div style={{
              color: "rgba(255,255,255,0.78)", fontSize: 11, fontWeight: 500,
              textShadow: "0 1px 4px rgba(0,0,0,0.6)",
              display: "inline-flex", alignItems: "center", gap: 4,
              whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              maxWidth: "100%",
            }}>
              {post.handle} · {post.time}
            </div>
          </div>
        </div>
        <button style={{
          width: 38, height: 38, borderRadius: "50%",
          background: "rgba(0,0,0,0.5)",
          backdropFilter: "blur(8px)",
          WebkitBackdropFilter: "blur(8px)",
          border: "1px solid rgba(255,255,255,0.18)",
          color: "#fff", display: "grid", placeItems: "center",
          cursor: "pointer", flexShrink: 0,
        }}>{IcoPD2.dots(20, "#fff")}</button>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Main full-screen post detail
// ───────────────────────────────────────────
function PostDetailScreen({ theme = "dark", post: postProp, onClose, embedded = false }) {
  const T = window.THEMES[theme] || window.THEMES.dark;

  const post = postProp || {
    id: "p1", name: "Maya Calderón", handle: "@mayac", time: "12m",
    place: "The Goose & Crown · SE15", drink: "Hazy Pale · 5.2%",
    caption: "first one after the marathon. earned.",
    cheers: 24, comments: 6, mine: false,
    tone: "beer", selfieTone: "selfie", late: false,
    views: 142,
  };

  const [reactionCounts, setReactionCounts] = useStatePD({ cheers: post.cheers, fire: 7, drop: 2, lol: 0 });
  const [mine, setMine] = useStatePD({});
  const [comments, setComments] = useStatePD(SEED_COMMENTS);
  const [commentCheers, setCommentCheers] = useStatePD({});

  const onReact = (id) => {
    setMine(prev => {
      const wasOn = !!prev[id];
      return { ...prev, [id]: !wasOn };
    });
    setReactionCounts(prev => ({
      ...prev,
      [id]: (prev[id] || 0) + (mine[id] ? -1 : 1),
    }));
  };

  const onSend = (text) => {
    setComments(prev => [
      ...prev,
      { id: `mine-${Date.now()}`, name: "You", handle: "@you", time: "now", text, tone: "avatar", cheers: 0, mine: true },
    ]);
  };

  const inner = (
    <div data-screen-label={`Post Detail · ${theme}`} style={{
      height: "100%",
      background: T.bg,
      color: T.text,
      fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
      position: "relative",
      display: "flex", flexDirection: "column",
    }}>
          {/* Image section — fixed aspect */}
          <div style={{
            position: "relative",
            width: "100%",
            height: 460,
            flexShrink: 0,
            background: "#000",
          }}>
            <PostHeader post={post} onClose={onClose || (() => {})} />
            <ZoomableImage post={post} />
          </div>

          {/* Caption + meta strip */}
          <div style={{
            padding: "12px 16px 4px",
            borderBottom: `1px solid ${T.divider}`,
            background: T.bg,
          }}>
            <div style={{
              display: "flex", alignItems: "center", gap: 8, marginBottom: 8,
            }}>
              <div style={{
                padding: "3px 9px", borderRadius: 999,
                background: T.goldSoft,
                border: `1px solid ${T.goldBorder}`,
                color: T.goldText, fontSize: 11, fontWeight: 800,
                letterSpacing: "-0.01em",
              }}>{post.drink}</div>
              <div style={{
                color: T.textMuted, fontSize: 11, fontWeight: 500,
                display: "inline-flex", alignItems: "center", gap: 4,
                whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              }}>
                {IcoPD2.pin(12, T.textMuted)} {post.place}
              </div>
            </div>
            <div style={{
              color: T.text, fontSize: 14, lineHeight: 1.45,
              letterSpacing: "-0.01em",
            }}>
              <span style={{ fontWeight: 700 }}>{post.handle}</span>{" "}
              {post.caption}
            </div>
            <div style={{
              display: "flex", alignItems: "center", gap: 14,
              marginTop: 10, marginBottom: 8,
              color: T.textMuted, fontSize: 11, fontWeight: 600,
            }}>
              <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
                {IcoPD2.eye(12, T.textMuted)} {post.views || 142} viewed
              </span>
              <span>{Object.values(reactionCounts).reduce((a,b)=>a+b,0)} reactions</span>
              <span>{comments.length} comments</span>
            </div>
          </div>

          <ReactionBar counts={reactionCounts} mine={mine} onReact={onReact}/>

          {/* Comments scroller */}
          <div style={{ flex: 1, overflowY: "auto", paddingBottom: 8 }}>
            <div style={{
              padding: "12px 16px 6px",
              color: T.textMuted, fontSize: 11, fontWeight: 700,
              letterSpacing: "0.16em", textTransform: "uppercase",
            }}>Comments</div>
            {comments.map(c => (
              <CommentRow
                key={c.id}
                c={c}
                onCheers={(id) => setCommentCheers(p => ({ ...p, [id]: !p[id] }))}
                mineCheered={!!commentCheers[c.id]}
              />
            ))}
            <div style={{
              padding: "16px", textAlign: "center",
              color: T.textFaint, fontSize: 11,
            }}>End of pour</div>
          </div>

          <Composer onSend={onSend}/>
        </div>
  );

  if (embedded) {
    return (
      <window.ThemeContext.Provider value={T}>
        {inner}
      </window.ThemeContext.Provider>
    );
  }
  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        {inner}
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

Object.assign(window, { PostDetailScreen });
