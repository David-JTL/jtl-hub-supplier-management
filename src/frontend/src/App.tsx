import { useEffect, useState } from 'react'

interface HealthStatus {
  status: string
  service: string
  version: string
  timestamp: string
}

function App() {
  const [health, setHealth] = useState<HealthStatus | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetch('/api/health')
      .then(res => res.json())
      .then(data => setHealth(data))
      .catch(err => setError(err.message))
  }, [])

  return (
    <div style={{ fontFamily: 'system-ui', padding: '2rem', maxWidth: '600px', margin: '0 auto' }}>
      <h1>JTL Supplier Management</h1>
      <p>Lieferantenverwaltung — JTL Hub App</p>
      
      <div style={{ marginTop: '2rem', padding: '1rem', border: '1px solid #ddd', borderRadius: '8px' }}>
        <h3>Backend Health Check</h3>
        {error && <p style={{ color: 'red' }}>Fehler: {error}</p>}
        {health && (
          <ul>
            <li>Status: <strong>{health.status}</strong></li>
            <li>Service: {health.service}</li>
            <li>Version: {health.version}</li>
            <li>Timestamp: {health.timestamp}</li>
          </ul>
        )}
        {!health && !error && <p>Lade...</p>}
      </div>
    </div>
  )
}

export default App
