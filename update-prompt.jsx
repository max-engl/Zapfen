// Pint. — "Update the app" modal
// Matches the brand system: black/gold, foamy "B" mark, rounded cards, GoldPill CTA.
// Renders inside the iOS device frame as a dimmed overlay sheet.

const { useState: useUpState } = React;

// Small download / arrow-down-to-tray glyph in the Pint stroke style
function DownloadGlyph({ s = 30, c = "currentColor" }) {
  return (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c}
      strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3v11" />
      <path d="M7.5 9.5 12 14l4.5-4.5" />
      <path d="M5 19h14" />
    </svg>
  );
}

function NewLine({ children }) {
  const T = window.useT();
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
      <span style={{
        width: 18, height: 18, borderRadius: "50%",
        background: T.goldSoft, border: `1px solid ${T.goldBorder}`,
        display: "grid", placeItems: "center", flexShrink: 0,
      }}>
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none"
          stroke={T.goldText} strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round">
          <path d="M5 12.5 10 17l9-10" />
        </svg>
      </span>
      <span style={{ color: T.text, fontSize: 13.5, letterSpacing: "-0.01em", opacity: 0.92 }}>
        {children}
      </span>
    </div>
  );
}

function UpdateModal({ onClose, onUpdate }) {
  const T = window.useT();
  const { BrandMark } = window;
  const [updating, setUpdating] = useUpState(false);

  const handleUpdate = () => {
    setUpdating(true);
    if (onUpdate) onUpdate();
  };

  return (
    <div style={{
      position: "absolute", inset: 0, zIndex: 200,
      display: "flex", alignItems: "flex-end", justifyContent: "center",
      padding: 16,
    }}>
      {/* dimmed backdrop */}
      <div onClick={onClose} style={{
        position: "absolute", inset: 0,
        background: "rgba(0,0,0,0.55)",
        backdropFilter: "blur(3px)", WebkitBackdropFilter: "blur(3px)",
      }} />

      {/* sheet */}
      <div style={{
        position: "relative",
        width: "100%", maxWidth: 360,
        marginBottom: 18,
        background: T.surface,
        borderRadius: 30,
        border: `1px solid ${T.border}`,
        boxShadow: "0 24px 60px rgba(0,0,0,0.45)",
        padding: "26px 22px 20px",
        overflow: "hidden",
      }}>
        {/* glow wash behind the mark */}
        <div style={{
          position: "absolute", top: -70, left: "50%", transform: "translateX(-50%)",
          width: 220, height: 160, borderRadius: "50%",
          background: T.goldFaint, filter: "blur(20px)", pointerEvents: "none",
        }} />

        {/* mark + foam dots */}
        <div style={{ position: "relative", display: "flex", justifyContent: "center", marginBottom: 16 }}>
          <div style={{
            width: 72, height: 72, borderRadius: 22,
            background: T.gold,
            display: "grid", placeItems: "center",
            color: T.goldInk,
            boxShadow: `0 8px 22px ${T.goldStrong}`,
            position: "relative",
          }}>
            <DownloadGlyph s={32} c={T.goldInk} />
            {/* tiny brand mark badge */}
            <div style={{
              position: "absolute", right: -6, bottom: -6,
              borderRadius: 12, border: `3px solid ${T.surface}`,
              lineHeight: 0,
            }}>
              <BrandMark size={26} />
            </div>
          </div>
        </div>

        {/* version chip */}
        <div style={{ position: "relative", display: "flex", justifyContent: "center", marginBottom: 12 }}>
          <div style={{
            display: "inline-flex", alignItems: "center", gap: 7,
            padding: "5px 12px", borderRadius: 999,
            background: T.goldSoft, border: `1px solid ${T.goldBorder}`,
            color: T.goldText, fontSize: 11, fontWeight: 800,
            letterSpacing: "0.1em", textTransform: "uppercase",
          }}>
            New version
            <span style={{ opacity: 0.55, fontWeight: 700 }}>2.6.1</span>
            <span style={{ opacity: 0.4 }}>→</span>
            <span style={{ fontWeight: 800 }}>2.7.0</span>
          </div>
        </div>

        {/* headline */}
        <div style={{
          position: "relative", textAlign: "center",
          color: T.text, fontSize: 23, fontWeight: 800,
          letterSpacing: "-0.03em", lineHeight: 1.12,
        }}>
          Time for a fresh pour
        </div>
        <div style={{
          position: "relative", textAlign: "center",
          color: T.textMuted, fontSize: 13.5, lineHeight: 1.45,
          marginTop: 8, padding: "0 6px",
        }}>
          A new version of Pint is ready. Update to keep your streak safe and unlock what's new.
        </div>

        {/* what's new */}
        <div style={{
          position: "relative",
          margin: "18px 0 20px",
          padding: "14px 16px",
          borderRadius: 18,
          background: T.surfaceWeaker,
          border: `1px solid ${T.borderWeak}`,
          display: "flex", flexDirection: "column", gap: 11,
        }}>
          <NewLine>Live pour map now updates in real time</NewLine>
          <NewLine>Beer Bingo nights with your circle</NewLine>
          <NewLine>Faster camera &amp; smoother streak grid</NewLine>
        </div>

        {/* actions */}
        <div style={{ position: "relative", display: "flex", flexDirection: "column", gap: 10 }}>
          <button onClick={handleUpdate} disabled={updating} style={{
            width: "100%", padding: "15px", borderRadius: 16,
            background: T.gold, border: "none", color: T.goldInk,
            fontSize: 16, fontWeight: 800, letterSpacing: "-0.01em",
            cursor: updating ? "default" : "pointer",
            display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 9,
            opacity: updating ? 0.92 : 1,
            transition: "transform 0.12s",
          }}>
            {updating ? (
              <React.Fragment>
                <span style={{
                  width: 16, height: 16, borderRadius: "50%",
                  border: `2.5px solid ${T.goldInk}`, borderTopColor: "transparent",
                  display: "inline-block", animation: "upSpin 0.7s linear infinite",
                }} />
                Updating…
              </React.Fragment>
            ) : (
              <React.Fragment>
                <DownloadGlyph s={18} c={T.goldInk} />
                Update now
              </React.Fragment>
            )}
          </button>
          <button onClick={onClose} disabled={updating} style={{
            width: "100%", padding: "12px", borderRadius: 16,
            background: "transparent", border: "none",
            color: T.textMuted, fontSize: 14.5, fontWeight: 600,
            cursor: "pointer",
          }}>
            Not now
          </button>
        </div>

        {/* footnote */}
        <div style={{
          position: "relative", textAlign: "center",
          color: T.textFaint, fontSize: 11, marginTop: 6,
          letterSpacing: "0.01em",
        }}>
          18 MB · takes a few seconds
        </div>
      </div>
    </div>
  );
}

// keyframes (injected once) — spinner only; the sheet rests in its visible
// state so captures, PDF export, and reduced-motion all show content.
if (!document.getElementById("up-modal-kf")) {
  const st = document.createElement("style");
  st.id = "up-modal-kf";
  st.textContent = `@keyframes upSpin { to { transform: rotate(360deg); } }`;
  document.head.appendChild(st);
}

Object.assign(window, { UpdateModal });
