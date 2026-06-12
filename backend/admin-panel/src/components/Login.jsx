import { useState } from 'react'

export default function Login({ onLogin }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function submit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const res = await fetch('/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ emailOrUsername: email.trim(), password }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.message || 'Login fehlgeschlagen')
      if (data.user?.role !== 'admin') throw new Error('Kein Admin-Konto')
      onLogin(data.token)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-wrap">
      <form className="login-card" onSubmit={submit}>
        <div className="login-brand">
          <span className="login-brand-icon">🍺</span>
          <div className="login-brand-name">Zapfen <span>Admin</span></div>
        </div>
        <p className="login-sub">Melde dich mit deinem Admin-Konto an.</p>

        <div className="field">
          <label>E-Mail oder Nutzername</label>
          <input
            type="text"
            value={email}
            onChange={e => setEmail(e.target.value)}
            placeholder="admin@example.com"
            autoComplete="username"
            autoFocus
          />
        </div>
        <div className="field">
          <label>Passwort</label>
          <input
            type="password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            placeholder="••••••••"
            autoComplete="current-password"
          />
        </div>

        <button
          type="submit"
          className="btn btn-primary btn-full"
          disabled={loading}
          style={{ marginTop: 8 }}
        >
          {loading
            ? <><span className="spinner" style={{ width: 13, height: 13, borderWidth: 2 }} /> Anmelden…</>
            : 'Anmelden'
          }
        </button>
        {error && <div className="error-msg">{error}</div>}
      </form>
    </div>
  )
}
