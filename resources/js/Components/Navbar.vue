<script setup>
import { Link } from '@inertiajs/vue3'
import { ref, onMounted } from 'vue'
import { supabase, syncAuthenticatedProfile } from '@/lib/supabase'

const user = ref(null)

onMounted(async () => {
    const { data: { session } } = await supabase.auth.getSession()
    user.value = session?.user || null

    if (session?.user) {
        await syncAuthenticatedProfile(session.user)
    }

    supabase.auth.onAuthStateChange(async (_event, session) => {
        user.value = session?.user || null

        if (session?.user) {
            await syncAuthenticatedProfile(session.user)
        }
    })
})

const logout = async () => {
    await supabase.auth.signOut()
    window.location.href = '/'
}
</script>

<template>
    <nav class="bg-white border-b shadow-sm">
        <div class="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
            <div class="text-xl font-bold flex-1">
                <Link href="/" class="text-gray-900 hover:text-black w-fit" style="display:flex; align-items:center; gap:8px;">
                    <img src="/images/logo.png" alt="Blueprint logo" style="width:32px; height:32px; object-fit:contain;" />
                    Blueprint
                </Link>
            </div>

            <div class="flex gap-8">
                <Link href="/pricing" class="text-gray-700 hover:text-black">
                    Precios
                </Link>
                <Link href="/about" class="text-gray-700 hover:text-black">
                    Nosotros
                </Link>
                <Link href="/support" class="text-gray-700 hover:text-black">
                    Soporte
                </Link>
            </div>

            <div class="flex-1 flex justify-end">
                <div v-if="!user" class="flex items-center gap-4">
                    <Link
                        href="/login"
                        class="px-4 py-2 text-gray-700 hover:text-black font-semibold rounded-lg transition"
                    >
                        Iniciar sesion
                    </Link>
                    <Link
                        href="/register"
                        class="px-5 py-2.5 bg-black text-white font-semibold rounded-lg hover:bg-gray-800 transition shadow-sm"
                    >
                        Empezar gratis
                    </Link>
                </div>

                <div v-else class="flex items-center gap-4">
                    <span class="text-sm text-gray-600 font-medium truncate max-w-[150px]">
                        {{ user.user_metadata?.full_name || user.email }}
                    </span>
                    <button
                        @click="logout"
                        class="text-sm px-4 py-2 border border-gray-200 text-gray-700 font-semibold rounded-lg hover:bg-gray-50 transition"
                    >
                        Salir
                    </button>
                    <Link
                        href="/dashboard"
                        class="px-5 py-2 bg-indigo-600 text-white font-semibold rounded-lg hover:bg-indigo-700 transition shadow-sm"
                    >
                        Dashboard
                    </Link>
                </div>
            </div>
        </div>
    </nav>
</template>
