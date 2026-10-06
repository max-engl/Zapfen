export default function OverviewTab({ stats, onRefresh }) {
  if (!stats) {
    return <div className="loading-center"><span className="spinner" /></div>
  }

  const avg = stats.totalUsers > 0
    ? (stats.totalPosts / stats.totalUsers).toFixed(1)
    : '0'

  return (
    <>
      <div className="stat-grid">
        <div className="stat-card gold">
          <div className="stat-label">Nutzer gesamt</div>
          <div className="stat-value">{stats.totalUsers}</div>
        </div>
        <div className="stat-card gold">
          <div className="stat-label">Beiträge gesamt</div>
          <div className="stat-value">{stats.totalPosts}</div>
        </div>
        <div className="stat-card red">
          <div className="stat-label">Ausstehende Meldungen</div>
          <div className="stat-value">{stats.pendingReports}</div>
        </div>
        <div className="stat-card red">
          <div className="stat-label">Löschanfragen</div>
          <div className="stat-value">{stats.pendingDeletions ?? 0}</div>
        </div>
        <div className="stat-card">
          <div className="stat-label">Ø Beiträge / Nutzer</div>
          <div className="stat-value">{avg}</div>
        </div>
      </div>
      <div className="overview-refresh">
        <button className="btn btn-ghost" onClick={onRefresh}>↻ Aktualisieren</button>
      </div>
    </>
  )
}
