import { useEffect, useState } from 'react'
import { collection, query, where, onSnapshot, getCountFromServer } from 'firebase/firestore'
import { db } from '@/lib/firebase'
import { TrendingUp, Users, Truck, Clock, Package, AlertTriangle } from 'lucide-react'

interface KPICardProps {
  title: string
  value: string | number
  subtitle?: string
  icon: React.ElementType
  color: string
}

function KPICard({ title, value, subtitle, icon: Icon, color }: KPICardProps) {
  return (
    <div className="rounded-xl border bg-white p-6 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-muted-foreground">{title}</p>
          <p className="mt-2 text-3xl font-bold text-gray-900">{value}</p>
          {subtitle && <p className="mt-1 text-xs text-muted-foreground">{subtitle}</p>}
        </div>
        <div className={`rounded-lg p-3 ${color}`}>
          <Icon className="h-5 w-5 text-white" />
        </div>
      </div>
    </div>
  )
}

export function DashboardPage() {
  const [kpis, setKpis] = useState({
    activeDrivers: 0,
    ordersToday: 0,
    pendingOrders: 0,
    avgEta: '—',
  })

  useEffect(() => {
    // Active drivers count
    const driversQuery = query(collection(db, 'drivers'), where('online', '==', true))
    const unsubDrivers = onSnapshot(driversQuery, (snap) => {
      setKpis((prev) => ({ ...prev, activeDrivers: snap.size }))
    })

    // Pending orders count
    const ordersQuery = query(
      collection(db, 'orders'),
      where('status', 'in', ['created', 'searching', 'assigned'])
    )
    const unsubOrders = onSnapshot(ordersQuery, (snap) => {
      setKpis((prev) => ({ ...prev, pendingOrders: snap.size }))
    })

    return () => {
      unsubDrivers()
      unsubOrders()
    }
  }, [])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-sm text-muted-foreground">Visión general del sistema</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard
          title="Repartidores activos"
          value={kpis.activeDrivers}
          subtitle="En línea ahora"
          icon={Truck}
          color="bg-emerald-500"
        />
        <KPICard
          title="Órdenes hoy"
          value={kpis.ordersToday}
          subtitle="Total del día"
          icon={Package}
          color="bg-primary"
        />
        <KPICard
          title="Órdenes pendientes"
          value={kpis.pendingOrders}
          subtitle="En progreso"
          icon={Clock}
          color="bg-amber-500"
        />
        <KPICard
          title="ETA promedio"
          value={kpis.avgEta}
          subtitle="Minutos"
          icon={TrendingUp}
          color="bg-secondary"
        />
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-xl border bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-900">Actividad reciente</h2>
          <p className="text-sm text-muted-foreground">Últimas órdenes en el sistema</p>
          <RecentOrders />
        </div>

        <div className="rounded-xl border bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-gray-900">Alertas</h2>
          <p className="text-sm text-muted-foreground">Requieren atención</p>
          <AlertsList />
        </div>
      </div>
    </div>
  )
}

function RecentOrders() {
  const [orders, setOrders] = useState<any[]>([])

  useEffect(() => {
    const q = query(collection(db, 'orders'))
    const unsub = onSnapshot(q, (snap) => {
      const items = snap.docs.slice(0, 5).map((d) => ({ id: d.id, ...d.data() }))
      setOrders(items)
    })
    return () => unsub()
  }, [])

  if (orders.length === 0) {
    return (
      <div className="mt-4 flex items-center gap-3 rounded-lg bg-gray-50 p-4 text-sm text-muted-foreground">
        <Package className="h-5 w-5" />
        Sin órdenes recientes
      </div>
    )
  }

  return (
    <div className="mt-4 space-y-3">
      {orders.map((order) => (
        <div key={order.id} className="flex items-center justify-between rounded-lg border p-3">
          <div>
            <p className="text-sm font-medium text-gray-900">Orden #{order.id.slice(-6)}</p>
            <p className="text-xs text-muted-foreground">{order.status}</p>
          </div>
          <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${getStatusStyle(order.status)}`}>
            {order.status}
          </span>
        </div>
      ))}
    </div>
  )
}

function AlertsList() {
  return (
    <div className="mt-4 space-y-3">
      <div className="flex items-start gap-3 rounded-lg bg-amber-50 p-4">
        <AlertTriangle className="mt-0.5 h-5 w-5 text-amber-600" />
        <div>
          <p className="text-sm font-medium text-amber-900">Órdenes expiradas</p>
          <p className="text-xs text-amber-700">3 órdenes expiraron sin asignación en la última hora</p>
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
