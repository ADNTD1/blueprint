import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export async function syncAuthenticatedProfile(user) {
    if (!user?.id) return

    const profilePayload = {
        id: user.id,
        email: user.email?.toLowerCase?.() || user.email || null,
        name: user.user_metadata?.full_name || user.user_metadata?.name || user.email || 'Usuario',
        role: user.user_metadata?.role || 'manager',
    }

    const { error } = await supabase
        .from('profiles')
        .upsert(profilePayload, { onConflict: 'id' })

    if (error) {
        console.error('Error syncing profile:', error)
    }
}
