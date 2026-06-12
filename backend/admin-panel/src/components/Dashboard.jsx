import { useState, useEffect } from 'react'
import { apiGet } from '../api.js'
import OverviewTab from '../tabs/OverviewTab.jsx'
import ReportsTab from '../tabs/ReportsTab.jsx'
import UsersTab from '../tabs/UsersTab.jsx'
import DeletionsTab from '../tabs/DeletionsTab.jsx'

const TAB_TITLES = {
  overview: 'Übersicht',
  reports: 'Gemeldete Beiträge',
  users: 'Alle Nutzer',
  deletions: 'Löschanfragen',
}

export default function Dashboard({ onLogout }) {
  const [tab, setTab] = useState('overview')
  const [stats, setStats] = useState(null)

  async function loadStats() {
    try {
      const data = await apiGet('/admin/stats')
      setStats(data)
    } catch {
      // individual tabs handle their own errors
    }
  }

  useEffect(() => { loadStats() }, [])

  const pendingReports = stats?.pendingReports ?? 0
  const pendingDeletions = stats?.pendingDeletions ?? 0

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="sidebar-brand-icon">🍺</span>
          <div className="sidebar-brand-name">Zapfen <span>Admin</span></div>
        </div>
        <nav className="sidebar-nav">
          <NavItem icon="◆" label="Übersicht" active={tab === 'overview'} onClick={() => setTab('overview')} />
          <NavItem icon="🚩" label="Meldungen" badge={pendingReports} active={tab === 'reports'} onClick={() => setTab('reports')} />
          <NavItem icon="👥" label="Nutzer" active={tab === 'users'} onClick={() => setTab('users')} />
          <NavItem icon="🗑" label="Löschungen" badge={pendingDeletions} active={tab === 'deletions'} onClick={() => setTab('deletions')} />
        </nav>
        <div className="sidebar-footer">
          <button className="btn btn-ghost btn-full" onClick={onLogout}>Abmelden</button>
        </div>
      </aside>

      <main className="main">
        <div className="topbar">
          <div className="topbar-title">{TAB_TITLES[tab]}</div>
        </div>
        <div className="content">
          {tab === 'overview' && <OverviewTab stats={stats} onRefresh={loadStats} />}
          {tab === 'reports' && <ReportsTab onRefresh={loadStats} />}
          {tab === 'users' && <UsersTab onRefresh={loadStats} />}
          {tab === 'deletions' && <DeletionsTab onRefresh={loadStats} />}
        </div>
      </main>
    </div>
  )
}

function NavItem({ icon, label, badge, active, onClick }) {
  return (
    <div className={`nav-item${active ? ' active' : ''}`} onClick={onClick}>
      <span className="nav-icon">{icon}</span>
      <span className="nav-label">{label}</span>
      {badge > 0 && <span className="nav-badge">{badge}</span>}
    </div>
  )
}
