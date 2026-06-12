import { useState, useEffect } from 'react'
import { apiGet, apiDelete, apiPatch, apiDownload } from '../api.js'
import { useToast } from '../contexts.js'

function fmtDate(iso) {
  if (!iso) return '–'
  return new Date(iso).toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

export default function UsersTab({ onRefresh }) {
  const [users, setUsers] = useState([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [search, setSearch] = useState('')
  const [exportingId, setExportingId] = useState(null)
  const [pwModal, setPwModal] = useState(null)
  const toast = useToast()

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const data = await apiGet('/admin/stats')
      setUsers(data.users || [])
      setTotal(data.totalUsers)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  async function deleteUser(userId, username) {
    if (!confirm(`Konto von @${username} unwiderruflich löschen? Alle Beiträge, Kommentare und Daten werden entfernt.`)) return
    try {
      await apiDelete(`/admin/users/${userId}`)
      toast(`@${username} gelöscht`)
      load()
      onRefresh()
    } catch (e) {
      toast('Fehler: ' + e.message)
    }
  }

  async function exportPhotos(userId, username) {
    setExportingId(userId)
    try {
      const res = await apiDownload(`/admin/users/${userId}/export`)
      const blob = await res.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `${username}_photos.zip`
      a.click()
      URL.revokeObjectURL(url)
      toast(`ZIP für @${username} heruntergeladen`)
    } catch (e) {
      toast('Fehler: ' + e.message)
    } finally {
      setExportingId(null)
    }
  }

  const filtered = search
    ? users.filter(u =>
        u.username.toLowerCase().includes(search.toLowerCase()) ||
        u.email.toLowerCase().includes(search.toLowerCase())
      )
    : users

  return (
    <>
      <div className="section-head">
        <h2>Alle Nutzer</h2>
        <span className="badge gold">{total}</span>
      </div>

      <div className="search-wrap">
        <span className="search-icon">🔍</span>
        <input
          className="search-input"
          type="text"
          placeholder="Suche nach Nutzername oder E-Mail…"
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
      </div>

      {loading && <div className="loading-center"><span className="spinner" /></div>}
      {error && <div className="empty">Fehler: {error}</div>}

      {!loading && !error && (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Nutzer</th>
                <th>E-Mail</th>
                <th style={{ textAlign: 'right' }}>Beiträge</th>
                <th>Rolle</th>
                <th>Registriert</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} className="empty">Keine Nutzer gefunden.</td>
                </tr>
              ) : filtered.map(u => (
                <tr key={u._id}>
                  <td>
                    <div className="user-cell">
                      <div
                        className="avatar"
                        style={{ background: `${u.avatarColor}22`, color: u.avatarColor }}
                      >
                        {u.avatarInitial}
                      </div>
                      <span className="username">@{u.username}</span>
                    </div>
                  </td>
                  <td style={{ color: 'var(--muted)' }}>{u.email}</td>
                  <td style={{ textAlign: 'right', fontWeight: 700 }}>{u.postCount}</td>
                  <td>
                    <span className={`role-badge ${u.role}`}>
                      {u.role === 'admin' ? 'Admin' : 'Nutzer'}
                    </span>
                  </td>
                  <td style={{ color: 'var(--muted)' }}>{fmtDate(u.createdAt)}</td>
                  <td>
                    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                      {u.postCount > 0 && (
                        <button
                          className="btn"
                          onClick={() => exportPhotos(u._id, u.username)}
                          disabled={exportingId === u._id}
                        >
                          {exportingId === u._id
                            ? <span className="spinner" style={{ width: 12, height: 12, borderWidth: 2 }} />
                            : '⬇ ZIP'
                          }
                        </button>
                      )}
                      <button className="btn" onClick={() => setPwModal({ userId: u._id, username: u.username })}>
                        🔑
                      </button>
                      {u.role !== 'admin' && (
                        <button className="btn btn-danger" onClick={() => deleteUser(u._id, u.username)}>
                          🗑
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {pwModal && (
        <PasswordModal
          userId={pwModal.userId}
          username={pwModal.username}
          onClose={() => setPwModal(null)}
          onSuccess={() => {
            toast('Passwort gespeichert')
            setPwModal(null)
          }}
        />
      )}
    </>
  )
}

function PasswordModal({ userId, username, onClose, onSuccess }) {
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function save(e) {
    e.preventDefault()
    if (!password || password.length < 6) {
      setError('Mindestens 6 Zeichen erforderlich.')
      return
    }
    setLoading(true)
    setError('')
    try {
      await apiPatch(`/admin/users/${userId}/password`, { password })
      onSuccess()
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="modal-backdrop" onClick={e => e.target === e.currentTarget && onClose()}>
      <form className="modal-card" onSubmit={save}>
        <div className="modal-title">Passwort ändern</div>
        <div className="modal-sub">@{username}</div>
        <div className="field">
          <label>Neues Passwort</label>
          <input
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            placeholder="Mindestens 6 Zeichen"
            autoFocus
          />
        </div>
        {error && <div className="error-msg">{error}</div>}
        <div className="modal-actions">
          <button type="button" className="btn" onClick={onClose}>Abbrechen</button>
          <button type="submit" className="btn btn-success" disabled={loading}>
            {loading ? '…' : 'Speichern'}
          </button>
        </div>
      </form>
    </div>
  )
}
