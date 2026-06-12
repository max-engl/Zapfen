const TOKEN_KEY = 'zapfen_admin_token'

export const getToken = () => localStorage.getItem(TOKEN_KEY) || ''
export const setToken = (t) => localStorage.setItem(TOKEN_KEY, t)
export const clearToken = () => localStorage.removeItem(TOKEN_KEY)

let _onUnauth = null
export function setUnauthHandler(fn) { _onUnauth = fn }

async function request(path, opts = {}) {
  const token = getToken()
  const res = await fetch(path, {
    ...opts,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(opts.headers || {}),
    },
    body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
  })

  if (res.status === 401 || res.status === 403) {
    clearToken()
    _onUnauth?.()
    const err = new Error('Session abgelaufen')
    err.code = 'UNAUTHORIZED'
    throw err
  }

  const ct = res.headers.get('content-type') || ''
  if (ct.includes('application/json')) {
    const data = await res.json().catch(() => ({}))
    if (!res.ok) throw new Error(data.message || `HTTP ${res.status}`)
    return data
  }

  if (!res.ok) throw new Error(`HTTP ${res.status}`)
  return res
}

export const apiGet = (path) => request(path)
export const apiPost = (path, body) => request(path, { method: 'POST', body })
export const apiPut = (path, body) => request(path, { method: 'PUT', body })
export const apiPatch = (path, body) => request(path, { method: 'PATCH', body })
export const apiDelete = (path) => request(path, { method: 'DELETE' })

export async function apiDownload(path) {
  const token = getToken()
  const res = await fetch(path, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  })
  if (!res.ok) {
    const d = await res.json().catch(() => ({}))
    throw new Error(d.message || `HTTP ${res.status}`)
  }
  return res
}
