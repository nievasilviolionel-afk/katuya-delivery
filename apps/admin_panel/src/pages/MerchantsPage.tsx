import { useState, useEffect } from 'react'
import { collection, onSnapshot, doc, updateDoc } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { Store, Search, MoreHorizontal, ToggleLeft, ToggleRight } from 'lucide-react'

interface Merchant {
  id: string
  name: string
  legalName: string
  taxId?: string
  address: string
  status: 'active' | 'paused'
  settings: {
    autoAssign: boolean
    deliveryRadiusKm: number
    cancelTimeoutSec: number
  }
}

export function MerchantsPage() {
  const [merchants, setMerchants] = useState<Merchant[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'merchants'), (snap) => {
      const items = snap.docs.map((d) => ({ id: d.id, ...d.data() } as Merchant))
      setMerchants(items)
      setLoading(false)
    })
    return () => unsub()
  }, [])

  const filtered = merchants.filter((m) =>
    m.name.toLowerCase().includes(search.toLowerCase()) ||
    m.legalName.toLowerCase().includes(search.toLowerCase())
  )

  async function toggleStatus(id: string, current: string) {
    const newStatus = current === 'active' ? 'paused' : 'active'
    await updateDoc(doc(db, 'merchants', id), { status: newStatus })
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Comercios</h1>
          <p className="text-sm text-muted-foreground">{merchants.length} comercios registrados</p>
        </div>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <input
          type="text"
          placeholder="Buscar comercios..."
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
                <th className="px-4 py-3 font-medium text-muted-foreground">Nombre</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Dirección</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Estado</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Auto-asignar</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Radio</th>
                <th className="px-4 py-3 font-medium text-muted-foreground">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">Cargando...</td></tr>
              ) : filtered.length === 0 ? (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-muted-foreground">Sin resultados</td></tr>
              ) : (
                filtered.map((m) => (
                  <tr key={m.id} className="border-b last:border-0 hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary/10">
                          <Store className="h-4 w-4 text-primary" />
                        </div>
                        <div>
                          <p className="font-medium text-gray-900">{m.name}</p>
                          <p className="text-xs text-muted-foreground">{m.legalName}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">{m.address}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
                        m.status === 'active' ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-600'
                      }`}>
                        {m.status === 'active' ? 'Activo' : 'Pausado'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      {m.settings?.autoAssign ? (
                        <span className="text-emerald-600">Sí</span>
                      ) : (
                        <span className="text-gray-400">No</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">{m.settings?.deliveryRadiusKm || 5} km</td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => toggleStatus(m.id, m.status)}
                        className="rounded-lg p-2 text-gray-500 hover:bg-gray-100"
                        title={m.status === 'active' ? 'Pausar' : 'Activar'}
                      >
                        {m.status === 'active' ? (
                          <ToggleRight className="h-5 w-5 text-emerald-500" />
                        ) : (
                          <ToggleLeft className="h-5 w-5 text-gray-400" />
                        )}
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
