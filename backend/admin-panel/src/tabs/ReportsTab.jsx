import { useState, useEffect } from 'react'
import { apiGet, apiPut, apiDelete } from '../api.js'
import { useToast, useLightbox } from '../contexts.js'

const STATUS_LABELS = { pending: 'Ausstehend', reviewed: 'Überprüft', dismissed: 'Behalten' }
const FILTERS = [
  { value: 'all', label: 'Alle' },
  { value: 'pending', label: 'Ausstehend' },
  { value: 'reviewed', label: 'Überprüft' },
  { value: 'dismissed', label: 'Behalten' },
]

function fmtDate(iso) {
  if (!iso) return '–'
  return new Date(iso).toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

export default function ReportsTab({ onRefresh }) {
  const [filter, setFilter] = useState('all')
  const [reports, setReports] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const toast = useToast()
  const openLightbox = useLightbox()

  useEffect(() => { load() }, [filter])

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const url = filter === 'all' ? '/admin/reports' : `/admin/reports?status=${filter}`
      const data = await apiGet(url)
      setReports(data)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  async function updateStatus(id, status) {
    try {
      await apiPut(`/admin/reports/${id}`, { status })
      toast('Status aktualisiert')
      load()
      onRefresh()
    } catch (e) {
      toast('Fehler: ' + e.message)
    }
  }

  async function removeReport(id) {
    if (!confirm('Meldung endgültig löschen?')) return
    try {
      await apiDelete(`/admin/reports/${id}`)
      toast('Meldung gelöscht')
      load()
      onRefresh()
    } catch (e) {
      toast('Fehler: ' + e.message)
    }
  }

  async function deletePost(postId) {
    if (!confirm('Beitrag unwiderruflich löschen? Alle Reaktionen und Kommentare werden ebenfalls entfernt.')) return
    try {
      await apiDelete(`/admin/posts/${postId}`)
      toast('Beitrag gelöscht')
      load()
      onRefresh()
    } catch (e) {
      toast('Fehler: ' + e.message)
    }
  }

  return (
    <>
      <div className="section-head">
        <h2>Gemeldete Beiträge</h2>
        <span className="badge">{loading ? '…' : reports.length}</span>
      </div>

      <div className="filter-row">
        {FILTERS.map(f => (
          <button
            key={f.value}
            className={`filter-btn${filter === f.value ? ' active' : ''}`}
            onClick={() => setFilter(f.value)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {loading && <div className="loading-center"><span className="spinner" /></div>}
      {error && <div className="empty">Fehler: {error}</div>}
      {!loading && !error && reports.length === 0 && (
        <div className="empty">Keine Meldungen in dieser Kategorie.</div>
      )}
      {!loading && !error && reports.map(r => (
        <ReportCard
          key={r._id}
          report={r}
          onUpdateStatus={updateStatus}
          onRemoveReport={removeReport}
          onDeletePost={deletePost}
          onOpenLightbox={openLightbox}
        />
      ))}
    </>
  )
}

function ReportCard({ report: r, onUpdateStatus, onRemoveReport, onDeletePost, onOpenLightbox }) {
  const postDeleted = !r.post
  const p = r.post || {}
  const drinkLabel = p.drink?.emoji ? `${p.drink.emoji} ${p.drink.name}` : ''
  const stats = p.stats || {}

  return (
    <div className={`report-card ${r.status}`}>
      <div className="rc-header">
        <span className={`report-status status-${r.status}`}>
          {STATUS_LABELS[r.status] || r.status}
        </span>
        <span className="rc-meta">
          Gemeldet von <strong>@{r.reporter?.username || '?'}</strong>
          {' · '}
          {fmtDate(r.createdAt)}
        </span>
      </div>

      <div className="rc-body">
        <div className="rc-images">
          {r.postImageUrl
            ? <img className="rc-main-img" src={r.postImageUrl} alt="Beitrag" onClick={() => onOpenLightbox(r.postImageUrl)} />
            : <div className="rc-img-placeholder">🍺</div>
          }
          {r.postSelfieUrl && (
            <>
              <img className="rc-selfie-img" src={r.postSelfieUrl} alt="Selfie" onClick={() => onOpenLightbox(r.postSelfieUrl)} />
              <div className="rc-img-label">Selfie</div>
            </>
          )}
        </div>

        <div className="rc-details">
          {postDeleted ? (
            <div className="rc-deleted">⚠ Beitrag wurde bereits gelöscht</div>
          ) : (
            <>
              <div className="rc-post-header">
                {r.reportedUser && (
                  <div
                    className="avatar"
                    style={{ background: `${r.reportedUser.avatarColor}22`, color: r.reportedUser.avatarColor }}
                  >
                    {r.reportedUser.avatarInitial ?? '?'}
                  </div>
                )}
                <span className="rc-username">@{r.reportedUser?.username || '?'}</span>
                {drinkLabel && <span className="rc-drink">{drinkLabel}</span>}
                <span className="rc-date">{fmtDate(p.createdAt)}</span>
              </div>
              {p.caption
                ? <div className="rc-caption">{p.caption}</div>
                : <div className="rc-no-caption">Kein Caption</div>
              }
              <div className="rc-stats">
                <div className="rc-stat">👁 {stats.views ?? 0}</div>
                <div className="rc-stat">💬 {stats.comments ?? 0}</div>
                <div className="rc-stat">⚡ {stats.reactions ?? 0}</div>
              </div>
            </>
          )}
          <div className="rc-reason-wrap">
            <div className="rc-reason-label">Meldegrund</div>
            <div className="rc-reason">{r.reason}</div>
          </div>
        </div>
      </div>

      <div className="rc-actions">
        {r.status === 'pending' ? (
          <>
            <button className="btn btn-success" onClick={() => onUpdateStatus(r._id, 'reviewed')}>
              ✓ Überprüft
            </button>
            <button className="btn" onClick={() => onUpdateStatus(r._id, 'dismissed')}>
              Behalten
            </button>
          </>
        ) : (
          <button className="btn" onClick={() => onUpdateStatus(r._id, 'pending')}>
            ↩ Zurücksetzen
          </button>
        )}
        {!postDeleted && (
          <button className="btn btn-danger" onClick={() => onDeletePost(r.post._id)}>
            🗑 Beitrag löschen
          </button>
        )}
        <div className="rc-spacer" />
        <button className="btn btn-ghost" onClick={() => onRemoveReport(r._id)}>
          Meldung entfernen
        </button>
      </div>
    </div>
  )
}
