import { useState, useEffect, useRef } from 'react'
import Login from './components/Login.jsx'
import Dashboard from './components/Dashboard.jsx'
import { ToastContext, LightboxContext } from './contexts.js'
import { getToken, clearToken, setToken, setUnauthHandler, apiGet } from './api.js'

export default function App() {
  const [authed, setAuthed] = useState(false)
  const [checking, setChecking] = useState(true)
  const [toast, setToast] = useState(null)
  const [lightboxSrc, setLightboxSrc] = useState(null)
  const toastTimer = useRef(null)

  function showToast(msg) {
    setToast(msg)
    clearTimeout(toastTimer.current)
    toastTimer.current = setTimeout(() => setToast(null), 3200)
  }

  function handleLogout() {
    clearToken()
    setAuthed(false)
  }

  function handleLogin(token) {
    setToken(token)
    setAuthed(true)
  }

  useEffect(() => {
    setUnauthHandler(handleLogout)
    const token = getToken()
    if (!token) { setChecking(false); return }
    apiGet('/admin/stats')
      .then(() => setAuthed(true))
      .catch(() => clearToken())
      .finally(() => setChecking(false))
  }, [])

  if (checking) {
    return <div className="splash"><div className="spinner" /></div>
  }

  return (
    <ToastContext.Provider value={showToast}>
      <LightboxContext.Provider value={setLightboxSrc}>
        {authed
          ? <Dashboard onLogout={handleLogout} />
          : <Login onLogin={handleLogin} />
        }
        {toast && <div className="toast show">{toast}</div>}
        {lightboxSrc && (
          <div className="lightbox-backdrop" onClick={() => setLightboxSrc(null)}>
            <button className="lightbox-close" onClick={() => setLightboxSrc(null)}>✕</button>
            <img
              className="lightbox-img"
              src={lightboxSrc}
              alt="Vollbild"
              onClick={e => e.stopPropagation()}
            />
          </div>
        )}
      </LightboxContext.Provider>
    </ToastContext.Provider>
  )
}
