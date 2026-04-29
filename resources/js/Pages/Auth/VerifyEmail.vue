<script setup>
import { Head, Link } from '@inertiajs/vue3';
import { ref, onMounted } from 'vue';
import { supabase } from '@/lib/supabase';

const props = defineProps({
    email: {
        type: String,
        default: ''
    }
});

const processing = ref(false);
const statusMessage = ref('');
const errorMessage = ref('');

const resendVerification = async () => {
    if (!props.email) {
        errorMessage.value = 'No se encontró el correo. Inicia sesión nuevamente.';
        return;
    }

    processing.value = true;
    errorMessage.value = '';
    statusMessage.value = '';

    try {
        const { error } = await supabase.auth.resend({
            type: 'signup',
            email: props.email,
            options: {
                // redirectTo: window.location.origin + '/dashboard' // opcional
            }
        });

        if (error) throw error;

        statusMessage.value = '¡Enlace reenviado! Revisa tu bandeja de entrada o spam.';
    } catch (error) {
        errorMessage.value = error.message || 'Ocurrió un error al enviar el correo.';
    } finally {
        processing.value = false;
    }
};

const logout = async () => {
    await supabase.auth.signOut();
    window.location.href = '/login';
};
</script>

<template>
    <Head title="Verificar Correo — Blueprint" />

    <div class="auth-wrapper flex-center">
        <!-- Logo Absolute Top Left -->
        <Link href="/" class="brand-link">
            <img src="/images/logo.png" alt="Blueprint logo" />
            <span>Blueprint</span>
        </Link>

        <!-- Main Card -->
        <div class="auth-card">
            
            <div class="auth-header">
                <div class="icon-wrapper">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-8 h-8">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75" />
                    </svg>
                </div>
                <h2>Verifica tu <br/><span class="gradient-text">correo electrónico</span></h2>
                <p>
                    ¡Gracias por registrarte! Antes de comenzar, por favor verifica tu dirección 
                    de correo haciendo clic en el enlace que te acabamos de enviar.
                </p>
            </div>

            <div v-if="statusMessage" class="alert alert-success">
                {{ statusMessage }}
            </div>
            
            <div v-if="errorMessage" class="alert alert-error">
                {{ errorMessage }}
            </div>

            <div class="actions-group">
                <button 
                    @click="resendVerification" 
                    class="submit-btn" 
                    :disabled="processing"
                >
                    <span v-if="processing">Enviando...</span>
                    <span v-else>Reenviar correo de verificación</span>
                </button>

                <button @click="logout" class="logout-btn">
                    Cerrar sesión
                </button>
            </div>

        </div>
    </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');

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
    max-width: 460px;
    border: 1.5px solid #e5e7eb;
    border-radius: 20px;
    padding: 48px;
    box-shadow: 0 12px 40px rgba(0,0,0,0.06);
}

.icon-wrapper {
    width: 56px;
    height: 56px;
    background: #f3f4f6;
    border-radius: 16px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 24px auto;
    color: #4f46e5;
}

.auth-header {
    text-align: center;
    margin-bottom: 32px;
}
.auth-header h2 {
    font-size: 26px;
    font-weight: 900;
    margin-bottom: 12px;
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
    font-size: 14.5px;
    color: #4b5563;
    line-height: 1.6;
}

.alert {
    padding: 14px 16px;
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
.alert-success {
    background: #ecfdf5;
    color: #047857;
    border: 1.5px solid #a7f3d0;
}

.actions-group {
    display: flex;
    flex-direction: column;
    gap: 12px;
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
    display: flex;
    justify-content: center;
    width: 100%;
}
.submit-btn:hover:not(:disabled) { background: #222; transform: translateY(-1px); }
.submit-btn:active:not(:disabled) { transform: translateY(0); }
.submit-btn:disabled {
    opacity: 0.7;
    cursor: not-allowed;
}

.logout-btn {
    background: transparent;
    color: #6b7280;
    padding: 12px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 14px;
    border: 1.5px solid transparent;
    cursor: pointer;
    transition: color 0.2s, background 0.2s;
    font-family: 'Inter', sans-serif;
    width: 100%;
}
.logout-btn:hover { 
    color: #111827;
    background: #f9fafb;
    border-color: #e5e7eb;
}

@media (max-width: 600px) {
    .auth-card { padding: 32px 24px; }
    .brand-link { position: relative; top: 0; left: 0; justify-content: center; margin-bottom: 32px; }
    .auth-wrapper { flex-direction: column; justify-content: center; }
}
</style>
