import { useState } from 'react'
import { Settings, Palette, Globe, DollarSign, Save } from 'lucide-react'

export function SettingsPage() {
  const [currency, setCurrency] = useState('ARS')
  const [locale, setLocale] = useState('es-AR')
  const [baseFare, setBaseFare] = useState('300')
  const [perKmRate, setPerKmRate] = useState('50')
  const [perMinRate, setPerMinRate] = useState('10')
  const [minFare, setMinFare] = useState('300')
  const [saved, setSaved] = useState(false)

  function handleSave() {
    // In real app, save to Firestore
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Configuración</h1>
        <p className="text-sm text-muted-foreground">Parámetros del sistema</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* General */}
        <div className="rounded-xl border bg-white p-6 shadow-sm">
          <div className="mb-4 flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
              <Palette className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h2 className="font-semibold text-gray-900">General</h2>
              <p className="text-xs text-muted-foreground">Preferencias del sistema</p>
            </div>
          </div>

          <div className="space-y-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">Idioma</label>
              <select
                value={locale}
                onChange={(e) => setLocale(e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
              >
                <option value="es-AR">Español (Argentina)</option>
                <option value="en-US">English (US)</option>
              </select>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">Moneda</label>
              <select
                value={currency}
                onChange={(e) => setCurrency(e.target.value)}
                className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
              >
                <option value="ARS">ARS - Peso argentino</option>
                <option value="USD">USD - Dólar estadounidense</option>
              </select>
            </div>
          </div>
        </div>

        {/* Pricing */}
        <div className="rounded-xl border bg-white p-6 shadow-sm">
          <div className="mb-4 flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-500/10">
              <DollarSign className="h-5 w-5 text-amber-600" />
            </div>
            <div>
              <h2 className="font-semibold text-gray-900">Tarifas</h2>
              <p className="text-xs text-muted-foreground">Configuración de precios</p>
            </div>
          </div>

          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Tarifa base</label>
                <input
                  type="number"
                  value={baseFare}
                  onChange={(e) => setBaseFare(e.target.value)}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Tarifa mínima</label>
                <input
                  type="number"
                  value={minFare}
                  onChange={(e) => setMinFare(e.target.value)}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">$/km</label>
                <input
                  type="number"
                  value={perKmRate}
                  onChange={(e) => setPerKmRate(e.target.value)}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">$/minuto</label>
                <input
                  type="number"
                  value={perMinRate}
                  onChange={(e) => setPerMinRate(e.target.value)}
                  className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-4">
        <button
          onClick={handleSave}
          className="flex items-center gap-2 rounded-lg bg-primary px-6 py-2.5 text-sm font-medium text-white transition-colors hover:bg-primary/90"
        >
          <Save className="h-4 w-4" />
          Guardar cambios
        </button>
        {saved && (
          <span className="text-sm text-emerald-600">Cambios guardados</span>
        )}
      </div>

      <div className="rounded-xl border bg-gray-50 p-6">
        <h2 className="font-semibold text-gray-900">Información del sistema</h2>
        <div className="mt-4 space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-muted-foreground">Versión</span>
            <span className="font-medium">1.0.0</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted-foreground">Autor</span>
            <span className="font-medium italic">Silvio Lionel Nieva</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted-foreground">Licencia</span>
            <span className="font-medium">MIT</span>
          </div>
          <div className="flex justify-between">
            <span className="text-muted-foreground">Stack</span>
            <span className="font-medium">React + Vite + Tailwind + Firebase</span>
          </div>
        </div>
      </div>
    </div>
  )
}
