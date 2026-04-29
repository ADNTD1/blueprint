<script setup>
import { Head, Link, router } from '@inertiajs/vue3';
import { ref } from 'vue';
import { supabase, syncAuthenticatedProfile } from '@/lib/supabase';

const form = ref({
    email: '',
    password: '',
    remember: false
});

const processing = ref(false);
const errorMessage = ref('');

const submit = async () => {
    processing.value = true;
    errorMessage.value = '';

    try {
        const { data, error } = await supabase.auth.signInWithPassword({
            email: form.value.email,
            password: form.value.password,
        });

        if (error) throw error;

        await syncAuthenticatedProfile(data.user);
        router.visit('/dashboard');
    } catch (error) {
        if (error.message.includes('Email not confirmed')) {
            router.visit(`/verify-email?email=${encodeURIComponent(form.value.email)}`);
        } else {
            errorMessage.value = 'Correo o contrasena incorrectos.';
        }
    } finally {
        processing.value = false;
    }
};
</script>

<template>
    <Head title="Iniciar Sesion - Blueprint" />

    <div class="auth-wrapper flex-center">
        <Link href="/" class="brand-link">
            <img src="/images/logo.png" alt="Blueprint logo" />
            <span>Blueprint</span>
        </Link>

        <div class="auth-card">
            <div class="auth-header">
                <h2>Accede a tu <br /><span class="gradient-text text-3xl">espacio de trabajo</span></h2>
                <p>Ingresa tus credenciales para continuar.</p>
            </div>

            <div v-if="errorMessage" class="alert alert-error">
                {{ errorMessage }}
            </div>

            <form @submit.prevent="submit" class="auth-form">
                <div class="form-group">
                    <label for="email">Correo electronico</label>
                    <input
                        id="email"
                        v-model="form.email"
                        type="email"
                        placeholder="tu@empresa.com"
                        required
                        autofocus
                    />
                </div>

                <div class="form-group">
                    <div class="label-row">
                        <label for="password">Contrasena</label>
                        <Link href="/forgot-password" class="forgot-link">Olvidaste tu contrasena?</Link>
                    </div>
                    <input
                        id="password"
                        v-model="form.password"
                        type="password"
                        placeholder="********"
                        required
                    />
                </div>

                <div class="checkbox-group">
                    <input
                        id="remember"
                        type="checkbox"
                        v-model="form.remember"
                    />
                    <label for="remember" class="flex items-center gap-2 cursor-pointer">
                        Recordarme en este equipo
                    </label>
                </div>

                <button type="submit" class="submit-btn" :disabled="processing">
                    <span v-if="processing">Iniciando sesion...</span>
                    <span v-else>Iniciar sesion</span>
                </button>
            </form>

            <div class="auth-footer">
                No tienes una cuenta aun?
                <Link href="/register" class="signup-link">Registrate gratis</Link>
            </div>
        </div>
    </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

.auth-wrapper {
    font-family: 'Inter', sans-serif;
    min-height: 100vh;
    background: #f9fafb;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
    position: relative;
    color: #0f0f0f;
}

.brand-link {
    position: absolute;
    top: 32px;
    left: 40px;
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 20px;
    font-weight: 800;
    color: #0f0f0f;
    text-decoration: none;
}

.brand-link img {
    width: 32px;
    height: 32px;
    object-fit: contain;
}

.auth-card {
    background: #fff;
    width: 100%;
    max-width: 440px;
    border: 1.5px solid #e5e7eb;
    border-radius: 20px;
    padding: 48px;
    box-shadow: 0 12px 40px rgba(0,0,0,0.06);
}

.auth-header {
    text-align: center;
    margin-bottom: 32px;
}

.auth-header h2 {
    font-size: 26px;
    font-weight: 900;
    margin-bottom: 8px;
    letter-spacing: -0.02em;
    line-height: 1.2;
}

.gradient-text {
    background: linear-gradient(135deg, #6366f1, #8b5cf6, #06b6d4);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
}

.auth-header p {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.5;
}

.alert {
    padding: 12px 16px;
    border-radius: 10px;
    font-size: 14px;
    font-weight: 500;
    margin-bottom: 24px;
    line-height: 1.5;
    text-align: center;
}

.alert-error {
    background: #fef2f2;
    color: #b91c1c;
    border: 1.5px solid #fecaca;
}

.auth-form {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.form-group {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.label-row {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
}

.form-group label {
    font-size: 13px;
    font-weight: 600;
    color: #374151;
}

.forgot-link {
    font-size: 13px;
    font-weight: 500;
    color: #6366f1;
    text-decoration: none;
    transition: color 0.2s;
}

.forgot-link:hover { color: #4f46e5; }

.form-group input[type="email"],
.form-group input[type="password"] {
    background: #fff;
    border: 1.5px solid #d1d5db;
    border-radius: 10px;
    padding: 12px 14px;
    font-size: 15px;
    color: #0f0f0f;
    outline: none;
    transition: border-color 0.2s, box-shadow 0.2s;
    font-family: 'Inter', sans-serif;
}

.form-group input::placeholder { color: #9ca3af; }

.form-group input:focus {
    border-color: #a78bfa;
    box-shadow: 0 0 0 3px rgba(139,92,246,0.15);
}

.checkbox-group {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-top: -4px;
}

.checkbox-group input[type="checkbox"] {
    width: 16px;
    height: 16px;
    border-radius: 4px;
    border: 1.5px solid #d1d5db;
    accent-color: #7c3aed;
    cursor: pointer;
}

.checkbox-group label {
    font-size: 13px;
    color: #6b7280;
    user-select: none;
}

.submit-btn {
    background: #0f0f0f;
    color: #fff;
    padding: 14px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 15px;
    border: none;
    cursor: pointer;
    transition: background 0.2s, transform 0.15s;
    font-family: 'Inter', sans-serif;
    margin-top: 8px;
    display: flex;
    justify-content: center;
}

.submit-btn:hover:not(:disabled) { background: #222; transform: translateY(-1px); }
.submit-btn:active:not(:disabled) { transform: translateY(0); }

.submit-btn:disabled {
    opacity: 0.7;
    cursor: not-allowed;
}

.auth-footer {
    margin-top: 32px;
    text-align: center;
    font-size: 14px;
    color: #6b7280;
}

.signup-link {
    font-weight: 600;
    color: #0f0f0f;
    text-decoration: none;
    margin-left: 4px;
}

.signup-link:hover { text-decoration: underline; }

@media (max-width: 600px) {
    .auth-card { padding: 32px 24px; }
    .brand-link { position: relative; top: 0; left: 0; justify-content: center; margin-bottom: 32px; }
    .auth-wrapper { flex-direction: column; justify-content: center; }
}
</style>
