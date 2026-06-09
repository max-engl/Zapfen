// site-sections.jsx — Zapfen landing: how-it-works, features, bingo, CTA, footer
const { Phone, StoreButtons, Wordmark, Mark, BoltGlyph } = window;

// small glyphs (reuse app icon set where possible)
function Glyph({ name, s = 26, c = "currentColor" }) {
  const I = window.Ico;
  if (I && I[name]) return I[name](s, c);
  return null;
}

// ─────────────────────────────────────────────
// HOW IT WORKS — three steps
// ─────────────────────────────────────────────
function HowItWorks() {
  const steps = [
    { ico: "bolt", n: "01", title: "Der Prompt kommt", body: "Einmal am Tag, zu einem zufälligen Moment, vibriert Zapfen bei allen gleichzeitig. Kein Planen, kein Tricksen. Wenn er landet, hast du ein kurzes Zeitfenster zum Zapfen." },
    { ico: "cam", n: "02", title: "Halte dein Bier fest", body: "Front- und Rückkamera lösen gemeinsam aus: dein Glas und dein Gesicht, genau dort, wo du bist. Noch eine Zeile dazu, was im Glas ist, und du bist dabei." },
    { ico: "cheers", n: "03", title: "Stoß mit deinem Kreis an", body: "Sieh alle heutigen Biermomente deiner Freunde in einem ehrlichen Feed. Reagiere, kommentiere und stoße quer durch die Stadt oder um die Welt an." },
  ];
  return (
    <section id="how" style={{ padding: "120px 0 100px" }}>
      <div className="wrap">
        <div style={{ textAlign: "center", maxWidth: 720, margin: "0 auto 64px" }}>
          <div className="kicker reveal">So funktioniert Zapfen</div>
          <h2 className="h2 reveal" style={{ marginTop: 18, transitionDelay: ".05s" }}>
            Drei Taps von durstig<br/>zu <span className="gold-text">zusammen.</span>
          </h2>
        </div>
        <div className="how-grid" style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 22 }}>
          {steps.map((s, i) => (
            <div key={s.n} className="reveal" style={{
              position: "relative", padding: "34px 30px 36px",
              borderRadius: 22, background: "var(--surface)",
              border: "1px solid var(--border)", overflow: "hidden",
              transitionDelay: `${i * 0.08}s`,
            }}>
              <div style={{ position: "absolute", top: -16, right: 14, fontSize: 92, fontWeight: 900, letterSpacing: "-0.06em", color: "rgba(255,255,255,0.035)" }}>{s.n}</div>
              <div style={{ width: 52, height: 52, borderRadius: 15, background: "var(--goldSoft)", border: "1px solid var(--goldBorder)", display: "grid", placeItems: "center", color: "var(--goldText)", marginBottom: 22 }}>
                <Glyph name={s.ico} s={26} c="var(--goldText)" />
              </div>
              <h3 style={{ fontSize: 22, fontWeight: 800, letterSpacing: "-0.02em" }}>{s.title}</h3>
              <p style={{ marginTop: 12, fontSize: 15.5, lineHeight: 1.55, color: "var(--muted)" }}>{s.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────
// FEATURE ROW — phone + copy, alternating + optional cream theme
// ─────────────────────────────────────────────
function FeatureRow({ id, kicker, title, body, bullets, phone, flip = false, cream = false, accentList }) {
  const textCol = cream ? "#0a0a0a" : "#fff";
  const muted = cream ? "rgba(0,0,0,0.6)" : "var(--muted)";
  const cardBorder = cream ? "rgba(0,0,0,0.10)" : "var(--border)";
  return (
    <div className="feat-grid" style={{
      display: "grid", gridTemplateColumns: flip ? "0.95fr 1.05fr" : "1.05fr 0.95fr",
      gap: 56, alignItems: "center",
    }}>
      <div style={{ order: flip ? 2 : 1 }} className={flip ? "feat-copy-flip" : "feat-copy"}>
        <div className="reveal kicker" style={{ color: cream ? "var(--goldDeep)" : "var(--goldText)" }}>{kicker}</div>
        <h2 className="h2 reveal" style={{ marginTop: 16, color: textCol, transitionDelay: ".05s" }}>{title}</h2>
        <p className="reveal" style={{ marginTop: 20, fontSize: 18, lineHeight: 1.55, color: muted, maxWidth: 460, transitionDelay: ".1s" }}>{body}</p>
        {bullets && (
          <ul className="reveal" style={{ listStyle: "none", padding: 0, margin: "26px 0 0", display: "grid", gap: 14, transitionDelay: ".15s" }}>
            {bullets.map((b, i) => (
              <li key={i} style={{ display: "flex", gap: 13, alignItems: "flex-start" }}>
                <span style={{ flex: "none", width: 24, height: 24, borderRadius: "50%", marginTop: 1, background: "var(--gold)", color: "var(--goldInk)", display: "grid", placeItems: "center" }}>
                  <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3.2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12.5 10 17l9-10"/></svg>
                </span>
                <span style={{ fontSize: 15.5, lineHeight: 1.45, color: cream ? "rgba(0,0,0,0.78)" : "rgba(255,255,255,0.82)" }}>
                  <strong style={{ color: textCol, fontWeight: 700 }}>{b.h}</strong> {b.t}
                </span>
              </li>
            ))}
          </ul>
        )}
      </div>
      <div className="reveal" style={{ order: flip ? 1 : 2, position: "relative", display: "flex", justifyContent: "center", transitionDelay: ".08s" }}>
        <div className="glow" style={{ width: 340, height: 460, top: 20, left: "50%", transform: "translateX(-50%)", opacity: cream ? 0.28 : 0.42 }} />
        <div style={{ position: "relative", transform: flip ? "rotate(2deg)" : "rotate(-2deg)", filter: "drop-shadow(0 40px 70px rgba(0,0,0,0.5))" }}>
          {phone}
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// FEATURES — Map (cream/light) + Streaks (dark)
// ─────────────────────────────────────────────
function Features() {
  return (
    <React.Fragment>
      {/* anchor target for nav "Features" */}
      <span id="features" />

      {/* The Map — light theme phone on cream */}
      <section id="map" style={{ background: "var(--cream)", color: "#0a0a0a", padding: "110px 0", borderRadius: "40px 40px 0 0" }}>
        <div className="wrap">
          <FeatureRow
            cream
            kicker="Sieh, wie der Abend entsteht"
            title={<span>Eine Live-Karte,<br/>wer gerade zapft.</span>}
            body="Jeder Freund, der heute gezapft hat, erscheint mit einem goldenen Pin auf der Karte. Tippe darauf, um zu sehen, was im Glas ist, dir den Weg zeigen zu lassen oder schon vor dem Ankommen anzustoßen."
            bullets={[
              { h: "Pins in Echtzeit -", t: "dein Kreis lässt die Karte aufleuchten, sobald der Prompt um die Welt geht." },
              { h: "Tippen und dazukommen -", t: "Wegbeschreibung mit einem Tap, damit die nächste Runde schon unterwegs ist." },
              { h: "Privat von Anfang an -", t: "nur deine Freunde sehen deinen Ort, und nur für diesen Tag." },
            ]}
            phone={<Phone screen="map" posted theme="light" scale={0.72} />}
          />
        </div>
      </section>

      {/* Streaks + achievements — dark */}
      <section style={{ background: "var(--cream)", padding: "0 0 0", borderRadius: "0 0 40px 40px" }}>
        <div style={{ background: "var(--bg)", borderRadius: "40px 40px 0 0", padding: "110px 0 120px" }}>
          <div className="wrap">
            <FeatureRow
              flip
              kicker="Gebaut, damit die Runde weitergeht"
              title={<span>Serien, Abzeichen<br/>und Ruhm.</span>}
              body="Zapf Tag für Tag und deine Serie wächst. Verdiene Medaillen für lange Nächte, neue Städte und hundert Biermomente - alles auf einem Profil, das deine Freunde wirklich anschauen."
              bullets={[
                { h: "Tägliche Serien -", t: "eine 12-Wochen-Heatmap, die Dranbleiben belohnt." },
                { h: "Erfolge -", t: "von der Ersten Runde bis zum Weltenbummler wartet immer das nächste Ziel." },
                { h: "Deine Wand -", t: "jeder Biermoment, den du geloggt hast, in einem warmen Raster." },
              ]}
              phone={<Phone screen="profile" posted theme="dark" scale={0.72} />}
            />
          </div>
        </div>
      </section>
    </React.Fragment>
  );
}

// ─────────────────────────────────────────────
// BIER-BINGO + LEADERBOARD band
// ─────────────────────────────────────────────
function BingoCardMini() {
  const card = window.fetchBingoCard ? window.fetchBingoCard() : null;
  if (!card) return null;
  return (
    <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 7, width: "100%", maxWidth: 360 }}>
      {card.cells.map((c) => (
        <div key={c.id} style={{
          aspectRatio: "1", borderRadius: 12, padding: 4,
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 3,
          textAlign: "center",
          background: c.free ? "var(--gold)" : (c.done ? "var(--goldSoft)" : "var(--surface)"),
          border: `1px solid ${c.free ? "var(--gold)" : (c.done ? "var(--goldBorder)" : "var(--border)")}`,
          boxShadow: c.done && !c.free ? "inset 0 0 12px rgba(246,183,51,0.08)" : "none",
        }}>
          <span style={{ fontSize: 17, lineHeight: 1, filter: c.done ? "none" : "grayscale(0.7) opacity(0.5)" }}>{c.emoji}</span>
          <span style={{ fontSize: 7.5, fontWeight: 700, letterSpacing: "-0.01em", lineHeight: 1.05, color: c.free ? "var(--goldInk)" : (c.done ? "var(--goldText)" : "var(--faint)") }}>{c.label}</span>
        </div>
      ))}
    </div>
  );
}

const LEADERS = [
  { r: 1, name: "Jonas Lindqvist", h: "@jlind", pts: 412, tone: "#3a2a1a" },
  { r: 2, name: "Theo Park", h: "@theop", pts: 388, tone: "#4a3a2a" },
  { r: 3, name: "Maya Calderón", h: "@mayac", pts: 351, tone: "#6a4a2a" },
  { r: 4, name: "Du", h: "@du", pts: 312, tone: "#5a3a1a", you: true },
  { r: 5, name: "Priya Anand", h: "@priyaa", pts: 286, tone: "#3a2410" },
];

function BingoLeaderboard() {
  return (
    <section id="bingo" style={{ padding: "118px 0" }}>
      <div className="wrap">
        <div style={{ textAlign: "center", maxWidth: 720, margin: "0 auto 60px" }}>
          <div className="kicker reveal">Mach ein Spiel daraus</div>
          <h2 className="h2 reveal" style={{ marginTop: 18, transitionDelay: ".05s" }}>
            Bier-Bingo und ein wöchentliches<br/><span className="gold-text">Rennen nach oben.</span>
          </h2>
          <p className="lede reveal" style={{ margin: "20px auto 0", maxWidth: 560, transitionDelay: ".1s" }}>
            Jeden Monat eine neue Karte. Jede Woche ein Live-Ranking. Zapfen macht aus
            deinen normalen Biermomenten Felder zum Füllen und Freunde zum Überholen.
          </p>
        </div>

        <div className="bingo-grid" style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 22 }}>
          {/* Bingo card */}
          <div className="reveal" style={{ position: "relative", padding: "34px 30px 32px", borderRadius: 24, background: "linear-gradient(180deg, var(--surface2), var(--surface))", border: "1px solid var(--border)", overflow: "hidden" }}>
            <div className="glow" style={{ width: 280, height: 280, top: -60, right: -60, opacity: 0.32 }} />
            <div style={{ position: "relative", display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 24 }}>
              <div>
                <div style={{ fontSize: 19, fontWeight: 800, letterSpacing: "-0.02em" }}>Bier-Bingo</div>
                <div style={{ fontSize: 13, color: "var(--muted)", marginTop: 2 }}>Juni 2026 · 16 / 25 erledigt</div>
              </div>
              <span className="pill pill-gold"><BoltGlyph /> 2 Zeilen</span>
            </div>
            <div style={{ position: "relative", display: "flex", justifyContent: "center" }}>
              <BingoCardMini />
            </div>
          </div>

          {/* Leaderboard */}
          <div className="reveal" style={{ position: "relative", padding: "34px 30px 30px", borderRadius: 24, background: "linear-gradient(180deg, var(--surface2), var(--surface))", border: "1px solid var(--border)", transitionDelay: ".08s" }}>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 22 }}>
              <div>
                <div style={{ fontSize: 19, fontWeight: 800, letterSpacing: "-0.02em" }}>Dein Kreis diese Woche</div>
                <div style={{ fontSize: 13, color: "var(--muted)", marginTop: 2 }}>Prost gesammelt · Reset am Sonntag</div>
              </div>
              <span className="pill pill-outline"><Glyph name="cheers" s={14} c="var(--goldText)" /> Top 5</span>
            </div>
            <div style={{ display: "grid", gap: 8 }}>
              {LEADERS.map(l => (
                <div key={l.r} style={{
                  display: "flex", alignItems: "center", gap: 13, padding: "10px 14px", borderRadius: 14,
                  background: l.you ? "var(--goldFaint)" : "rgba(255,255,255,0.025)",
                  border: `1px solid ${l.you ? "var(--goldBorder)" : "var(--borderWeak)"}`,
                }}>
                  <span style={{ width: 22, textAlign: "center", fontWeight: 800, fontSize: 14, color: l.r <= 3 ? "var(--goldText)" : "var(--faint)" }}>{l.r}</span>
                  <span style={{ width: 34, height: 34, borderRadius: "50%", background: l.tone, flex: "none", border: l.you ? "2px solid var(--gold)" : "2px solid transparent" }} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 14.5, fontWeight: 600, letterSpacing: "-0.01em" }}>{l.name}</div>
                    <div style={{ fontSize: 12, color: "var(--muted)" }}>{l.h}</div>
                  </div>
                  <div style={{ display: "inline-flex", alignItems: "center", gap: 5, fontSize: 14, fontWeight: 700, color: l.you ? "var(--goldText)" : "#fff" }}>
                    {l.pts}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────
// QUOTE / STAT band
// ─────────────────────────────────────────────
function StatBand() {
  const stats = [
    { v: "1", l: "Prompt pro Tag" },
    { v: "40k+", l: "Biermomente täglich" },
    { v: "4,9★", l: "App-Store-Bewertung" },
    { v: "0", l: "Endlos-Scrollen" },
  ];
  return (
    <section style={{ padding: "10px 0 70px" }}>
      <div className="wrap">
        <div className="reveal" style={{ borderRadius: 28, padding: "54px 40px", background: "linear-gradient(135deg, rgba(246,183,51,0.10), rgba(246,183,51,0.03))", border: "1px solid var(--goldBorder)", textAlign: "center" }}>
          <p style={{ fontSize: "clamp(24px, 3.2vw, 38px)", fontWeight: 700, letterSpacing: "-0.03em", lineHeight: 1.18, maxWidth: 860, margin: "0 auto" }}>
            „Das ist die eine App, auf die ich mich wirklich freue. Der Prompt kommt, ich zeige mein Bier
            und weiß plötzlich <span className="gold-text">genau</span>, wen ich auf eine Runde anrufe.“
          </p>
          <div style={{ marginTop: 22, fontSize: 14, color: "var(--muted)", fontFamily: "var(--mono)", letterSpacing: "0.08em", textTransform: "uppercase" }}>- Maya C., 312 Tage am Stück gezapft</div>
          <div className="stat-row" style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 20, marginTop: 48, paddingTop: 40, borderTop: "1px solid var(--goldBorder)" }}>
            {stats.map((s, i) => (
              <div key={i}>
                <div style={{ fontSize: "clamp(30px, 4vw, 46px)", fontWeight: 800, letterSpacing: "-0.04em" }} className="gold-text">{s.v}</div>
                <div style={{ fontSize: 13, color: "var(--muted)", marginTop: 6, letterSpacing: "0.04em" }}>{s.l}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

// ─────────────────────────────────────────────
// CTA + FOOTER
// ─────────────────────────────────────────────
function CTA() {
  return (
    <section id="get" style={{ padding: "40px 0 110px" }}>
      <div className="wrap">
        <div className="reveal" style={{ position: "relative", overflow: "hidden", borderRadius: 34, background: "var(--gold)", color: "var(--goldInk)", padding: "78px 40px", textAlign: "center" }}>
          <div style={{ position: "absolute", inset: 0, background: "radial-gradient(circle at 50% 120%, rgba(255,255,255,0.35), transparent 60%)", pointerEvents: "none" }} />
          <div style={{ position: "relative" }}>
            <div style={{ display: "inline-flex", marginBottom: 26 }}><Mark size={56} /></div>
            <h2 style={{ fontSize: "clamp(40px, 6.5vw, 84px)", fontWeight: 800, letterSpacing: "-0.045em", lineHeight: 0.95 }}>
              Gleich ist es Zeit<br/>zu zapfen.
            </h2>
            <p style={{ fontSize: 19, lineHeight: 1.5, margin: "22px auto 0", maxWidth: 480, color: "rgba(58,31,2,0.78)", fontWeight: 500 }}>
              Kostenlos dabei sein. Ein Prompt pro Tag. Bring die Freunde mit, mit denen du wirklich eine Runde teilen würdest.
            </p>
            <div style={{ display: "flex", justifyContent: "center", marginTop: 34 }}>
              <StoreButtons />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function Footer() {
  const cols = [
    { h: "App", links: ["Der tägliche Biermoment", "Karte", "Serien", "Bier-Bingo", "Ranking"] },
    { h: "Unternehmen", links: ["Über uns", "Jobs", "Presse", "Verantwortungsvoll trinken"] },
    { h: "Rechtliches", links: ["Datenschutz", "AGB", "Cookies", "Altersrichtlinie"] },
  ];
  return (
    <footer style={{ borderTop: "1px solid var(--border)", padding: "64px 0 50px" }}>
      <div className="wrap">
        <div className="foot-grid" style={{ display: "grid", gridTemplateColumns: "1.4fr 1fr 1fr 1fr", gap: 40 }}>
          <div>
            <Wordmark size={32} fs={25} />
            <p style={{ marginTop: 18, fontSize: 14.5, lineHeight: 1.55, color: "var(--muted)", maxWidth: 280 }}>
              Der einmal tägliche Biermoment, den du mit deinem engsten Kreis teilst.
            </p>
            <div style={{ marginTop: 22 }}><StoreButtons small /></div>
          </div>
          {cols.map(c => (
            <div key={c.h}>
              <div className="kicker" style={{ fontSize: 11, marginBottom: 16 }}>{c.h}</div>
              <ul style={{ listStyle: "none", padding: 0, margin: 0, display: "grid", gap: 11 }}>
                {c.links.map(l => (
                  <li key={l}><a href="#top" style={{ fontSize: 14.5, color: "var(--muted)" }}
                    onMouseEnter={e => e.currentTarget.style.color = "#fff"}
                    onMouseLeave={e => e.currentTarget.style.color = "var(--muted)"}>{l}</a></li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div style={{ marginTop: 54, paddingTop: 26, borderTop: "1px solid var(--borderWeak)", display: "flex", justifyContent: "space-between", flexWrap: "wrap", gap: 12 }}>
          <div style={{ fontSize: 13, color: "var(--faint)" }}>© 2026 Zapfen. - Bitte verantwortungsvoll genießen. 21+ / 18+ wo zutreffend.</div>
          <div style={{ fontSize: 13, color: "var(--faint)", fontFamily: "var(--mono)", letterSpacing: "0.1em" }}>GEMACHT FÜR MENSCHEN, DIE IHRE FREUNDE NOCH ANRUFEN</div>
        </div>
      </div>
    </footer>
  );
}

// responsive
if (!document.getElementById("sections-kf")) {
  const st = document.createElement("style");
  st.id = "sections-kf";
  st.textContent = `
    @media (max-width: 900px) {
      .how-grid { grid-template-columns: 1fr !important; }
      .feat-grid { grid-template-columns: 1fr !important; gap: 36px !important; }
      .feat-grid > div { order: unset !important; }
      .feat-grid .reveal:last-child { order: -1 !important; }
      .bingo-grid { grid-template-columns: 1fr !important; }
      .stat-row { grid-template-columns: 1fr 1fr !important; gap: 30px !important; }
      .foot-grid { grid-template-columns: 1fr 1fr !important; gap: 32px !important; }
    }
    @media (max-width: 560px) {
      .stat-row { grid-template-columns: 1fr 1fr !important; }
      .foot-grid { grid-template-columns: 1fr !important; }
    }
  `;
  document.head.appendChild(st);
}

function SiteSections() {
  return (
    <React.Fragment>
      <HowItWorks />
      <Features />
      <BingoLeaderboard />
      <StatBand />
      <CTA />
      <Footer />
    </React.Fragment>
  );
}

Object.assign(window, { SiteSections });
