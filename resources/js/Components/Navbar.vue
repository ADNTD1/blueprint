<script setup>
import { Link } from '@inertiajs/vue3'
import { ref, onMounted } from 'vue'
import { supabase, syncAuthenticatedProfile } from '@/lib/supabase'

const user = ref(null)
const mobileMenuOpen = ref(false)

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
        <div class="max-w-7xl mx-auto px-4 sm:px-6">
            <div class="h-16 sm:h-20 flex items-center justify-between gap-3">
                <Link href="/" class="brand-link">
                    <img src="/images/logo.png" alt="Blueprint logo" />
                    <span>Blueprint</span>
                </Link>

                <div class="hidden md:flex items-center gap-8">
                    <Link href="/pricing" class="nav-link">
                        Precios
                    </Link>
                    <Link href="/about" class="nav-link">
                        Nosotros
                    </Link>
                    <Link href="/support" class="nav-link">
                        Soporte
                    </Link>
                </div>

                <div class="hidden md:flex justify-end min-w-[240px]">
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

                <button
                    type="button"
                    class="mobile-menu-button"
                    :aria-expanded="mobileMenuOpen"
                    aria-label="Abrir menu"
                    @click="mobileMenuOpen = !mobileMenuOpen"
                >
                    <svg v-if="!mobileMenuOpen" xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7h16M4 12h16M4 17h16" />
                    </svg>
                    <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18 18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <div v-if="mobileMenuOpen" class="md:hidden border-t border-gray-100 py-4">
                <div class="flex flex-col gap-1">
                    <Link href="/pricing" class="mobile-nav-link" @click="mobileMenuOpen = false">
                        Precios
                    </Link>
                    <Link href="/about" class="mobile-nav-link" @click="mobileMenuOpen = false">
                        Nosotros
                    </Link>
                    <Link href="/support" class="mobile-nav-link" @click="mobileMenuOpen = false">
                        Soporte
                    </Link>
                </div>

                <div v-if="!user" class="mt-4 grid gap-2">
                    <Link
                        href="/login"
                        class="mobile-action secondary"
                        @click="mobileMenuOpen = false"
                    >
                        Iniciar sesion
                    </Link>
                    <Link
                        href="/register"
                        class="mobile-action primary"
                        @click="mobileMenuOpen = false"
                    >
                        Empezar gratis
                    </Link>
                </div>

                <div v-else class="mt-4 grid gap-2">
                    <div class="px-3 py-2 text-sm text-gray-600 truncate">
                        {{ user.user_metadata?.full_name || user.email }}
                    </div>
                    <Link
                        href="/dashboard"
                        class="mobile-action primary"
                        @click="mobileMenuOpen = false"
                    >
                        Dashboard
                    </Link>
                    <button
                        @click="logout"
                        class="mobile-action secondary"
                    >
                        Salir
                    </button>
                </div>
            </div>
        </div>
    </nav>
</template>

<style scoped>
.brand-link {
    display: inline-flex;
    align-items: center;
    min-width: 0;
    gap: 8px;
    color: #111827;
    font-size: 20px;
    font-weight: 800;
    letter-spacing: 0;
    text-decoration: none;
}

.brand-link img {
    width: 32px;
    height: 32px;
    flex: 0 0 32px;
    object-fit: contain;
}

.brand-link span {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.nav-link {
    color: #374151;
    font-weight: 600;
    transition: color 0.2s;
}

.nav-link:hover {
    color: #000;
}

.mobile-menu-button {
    display: inline-flex;
    width: 40px;
    height: 40px;
    flex: 0 0 40px;
    align-items: center;
    justify-content: center;
    border-radius: 8px;
    color: #374151;
    transition: background 0.2s, color 0.2s;
}

.mobile-menu-button:hover {
    background: #f3f4f6;
    color: #000;
}

.mobile-nav-link,
.mobile-action {
    display: flex;
    align-items: center;
    min-height: 44px;
    border-radius: 8px;
    padding: 10px 12px;
    font-weight: 700;
    text-decoration: none;
}

.mobile-nav-link {
    color: #374151;
}

.mobile-action {
    justify-content: center;
}

.mobile-action.primary {
    background: #000;
    color: #fff;
}

.mobile-action.secondary {
    border: 1px solid #e5e7eb;
    color: #374151;
}

@media (min-width: 768px) {
    .mobile-menu-button {
        display: none;
    }
}

@media (max-width: 360px) {
    .brand-link {
        font-size: 18px;
    }

    .brand-link img {
        width: 28px;
        height: 28px;
        flex-basis: 28px;
    }
}
</style>
