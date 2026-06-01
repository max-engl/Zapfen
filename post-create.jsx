// Post Create flow for Pint.
// Three connected stages of a single full-screen sheet:
//   1. "aim"      — dual-camera preview (drink + selfie), big shutter, countdown
//   2. "review"   — both shots captured, retake/keep chrome
//   3. "describe" — captured pair locked in, write caption + tag drink/place/audience

const { useState: usePC, useEffect: usePCE, useRef: usePCR } = React;
const useTPC = () => React.useContext(window.ThemeContext);
const { Ico: IcoPC, ImgPH: ImgPHPC, Avatar: AvatarPC, BrandMark: BrandMarkPC, GoldPill: GoldPillPC } = window;

// Extra glyphs not in the main Ico set
const IcoPC2 = {
  swap: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M16 3h5v5"/><path d="M4 20 21 3"/>
      <path d="M21 16v5h-5"/><path d="M15 15l6 6"/>
      <path d="M4 4l5 5"/><path d="M3 9V4h5"/>
    </svg>
  ),
  retake: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/>
    </svg>
  ),
  pin: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 22s7-6.5 7-12a7 7 0 1 0-14 0c0 5.5 7 12 7 12z"/><circle cx="12" cy="10" r="2.5"/>
    </svg>
  ),
  glass: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 3h12l-1.2 13a3 3 0 0 1-3 2.7H10.2a3 3 0 0 1-3-2.7z"/>
      <path d="M7 8h10"/>
    </svg>
  ),
  people: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="9" cy="9" r="3.5"/><circle cx="17" cy="10" r="2.5"/>
      <path d="M3 20c0-3 3-5 6-5s6 2 6 5"/><path d="M15 20c0-2.5 2-4 4-4"/>
    </svg>
  ),
  chevron: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m9 6 6 6-6 6"/>
    </svg>
  ),
  check: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12l5 5L20 7"/>
    </svg>
  ),
  flash: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M13 2 4 14h7l-1 8 9-12h-7z"/>
    </svg>
  ),
  flashOff: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M13 2 4 14h7l-1 8 9-12h-7z"/>
      <path d="M3 3l18 18"/>
    </svg>
  ),
  timer: (s = 20, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2"/><path d="M9 2h6"/>
    </svg>
  ),
  x: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 6 18 18M18 6 6 18"/>
    </svg>
  ),
  bolt: (s = 12, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M13 2 4 14h7l-1 8 9-12h-7z"/>
    </svg>
  ),
};

// ───────────────────────────────────────────
// The dual-photo frame: main shot + selfie inset.
// Used live in stage="aim" and frozen in "review"/"describe".
// ───────────────────────────────────────────
function DualFrame({ T, captured, selfieCorner = "tl", showCorners = false, ringPulse = false, scale = 1 }) {
  const insetPos = {
    tl: { top: 14, left: 14 },
    tr: { top: 14, right: 14 },
    bl: { bottom: 14, left: 14 },
    br: { bottom: 14, right: 14 },
  }[selfieCorner];

  const selfieW = 96 * scale;
  const selfieH = 128 * scale;

  return (
    <div style={{
      position: "relative",
      width: "100%", aspectRatio: "3 / 4",
      borderRadius: 28, overflow: "hidden",
      background: "#000",
      boxShadow: "0 24px 60px -20px rgba(0,0,0,0.5)",
    }}>
      <ImgPHPC tone="pour" label={captured ? "" : "point at your drink"} style={{ position: "absolute", inset: 0 }} />

      {/* aiming guide */}
      {!captured && (
        <React.Fragment>
          <div style={{
            position: "absolute", inset: 28,
            border: "1.5px dashed rgba(255,255,255,0.35)",
            borderRadius: 22,
          }} />
          {[
            { top: 16, left: 16 }, { top: 16, right: 16 },
            { bottom: 16, left: 16 }, { bottom: 16, right: 16 },
          ].map((s, i) => (
            <div key={i} style={{
              position: "absolute", width: 22, height: 22,
              borderTop: i < 2 ? "2.5px solid #fff" : "none",
              borderBottom: i >= 2 ? "2.5px solid #fff" : "none",
              borderLeft: (i % 2 === 0) ? "2.5px solid #fff" : "none",
              borderRight: (i % 2 === 1) ? "2.5px solid #fff" : "none",
              borderRadius: 4,
              ...s,
            }} />
          ))}
          <div style={{
            position: "absolute", top: "50%", left: "50%",
            transform: "translate(-50%, -50%)",
            width: 26, height: 26, borderRadius: "50%",
            border: "1.5px solid rgba(255,255,255,0.7)",
            display: "grid", placeItems: "center",
          }}>
            <div style={{ width: 5, height: 5, borderRadius: "50%", background: "rgba(255,255,255,0.85)" }} />
          </div>
        </React.Fragment>
      )}

      {/* selfie inset */}
      <div style={{
        position: "absolute",
        width: selfieW, height: selfieH,
        borderRadius: 14, overflow: "hidden",
        border: "2px solid #000",
        outline: "1px solid rgba(255,255,255,0.18)",
        boxShadow: ringPulse ? "0 0 0 3px rgba(246,183,51,0.55)" : "0 8px 20px rgba(0,0,0,0.4)",
        transition: "box-shadow 0.2s",
        ...insetPos,
      }}>
        <ImgPHPC tone="selfie" label={captured ? "" : "you"} style={{ width: "100%", height: "100%" }} />
        {/* dual-cam indicator */}
        <div style={{
          position: "absolute", bottom: 6, left: 6,
          padding: "2px 6px", borderRadius: 999,
          background: "rgba(0,0,0,0.7)",
          color: "#fff", fontSize: 8, fontWeight: 700,
          letterSpacing: "0.1em",
        }}>FRONT</div>
      </div>

      {/* "live" badge on main cam */}
      {!captured && (
        <div style={{
          position: "absolute", top: 14,
          left: selfieCorner === "tl" ? "auto" : 14,
          right: selfieCorner === "tl" ? 14 : "auto",
          display: "inline-flex", alignItems: "center", gap: 6,
          padding: "4px 10px", borderRadius: 999,
          background: "rgba(0,0,0,0.7)",
          color: "#fff", fontSize: 10, fontWeight: 700,
          letterSpacing: "0.1em",
        }}>
          <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#ef4444" }} />
          REAR · LIVE
        </div>
      )}

      {/* gold ring on captured pair */}
      {captured && (
        <div style={{
          position: "absolute", top: 14, right: 14,
          padding: "4px 10px", borderRadius: 999,
          background: T.gold, color: T.goldInk,
          fontSize: 10, fontWeight: 800, letterSpacing: "0.1em",
          display: "inline-flex", alignItems: "center", gap: 4,
        }}>
          {IcoPC2.check(11, T.goldInk)} CAPTURED
        </div>
      )}
    </div>
  );
}

// ───────────────────────────────────────────
// Camera chrome top bar (close, label, settings)
// ───────────────────────────────────────────
function CamTopBar({ T, label, sub, onClose }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "0 18px",
    }}>
      <button onClick={onClose} style={{
        width: 38, height: 38, borderRadius: "50%",
        background: "rgba(255,255,255,0.1)",
        border: "none", color: "#fff", display: "grid", placeItems: "center",
        cursor: "pointer",
      }}>{IcoPC2.x(20)}</button>

      <div style={{ textAlign: "center" }}>
        <div style={{
          display: "inline-flex", alignItems: "center", gap: 6,
          color: T.gold, fontSize: 11, fontWeight: 700,
          letterSpacing: "0.14em", textTransform: "uppercase",
        }}>{IcoPC2.bolt(10, T.gold)} {label}</div>
        {sub && (
          <div style={{ color: "rgba(255,255,255,0.55)", fontSize: 11, marginTop: 3 }}>
            {sub}
          </div>
        )}
      </div>

      <button style={{
        width: 38, height: 38, borderRadius: "50%",
        background: "rgba(255,255,255,0.1)",
        border: "none", color: "#fff", display: "grid", placeItems: "center",
        cursor: "pointer",
      }}>{IcoPC2.flash(18)}</button>
    </div>
  );
}

// ───────────────────────────────────────────
// Mode rail just above the shutter (live | timer | mirror)
// ───────────────────────────────────────────
function ModeRail({ T, selfieCorner, setSelfieCorner }) {
  const corners = [
    { id: "tl", label: "↖" },
    { id: "tr", label: "↗" },
    { id: "bl", label: "↙" },
    { id: "br", label: "↘" },
  ];
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 8,
      padding: "12px 18px",
      justifyContent: "center",
    }}>
      <div style={{
        display: "inline-flex", alignItems: "center", gap: 6,
        padding: "6px 14px", borderRadius: 999,
        background: "rgba(255,255,255,0.06)",
        border: "1px solid rgba(255,255,255,0.06)",
        color: "rgba(255,255,255,0.7)",
        fontSize: 11, fontWeight: 700, letterSpacing: "0.14em",
      }}>
        <span style={{ width: 6, height: 6, borderRadius: "50%", background: T.gold }} />
        DUAL CAPTURE · REAR + FRONT
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Bottom control row (swap, shutter, gallery)
// ───────────────────────────────────────────
function CamControls({ T, onShutter }) {
  return (
    <div style={{
      padding: "8px 32px 30px",
      display: "flex", alignItems: "center", justifyContent: "space-between",
    }}>
      <button style={{
        width: 56, height: 56, borderRadius: 16,
        background: "rgba(255,255,255,0.08)",
        border: "1px solid rgba(255,255,255,0.08)",
        color: "#fff", display: "grid", placeItems: "center",
        cursor: "pointer",
        overflow: "hidden", padding: 0,
      }}>
        <ImgPHPC tone="bar" label="" style={{ width: "100%", height: "100%" }} />
      </button>

      <button onClick={onShutter} style={{
        width: 84, height: 84, borderRadius: "50%",
        background: "transparent",
        border: "4px solid #fff",
        cursor: "pointer", position: "relative",
        padding: 0,
      }}>
        <div style={{
          position: "absolute", inset: 6, borderRadius: "50%",
          background: T.gold,
          display: "grid", placeItems: "center",
        }}>
          <div style={{
            width: 12, height: 12, borderRadius: 3,
            background: T.goldInk, opacity: 0.18,
          }} />
        </div>
      </button>

      <button style={{
        width: 56, height: 56, borderRadius: 16,
        background: "rgba(255,255,255,0.08)",
        border: "1px solid rgba(255,255,255,0.08)",
        color: "#fff", display: "grid", placeItems: "center",
        cursor: "pointer", flexDirection: "column", gap: 2,
      }}>
        {IcoPC2.swap(22, "#fff")}
        <div style={{ fontSize: 8, fontWeight: 700, letterSpacing: "0.08em", color: "rgba(255,255,255,0.6)" }}>FLIP</div>
      </button>
    </div>
  );
}

// ───────────────────────────────────────────
// Stage 1: Aim
// ───────────────────────────────────────────
function StageAim({ T, onClose, onShutter }) {
  const [corner, setCorner] = usePC("tl");
  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%", color: "#fff" }}>
      <div style={{ paddingTop: 8, paddingBottom: 12 }}>
        <CamTopBar T={T} label="pour now" sub="prompt closes in 84m" onClose={onClose} />
      </div>

      <div style={{ flex: 1, padding: "0 18px", display: "flex", alignItems: "center" }}>
        <DualFrame T={T} captured={false} selfieCorner={corner} />
      </div>

      <ModeRail T={T} selfieCorner={corner} setSelfieCorner={setCorner} />

      <CamControls T={T} onShutter={onShutter} />
    </div>
  );
}

// ───────────────────────────────────────────
// Stage 2: Review (retake / keep)
// ───────────────────────────────────────────
function StageReview({ T, onRetake, onKeep, onClose }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%", color: "#fff" }}>
      <div style={{ paddingTop: 8, paddingBottom: 14 }}>
        <CamTopBar T={T} label="captured" sub="2 of 2 · rear + front" onClose={onClose} />
      </div>

      <div style={{ flex: 1, padding: "0 18px", display: "flex", alignItems: "center" }}>
        <DualFrame T={T} captured={true} selfieCorner="tl" ringPulse />
      </div>

      <div style={{
        padding: "18px 18px 8px",
        display: "flex", alignItems: "center", justifyContent: "center", gap: 8,
      }}>
        <button style={{
          padding: "8px 14px", borderRadius: 999,
          background: "rgba(255,255,255,0.08)",
          border: "1px solid rgba(255,255,255,0.08)",
          color: "rgba(255,255,255,0.85)",
          fontSize: 12, fontWeight: 600, cursor: "pointer",
        }}>2 retakes left today</button>
      </div>

      <div style={{
        padding: "8px 24px 30px",
        display: "flex", alignItems: "center", gap: 12,
      }}>
        <button onClick={onRetake} style={{
          flex: 1, padding: "16px",
          borderRadius: 18,
          background: "rgba(255,255,255,0.08)",
          border: "1px solid rgba(255,255,255,0.1)",
          color: "#fff", fontSize: 15, fontWeight: 700,
          letterSpacing: "-0.01em",
          cursor: "pointer",
          display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
        }}>
          {IcoPC2.retake(16, "#fff")} Retake
        </button>
        <button onClick={onKeep} style={{
          flex: 1.4, padding: "16px",
          borderRadius: 18,
          background: T.gold, border: "none",
          color: T.goldInk, fontSize: 15, fontWeight: 800,
          letterSpacing: "-0.01em",
          cursor: "pointer",
          display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
        }}>
          Use these {IcoPC2.chevron(15, T.goldInk)}
        </button>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Stage 3: Describe
// ───────────────────────────────────────────
function StageDescribe({ T, onBack, onPost, initialCaption = "" }) {
  const [caption, setCaption] = usePC(initialCaption);
  const [drink, setDrink] = usePC("Half Acre Daisy Cutter");
  const [place, setPlace] = usePC("Home · Brooklyn");
  const [audience, setAudience] = usePC("friends");
  const max = 140;

  return (
    <div style={{
      display: "flex", flexDirection: "column",
      height: "100%", color: "#fff",
      background: "#000",
    }}>
      {/* top bar */}
      <div style={{
        padding: "8px 18px 14px",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <button onClick={onBack} style={{
          width: 38, height: 38, borderRadius: "50%",
          background: "rgba(255,255,255,0.1)",
          border: "none", color: "#fff", display: "grid", placeItems: "center",
          cursor: "pointer", transform: "rotate(180deg)",
        }}>{IcoPC2.chevron(20)}</button>
        <div style={{
          color: T.gold, fontSize: 11, fontWeight: 700,
          letterSpacing: "0.14em", textTransform: "uppercase",
          display: "inline-flex", alignItems: "center", gap: 6,
        }}>{IcoPC2.bolt(10, T.gold)} describe your pour</div>
        <div style={{ width: 38 }} />
      </div>

      {/* photo header — small dual frame */}
      <div style={{ padding: "0 18px", display: "flex", gap: 12, alignItems: "flex-start" }}>
        <div style={{
          width: 84, height: 112, borderRadius: 14, overflow: "hidden",
          position: "relative", flexShrink: 0,
          background: "#000",
          border: "1px solid rgba(255,255,255,0.08)",
        }}>
          <ImgPHPC tone="pour" label="" style={{ position: "absolute", inset: 0 }} />
          <div style={{
            position: "absolute", top: 5, left: 5,
            width: 28, height: 38, borderRadius: 6, overflow: "hidden",
            border: "1.5px solid #000",
            outline: "1px solid rgba(255,255,255,0.18)",
          }}>
            <ImgPHPC tone="selfie" label="" style={{ width: "100%", height: "100%" }} />
          </div>
        </div>

        <div style={{ flex: 1, paddingTop: 4 }}>
          <div style={{
            color: "rgba(255,255,255,0.55)", fontSize: 11,
            fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase",
          }}>Pour · just now</div>
          <div style={{
            color: "#fff", fontSize: 18, fontWeight: 700,
            letterSpacing: "-0.02em", marginTop: 4,
            lineHeight: 1.2,
          }}>Show your friends<br/>what's in your glass.</div>
          <button style={{
            marginTop: 8,
            padding: "5px 10px", borderRadius: 999,
            background: "rgba(255,255,255,0.08)",
            border: "1px solid rgba(255,255,255,0.08)",
            color: "rgba(255,255,255,0.7)",
            fontSize: 11, fontWeight: 600, cursor: "pointer",
            display: "inline-flex", alignItems: "center", gap: 4,
          }}>
            {IcoPC2.retake(11, "rgba(255,255,255,0.7)")} Retake
          </button>
        </div>
      </div>

      {/* caption */}
      <div style={{ padding: "20px 18px 0" }}>
        <div style={{
          padding: 16,
          borderRadius: 18,
          background: "rgba(255,255,255,0.05)",
          border: "1px solid rgba(255,255,255,0.08)",
        }}>
          <textarea
            value={caption}
            onChange={(e) => setCaption(e.target.value.slice(0, max))}
            placeholder="Say something about this one…"
            style={{
              width: "100%", minHeight: 72,
              background: "transparent", border: "none", outline: "none",
              color: "#fff", fontSize: 16, lineHeight: 1.4,
              letterSpacing: "-0.01em",
              fontFamily: "inherit", resize: "none",
            }}
          />
          <div style={{
            display: "flex", alignItems: "center", justifyContent: "space-between",
            marginTop: 4,
          }}>
            <div style={{
              display: "flex", alignItems: "center", gap: 8,
              fontSize: 12, color: "rgba(255,255,255,0.5)",
            }}>
              <span style={{ cursor: "pointer" }}>@mention</span>
              <span style={{ width: 3, height: 3, borderRadius: "50%", background: "rgba(255,255,255,0.3)" }} />
              <span style={{ cursor: "pointer" }}>#tag</span>
            </div>
            <div style={{
              fontSize: 11, fontFamily: "ui-monospace, Menlo, monospace",
              color: caption.length > max - 20 ? T.gold : "rgba(255,255,255,0.4)",
            }}>{caption.length}/{max}</div>
          </div>
        </div>
      </div>

      {/* meta rows */}
      <div style={{ padding: "14px 18px 0" }}>
        <div style={{
          borderRadius: 18,
          background: "rgba(255,255,255,0.04)",
          border: "1px solid rgba(255,255,255,0.06)",
          overflow: "hidden",
        }}>
          <MetaRow T={T} icon={IcoPC2.glass(15, T.gold)} label="Drink" value={drink} hint="Daisy Cutter · APA · 5.2%" />
          <Divider />
          <MetaRow T={T} icon={IcoPC2.pin(15, T.gold)} label="Place" value={place} hint="Auto · within 80m" />
          <Divider />
          <MetaRow T={T} icon={IcoPC2.people(15, T.gold)} label="Visible to" value="Friends only" hint="8 people" trailing={(
            <div style={{ display: "flex" }}>
              {["selfie","avatar","selfie"].map((tone, i) => (
                <div key={i} style={{
                  width: 22, height: 22, borderRadius: "50%",
                  overflow: "hidden",
                  marginLeft: i === 0 ? 0 : -6,
                  border: "1.5px solid #000",
                }}>
                  <ImgPHPC tone={tone} label="" style={{ width: "100%", height: "100%" }} />
                </div>
              ))}
            </div>
          )} />
        </div>
      </div>

      {/* footer post button */}
      <div style={{ flex: 1 }} />
      <div style={{ padding: "16px 18px 28px" }}>
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "center",
          gap: 6, marginBottom: 10,
          fontSize: 11, color: "rgba(255,255,255,0.45)",
          letterSpacing: "0.02em",
        }}>
          {IcoPC2.timer(12, "rgba(255,255,255,0.45)")} <span>on time · 84 min before window closes</span>
        </div>
        <button onClick={() => onPost(caption)} style={{
          width: "100%", padding: "18px",
          borderRadius: 22,
          background: T.gold, border: "none",
          color: T.goldInk, fontSize: 17, fontWeight: 800,
          letterSpacing: "-0.01em",
          cursor: "pointer",
          display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
        }}>
          Pour it to your circle
        </button>
      </div>
    </div>
  );
}

function MetaRow({ T, icon, label, value, hint, trailing }) {
  return (
    <button style={{
      width: "100%", display: "flex", alignItems: "center", gap: 12,
      padding: "14px 14px",
      background: "transparent", border: "none", color: "#fff",
      cursor: "pointer", textAlign: "left",
    }}>
      <div style={{
        width: 32, height: 32, borderRadius: 10,
        background: T.goldFaint,
        border: `1px solid ${T.goldBorder}`,
        display: "grid", placeItems: "center", flexShrink: 0,
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          color: "rgba(255,255,255,0.5)", fontSize: 10,
          fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase",
        }}>{label}</div>
        <div style={{
          color: "#fff", fontSize: 14, fontWeight: 600,
          letterSpacing: "-0.01em", marginTop: 2,
          whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
        }}>{value}</div>
        {hint && (
          <div style={{
            color: "rgba(255,255,255,0.4)", fontSize: 11, marginTop: 1,
            whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
          }}>{hint}</div>
        )}
      </div>
      {trailing || (
        <div style={{ color: "rgba(255,255,255,0.35)" }}>{IcoPC2.chevron(16)}</div>
      )}
    </button>
  );
}

function Divider() {
  return <div style={{ height: 1, background: "rgba(255,255,255,0.05)", marginLeft: 58 }} />;
}

// ───────────────────────────────────────────
// Wrapper that picks the stage. Used by the showcase + the main app.
// ───────────────────────────────────────────
function PostCreateScreen({ initialStage = "aim", theme = "dark", onClose = () => {}, onDone = () => {} }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [stage, setStage] = usePC(initialStage);
  const [caption, setCaption] = usePC("");
  const [flashOn, setFlashOn] = usePC(false);

  const shutter = () => {
    setFlashOn(true);
    setTimeout(() => {
      setFlashOn(false);
      setStage("review");
    }, 160);
  };

  return (
    <window.IOSDevice width={402} height={874} dark={true}>
      <div data-screen-label={`Post Create · ${theme} · ${stage}`} style={{
        height: "100%", background: "#000",
        color: "#fff",
        fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
        position: "relative",
        paddingTop: 54,
        overflow: "hidden",
      }}>
        {stage === "aim" && <StageAim T={T} onClose={onClose} onShutter={shutter} />}
        {stage === "review" && <StageReview T={T} onRetake={() => setStage("aim")} onKeep={() => setStage("describe")} onClose={onClose} />}
        {stage === "describe" && <StageDescribe T={T} onBack={() => setStage("review")} onPost={(c) => onDone(c)} />}

        {flashOn && (
          <div style={{
            position: "absolute", inset: 0, background: "#fff",
            zIndex: 99, pointerEvents: "none",
            animation: "flash 160ms",
          }} />
        )}
      </div>
    </window.IOSDevice>
  );
}

Object.assign(window, { PostCreateScreen });
