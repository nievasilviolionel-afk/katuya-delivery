import { useState, useEffect } from 'react'
import { collection, onSnapshot, doc, updateDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Truck, Search, Circle } from 'lucide-react'

interface Driver {
  id: string
  userId: string
  vehicle: { type: string; plate: string }
  online: boolean
  lastLocation?: { lat: number; lng: number }
  ratings: { avg: number; count: number }
  status?: string
}

export function DriversPage() {
  const [drivers, setDrivers] = useState<Driver[]>([])
  const [search, setSearch] = useState('')

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'drivers'), (snap) => {
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() } as Driver))
      setDrivers(items)
    })
    return () => unsub()
  }, [])

  const filtered = drivers.filter((d) =>
    d.vehicle?.plate?.toLowerCase().includes(search.toLowerCase())
  )

  const onlineCount = drivers.filter((d) => d.online).length
  const busyCount = drivers.filter((d) => d.status === 'busy').length

  async function toggleSuspend(id: string, currentStatus?: string) {
    const newStatus = currentStatus === 'suspended' ? 'online' : 'suspended'
    await updateDoc(doc(db, 'drivers', id), {
      status: newStatus,
      online: newStatus !== 'suspended',
    })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Repartidores</h1>
          <p className="text-sm text-muted-foreground">
            {onlineCount} en línea · {busyCount} ocupados · {drivers.length} total
          </p>
        </div>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <input
          type="text"
          placeholder="Buscar por patente..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full rounded-lg border border-gray-200 py-2.5 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
        />
      </div>

      <div className="rounded-xl border bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-gray-50 text-left">
                <th className="px-4 py-3 font-medium text-muted-foreground">Estado</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">ID</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Vehículo</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Patente</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Calificación</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">Sin repartidores</td></tr>
              ) : (
                filtered.map((d) => (
                  <tr key={d.id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <Circle className={`h-3 w-3 fill-current ${
                          d.status === 'suspended' ? 'text-red-500' :
                          d.online ? 'text-emerald-500' : 'text-gray-300'
                        }`} />
                        <span className="text-xs text-muted-foreground">
                          {d.status === 'suspended' ? 'Suspendido' : d.online ? 'En línea' : 'Desconectado'}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-muted-foreground">{d.userId.slice(0, 12)}...</td>
                    <td className="px-4 py-3 capitalize text-muted-foreground">{d.vehicle?.type || '—'}</td>
                    <td className="px-4 py-3 font-medium">{d.vehicle?.plate || '—'}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1">
                        <span className="text-amber-500">★</span>
                        <span>{d.ratings?.avg?.toFixed(1) || '0.0'}</span>
                        <span className="text-xs text-muted-foreground">({d.ratings?.count || 0})</span>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => toggleSuspend(d.id, d.status)}
                        className={`rounded-lg px-3 py-1 text-xs font-medium transition-colors ${
                          d.status === 'suspended'
                            ? 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
                            : 'bg-red-50 text-red-700 hover:bg-red-100'
                        }`}
                      >
                        {d.status === 'suspended' ? 'Activar' : 'Suspender'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
