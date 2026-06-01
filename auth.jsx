// Login / Register flow for Pint.
// Steps: welcome → phone → verify → handle → done(sign-in variant included)

const { useState: useStateAuth, useEffect: useEffectAuth, useRef: useRefAuth } = React;

const useTAuth = () => React.useContext(window.ThemeContext);
const { BrandMark: BrandMarkAuth, Ico: IcoAuth, ImgPH: ImgPHAuth } = window;

const IcoAuth2 = {
  back: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M15 6 9 12l6 6"/>
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
  phone: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="6" y="2" width="12" height="20" rx="3"/><path d="M10 19h4"/>
    </svg>
  ),
  mail: (s = 18, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>
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
};

// ───────────────────────────────────────────
// Common chrome
// ───────────────────────────────────────────
function AuthShell({ children, onBack, step, totalSteps, theme = "dark" }) {
  const T = useTAuth();
  return (
    <div data-screen-label={`Auth · ${theme} · step ${step}/${totalSteps}`} style={{
      height: "100%",
      background: T.bg,
      color: T.text,
      fontFamily: '-apple-system, "Helvetica Neue", Helvetica, Arial, sans-serif',
      position: "relative",
      paddingTop: 54,
      display: "flex", flexDirection: "column",
    }}>
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
          }}>{IcoAuth2.back(20)}</button>
        ) : <div style={{ width: 36 }} />}
        {totalSteps > 1 && (
          <div style={{ display: "flex", gap: 6 }}>
            {Array.from({ length: totalSteps }).map((_, i) => (
              <div key={i} style={{
                width: i + 1 === step ? 22 : 6, height: 6, borderRadius: 3,
                background: i + 1 <= step ? T.gold : T.surfaceWeak,
                border: `1px solid ${i + 1 <= step ? "transparent" : T.border}`,
                transition: "all 0.25s",
              }} />
            ))}
          </div>
        )}
        <div style={{ width: 36 }} />
      </div>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", padding: "20px 24px 24px" }}>
        {children}
      </div>
    </div>
  );
}

function PrimaryButton({ children, disabled, onClick, full = true, style = {} }) {
  const T = useTAuth();
  return (
    <button onClick={onClick} disabled={disabled} style={{
      width: full ? "100%" : "auto",
      padding: "16px 22px", borderRadius: 16,
      background: disabled ? T.surfaceWeak : T.gold,
      border: disabled ? `1px solid ${T.border}` : "none",
      color: disabled ? T.textFaint : T.goldInk,
      fontSize: 16, fontWeight: 800,
      letterSpacing: "-0.01em",
      cursor: disabled ? "not-allowed" : "pointer",
      display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
      ...style,
    }}>{children}</button>
  );
}

function GhostButton({ children, onClick, style = {} }) {
  const T = useTAuth();
  return (
    <button onClick={onClick} style={{
      width: "100%",
      padding: "14px 22px", borderRadius: 16,
      background: T.surfaceWeak,
      border: `1px solid ${T.border}`,
      color: T.text,
      fontSize: 14, fontWeight: 700,
      letterSpacing: "-0.01em",
      cursor: "pointer",
      display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 8,
      ...style,
    }}>{children}</button>
  );
}

// ───────────────────────────────────────────
// Step 1: Welcome
// ───────────────────────────────────────────
function WelcomeStep({ onPhone, onSignIn, theme }) {
  const T = useTAuth();
  return (
    <AuthShell step={0} totalSteps={0} theme={theme}>
      {/* Stacked pint photo collage */}
      <div style={{
        flex: 1, display: "flex", flexDirection: "column",
        alignItems: "center", justifyContent: "center", gap: 24,
      }}>
        <div style={{
          position: "relative", width: 240, height: 240,
        }}>
          {/* Tilted card stack */}
          {[
            { rot: -10, tone: "beer",  drink: "Hazy Pale",   left: 0,  top: 24 },
            { rot:  10, tone: "bar",   drink: "Triple",      left: 80, top: 8 },
            { rot:  -2, tone: "night", drink: "Stout",       left: 40, top: 56 },
          ].map((c, i) => (
            <div key={i} style={{
              position: "absolute", left: c.left, top: c.top,
              width: 120, height: 160, borderRadius: 18,
              overflow: "hidden",
              transform: `rotate(${c.rot}deg)`,
              boxShadow: "0 20px 40px rgba(0,0,0,0.35)",
              border: `2px solid ${T.bg}`,
            }}>
              <ImgPHAuth tone={c.tone} label={c.drink} style={{ width: "100%", height: "100%" }} />
            </div>
          ))}
          {/* Brand mark floating */}
          <div style={{
            position: "absolute", right: -8, bottom: -8,
            background: T.bg, padding: 8, borderRadius: 18,
          }}>
            <BrandMarkAuth size={56} />
          </div>
        </div>

        <div style={{ textAlign: "center", marginTop: 12 }}>
          <div style={{
            color: T.text, fontWeight: 800, fontSize: 32,
            letterSpacing: "-0.03em", lineHeight: 1.05,
          }}>
            One beer.<br/>
            <span style={{ color: T.goldText }}>One moment.</span>
          </div>
          <div style={{
            color: T.textMuted, fontSize: 14, marginTop: 12,
            maxWidth: 280, marginLeft: "auto", marginRight: "auto",
            lineHeight: 1.45,
          }}>
            A daily prompt drops at a random time.
            Pour, snap, and see what your circle is drinking.
          </div>
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        <PrimaryButton onClick={onPhone}>
          Pour your first one {IcoAuth2.arrow(16, T.goldInk)}
        </PrimaryButton>
        <div style={{ display: "flex", gap: 10 }}>
          <GhostButton onClick={onPhone}>
            {IcoAuth2.apple(16, T.text)} Apple
          </GhostButton>
          <GhostButton onClick={onPhone}>
            {IcoAuth2.google(16)} Google
          </GhostButton>
        </div>
        <div style={{
          textAlign: "center", marginTop: 6,
          color: T.textMuted, fontSize: 13,
        }}>
          Already pouring?{" "}
          <button onClick={onSignIn} style={{
            background: "transparent", border: "none", padding: 0,
            color: T.goldText, fontWeight: 700, fontSize: 13,
            cursor: "pointer", textDecoration: "underline", textUnderlineOffset: 3,
            fontFamily: "inherit",
          }}>Sign in</button>
        </div>
        <div style={{
          textAlign: "center", color: T.textFaint, fontSize: 11,
          padding: "10px 14px 0", lineHeight: 1.4,
        }}>
          By continuing, you agree to our terms and acknowledge our privacy notice. 21+ only.
        </div>
      </div>
    </AuthShell>
  );
}

// ───────────────────────────────────────────
// Step 2: Phone entry
// ───────────────────────────────────────────
function PhoneStep({ onBack, onNext, theme, signIn = false }) {
  const T = useTAuth();
  const [phone, setPhone] = useStateAuth("");
  const [country, setCountry] = useStateAuth({ code: "+1", flag: "🇺🇸" });
  const valid = phone.replace(/\D/g, "").length >= 10;

  const fmt = (v) => {
    const d = v.replace(/\D/g, "").slice(0, 10);
    if (d.length <= 3) return d;
    if (d.length <= 6) return `(${d.slice(0,3)}) ${d.slice(3)}`;
    return `(${d.slice(0,3)}) ${d.slice(3,6)}-${d.slice(6)}`;
  };

  return (
    <AuthShell step={1} totalSteps={3} onBack={onBack} theme={theme}>
      <div style={{ marginBottom: 28 }}>
        <div style={{
          color: T.goldText, fontSize: 11, fontWeight: 700,
          letterSpacing: "0.14em", textTransform: "uppercase",
          display: "inline-flex", alignItems: "center", gap: 6,
        }}>
          {IcoAuth.bolt(10, T.goldText)} {signIn ? "Sign in" : "Step 1 of 3"}
        </div>
        <div style={{
          color: T.text, fontWeight: 800, fontSize: 28,
          letterSpacing: "-0.03em", marginTop: 8, lineHeight: 1.1,
        }}>What's your<br/>phone number?</div>
        <div style={{
          color: T.textMuted, fontSize: 14, marginTop: 8, lineHeight: 1.45,
        }}>We'll text you a 4-digit pour code. Number stays private — only your handle shows in the app.</div>
      </div>

      <div style={{
        display: "flex", gap: 8, marginBottom: 14,
      }}>
        <button style={{
          padding: "16px 14px", borderRadius: 14,
          background: T.surfaceWeak,
          border: `1px solid ${T.border}`,
          color: T.text, fontSize: 15, fontWeight: 600,
          display: "inline-flex", alignItems: "center", gap: 8,
          cursor: "pointer", fontFamily: "inherit",
        }}>
          <span style={{ fontSize: 18 }}>{country.flag}</span> {country.code}
        </button>
        <input
          value={fmt(phone)}
          onChange={e => setPhone(e.target.value.replace(/\D/g, ""))}
          placeholder="(555) 867-5309"
          inputMode="tel"
          style={{
            flex: 1, padding: "16px 18px", borderRadius: 14,
            background: T.surfaceWeak,
            border: `1px solid ${valid ? T.goldBorder : T.border}`,
            color: T.text, fontSize: 17, fontWeight: 600,
            outline: "none", letterSpacing: "-0.01em",
            fontFamily: "inherit",
            transition: "border-color 0.2s",
          }}
        />
      </div>

      <div style={{
        display: "flex", alignItems: "center", gap: 8,
        color: T.textMuted, fontSize: 12, padding: "0 4px",
        marginBottom: 16,
      }}>
        <span style={{ display: "inline-flex", color: T.goldText }}>{IcoAuth2.mail(14, T.goldText)}</span>
        Prefer email?{" "}
        <button style={{
          background: "transparent", border: "none", padding: 0,
          color: T.goldText, fontWeight: 700, cursor: "pointer",
          fontFamily: "inherit", fontSize: 12, textDecoration: "underline",
          textUnderlineOffset: 3,
        }}>Use email instead</button>
      </div>

      <div style={{ flex: 1 }} />

      <PrimaryButton disabled={!valid} onClick={() => onNext(phone)}>
        Send code {IcoAuth2.arrow(16, valid ? T.goldInk : T.textFaint)}
      </PrimaryButton>
    </AuthShell>
  );
}

// ───────────────────────────────────────────
// Step 3: OTP verification
// ───────────────────────────────────────────
function VerifyStep({ onBack, onNext, theme, phone = "(555) 867-5309", signIn = false }) {
  const T = useTAuth();
  const [code, setCode] = useStateAuth(["", "", "", ""]);
  const [error, setError] = useStateAuth(false);
  const [resent, setResent] = useStateAuth(false);
  const refs = [useRefAuth(), useRefAuth(), useRefAuth(), useRefAuth()];

  const set = (i, v) => {
    const d = v.replace(/\D/g, "").slice(-1);
    setError(false);
    setCode(prev => {
      const next = [...prev];
      next[i] = d;
      return next;
    });
    if (d && i < 3) refs[i + 1].current?.focus();
  };
  const onKey = (i, e) => {
    if (e.key === "Backspace" && !code[i] && i > 0) refs[i - 1].current?.focus();
  };

  const complete = code.every(c => c.length === 1);
  const verify = () => {
    if (code.join("") === "0000") setError(true);
    else onNext(code.join(""));
  };

  return (
    <AuthShell step={2} totalSteps={3} onBack={onBack} theme={theme}>
      <div style={{ marginBottom: 28 }}>
        <div style={{
          color: T.goldText, fontSize: 11, fontWeight: 700,
          letterSpacing: "0.14em", textTransform: "uppercase",
          display: "inline-flex", alignItems: "center", gap: 6,
        }}>
          {IcoAuth.bolt(10, T.goldText)} {signIn ? "Sign in" : "Step 2 of 3"}
        </div>
        <div style={{
          color: T.text, fontWeight: 800, fontSize: 28,
          letterSpacing: "-0.03em", marginTop: 8, lineHeight: 1.1,
        }}>Drop your<br/>pour code.</div>
        <div style={{
          color: T.textMuted, fontSize: 14, marginTop: 8, lineHeight: 1.45,
        }}>
          Sent to <span style={{ color: T.text, fontWeight: 600 }}>{phone}</span>.{" "}
          <button onClick={onBack} style={{
            background: "transparent", border: "none", padding: 0,
            color: T.goldText, fontWeight: 700, cursor: "pointer",
            fontFamily: "inherit", fontSize: 14, textDecoration: "underline",
            textUnderlineOffset: 3,
          }}>Change</button>
        </div>
      </div>

      <div style={{
        display: "flex", justifyContent: "space-between", gap: 12,
        marginBottom: 14,
      }}>
        {code.map((c, i) => (
          <input
            key={i}
            ref={refs[i]}
            value={c}
            onChange={e => set(i, e.target.value)}
            onKeyDown={e => onKey(i, e)}
            inputMode="numeric"
            maxLength={1}
            style={{
              flex: 1, aspectRatio: "1",
              textAlign: "center", fontSize: 28, fontWeight: 800,
              letterSpacing: "-0.02em",
              borderRadius: 16,
              background: T.surfaceWeak,
              border: `2px solid ${error ? "#c2511e" : (c ? T.goldBorderStrong : T.border)}`,
              color: T.text,
              outline: "none",
              fontFamily: "inherit",
              transition: "border-color 0.15s",
            }}
          />
        ))}
      </div>

      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        marginBottom: 16, padding: "0 4px",
      }}>
        {error ? (
          <div style={{ color: "#c2511e", fontSize: 12, fontWeight: 600 }}>
            That code didn't pour. Try again or resend.
          </div>
        ) : resent ? (
          <div style={{
            color: T.goldText, fontSize: 12, fontWeight: 600,
            display: "inline-flex", alignItems: "center", gap: 4,
          }}>{IcoAuth2.check(13, T.goldText)} New code sent</div>
        ) : (
          <div style={{ color: T.textMuted, fontSize: 12 }}>
            Didn't get it? Code expires in 4:32.
          </div>
        )}
        <button onClick={() => { setResent(true); setTimeout(() => setResent(false), 2000); }} style={{
          background: "transparent", border: "none", padding: 0,
          color: T.goldText, fontWeight: 700, cursor: "pointer",
          fontFamily: "inherit", fontSize: 12, textDecoration: "underline",
          textUnderlineOffset: 3,
        }}>Resend</button>
      </div>

      <div style={{ flex: 1 }} />

      <PrimaryButton disabled={!complete} onClick={verify}>
        Verify {IcoAuth2.arrow(16, complete ? T.goldInk : T.textFaint)}
      </PrimaryButton>
    </AuthShell>
  );
}

// ───────────────────────────────────────────
// Step 4: Handle picker (register only)
// ───────────────────────────────────────────
function HandleStep({ onBack, onDone, theme }) {
  const T = useTAuth();
  const [handle, setHandle] = useStateAuth("");
  const [name, setName] = useStateAuth("");
  const taken = ["sam", "maya", "theo", "you"].includes(handle.toLowerCase());
  const long = handle.length > 16;
  const short = handle.length < 3;
  const valid = !taken && !long && !short && /^[a-z0-9_]+$/.test(handle);
  const status = !handle ? null : taken ? "taken" : long ? "long" : short ? "short" : !/^[a-z0-9_]+$/.test(handle) ? "chars" : "ok";

  return (
    <AuthShell step={3} totalSteps={3} onBack={onBack} theme={theme}>
      <div style={{ marginBottom: 24 }}>
        <div style={{
          color: T.goldText, fontSize: 11, fontWeight: 700,
          letterSpacing: "0.14em", textTransform: "uppercase",
          display: "inline-flex", alignItems: "center", gap: 6,
        }}>{IcoAuth.bolt(10, T.goldText)} Step 3 of 3</div>
        <div style={{
          color: T.text, fontWeight: 800, fontSize: 28,
          letterSpacing: "-0.03em", marginTop: 8, lineHeight: 1.1,
        }}>Pick your<br/>pour name.</div>
        <div style={{ color: T.textMuted, fontSize: 14, marginTop: 8, lineHeight: 1.45 }}>
          Your handle is how friends find you and tag you in pours. Lowercase letters, numbers, underscores.
        </div>
      </div>

      {/* Avatar circle */}
      <div style={{
        display: "flex", alignItems: "center", gap: 14,
        marginBottom: 18,
      }}>
        <div style={{
          width: 64, height: 64, borderRadius: "50%",
          background: T.goldFaint,
          border: `2px solid ${T.goldBorderStrong}`,
          display: "grid", placeItems: "center",
          color: T.goldText, fontSize: 26, fontWeight: 800, letterSpacing: "-0.02em",
        }}>{(name[0] || handle[0] || "?").toUpperCase()}</div>
        <button style={{
          padding: "10px 14px", borderRadius: 999,
          background: T.surfaceWeak, border: `1px solid ${T.border}`,
          color: T.text, fontSize: 13, fontWeight: 600,
          cursor: "pointer", fontFamily: "inherit",
        }}>Upload selfie</button>
      </div>

      <div style={{ marginBottom: 12 }}>
        <label style={{
          display: "block", color: T.textMuted, fontSize: 11,
          fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase",
          marginBottom: 6, paddingLeft: 4,
        }}>Display name</label>
        <input
          value={name}
          onChange={e => setName(e.target.value)}
          placeholder="Your name"
          style={{
            width: "100%", boxSizing: "border-box",
            padding: "14px 16px", borderRadius: 14,
            background: T.surfaceWeak,
            border: `1px solid ${T.border}`,
            color: T.text, fontSize: 16, fontWeight: 600,
            outline: "none", fontFamily: "inherit",
            letterSpacing: "-0.01em",
          }}
        />
      </div>

      <div style={{ marginBottom: 10 }}>
        <label style={{
          display: "block", color: T.textMuted, fontSize: 11,
          fontWeight: 700, letterSpacing: "0.14em", textTransform: "uppercase",
          marginBottom: 6, paddingLeft: 4,
        }}>Handle</label>
        <div style={{
          display: "flex", alignItems: "center",
          padding: "0 16px 0 14px", borderRadius: 14,
          background: T.surfaceWeak,
          border: `1px solid ${
            status === "ok" ? T.goldBorderStrong :
            status && status !== "ok" ? "#c2511e" :
            T.border
          }`,
        }}>
          <span style={{ color: T.textMuted, fontSize: 16, fontWeight: 600, marginRight: 2 }}>@</span>
          <input
            value={handle}
            onChange={e => setHandle(e.target.value.toLowerCase().replace(/\s/g, ""))}
            placeholder="yourhandle"
            style={{
              flex: 1, padding: "14px 0", border: "none",
              background: "transparent", color: T.text,
              fontSize: 16, fontWeight: 600, outline: "none",
              fontFamily: "inherit", letterSpacing: "-0.01em",
            }}
          />
          {status === "ok" && (
            <span style={{ display: "inline-flex", color: T.goldText }}>{IcoAuth2.check(18, T.goldText)}</span>
          )}
        </div>
        <div style={{
          minHeight: 18, marginTop: 6, paddingLeft: 4,
          fontSize: 12, color: status === "ok" ? T.goldText :
            status === "taken" ? "#c2511e" :
            status ? "#c2511e" : T.textMuted,
          fontWeight: 600,
        }}>
          {status === "ok"   && `@${handle} is yours.`}
          {status === "taken" && `@${handle} is taken. Try ${handle}_${Math.floor(Math.random() * 99)}.`}
          {status === "short" && "At least 3 characters."}
          {status === "long"  && "Max 16 characters."}
          {status === "chars" && "Letters, numbers, and underscores only."}
          {!status && "3–16 characters."}
        </div>
      </div>

      {/* notifications opt-in */}
      <div style={{
        padding: "12px 14px", borderRadius: 14,
        background: T.goldFaint,
        border: `1px solid ${T.goldBorder}`,
        display: "flex", gap: 10, alignItems: "flex-start",
        marginTop: 8,
      }}>
        <div style={{
          width: 22, height: 22, borderRadius: 7,
          background: T.gold, color: T.goldInk,
          display: "grid", placeItems: "center",
          flexShrink: 0,
        }}>{IcoAuth2.check(14, T.goldInk)}</div>
        <div style={{ fontSize: 12, color: T.text, lineHeight: 1.45 }}>
          <span style={{ fontWeight: 700 }}>Send me the daily prompt.</span>{" "}
          <span style={{ color: T.textMuted }}>One push per day. Random time. Miss it and your pour shows up late.</span>
        </div>
      </div>

      <div style={{ flex: 1, minHeight: 16 }} />

      <PrimaryButton disabled={!valid || !name.trim()} onClick={onDone}>
        Pour the first one 🍻
      </PrimaryButton>
    </AuthShell>
  );
}

// ───────────────────────────────────────────
// Final / success screen
// ───────────────────────────────────────────
function SuccessStep({ theme, onEnter }) {
  const T = useTAuth();
  return (
    <AuthShell step={0} totalSteps={0} theme={theme}>
      <div style={{
        flex: 1, display: "flex", flexDirection: "column",
        alignItems: "center", justifyContent: "center", gap: 18, textAlign: "center",
      }}>
        <div style={{
          width: 96, height: 96, borderRadius: "50%",
          background: T.goldSoft,
          border: `2px solid ${T.goldBorderStrong}`,
          display: "grid", placeItems: "center",
          color: T.goldText,
        }}>{IcoAuth2.check(46, T.goldText)}</div>
        <div style={{
          color: T.text, fontWeight: 800, fontSize: 28,
          letterSpacing: "-0.03em", lineHeight: 1.1, marginTop: 4,
        }}>You're in,<br/>@you.</div>
        <div style={{ color: T.textMuted, fontSize: 14, lineHeight: 1.45, maxWidth: 280 }}>
          The next prompt drops sometime tomorrow.
          We'll buzz when it's time to pour.
        </div>
      </div>
      <PrimaryButton onClick={onEnter}>Open Pint.</PrimaryButton>
    </AuthShell>
  );
}

// ───────────────────────────────────────────
// Top-level controller — for showcase, exposes individual frames too
// ───────────────────────────────────────────
function AuthFlow({ theme = "dark", initialStep = "welcome" }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [step, setStep] = useStateAuth(initialStep);
  const [phone, setPhone] = useStateAuth("");
  const [signIn, setSignIn] = useStateAuth(false);

  let body;
  if (step === "welcome") body = <WelcomeStep theme={theme} onPhone={() => { setSignIn(false); setStep("phone"); }} onSignIn={() => { setSignIn(true); setStep("phone"); }} />;
  else if (step === "phone") body = <PhoneStep theme={theme} signIn={signIn} onBack={() => setStep("welcome")} onNext={p => { setPhone(p); setStep("verify"); }} />;
  else if (step === "verify") body = <VerifyStep theme={theme} signIn={signIn} phone={phone ? `(${phone.slice(0,3)}) ${phone.slice(3,6)}-${phone.slice(6)}` : "(555) 867-5309"} onBack={() => setStep("phone")} onNext={() => setStep(signIn ? "done" : "handle")} />;
  else if (step === "handle") body = <HandleStep theme={theme} onBack={() => setStep("verify")} onDone={() => setStep("done")} />;
  else body = <SuccessStep theme={theme} onEnter={() => setStep("welcome")} />;

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        {body}
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

// Single-step pinned variant for the showcase grid
function AuthStepFrame({ theme = "dark", which = "welcome" }) {
  const T = window.THEMES[theme] || window.THEMES.dark;
  const [step, setStep] = useStateAuth(which);
  const [phone, setPhone] = useStateAuth("5558675309");

  let body;
  const noop = () => {};
  if (step === "welcome")
    body = <WelcomeStep theme={theme} onPhone={() => setStep("phone")} onSignIn={() => setStep("phone")} />;
  else if (step === "phone")
    body = <PhoneStep theme={theme} onBack={() => setStep("welcome")} onNext={p => { setPhone(p); setStep("verify"); }} />;
  else if (step === "verify")
    body = <VerifyStep theme={theme} phone="(555) 867-5309" onBack={() => setStep("phone")} onNext={() => setStep("handle")} />;
  else if (step === "handle")
    body = <HandleStep theme={theme} onBack={() => setStep("verify")} onDone={() => setStep("done")} />;
  else
    body = <SuccessStep theme={theme} onEnter={noop} />;

  return (
    <window.ThemeContext.Provider value={T}>
      <window.IOSDevice width={402} height={874} dark={T.iosDark}>
        {body}
      </window.IOSDevice>
    </window.ThemeContext.Provider>
  );
}

Object.assign(window, { AuthFlow, AuthStepFrame });
