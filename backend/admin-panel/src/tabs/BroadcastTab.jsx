import { useState } from 'react'
import { apiPost } from '../api.js'
import { useToast } from '../contexts.js'

const PRESETS = [
  { label: 'Samstag-Reminder', title: 'Zapfen. 🍺', body: 'Es ist Samstag – worauf wartest du noch?' },
  { label: 'Freitag-Reminder', title: 'Zapfen. 🍺', body: 'Das Wochenende hat begonnen. Prost! 🥂' },
  { label: 'Bingo-Hype', title: 'Bingo-Zeit! 🎯', body: 'Schaffst du diese Woche eine Bingo-Reihe?' },
  { label: 'Wochenend-Check', title: 'Wie war dein Wochenende?', body: 'Teile deine Bierchen mit deinen Freunden auf Zapfen!' },
  { label: 'Neue Freunde', title: 'Lade deine Freunde ein! 👥', body: 'Schick ihnen deinen Einladungslink und sammelt gemeinsam Punkte.' },
]

export default function BroadcastTab() {
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [sending, setSending] = useState(false)
  const [lastResult, setLastResult] = useState(null)
  const toast = useToast()

  function applyPreset(preset) {
    setTitle(preset.title)
    setBody(preset.body)
    setLastResult(null)
  }

  async function send() {
    if (!title.trim() || !body.trim()) {
      toast('Titel und Nachricht sind erforderlich')
      return
    }
    if (!confirm(`Broadcast an ALLE Nutzer senden?\n\nTitel: ${title}\nNachricht: ${body}`)) return
    setSending(true)
    setLastResult(null)
    try {
      const data = await apiPost('/admin/broadcast', { title: title.trim(), body: body.trim() })
      setLastResult({ ok: true, sent: data.sent })
      toast(`Gesendet an ${data.sent} Nutzer`)
    } catch (e) {
      setLastResult({ ok: false, message: e.message })
      toast('Fehler: ' + e.message)
    } finally {
      setSending(false)
    }
  }

  const charsTitle = title.length
  const charsBody = body.length

  return (
    <div className="broadcast-wrap">
      <section className="broadcast-section">
        <div className="broadcast-section-title">Vorlagen</div>
        <div className="preset-grid">
          {PRESETS.map((p) => (
            <button
              key={p.label}
              className={`preset-btn${title === p.title && body === p.body ? ' active' : ''}`}
              onClick={() => applyPreset(p)}
            >
              <span className="preset-label">{p.label}</span>
              <span className="preset-preview">{p.body}</span>
            </button>
          ))}
        </div>
      </section>

      <section className="broadcast-section">
        <div className="broadcast-section-title">Nachricht</div>
        <div className="broadcast-field">
          <label className="broadcast-label">Titel <span className="char-count">{charsTitle}/65</span></label>
          <input
            className="broadcast-input"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            maxLength={65}
            placeholder="z. B. Zapfen. 🍺"
          />
        </div>
        <div className="broadcast-field">
          <label className="broadcast-label">Nachricht <span className="char-count">{charsBody}/200</span></label>
          <textarea
            className="broadcast-textarea"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            maxLength={200}
            rows={3}
            placeholder="Deine Nachricht an alle Nutzer…"
          />
        </div>

        {lastResult && (
          <div className={`broadcast-result ${lastResult.ok ? 'ok' : 'err'}`}>
            {lastResult.ok
              ? `✓ Gesendet an ${lastResult.sent} Nutzer`
              : `✗ ${lastResult.message}`}
          </div>
        )}

        <button
          className="btn btn-gold btn-broadcast"
          onClick={send}
          disabled={sending || !title.trim() || !body.trim()}
        >
          {sending ? 'Wird gesendet…' : 'An alle Nutzer senden →'}
        </button>
      </section>
    </div>
  )
}
