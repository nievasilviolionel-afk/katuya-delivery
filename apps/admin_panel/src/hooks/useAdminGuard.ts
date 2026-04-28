import { useState, useEffect } from 'react'
import { auth } from '@/lib/firebase'
import { useAuth } from './useAuth'

export function useAdminGuard() {
  const { user } = useAuth()
  const [isAdmin, setIsAdmin] = useState(false)
  const [checking, setChecking] = useState(true)

  useEffect(() => {
    async function checkRole() {
      if (!user) {
        setChecking(false)
        return
      }
      try {
        const idTokenResult = await auth.currentUser?.getIdTokenResult(true)
        const role = idTokenResult?.claims?.role as string
        setIsAdmin(role === 'admin')
      } catch (err) {
        setIsAdmin(false)
      } finally {
        setChecking(false)
      }
    }
    checkRole()
  }, [user])

  return { isAdmin, checking }
}
