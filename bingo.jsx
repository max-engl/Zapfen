// Bier-Bingo — monthly 5×5 challenge card for the Pint. app.
// One shared card per month; cells auto-complete from the user's logged posts.
// Complete a row / column / diagonal → a "Zeile". All 25 → "Blackout".
//
// Renders from the GET /bingo/card payload shape (mocked below):
//   { month, totalDone, lineCount, blackout, cells: [{ id, emoji, label, done }] }
//
// Exports: window.BingoModal, window.BingoBanner, window.fetchBingoCard
// Themes via window.THEMES tokens.

const { useState: useStateBg, useMemo: useMemoBg } = React;
const useTBg = () => React.useContext(window.ThemeContext);

// ───────────────────────────────────────────
// Mock API — GET /bingo/card
// 25 cells, row-major. Center (index 12) is the free space.
// ───────────────────────────────────────────
const BINGO_CELLS = [
  { id: "c0",  emoji: "🌙", label: "Nach 2 Uhr",        done: true  },
  { id: "c1",  emoji: "🌾", label: "Weißbier",          done: false },
  { id: "c2",  emoji: "🤝", label: "Mit Fremden",       done: true  },
  { id: "c3",  emoji: "🍺", label: "Pils",              done: true  },
  { id: "c4",  emoji: "☀️", label: "Vor 12 Uhr",        done: false },

  { id: "c5",  emoji: "🏖️", label: "Am Strand",         done: false },
  { id: "c6",  emoji: "🍻", label: "5 getaggt",         done: true  },
  { id: "c7",  emoji: "🥨", label: "Mit Brezel",        done: true  },
  { id: "c8",  emoji: "🎸", label: "Konzert",           done: false },
  { id: "c9",  emoji: "🍋", label: "Radler",            done: true  },

  { id: "c10", emoji: "🏡", label: "Im Biergarten",     done: true  },
  { id: "c11", emoji: "🌑", label: "Dunkles",           done: true  },
  { id: "c12", emoji: "⭐", label: "FREI",              done: true,  free: true },
  { id: "c13", emoji: "🍑", label: "Sauerbier",         done: true  },
  { id: "c14", emoji: "🌍", label: "Im Ausland",        done: true  },

  { id: "c15", emoji: "🚂", label: "Im Zug",            done: false },
  { id: "c16", emoji: "🍫", label: "Stout",             done: true  },
  { id: "c17", emoji: "🎲", label: "Spieleabend",       done: false },
  { id: "c18", emoji: "🌧️", label: "Bei Regen",         done: true  },
  { id: "c19", emoji: "🍊", label: "IPA",               done: false },

  { id: "c20", emoji: "🏟️", label: "Im Stadion",        done: true  },
  { id: "c21", emoji: "👑", label: "Bockbier",          done: false },
  { id: "c22", emoji: "🌃", label: "Rooftop-Bar",       done: false },
  { id: "c23", emoji: "🎉", label: "Auf 'ner Party",    done: false },
  { id: "c24", emoji: "🔥", label: "7-Tage-Streak",     done: true  },
];

// The 12 winning lines, as index tuples
const BINGO_LINES = [
  [0,1,2,3,4],[5,6,7,8,9],[10,11,12,13,14],[15,16,17,18,19],[20,21,22,23,24], // rows
  [0,5,10,15,20],[1,6,11,16,21],[2,7,12,17,22],[3,8,13,18,23],[4,9,14,19,24], // cols
  [0,6,12,18,24],[4,8,12,16,20], // diagonals
];

function computeBingo(cells) {
  const done = cells.map(c => !!c.done);
  const completedLines = BINGO_LINES.filter(line => line.every(i => done[i]));
  const inLine = new Set();
  completedLines.forEach(line => line.forEach(i => inLine.add(i)));
  const totalDone = done.filter(Boolean).length;
  return {
    completedLines,
    lineCount: completedLines.length,
    inLine,
    totalDone,
    blackout: totalDone === 25,
  };
}

// Simulates GET /bingo/card
function fetchBingoCard() {
  const meta = computeBingo(BINGO_CELLS);
  return {
    month: "Juni 2026",
    cells: BINGO_CELLS,
    totalDone: meta.totalDone,
    lineCount: meta.lineCount,
    blackout: meta.blackout,
  };
}

// ───────────────────────────────────────────
// Icons
// ───────────────────────────────────────────
const BgIco = {
  close: (s = 22, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 6l12 12M18 6 6 18"/></svg>
  ),
  check: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12.5 10 17l9-10"/></svg>
  ),
  line: (s = 14, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2.4" strokeLinecap="round"><path d="M4 12h16"/></svg>
  ),
  info: (s = 15, c = "currentColor") => (
    <svg width={s} height={s} viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 11v5"/><path d="M12 8h.01"/></svg>
  ),
};

// ───────────────────────────────────────────
// Single bingo cell
// ───────────────────────────────────────────
function BingoCell({ cell, inLine }) {
  const T = useTBg();
  const done = !!cell.done;

  // three visual states: in-completed-line (gold filled) · done (gold tint) · undone (faint)
  let bg, borderC, emojiOpacity, labelColor;
  if (done && inLine) {
    bg = T.gold; borderC = "transparent"; emojiOpacity = 1; labelColor = T.goldInk;
  } else if (done) {
    bg = T.goldSoft; borderC = T.goldBorder; emojiOpacity = 1; labelColor = T.text;
  } else {
    bg = T.surfaceWeaker; borderC = T.border; emojiOpacity = 0.32; labelColor = T.textFaint;
  }

  return (
    <div style={{
      position: "relative", aspectRatio: "1 / 1", borderRadius: 12,
      background: bg, border: `1px solid ${borderC}`,
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      gap: 3, padding: "2px 3px", overflow: "hidden",
      boxShadow: done && inLine ? `0 3px 10px ${T.goldStrong}` : "none",
    }}>
      <div style={{
        fontSize: 21, lineHeight: 1, opacity: emojiOpacity,
        filter: done ? "none" : "grayscale(1)",
      }}>{cell.emoji}</div>
      <div style={{
        fontSize: 8.2, fontWeight: 700, letterSpacing: "-0.01em",
        textAlign: "center", lineHeight: 1.12, color: labelColor,
        textTransform: "uppercase", maxWidth: "100%",
      }}>{cell.label}</div>

      {/* done tick — only for plain done cells (in-line cells read as filled already) */}
      {done && !inLine && !cell.free && (
        <div style={{
          position: "absolute", top: 4, right: 4, width: 14, height: 14, borderRadius: "50%",
          background: T.gold, display: "grid", placeItems: "center",
        }}>{BgIco.check(9, T.goldInk)}</div>
      )}
      {cell.free && (
        <div style={{
          position: "absolute", top: 4, right: 4, fontSize: 9, fontWeight: 800,
          color: done && inLine ? T.goldInk : T.goldText, letterSpacing: "0.04em",
        }}>★</div>
      )}
    </div>
  );
}

// ───────────────────────────────────────────
// Progress stat pill
// ───────────────────────────────────────────
function StatPill({ icon, value, label, hot }) {
  const T = useTBg();
  return (
    <div style={{
      flex: 1, display: "flex", alignItems: "center", gap: 9,
      padding: "11px 13px", borderRadius: 14,
      background: hot ? T.goldSoft : T.surfaceWeak,
      border: `1px solid ${hot ? T.goldBorder : T.border}`,
    }}>
      <div style={{
        width: 30, height: 30, borderRadius: 9, flexShrink: 0,
        background: hot ? T.gold : T.surfaceWeak,
        display: "grid", placeItems: "center", color: hot ? T.goldInk : T.goldText,
      }}>{icon}</div>
      <div style={{ minWidth: 0 }}>
        <div style={{ color: T.text, fontSize: 17, fontWeight: 900, letterSpacing: "-0.03em", lineHeight: 1 }}>{value}</div>
        <div style={{ color: T.textMuted, fontSize: 10.5, fontWeight: 600, marginTop: 2 }}>{label}</div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Bingo modal (sheet)
// ───────────────────────────────────────────
function BingoModal({ card, onClose }) {
  const T = useTBg();
  const meta = useMemoBg(() => computeBingo(card.cells), [card]);

  return (
    <div style={{
      position: "absolute", inset: 0, zIndex: 80,
      display: "flex", flexDirection: "column", justifyContent: "flex-end",
      background: "rgba(0,0,0,0.5)", backdropFilter: "blur(2px)",
    }}>
      <div style={{
        background: T.bg, borderRadius: "26px 26px 0 0",
        borderTop: `1px solid ${T.border}`,
        maxHeight: "calc(100% - 28px)", display: "flex", flexDirection: "column",
        boxShadow: "0 -16px 48px rgba(0,0,0,0.4)",
      }}>
        {/* grabber */}
        <div style={{ display: "grid", placeItems: "center", paddingTop: 10 }}>
          <div style={{ width: 38, height: 4, borderRadius: 999, background: T.border }} />
        </div>

        {/* header */}
        <div style={{ padding: "12px 20px 4px", display: "flex", alignItems: "flex-start", justifyContent: "space-between" }}>
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <span style={{ fontSize: 21 }}>🍺</span>
              <h2 style={{ margin: 0, fontSize: 22, fontWeight: 900, letterSpacing: "-0.03em", color: T.text }}>Bier-Bingo</h2>
            </div>
            <div style={{ color: T.goldText, fontSize: 12.5, fontWeight: 700, marginTop: 3, letterSpacing: "0.01em" }}>
              {card.month} · für alle gleich
            </div>
          </div>
          <button onClick={onClose} style={{
            width: 34, height: 34, borderRadius: "50%", flexShrink: 0,
            background: T.surfaceWeak, border: `1px solid ${T.border}`,
            color: T.text, display: "grid", placeItems: "center", cursor: "pointer",
          }}>{BgIco.close(19)}</button>
        </div>

        {/* scrollable body */}
        <div style={{ overflow: "auto", padding: "10px 20px 0" }}>
          {/* progress summary */}
          <div style={{ display: "flex", gap: 10, marginBottom: 8 }}>
            <StatPill icon={BgIco.check(15, T.goldInk)} value={`${meta.totalDone}/25`} label="erledigt" hot />
            <StatPill icon={BgIco.line(15, T.goldText)} value={meta.lineCount} label={meta.lineCount === 1 ? "Zeile" : "Zeilen"} />
          </div>

          {/* progress bar */}
          <div style={{ height: 7, borderRadius: 999, background: T.surfaceWeak, overflow: "hidden", marginBottom: 16 }}>
            <div style={{ width: `${(meta.totalDone / 25) * 100}%`, height: "100%", borderRadius: 999, background: T.gold }} />
          </div>

          {/* blackout banner */}
          {meta.blackout ? (
            <div style={{
              margin: "0 0 14px", padding: "13px 15px", borderRadius: 14,
              background: T.gold, color: T.goldInk,
              display: "flex", alignItems: "center", gap: 10,
            }}>
              <span style={{ fontSize: 22 }}>👑</span>
              <div>
                <div style={{ fontSize: 14.5, fontWeight: 900 }}>BLACKOUT!</div>
                <div style={{ fontSize: 12, fontWeight: 600, opacity: 0.85 }}>Alle 25 Felder — legendäres Abzeichen verdient.</div>
              </div>
            </div>
          ) : meta.lineCount > 0 ? (
            <div style={{
              margin: "0 0 14px", padding: "11px 14px", borderRadius: 14,
              background: T.goldFaint, border: `1px solid ${T.goldBorder}`,
              display: "flex", alignItems: "center", gap: 9, color: T.text,
            }}>
              <span style={{ display: "inline-flex", color: T.goldText }}>{BgIco.line(16, T.goldText)}</span>
              <div style={{ fontSize: 12.5, fontWeight: 600 }}>
                <strong style={{ fontWeight: 800 }}>{meta.lineCount} {meta.lineCount === 1 ? "Zeile" : "Zeilen"}</strong> komplett — die goldenen Felder zählen.
              </div>
            </div>
          ) : null}

          {/* 5×5 grid */}
          <div style={{
            display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 6,
          }}>
            {card.cells.map((cell, i) => (
              <BingoCell key={cell.id} cell={cell} inLine={meta.inLine.has(i)} />
            ))}
          </div>

          {/* footnote */}
          <div style={{
            display: "flex", alignItems: "flex-start", gap: 8, marginTop: 14,
            color: T.textMuted, fontSize: 11.5, lineHeight: 1.45,
          }}>
            <span style={{ display: "inline-flex", flexShrink: 0, marginTop: 1, color: T.textFaint }}>{BgIco.info(14, T.textFaint)}</span>
            <div>Felder werden automatisch markiert, sobald ein Post passt — kein Antippen nötig. Neue Karte am 1. Juli.</div>
          </div>
        </div>

        {/* close button */}
        <div style={{ padding: "12px 20px 26px" }}>
          <button onClick={onClose} style={{
            width: "100%", padding: "15px 0", borderRadius: 15, border: "none",
            background: T.gold, color: T.goldInk, fontSize: 15.5, fontWeight: 800,
            letterSpacing: "-0.01em", cursor: "pointer",
          }}>Schließen</button>
        </div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────
// Profile banner — mini 5×5 dot preview + "X/25 erledigt"
// ───────────────────────────────────────────
function BingoBanner({ card, onOpen }) {
  const T = useTBg();
  const meta = useMemoBg(() => computeBingo(card.cells), [card]);

  return (
    <button onClick={onOpen} style={{
      width: "calc(100% - 36px)", margin: "0 18px 22px", padding: "14px 16px",
      borderRadius: 18, border: `1px solid ${T.goldBorder}`,
      background: `linear-gradient(105deg, ${T.goldSoft}, ${T.goldFaint})`,
      display: "flex", alignItems: "center", gap: 14, cursor: "pointer", textAlign: "left",
    }}>
      {/* mini dot grid */}
      <div style={{
        display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 3,
        padding: 7, borderRadius: 11, background: T.bg, border: `1px solid ${T.border}`,
        flexShrink: 0,
      }}>
        {card.cells.map((c, i) => (
          <div key={c.id} style={{
            width: 7, height: 7, borderRadius: 2.5,
            background: c.done ? T.gold : T.surfaceWeak,
            opacity: c.done ? 1 : 0.7,
          }} />
        ))}
      </div>

      {/* copy */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <span style={{ fontSize: 15 }}>🍺</span>
          <span style={{ color: T.text, fontSize: 15, fontWeight: 800, letterSpacing: "-0.02em" }}>Bier-Bingo</span>
          <span style={{
            fontSize: 9.5, fontWeight: 800, color: T.goldInk, background: T.gold,
            padding: "2px 6px", borderRadius: 999, letterSpacing: "0.02em",
          }}>{card.month.split(" ")[0].toUpperCase()}</span>
        </div>
        <div style={{ color: T.textMuted, fontSize: 12.5, fontWeight: 600, marginTop: 3 }}>
          <strong style={{ color: T.goldText, fontWeight: 800 }}>{meta.totalDone}/25 erledigt</strong>
          {meta.lineCount > 0 && ` · ${meta.lineCount} ${meta.lineCount === 1 ? "Zeile" : "Zeilen"}`}
        </div>
      </div>

      {/* chevron */}
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={T.goldText} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}><path d="M9 6l6 6-6 6"/></svg>
    </button>
  );
}

Object.assign(window, { BingoModal, BingoBanner, fetchBingoCard, computeBingo });
