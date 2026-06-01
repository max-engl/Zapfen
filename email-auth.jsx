// Email + password login and register screens for Pint.
// Reuses theme tokens + IOSDevice from app.jsx / ios-frame.jsx.

const { useState: useStateEA, useRef: useRefEA } = React;
const useTEA = () => React.useContext(window.ThemeContext);
const { BrandMark: BrandMarkEA, Ico: IcoEA, ImgPH: ImgPHEA } = window;

// Icons specific to email auth screens
const IcoEA2 = {
  back: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 6 9 12l6 6"/>
    </svg>
  ),
  mail: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>
    </svg>
  ),
  lock: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="4" y="11" width="16" height="10" rx="2"/>
      <path d="M8 11V8a4 4 0 0 1 8 0v3"/>
    </svg>
  ),
  eye: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/>
      <circle cx="12" cy="12" r="3"/>
    </svg>
  ),
  eyeOff: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="m3 3 18 18"/>
      <path d="M10.6 6.1A10 10 0 0 1 22 12s-1 2-3 4"/>
      <path d="M6.7 6.7C3.5 8.5 2 12 2 12s3.5 7 10 7c2 0 3.7-.6 5.2-1.5"/>
      <path d="M9.9 9.9a3 3 0 0 0 4.2 4.2"/>
    </svg>
  ),
  apple: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill={c}>
      <path d="M16.4 12.5c0-2.4 2-3.6 2.1-3.6-1.1-1.7-2.9-1.9-3.5-1.9-1.5-.2-2.9.9-3.7.9-.8 0-1.9-.9-3.2-.8-1.6 0-3.2 1-4 2.4-1.7 3-.4 7.5 1.2 9.9.8 1.2 1.8 2.5 3.1 2.4 1.2 0 1.7-.8 3.2-.8 1.5 0 1.9.8 3.2.8 1.3 0 2.2-1.2 3-2.4.9-1.4 1.3-2.7 1.3-2.8-.1-.1-2.7-1-2.7-4.1zm-2.4-7.5C14.7 4.2 15.2 3 15 1.8c-1 0-2.3.7-3 1.5-.6.7-1.2 1.9-1.1 3 1.1.1 2.3-.6 3.1-1.3z"/>
    </svg>
  ),
  google: (s = 18) => (
    <svg width={s} height={s} viewBox="0 0 24 24">
      <path fill="#4285F4" d="M21.6 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.4c-.2 1.2-.9 2.3-2 3v2.5h3.2c1.9-1.7 3-4.3 3-7.3z"/>
      <path fill="#34A853" d="M12 22c2.7 0 5-.9 6.6-2.4l-3.2-2.5c-.9.6-2 1-3.4 1-2.6 0-4.8-1.8-5.6-4.1H3.1v2.6C4.7 19.7 8.1 22 12 22z"/>
      <path fill="#FBBC05" d="M6.4 14c-.2-.6-.3-1.3-.3-2s.1-1.4.3-2V7.4H3.1A10 10 0 0 0 2 12c0 1.6.4 3.2 1.1 4.6L6.4 14z"/>
      <path fill="#EA4335" d="M12 5.9c1.5 0 2.8.5 3.8 1.5l2.8-2.8C16.9 3 14.7 2 12 2 8.1 2 4.7 4.3 3.1 7.4L6.4 10c.8-2.3 3-4.1 5.6-4.1z"/>
    </svg>
  ),
  check: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="m5 12 5 5 9-11"/>
    </svg>
  ),
  arrow: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
      <path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>
    </svg>
  ),
  warn: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="9"/><path d="M12 8v4"/><path d="M12 16h.01"/>
    </svg>
  ),
};

// ───────────────────────────────────────────
// Shared field component
// ───────────────────────────────────────────
function Field({ label, icon, value, onChange, type = "text", placeholder, error, hint, autoFocus, right, rightAdornment }) {
  const T = useTEA();
  const errored = !!error;
  const filled = !!value;
  return (
    <div style={{ marginBottom: 14 }}>
      <label style={{
        display: "flex", justifyContent: "space-between",
        color: T.textMuted, fontSize: 11,
        fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase",
        marginBottom: 6, paddingLeft: 4,
      }}>
        <span>{label}</span>
        {right && <span style={{ textTransform: "none", letterSpacing: 0 }}>{right}</span>}
      </label>
      <div style={{
        display: "flex", alignItems: "center", gap: 10,
        padding: "0 14px", borderRadius: 14,
        background: T.surfaceWeak,
        border: `1px solid ${errored ? "#c2511e" : filled ? T.goldBorderStrong : T.border}`,
        transition: "border-color 0.15s",
      }}>
        {icon && <span style={{ display: "inline-flex", color: T.textMuted, flexShrink: 0 }}>{icon}</span>}
        <input
          autoFocus={autoFocus}
          value={value}
          onChange={e => onChange(e.target.value)}
          type={type}
          placeholder={placeholder}
          style={{
            flex: 1, minWidth: 0, padding: "15px 0",
            background: "transparent", border: "none",
            color: T.text, fontSize: 16, fontWeight: 600,
            outline: "none", fontFamily: "inherit",
            letterSpacing: "-0.01em",
          }}
        />
        {rightAdornment}
      </div>
      {(error || hint) && (
        <div style={{
          minHeight: 18, marginTop: 6, paddingLeft: 4,
          fontSize: 12, fontWeight: 600,
          color: error ? "#c2511e" : T.textMuted,
          display: "inline-flex", alignItems: "center", gap: 5,
        }}>
          {error && <span style={{ display: "inline-flex", color: "#c2511e" }}>{IcoEA2.warn(12, "#c2511e")}</span>}
          {error || hint}
        </div>
      )}
    </div>
  );
}

function PrimaryBtnEA({ children, disabled, onClick, loading }) {
  const T = useTEA();
  return (
    <button onClick={onClick} disabled={disabled || loading} style={{
      width: "100%",
      padding: "16px 22px", borderRadius: 16,
      background: disabled ? T.surfaceWeak : T.gold,
      border: disabled ? `1px solid ${T.border}` : "none",
      color: disabled ? T.textFaint : T.goldInk,
      fontSize: 16, fontWeight: 800,
      letterSpacing: "-0.01em",
      cursor: disabled ? "not-allowed" : "pointer",
      display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
    }}>
      {loading ? <SpinnerEA /> : children}
    </button>
  );
}

function GhostBtnEA({ children, onClick, flex = 1 }) {
  const T = useTEA();
  return (
    <button onClick={onClick} style={{
      flex,
      padding: "13px 14px", borderRadius: 14,
      background: T.surfaceWeak,
      border: `1px solid ${T.border}`,
      color: T.text,
      fontSize: 13, fontWeight: 700,
      letterSpacing: "-0.01em",
      cursor: "pointer",
      display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 7,
      fontFamily: "inherit",
    }}>{children}</button>
  );
}

function SpinnerEA() {
  const T = useTEA();
  return (
    <span style={{ display: "inline-block", width: 18, height: 18 }}>
      <svg width="18" height="18" viewBox="0 0 24 24" style={{ animation: "ea-spin 0.7s linear infinite" }}>
        <circle cx="12" cy="12" r="9" fill="none" stroke="rgba(0,0,0,0.2)" strokeWidth="3"/>
        <path d="M12 3a9 9 0 0 1 9 9" fill="none" stroke={T.goldInk} strokeWidth="3" strokeLinecap="round"/>
      </svg>
      <style>{`@keyframes ea-spin { to { transform: rotate(360deg); } }`}</style>
    </span>
  );
}

function DividerWithLabel({ label }) {
  const T = useTEA();
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 12,
      margin: "16px 0 14px",
    }}>
      <div style={{ flex: 1, height: 1, background: T.border }}/>
      <div style={{
        color: T.textMuted, fontSize: 11, fontWeight: 700,
        letterSpacing: "0.16em", textTransform: "uppercase",
      }}>{label}</div>
      <div style={{ flex: 1, height: 1, background: T.border }}/>
    </div>
  );
}

function AuthHeader({ onBack }) {
  const T = useTEA();
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "10px 18px 0",
    }}>
      {onBack ? (
        <button onClick={onBack} style={{
          width: 36, height: 36, borderRadius: "50%",
          background: T.surfaceWeak,
          border: `1px solid ${T.border}`,
          color: T.text, display: "grid", placeItems: "center",
          cursor: "pointer",
        }}>{IcoEA2.back(20)}</button>
      ) : <div style={{ width: 36 }} />}
      <BrandMarkEA size={28} />
      <div style={{ width: 36 }} />
    </div>
  );
}

// ───────────────────────────────────────────
// Password strength meter
// ───────────────────────────────────────────
function strength(pw) {
  let score = 0;
  if (pw.length >= 8) score++;
  if (/[A-Z]/.test(pw)) score++;
  if (/\d/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  if (pw.length >= 14) score++;
  return Math.min(score, 4);
}

function StrengthMeter({ pw }) {
  const T = useTEA();
  if (!pw) return <div style={{ height: 18 }}/>;
  const s = strength(pw);
  const labels = ["weak", "okay", "good", "strong", "rock solid"];
  const colors = ["#c2511e", "#c2511e", T.goldText, T.goldText, T.goldText];
  return (
    <div style={{ marginTop: 6, paddingLeft: 4, marginBottom: 14 }}>
      <div style={{ display: "flex", gap: 4, marginBottom: 4 }}>
        {[0,1,2,3].map(i => (
          <div key={i} style={{
            flex: 1, height: 4, borderRadius: 2,
            background: i < s ? colors[s] : T.surfaceWeak,
            transition: "background 0.2s",
          }}/>
        ))}
      </div>
      <div style={{ fontSize: 11, fontWeight: 600, color: T.textMuted }}>
        Pour strength: <span style={{ color: colors[s] }}>{labels[s]}</span>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// LOGIN — email + password
// ───────────────────────────────────────────
function EmailLoginScreen({ theme = "dark", onBack, onRegister, onForgot, onLogin }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [email, setEmail] = useStateEA("");
  const [pw, setPw] = useStateEA("");
  const [show, setShow] = useStateEA(false);
  const [remember, setRemember] = useStateEA(true);
  const [error, setError] = useStateEA("");
  const [loading, setLoading] = useStateEA(false);

  const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  const valid = emailOk && pw.length >= 1;

  const submit = () => {
    if (!valid) return;
    setLoading(true);
    setError("");
    setTimeout(() => {
      // Demo: any password except "wrong" succeeds
      if (pw === "wrong") {
        setError("Wrong email or password. The bartender doesn't recognize you.");
        setLoading(false);
      } else {
        setLoading(false);
        onLogin && onLogin();
      }
    }, 700);
  };

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        <div data-screen-label={`Login · email · ${theme}`} style={{
          height: "100%",
          background: T.bg,
          color: T.text,
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          position: "relative",
          paddingTop: 54,
          display: "flex", flexDirection: "column",
        }}>
          <AuthHeader onBack={onBack} />

          <div style={{
            padding: "28px 24px 24px", flex: 1,
            display: "flex", flexDirection: "column",
          }}>
            <div style={{ marginBottom: 24 }}>
              <div style={{
                color: T.goldText, fontSize: 11, fontWeight: 700,
                letterSpacing: "0.14em", textTransform: "uppercase",
                display: "inline-flex", alignItems: "center", gap: 6,
              }}>
                {IcoEA.bolt(10, T.goldText)} Welcome back
              </div>
              <div style={{
                color: T.text, fontWeight: 800, fontSize: 28,
                letterSpacing: "-0.03em", marginTop: 8, lineHeight: 1.1,
              }}>Sign in to <span style={{ color: T.goldText }}>Pint.</span></div>
              <div style={{ color: T.textMuted, fontSize: 14, marginTop: 8, lineHeight: 1.45 }}>
                Ready to pour the next one? Use your email and password.
              </div>
            </div>

            <Field
              label="Email"
              icon={IcoEA2.mail(18)}
              value={email}
              onChange={setEmail}
              type="email"
              placeholder="you@brewery.co"
              autoFocus
            />

            <Field
              label="Password"
              right={
                <button onClick={onForgot} style={{
                  background: "transparent", border: "none", padding: 0,
                  color: T.goldText, fontWeight: 700, cursor: "pointer",
                  fontFamily: "inherit", fontSize: 12,
                  textTransform: "none", letterSpacing: 0,
                }}>Forgot?</button>
              }
              icon={IcoEA2.lock(18)}
              value={pw}
              onChange={setPw}
              type={show ? "text" : "password"}
              placeholder="••••••••"
              error={error}
              rightAdornment={
                <button onClick={() => setShow(s => !s)} style={{
                  background: "transparent", border: "none", padding: 4,
                  color: T.textMuted, cursor: "pointer", display: "inline-flex",
                }}>{show ? IcoEA2.eyeOff(18) : IcoEA2.eye(18)}</button>
              }
            />

            <label style={{
              display: "inline-flex", alignItems: "center", gap: 10,
              color: T.text, fontSize: 13, cursor: "pointer", marginTop: 2,
            }}>
              <span onClick={() => setRemember(r => !r)} style={{
                width: 20, height: 20, borderRadius: 6,
                background: remember ? T.gold : "transparent",
                border: `1px solid ${remember ? T.gold : T.border}`,
                display: "grid", placeItems: "center",
                transition: "all 0.15s",
              }}>
                {remember && IcoEA2.check(14, T.goldInk)}
              </span>
              Keep me poured in
            </label>

            <div style={{ flex: 1, minHeight: 16 }}/>

            <PrimaryBtnEA disabled={!valid} loading={loading} onClick={submit}>
              {loading ? null : <>Sign in {IcoEA2.arrow(16, valid ? T.goldInk : T.textFaint)}</>}
            </PrimaryBtnEA>

            <DividerWithLabel label="or" />

            <div style={{ display: "flex", gap: 10 }}>
              <GhostBtnEA>{IcoEA2.apple(15, T.text)} Apple</GhostBtnEA>
              <GhostBtnEA>{IcoEA2.google(15)} Google</GhostBtnEA>
            </div>

            <div style={{
              textAlign: "center", marginTop: 20,
              color: T.textMuted, fontSize: 13,
            }}>
              First time pouring?{" "}
              <button onClick={onRegister} style={{
                background: "transparent", border: "none", padding: 0,
                color: T.goldText, fontWeight: 700, fontSize: 13,
                cursor: "pointer", textDecoration: "underline", textUnderlineOffset: 3,
                fontFamily: "inherit",
              }}>Create an account</button>
            </div>
          </div>
        </div>
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

// ───────────────────────────────────────────
// REGISTER — email + password
// ───────────────────────────────────────────
function EmailRegisterScreen({ theme = "dark", onBack, onLogin, onContinue }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [email, setEmail] = useStateEA("");
  const [pw, setPw] = useStateEA("");
  const [show, setShow] = useStateEA(false);
  const [agree, setAgree] = useStateEA(false);
  const [marketing, setMarketing] = useStateEA(true);
  const [error, setError] = useStateEA("");

  const emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  const emailTouched = email.length > 3;
  const emailError = emailTouched && !emailOk ? "That doesn't look like an email." : "";
  const pwTouched = pw.length > 0;
  const pwShort = pwTouched && pw.length < 8;
  const pwError = pwShort ? "8+ characters, please." : "";
  const valid = emailOk && pw.length >= 8 && agree;

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        <div data-screen-label={`Register · email · ${theme}`} style={{
          height: "100%",
          background: T.bg,
          color: T.text,
          fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
          position: "relative",
          paddingTop: 54,
          display: "flex", flexDirection: "column",
        }}>
          <AuthHeader onBack={onBack} />

          <div style={{
            padding: "28px 24px 24px", flex: 1,
            display: "flex", flexDirection: "column",
            overflowY: "auto",
          }}>
            <div style={{ marginBottom: 22 }}>
              <div style={{
                color: T.goldText, fontSize: 11, fontWeight: 700,
                letterSpacing: "0.14em", textTransform: "uppercase",
                display: "inline-flex", alignItems: "center", gap: 6,
              }}>
                {IcoEA.bolt(10, T.goldText)} New here
              </div>
              <div style={{
                color: T.text, fontWeight: 800, fontSize: 28,
                letterSpacing: "-0.03em", marginTop: 8, lineHeight: 1.1,
              }}>Start your tab.</div>
              <div style={{ color: T.textMuted, fontSize: 14, marginTop: 8, lineHeight: 1.45 }}>
                Create an account with email and a password. You'll pick your handle next.
              </div>
            </div>

            <Field
              label="Email"
              icon={IcoEA2.mail(18)}
              value={email}
              onChange={setEmail}
              type="email"
              placeholder="you@brewery.co"
              error={emailError}
              autoFocus
            />

            <Field
              label="Password"
              icon={IcoEA2.lock(18)}
              value={pw}
              onChange={setPw}
              type={show ? "text" : "password"}
              placeholder="At least 8 characters"
              error={pwError}
              rightAdornment={
                <button onClick={() => setShow(s => !s)} style={{
                  background: "transparent", border: "none", padding: 4,
                  color: T.textMuted, cursor: "pointer", display: "inline-flex",
                }}>{show ? IcoEA2.eyeOff(18) : IcoEA2.eye(18)}</button>
              }
            />
            {pw && !pwError && <StrengthMeter pw={pw} />}

            {/* checkboxes */}
            <label style={{
              display: "flex", alignItems: "flex-start", gap: 10,
              color: T.text, fontSize: 13, cursor: "pointer",
              marginTop: 6, lineHeight: 1.45,
            }}>
              <span onClick={() => setAgree(a => !a)} style={{
                width: 20, height: 20, borderRadius: 6, flexShrink: 0,
                background: agree ? T.gold : "transparent",
                border: `1px solid ${agree ? T.gold : T.border}`,
                display: "grid", placeItems: "center",
                marginTop: 1,
              }}>
                {agree && IcoEA2.check(14, T.goldInk)}
              </span>
              <span>
                I'm 21+ and agree to the{" "}
                <a style={{ color: T.goldText, fontWeight: 700, textDecoration: "underline", textUnderlineOffset: 3 }}>Terms</a>
                {" "}and{" "}
                <a style={{ color: T.goldText, fontWeight: 700, textDecoration: "underline", textUnderlineOffset: 3 }}>Privacy</a>.
              </span>
            </label>

            <label style={{
              display: "flex", alignItems: "flex-start", gap: 10,
              color: T.text, fontSize: 13, cursor: "pointer",
              marginTop: 12, lineHeight: 1.45,
            }}>
              <span onClick={() => setMarketing(m => !m)} style={{
                width: 20, height: 20, borderRadius: 6, flexShrink: 0,
                background: marketing ? T.gold : "transparent",
                border: `1px solid ${marketing ? T.gold : T.border}`,
                display: "grid", placeItems: "center",
                marginTop: 1,
              }}>
                {marketing && IcoEA2.check(14, T.goldInk)}
              </span>
              <span style={{ color: T.textMuted }}>
                <span style={{ color: T.text, fontWeight: 600 }}>Send the daily prompt</span> when it drops.
                One push a day, random time. No marketing emails.
              </span>
            </label>

            <div style={{ flex: 1, minHeight: 20 }}/>

            <PrimaryBtnEA disabled={!valid} onClick={onContinue}>
              Continue {IcoEA2.arrow(16, valid ? T.goldInk : T.textFaint)}
            </PrimaryBtnEA>

            <DividerWithLabel label="or sign up with" />

            <div style={{ display: "flex", gap: 10 }}>
              <GhostBtnEA>{IcoEA2.apple(15, T.text)} Apple</GhostBtnEA>
              <GhostBtnEA>{IcoEA2.google(15)} Google</GhostBtnEA>
            </div>

            <div style={{
              textAlign: "center", marginTop: 18,
              color: T.textMuted, fontSize: 13,
            }}>
              Already pouring?{" "}
              <button onClick={onLogin} style={{
                background: "transparent", border: "none", padding: 0,
                color: T.goldText, fontWeight: 700, fontSize: 13,
                cursor: "pointer", textDecoration: "underline", textUnderlineOffset: 3,
                fontFamily: "inherit",
              }}>Sign in</button>
            </div>
          </div>
        </div>
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

Object.assign(window, { EmailLoginScreen, EmailRegisterScreen });
