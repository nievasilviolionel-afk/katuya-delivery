import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  Store,
  Truck,
  ClipboardList,
  Settings,
  LogOut,
} from 'lucide-react'
import { auth } from '@/lib/firebase'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/merchants', icon: Store, label: 'Comercios' },
  { to: '/drivers', icon: Truck, label: 'Repartidores' },
  { to: '/orders', icon: ClipboardList, label: 'Órdenes' },
  { to: '/settings', icon: Settings, label: 'Configuración' },
]

export function Sidebar() {
  return (
    <aside className="flex w-64 flex-col border-r bg-white">
      <div className="flex h-16 items-center gap-3 border-b px-6">
        <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br from-primary to-secondary text-lg font-bold text-white">
          K
        </div>
        <div>
          <h1 className="text-sm font-bold leading-tight text-gray-900">Katuya</h1>
          <p className="text-xs text-muted-foreground">Admin</p>
        </div>
      </div>

      <nav className="flex-1 space-y-1 px-3 py-4">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-primary/10 text-primary'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              }`
            }
          >
            <item.icon className="h-5 w-5" />
            {item.label}
          </NavLink>
        ))}
      </nav>

      <div className="border-t p-3">
        <button
          onClick={() => auth.signOut()}
          className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-gray-600 transition-colors hover:bg-gray-50 hover:text-red-600"
        >
          <LogOut className="h-5 w-5" />
          Cerrar sesión
        </button>
        <p className="mt-2 px-3 text-[10px] text-gray-400 italic">by Silvio Lionel Nieva</p>
      </div>
    </aside>
  )
}
