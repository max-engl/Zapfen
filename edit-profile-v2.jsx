// Edit Profile — v2 (slim). Only avatar, username, and password.

const { useState: useStateEP, useRef: useRefEP } = React;
const useTEP = () => React.useContext(window.ThemeContext);
const { BrandMark: BrandMarkEP, Ico: IcoEP, ImgPH: ImgPHEP } = window;

const IcoEP2 = {
  back: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 6 9 12l6 6"/>
    </svg>
  ),
  cam: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 7h3l2-2h4l2 2h3a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z"/><circle cx="12" cy="13" r="4"/>
    </svg>
  ),
  trash: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 7h16"/><path d="M10 11v6"/><path d="M14 11v6"/>
      <path d="M6 7l1 13a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-13"/>
      <path d="M9 7V4h6v3"/>
    </svg>
  ),
  check: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="m5 12 5 5 9-11"/>
    </svg>
  ),
  lock: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="11" width="16" height="10" rx="2"/>
      <path d="M8 11V8a4 4 0 0 1 8 0v3"/>
    </svg>
  ),
  eye: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>
    </svg>
  ),
  eyeOff: (s = 16, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m3 3 18 18"/>
      <path d="M10.6 6.1A10 10 0 0 1 22 12s-1 2-3 4"/>
      <path d="M6.7 6.7C3.5 8.5 2 12 2 12s3.5 7 10 7c2 0 3.7-.6 5.2-1.5"/>
      <path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>
    </svg>
  ),
  upload: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 16V4"/><path d="m6 10 6-6 6 6"/><path d="M4 20h16"/>
    </svg>
  ),
  warn: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9"/><path d="M12 8v4"/><path d="M12 16h.01"/>
    </svg>
  ),
};

// Password strength
function strengthEP(pw) {
  let s = 0;
  if (pw.length >= 8) s++;
  if (/[A-Z]/.test(pw)) s++;
  if (/\d/.test(pw)) s++;
  if (/[^A-Za-z0-9]/.test(pw)) s++;
  if (pw.length >= 14) s++;
  return Math.min(s, 4);
}

function StrengthMeterEP({ pw }) {
  const T = useTEP();
  const s = strengthEP(pw);
  const labels = ["weak", "okay", "good", "strong", "rock solid"];
  const c = s < 2 ? "#c2511e" : T.goldText;
  return (
    <div style={{ marginTop: 8 }}>
      <div style={{ display: "flex", gap: 4 }}>
        {[0,1,2,3].map(i => (
          <div key={i} style={{
            flex: 1, height: 4, borderRadius: 2,
            background: i < s ? c : T.surfaceWeak,
            transition: "background 0.2s",
          }}/>
        ))}
      </div>
      <div style={{ fontSize: 11, fontWeight: 600, color: T.textMuted, marginTop: 5 }}>
        Pour strength: <span style={{ color: c }}>{pw ? labels[s] : "—"}</span>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
function SectionHeading({ children, hint }) {
  const T = useTEP();
  return (
    <div style={{ padding: "22px 22px 10px 22px" }}>
      <div style={{
        color: T.textMuted, fontSize: 11, fontWeight: 700,
        letterSpacing: "0.16em", textTransform: "uppercase",
      }}>{children}</div>
      {hint && <div style={{ color: T.textFaint, fontSize: 12, marginTop: 4 }}>{hint}</div>}
    </div>
  );
}

function Card({ children }) {
  const T = useTEP();
  return (
    <div style={{
      margin: "0 16px",
      background: T.surfaceWeaker,
      border: `1px solid ${T.border}`,
      borderRadius: 16,
      overflow: "hidden",
    }}>{children}</div>
  );
}

function FieldShell({ label, hint, error, status, children, last }) {
  const T = useTEP();
  const errored = !!error;
  return (
    <div style={{
      padding: "14px 16px",
      borderBottom: last ? "none" : `1px solid ${T.divider}`,
    }}>
      <div style={{
        display: "flex", justifyContent: "space-between",
        color: T.textMuted, fontSize: 11, fontWeight: 700,
        letterSpacing: "0.14em", textTransform: "uppercase",
        marginBottom: 8,
      }}>
        <span>{label}</span>
        {status === "ok" && (
          <span style={{ color: T.goldText, display: "inline-flex", alignItems: "center", gap: 4, textTransform: "none", letterSpacing: 0 }}>
            {IcoEP2.check(12, T.goldText)} saved
          </span>
        )}
      </div>
      <div style={{
        padding: "12px 14px", borderRadius: 12,
        background: T.surfaceWeak,
        border: `1px solid ${errored ? "#c2511e" : T.border}`,
        transition: "border-color 0.15s",
      }}>{children}</div>
      <div style={{
        minHeight: 16, marginTop: 6, paddingLeft: 2,
        fontSize: 12, fontWeight: 600,
        color: error ? "#c2511e" : T.textMuted,
        display: "inline-flex", alignItems: "center", gap: 5,
      }}>
        {error && <span style={{ display: "inline-flex", color: "#c2511e" }}>{IcoEP2.warn(12, "#c2511e")}</span>}
        {error || hint}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Avatar editor block
// ───────────────────────────────────────────
function AvatarBlock({ hasPhoto, onUpload, onRemove }) {
  const T = useTEP();
  return (
    <div style={{
      margin: "0 16px",
      padding: "22px 20px",
      background: T.goldFaint,
      border: `1px solid ${T.goldBorder}`,
      borderRadius: 18,
      display: "flex", alignItems: "center", gap: 18,
    }}>
      <div style={{ position: "relative", flexShrink: 0 }}>
        <div style={{
          width: 92, height: 92, borderRadius: "50%",
          overflow: "hidden", position: "relative",
          border: `3px solid ${T.gold}`,
          boxShadow: "0 14px 28px rgba(0,0,0,0.28)",
        }}>
          {hasPhoto ? (
            <ImgPHEP tone="selfie" label="" style={{ width: "100%", height: "100%" }}/>
          ) : (
            <div style={{
              width: "100%", height: "100%",
              background: T.gold,
              display: "grid", placeItems: "center",
              color: T.goldInk, fontSize: 40, fontWeight: 800, letterSpacing: "-0.03em",
            }}>M</div>
          )}
        </div>
        <button onClick={onUpload} style={{
          position: "absolute", right: -2, bottom: -2,
          width: 32, height: 32, borderRadius: "50%",
          background: T.gold, color: T.goldInk,
          border: `2px solid ${T.bg}`,
          display: "grid", placeItems: "center",
          cursor: "pointer",
        }}>{IcoEP2.cam(16, T.goldInk)}</button>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          color: T.text, fontSize: 18, fontWeight: 800,
          letterSpacing: "-0.02em",
        }}>Profile photo</div>
        <div style={{
          color: T.textMuted, fontSize: 12, marginTop: 3, lineHeight: 1.4,
        }}>A real selfie tends to land better with your circle.</div>
        <div style={{ display: "flex", gap: 8, marginTop: 12 }}>
          <button onClick={onUpload} style={{
            padding: "8px 14px", borderRadius: 999,
            background: T.gold, color: T.goldInk,
            border: "none", fontSize: 12, fontWeight: 700,
            cursor: "pointer", fontFamily: "inherit",
            display: "inline-flex", alignItems: "center", gap: 5,
          }}>{IcoEP2.upload(12, T.goldInk)} {hasPhoto ? "Replace" : "Upload"}</button>
          {hasPhoto && (
            <button onClick={onRemove} style={{
              padding: "8px 12px", borderRadius: 999,
              background: T.surfaceWeak, color: T.text,
              border: `1px solid ${T.border}`,
              fontSize: 12, fontWeight: 600,
              cursor: "pointer", fontFamily: "inherit",
              display: "inline-flex", alignItems: "center", gap: 5,
            }}>{IcoEP2.trash(12, T.textMuted)} Remove</button>
          )}
        </div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
function ToastEP({ msg }) {
  const T = useTEP();
  if (!msg) return null;
  return (
    <div style={{
      position: "absolute", left: 0, right: 0, bottom: 36,
      display: "flex", justifyContent: "center", pointerEvents: "none", zIndex: 60,
    }}>
      <div style={{
        padding: "10px 16px", borderRadius: 999,
        background: T.gold, color: T.goldInk,
        fontSize: 13, fontWeight: 700, letterSpacing: "-0.01em",
        boxShadow: "0 14px 28px rgba(0,0,0,0.35)",
        display: "inline-flex", alignItems: "center", gap: 6,
      }}>
        {IcoEP2.check(15, T.goldInk)} {msg}
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Main slim screen
// ───────────────────────────────────────────
function EditProfileScreen({ theme = "dark" }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [username, setUsername] = useStateEP("mayac");
  const [hasPhoto, setHasPhoto] = useStateEP(true);

  const [currentPw, setCurrentPw] = useStateEP("");
  const [newPw, setNewPw] = useStateEP("");
  const [confirmPw, setConfirmPw] = useStateEP("");
  const [showNew, setShowNew] = useStateEP(false);
  const [showCurrent, setShowCurrent] = useStateEP(false);

  const [toast, setToast] = useStateEP("");
  const showToast = (m) => { setToast(m); setTimeout(() => setToast(""), 1800); };

  const TAKEN = ["sam", "theo", "you", "admin", "pint"];
  const original = "mayac";
  const usernameStatus = !username
    ? null
    : username.length < 3 ? "short"
    : username.length > 16 ? "long"
    : !/^[a-z0-9_]+$/.test(username) ? "chars"
    : TAKEN.includes(username) ? "taken"
    : username === original ? "same"
    : "ok";

  const usernameError =
    usernameStatus === "short" ? "At least 3 characters." :
    usernameStatus === "long"  ? "Max 16 characters." :
    usernameStatus === "chars" ? "Letters, numbers, and underscores only." :
    usernameStatus === "taken" ? `@${username} is already taken.` :
    "";

  const usernameHint =
    usernameStatus === "ok"   ? `pint.so/u/${username}` :
    usernameStatus === "same" ? `Your current handle: @${original}` :
    !usernameStatus ? "3–16 characters, lowercase." :
    "";

  // Password validation
  const newPwTouched = newPw.length > 0;
  const newPwShort = newPwTouched && newPw.length < 8;
  const newPwSameAsCurrent = newPwTouched && currentPw && newPw === currentPw;
  const confirmTouched = confirmPw.length > 0;
  const confirmMismatch = confirmTouched && newPw !== confirmPw;

  const newPwError = newPwShort ? "8+ characters, please." : newPwSameAsCurrent ? "Pick something different from your current one." : "";
  const confirmError = confirmMismatch ? "These don't match." : "";

  const wantingPwChange = currentPw || newPw || confirmPw;
  const pwValid = !wantingPwChange || (
    currentPw && newPw.length >= 8 && newPw === confirmPw && !newPwSameAsCurrent
  );

  const usernameValid = usernameStatus === "ok" || usernameStatus === "same";
  const canSave = usernameValid && pwValid && (usernameStatus === "ok" || wantingPwChange || /* avatar change implicit */ true);
  // Loosely: Save is always tappable if no errors

  const onSave = () => {
    if (!usernameValid) return;
    if (wantingPwChange && !pwValid) return;
    if (wantingPwChange) {
      setCurrentPw(""); setNewPw(""); setConfirmPw("");
      showToast(usernameStatus === "ok" ? "Saved · handle & password updated" : "Password updated");
    } else if (usernameStatus === "ok") {
      showToast(`Saved · you're now @${username}`);
    } else {
      showToast("Nothing to save");
    }
  };

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        <div data-screen-label={`Edit Profile · ${theme}`} style={{
          height: "100%",
          background: T.bg,
          color: T.text,
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          position: "relative",
          paddingTop: 54,
        }}>
          {/* Sticky header */}
          <div style={{
            display: "flex", alignItems: "center", justifyContent: "space-between",
            padding: "10px 10px 10px 6px",
            position: "sticky", top: 0, zIndex: 30,
            background: T.bg,
            borderBottom: `1px solid ${T.border}`,
          }}>
            <button style={{
              width: 36, height: 36, borderRadius: "50%",
              background: "transparent", border: "none",
              color: T.text, display: "grid", placeItems: "center",
              cursor: "pointer", marginLeft: 10,
            }}>{IcoEP2.back(20)}</button>
            <div style={{
              color: T.text, fontWeight: 700, fontSize: 16, letterSpacing: "-0.02em",
            }}>Edit profile</div>
            <button
              onClick={onSave}
              disabled={!canSave}
              style={{
                padding: "8px 16px", borderRadius: 999,
                background: canSave ? T.gold : T.surfaceWeak,
                border: canSave ? "none" : `1px solid ${T.border}`,
                color: canSave ? T.goldInk : T.textFaint,
                fontSize: 13, fontWeight: 800,
                cursor: canSave ? "pointer" : "not-allowed",
                fontFamily: "inherit",
                letterSpacing: "-0.01em",
                marginRight: 10,
              }}>Save</button>
          </div>

          {/* Body */}
          <div style={{ height: "calc(100% - 54px - 56px)", overflowY: "auto", paddingBottom: 28 }}>

            <div style={{ height: 18 }} />
            <AvatarBlock
              hasPhoto={hasPhoto}
              onUpload={() => { setHasPhoto(true); showToast("Photo updated"); }}
              onRemove={() => { setHasPhoto(false); showToast("Photo removed"); }}
            />

            <SectionHeading>Username</SectionHeading>
            <Card>
              <FieldShell
                label="Handle"
                hint={usernameHint}
                error={usernameError}
                status={usernameStatus === "ok" ? "ok" : null}
                last
              >
                <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
                  <span style={{ color: T.textMuted, fontSize: 16, fontWeight: 600 }}>@</span>
                  <input
                    value={username}
                    onChange={e => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, "").slice(0, 16))}
                    placeholder="handle"
                    style={{
                      flex: 1, padding: 0, border: "none", background: "transparent",
                      outline: "none", color: T.text,
                      fontSize: 16, fontWeight: 600, letterSpacing: "-0.01em",
                      fontFamily: "inherit",
                    }}
                  />
                  {usernameStatus === "ok" && (
                    <span style={{ display: "inline-flex", color: T.goldText }}>{IcoEP2.check(18, T.goldText)}</span>
                  )}
                </div>
              </FieldShell>
            </Card>

            <SectionHeading hint="Leave blank to keep your current password.">Password</SectionHeading>
            <Card>
              <FieldShell label="Current password">
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ display: "inline-flex", color: T.textMuted }}>{IcoEP2.lock(16, T.textMuted)}</span>
                  <input
                    value={currentPw}
                    onChange={e => setCurrentPw(e.target.value)}
                    type={showCurrent ? "text" : "password"}
                    placeholder="••••••••"
                    style={{
                      flex: 1, padding: 0, border: "none", background: "transparent",
                      outline: "none", color: T.text,
                      fontSize: 16, fontWeight: 600, letterSpacing: "-0.01em",
                      fontFamily: "inherit",
                    }}/>
                  <button onClick={() => setShowCurrent(s => !s)} style={{
                    background: "transparent", border: "none", padding: 4,
                    color: T.textMuted, cursor: "pointer", display: "inline-flex",
                  }}>{showCurrent ? IcoEP2.eyeOff(16, T.textMuted) : IcoEP2.eye(16, T.textMuted)}</button>
                </div>
              </FieldShell>
              <FieldShell
                label="New password"
                error={newPwError}
                hint={newPw && !newPwError ? null : "8+ characters."}
              >
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ display: "inline-flex", color: T.textMuted }}>{IcoEP2.lock(16, T.textMuted)}</span>
                  <input
                    value={newPw}
                    onChange={e => setNewPw(e.target.value)}
                    type={showNew ? "text" : "password"}
                    placeholder="At least 8 characters"
                    style={{
                      flex: 1, padding: 0, border: "none", background: "transparent",
                      outline: "none", color: T.text,
                      fontSize: 16, fontWeight: 600, letterSpacing: "-0.01em",
                      fontFamily: "inherit",
                    }}/>
                  <button onClick={() => setShowNew(s => !s)} style={{
                    background: "transparent", border: "none", padding: 4,
                    color: T.textMuted, cursor: "pointer", display: "inline-flex",
                  }}>{showNew ? IcoEP2.eyeOff(16, T.textMuted) : IcoEP2.eye(16, T.textMuted)}</button>
                </div>
                {newPw && !newPwError && <StrengthMeterEP pw={newPw}/>}
              </FieldShell>
              <FieldShell
                label="Confirm new password"
                error={confirmError}
                last
              >
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ display: "inline-flex", color: T.textMuted }}>{IcoEP2.lock(16, T.textMuted)}</span>
                  <input
                    value={confirmPw}
                    onChange={e => setConfirmPw(e.target.value)}
                    type={showNew ? "text" : "password"}
                    placeholder="Type it again"
                    style={{
                      flex: 1, padding: 0, border: "none", background: "transparent",
                      outline: "none", color: T.text,
                      fontSize: 16, fontWeight: 600, letterSpacing: "-0.01em",
                      fontFamily: "inherit",
                    }}/>
                  {confirmPw && !confirmError && (
                    <span style={{ display: "inline-flex", color: T.goldText }}>{IcoEP2.check(16, T.goldText)}</span>
                  )}
                </div>
              </FieldShell>
            </Card>

            <div style={{ height: 24 }} />

            {/* Big save in case header is offscreen */}
            <div style={{ padding: "0 22px" }}>
              <button
                onClick={onSave}
                disabled={!canSave}
                style={{
                  width: "100%", padding: "16px 22px", borderRadius: 16,
                  background: canSave ? T.gold : T.surfaceWeak,
                  border: canSave ? "none" : `1px solid ${T.border}`,
                  color: canSave ? T.goldInk : T.textFaint,
                  fontSize: 16, fontWeight: 800,
                  letterSpacing: "-0.01em",
                  cursor: canSave ? "pointer" : "not-allowed",
                  fontFamily: "inherit",
                  display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
                }}>
                {IcoEP2.check(17, canSave ? T.goldInk : T.textFaint)} Save changes
              </button>
            </div>

            <div style={{ height: 24 }} />
          </div>

          <ToastEP msg={toast}/>
        </div>
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

Object.assign(window, { EditProfileScreen });
