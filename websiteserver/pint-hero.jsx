// site-hero.jsx — Pint. landing: shared atoms + nav + hero
const { useState, useEffect, useRef } = React;

// ── Brand wordmark / mark (CSS version, matches app) ──
function Mark({ size = 30 }) {
  return (
    <span className="bmark" style={{ width: size, height: size }}>
      <span className="b" style={{ fontSize: size * 0.95, paddingBottom: size * 0.02 }}>B</span>
      <span className="foam" style={{ left: "38%", top: "10%", width: size*0.11, height: size*0.11, background:"#fff" }} />
      <span className="foam" style={{ left: "55%", top: "6%",  width: size*0.075, height: size*0.075, background:"#fff" }} />
      <span className="foam" style={{ left: "66%", top: "14%", width: size*0.056, height: size*0.056, background:"#f0ebde" }} />
    </span>
  );
}

function Wordmark({ size = 30, fs = 23 }) {
  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 10 }}>
      <Mark size={size} />
      <span style={{ fontWeight: 800, fontSize: fs, letterSpacing: "-0.03em" }}>
        Pint<span className="gold-text">.</span>
      </span>
    </span>
  );
}

// ── Store buttons ──
function StoreButtons({ small = false }) {
  return (
    <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
      <a className="store-btn" href="#get" style={small ? { padding: "10px 16px 10px 14px" } : {}}>
        <svg width="22" height="26" viewBox="0 0 24 28" fill="#0a0a0a"><path d="M17.5 14.9c0-2.7 2.2-4 2.3-4.1-1.3-1.8-3.2-2.1-3.9-2.1-1.6-.2-3.2 1-4 1-.8 0-2.1-1-3.5-.9-1.8 0-3.4 1-4.3 2.6-1.9 3.2-.5 8 1.3 10.6.9 1.3 1.9 2.7 3.3 2.6 1.3-.1 1.8-.8 3.4-.8 1.6 0 2 .8 3.4.8 1.4 0 2.3-1.3 3.2-2.6.7-1 1-1.5 1.5-2.6-3.9-1.5-4.4-6.9-.7-9.1zM15 6.9c.7-.9 1.2-2.1 1.1-3.3-1 0-2.3.7-3 1.6-.7.8-1.3 2-1.1 3.2 1.1.1 2.3-.6 3-1.5z"/></svg>
        <span><span className="sb-sub">Download on the</span><span className="sb-main">App Store</span></span>
      </a>
      <a className="store-btn" href="#get" style={small ? { padding: "10px 16px 10px 14px" } : {}}>
        <svg width="22" height="24" viewBox="0 0 22 24" fill="none"><path d="M2 1.5 13 12 2 22.5c-.5-.2-.8-.7-.8-1.4V2.9c0-.7.3-1.2.8-1.4z" fill="#0a0a0a"/><path d="M2 1.5 13 12 2 22.5" stroke="#0a0a0a" strokeWidth="0.4"/></svg>
        <span><span className="sb-sub">Get it on</span><span className="sb-main">Google Play</span></span>
      </a>
    </div>
  );
}

// ── Phone embed: a real PintApp screen, scaled ──
function Phone({ screen = "feed", posted = false, theme = "dark", scale = 1, demoReact = false, style = {} }) {
  const W = 402, H = 874;
  const { PintApp } = window;
  return (
    <div style={{ width: W * scale, height: H * scale, position: "relative", ...style }}>
      <div className="phone-scale" style={{ position: "absolute", top: 0, left: 0, width: W, height: H, transform: `scale(${scale})`, transformOrigin: "top left" }}>
        <PintApp initialScreen={screen} initialPosted={posted} theme={theme} demoReact={demoReact} />
      </div>
    </div>
  );
}

// ── Sticky nav ──
function Nav() {
  const [scrolled, setScrolled] = useState(false);
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);
  const links = [
    { label: "How it works", href: "#how" },
    { label: "Features", href: "#features" },
    { label: "The Map", href: "#map" },
    { label: "Bingo", href: "#bingo" },
  ];
  return (
    <div style={{
      position: "fixed", top: 0, left: 0, right: 0, zIndex: 100,
      transition: "background .25s ease, border-color .25s ease, backdrop-filter .25s",
      background: scrolled ? "rgba(10,10,10,0.72)" : "transparent",
      backdropFilter: scrolled ? "blur(16px) saturate(160%)" : "none",
      WebkitBackdropFilter: scrolled ? "blur(16px) saturate(160%)" : "none",
      borderBottom: `1px solid ${scrolled ? "var(--border)" : "transparent"}`,
    }}>
      <div className="wrap" style={{ display: "flex", alignItems: "center", justifyContent: "space-between", height: 70 }}>
        <a href="#top"><Wordmark size={30} fs={23} /></a>
        <div className="nav-links" style={{ display: "flex", alignItems: "center", gap: 30 }}>
          {links.map(l => (
            <a key={l.href} href={l.href} style={{ fontSize: 14.5, fontWeight: 500, color: "var(--muted)", transition: "color .15s" }}
              onMouseEnter={e => e.currentTarget.style.color = "#fff"}
              onMouseLeave={e => e.currentTarget.style.color = "var(--muted)"}>{l.label}</a>
          ))}
        </div>
        <a className="btn btn-gold" href="#get" style={{ padding: "11px 20px", fontSize: 14.5 }}>Get Pint</a>
      </div>
    </div>
  );
}

// ── Hero ──
function Hero() {
  return (
    <section id="top" style={{ position: "relative", paddingTop: 132, paddingBottom: 40, overflow: "hidden" }}>
      {/* ambient glows */}
      <div className="glow" style={{ width: 620, height: 620, top: -160, right: -120, opacity: 0.55 }} />
      <div className="glow" style={{ width: 460, height: 460, bottom: -160, left: -160, opacity: 0.30 }} />
      {/* grain-ish top vignette */}
      <div style={{ position: "absolute", inset: 0, background: "radial-gradient(ellipse 80% 50% at 50% 0%, rgba(246,183,51,0.07), transparent 70%)", pointerEvents: "none" }} />

      <div className="wrap hero-grid" style={{
        position: "relative", display: "grid",
        gridTemplateColumns: "1.05fr 0.95fr", gap: 40, alignItems: "center",
      }}>
        {/* Left: copy */}
        <div>
          <div className="reveal pill pill-gold" style={{ marginBottom: 26 }}>
            <BoltGlyph /> One prompt a day. No scrolling forever.
          </div>
          <h1 className="display reveal" style={{ transitionDelay: ".05s" }}>
            Pour with<br/>your <span className="beer-clip">people.</span>
          </h1>
          <p className="lede reveal" style={{ marginTop: 26, maxWidth: 480, transitionDelay: ".12s" }}>
            Pint sends one surprise prompt a day. Snap your glass and a quick selfie,
            see what your circle is drinking right now, and cheers them from anywhere.
          </p>
          <div className="reveal" style={{ marginTop: 32, transitionDelay: ".18s" }}>
            <StoreButtons />
          </div>
          <div className="reveal" style={{ display: "flex", alignItems: "center", gap: 16, marginTop: 30, transitionDelay: ".24s" }}>
            <div style={{ display: "flex" }}>
              {["selfie","avatar","bar","night"].map((t, i) => (
                <span key={i} style={{
                  width: 34, height: 34, borderRadius: "50%", overflow: "hidden",
                  border: "2px solid var(--bg)", marginLeft: i ? -11 : 0,
                  background: ["#6a4a2a","#4a3a2a","#3a2410","#1a1a22"][i],
                  display: "inline-block",
                }} />
              ))}
            </div>
            <div style={{ fontSize: 13.5, color: "var(--muted)", lineHeight: 1.35 }}>
              <strong style={{ color: "#fff" }}>40,000+</strong> friends poured today<br/>
              <span style={{ color: "var(--goldText)" }}>★★★★★</span> 4.9 · loved on the App Store
            </div>
          </div>
        </div>

        {/* Right: live phone */}
        <div className="hero-phone reveal" style={{ position: "relative", display: "flex", justifyContent: "center", transitionDelay: ".1s" }}>
          <div className="glow" style={{ width: 360, height: 520, top: 30, left: "50%", transform: "translateX(-50%)", opacity: 0.5 }} />
          <div style={{ position: "relative", transform: "rotate(-2deg)" }}>
            <Phone screen="feed" posted={false} theme="dark" scale={0.82} demoReact={true} />
          </div>
        </div>
      </div>

      {/* marquee strip */}
      <Marquee />
    </section>
  );
}

function BoltGlyph({ s = 12, c = "currentColor" }) {
  return <svg width={s} height={s} viewBox="0 0 24 24" fill={c}><path d="M13 2 4 14h7l-1 8 9-12h-7z"/></svg>;
}

function Marquee() {
  const items = ["Snap your pour", "•", "See your circle", "•", "Cheers from anywhere", "•", "Keep your streak", "•", "Climb the leaderboard", "•", "Play Bier-Bingo", "•"];
  const run = [...items, ...items];
  return (
    <div style={{ marginTop: 88, borderTop: "1px solid var(--border)", borderBottom: "1px solid var(--border)", padding: "18px 0", overflow: "hidden", position: "relative", maskImage: "linear-gradient(90deg, transparent, #000 8%, #000 92%, transparent)", WebkitMaskImage: "linear-gradient(90deg, transparent, #000 8%, #000 92%, transparent)" }}>
      <div style={{ display: "inline-flex", gap: 38, whiteSpace: "nowrap", animation: "marq 28s linear infinite", willChange: "transform" }}>
        {run.map((t, i) => (
          <span key={i} style={{
            fontFamily: t === "•" ? "inherit" : "var(--mono)",
            fontSize: t === "•" ? 16 : 14, letterSpacing: t === "•" ? 0 : "0.14em",
            textTransform: "uppercase", color: t === "•" ? "var(--goldText)" : "var(--muted)", fontWeight: 600,
          }}>{t}</span>
        ))}
      </div>
    </div>
  );
}

// keyframes + responsive (injected once)
if (!document.getElementById("hero-kf")) {
  const st = document.createElement("style");
  st.id = "hero-kf";
  st.textContent = `
    @keyframes marq { from { transform: translateX(0); } to { transform: translateX(-50%); } }
    @media (max-width: 940px) {
      .hero-grid { grid-template-columns: 1fr !important; gap: 8px !important; }
      .hero-phone { order: -1; margin-bottom: 8px; }
      .nav-links { display: none !important; }
    }
    @media (prefers-reduced-motion: reduce) {
      [style*="marq"] { animation: none !important; }
    }
  `;
  document.head.appendChild(st);
}

function SiteHero() {
  return (
    <React.Fragment>
      <Nav />
      <Hero />
    </React.Fragment>
  );
}

Object.assign(window, { SiteHero, Mark, Wordmark, StoreButtons, Phone, BoltGlyph });
