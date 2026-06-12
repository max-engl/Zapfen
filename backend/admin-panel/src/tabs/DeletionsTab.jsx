import { useState, useEffect } from 'react'
import { apiGet, apiPost, apiDelete } from '../api.js'
import { useToast } from '../contexts.js'

const FILTERS = [
  { value: 'pending', label: 'Ausstehend' },
  { value: 'completed', label: 'Erledigt' },
  { value: 'dismissed', label: 'Abgelehnt' },
]

const STATUS_COLORS = {
  pending: 'var(--red)',
  completed: 'var(--green)',
  dismissed: 'var(--faint)',
}

const STATUS_LABELS = {
  pending: 'Ausstehend',
  completed: 'Erledigt',
  dismissed: 'Abgelehnt',
}

function fmtDate(iso) {
  if (!iso) return '–'
  return new Date(iso).toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

export default function DeletionsTab({ onRefresh }) {
  const [filter, setFilter] = useState('pending')
  const [requests, setRequests] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const toast = useToast()

  useEffect(() => { load() }, [filter])

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const data = await apiGet(`/admin/deletion-requests?status=${filter}`)
      setRequests(data)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  async function execute(id, email) {
    if (!confirm(`Konto für ${email} unwiderruflich löschen? Alle Daten werden entfernt.`)) return
    try {
      const result = await apiPost(`/admin/deletion-requests/${id}/execute`)
      toast(result.userFound ? 'Konto gelöscht' : 'Anfrage erledigt (kein passendes Konto gefunden)')
      load()
      onRefresh()
    } catch (e) {
      toast('Fehler: ' + e.message)
    }
  }

  async function dismiss(id) {
    if (!confirm('Anfrage ablehnen?')) return
    try {
      await apiDelete(`/admin/deletion-requests/${id}`)
      toast('Anfrage abgelehnt')
      load()
      onRefresh()
    } catch (e) {
      toast('Fehler: ' + e.message)
    }
  }

  return (
    <>
      <div className="section-head">
        <h2>Löschanfragen</h2>
        <span className="badge">{loading ? '…' : requests.length}</span>
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
      {!loading && !error && requests.length === 0 && (
        <div className="empty">Keine Anfragen in dieser Kategorie.</div>
      )}
      {!loading && !error && requests.length > 0 && (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>E-Mail</th>
                <th>Status</th>
                <th>Eingereicht</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {requests.map(r => (
                <tr key={r._id}>
                  <td style={{ fontWeight: 600 }}>{r.email}</td>
                  <td>
                    <span style={{ color: STATUS_COLORS[r.status] || 'var(--muted)', fontSize: 12, fontWeight: 700 }}>
                      {STATUS_LABELS[r.status] || r.status}
                    </span>
                  </td>
                  <td style={{ color: 'var(--muted)' }}>{fmtDate(r.createdAt)}</td>
                  <td>
                    <div style={{ display: 'flex', gap: 6 }}>
                      {r.status === 'pending' && (
                        <>
                          <button className="btn btn-danger" onClick={() => execute(r._id, r.email)}>
                            🗑 Konto löschen
                          </button>
                          <button className="btn" onClick={() => dismiss(r._id)}>
                            Ablehnen
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </>
  )
}
