import { useState, useEffect } from 'react'
import { collection, onSnapshot, doc, updateDoc, query, orderBy, limit } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { ClipboardList, Search, XCircle, UserCheck } from 'lucide-react'

interface Order {
  id: string
  merchantId: string
  status: string
  pickup: { address: string }
  dropoff: { address: string }
  pricing: { total: number; currency: string }
  assignedDriverId?: string
  createdAt: any
}

const statusFilters = [
  { value: 'all', label: 'Todas' },
  { value: 'created', label: 'Creadas' },
  { value: 'searching', label: 'Buscando' },
  { value: 'assigned', label: 'Asignadas' },
  { value: 'picked_up', label: 'En camino' },
  { value: 'delivered', label: 'Entregadas' },
  { value: 'canceled', label: 'Canceladas' },
]

export function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([])
  const [filter, setFilter] = useState('all')
  const [search, setSearch] = useState('')

  useEffect(() => {
    const q = query(collection(db, 'orders'), orderBy('createdAt', 'desc'), limit(100))
    const unsub = onSnapshot(q, (snap) => {
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() } as Order))
      setOrders(items)
    })
    return () => unsub()
  }, [])

  const filtered = orders
    .filter((o) => filter === 'all' || o.status === filter)
    .filter((o) =>
      search === '' ||
      o.pickup?.address?.toLowerCase().includes(search.toLowerCase()) ||
      o.dropoff?.address?.toLowerCase().includes(search.toLowerCase())
    )

  async function cancelOrder(id: string) {
    await updateDoc(doc(db, 'orders', id), {
      status: 'canceled',
      updatedAt: new Date(),
    })
  }

  async function forceAssign(id: string) {
    // In real app, would show driver selection dialog
    await updateDoc(doc(db, 'orders', id), {
      status: 'assigned',
      updatedAt: new Date(),
    })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Órdenes</h1>
          <p className="text-sm text-muted-foreground">{orders.length} órdenes en el sistema</p>
        </div>
      </div>

      <div className="flex flex-col gap-4 sm:flex-row">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <input
            type="text"
            placeholder="Buscar por dirección..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-lg border border-gray-200 py-2.5 pl-10 pr-4 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
          />
        </div>
      </div>

      <div className="flex flex-wrap gap-2">
        {statusFilters.map((f) => (
          <button
            key={f.value}
            onClick={() => setFilter(f.value)}
            className={`rounded-full px-4 py-1.5 text-xs font-medium transition-colors ${
              filter === f.value
                ? 'bg-primary text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      <div className="rounded-xl border bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-gray-50 text-left">
                <th className="px-4 py-3 font-medium text-muted-foreground">ID</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Estado</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Retiro</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Entrega</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Total</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Repartidor</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">Sin órdenes</td></tr>
              ) : (
                filtered.map((o) => (
                  <tr key={o.id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-3 font-mono text-xs">#{o.id.slice(-6)}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${getStatusStyle(o.status)}`}>
                        {o.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 max-w-[200px] truncate text-muted-foreground">{o.pickup?.address || '—'}</td>
                    <td className="px-4 py-3 max-w-[200px] truncate text-muted-foreground">{o.dropoff?.address || '—'}</td>
                    <td className="px-4 py-3 font-medium">
                      ${o.pricing?.total?.toFixed(2) || '0.00'} {o.pricing?.currency}
                    </td>
                    <td className="px-4 py-3">
                      {o.assignedDriverId ? (
                        <span className="inline-flex items-center gap-1 text-xs text-emerald-600">
                          <UserCheck className="h-3 w-3" />
                          Asignado
                        </span>
                      ) : (
                        <span className="text-xs text-gray-400">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex gap-1">
                        {!o.assignedDriverId && o.status !== 'canceled' && (
                          <button
                            onClick={() => forceAssign(o.id)}
                            className="rounded-lg p-1.5 text-primary hover:bg-primary/10"
                            title="Asignar manualmente"
                          >
                            <UserCheck className="h-4 w-4" />
                          </button>
                        )}
                        {o.status !== 'canceled' && o.status !== 'delivered' && (
                          <button
                            onClick={() => cancelOrder(o.id)}
                            className="rounded-lg p-1.5 text-red-500 hover:bg-red-50"
                            title="Forzar cancelación"
                          >
                            <XCircle className="h-4 w-4" />
                          </button>
                        )}
                      </div>
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

function getStatusStyle(status: string) {
  const styles: Record<string, string> = {
    created: 'bg-gray-100 text-gray-700',
    searching: 'bg-blue-100 text-blue-700',
    assigned: 'bg-purple-100 text-purple-700',
    picked_up: 'bg-amber-100 text-amber-700',
    delivered: 'bg-emerald-100 text-emerald-700',
    canceled: 'bg-red-100 text-red-700',
    expired: 'bg-gray-100 text-gray-500',
  }
  return styles[status] || 'bg-gray-100 text-gray-700'
}
