<script setup>
import { Head, Link } from '@inertiajs/vue3';
import { ref } from 'vue';

const form = ref({
    email: '',
});

const status = ref('');

const submit = () => {
    // Simulado
    status.value = 'Se ha enviado un enlace de recuperación a tu correo.';
    console.log('Forgot Password Simulado:', form.value);
};
</script>

<template>
    <Head title="Recuperar Contraseña — Blueprint" />

    <div class="auth-wrapper flex-center">
        <!-- Logo Absolute Top Left -->
        <Link href="/" class="brand-link">
            <img src="/images/logo.png" alt="Blueprint logo" />
            <span>Blueprint</span>
        </Link>

        <!-- Main Card -->
        <div class="auth-card">
            
            <div class="auth-header">
                <h2>Recupera tu <br/><span class="gradient-text">acceso seguro</span></h2>
                <p>Ingresa el correo asociado a tu cuenta y te enviaremos un enlace para restablecer tu contraseña.</p>
            </div>

            <div v-if="status" class="status-message">
                {{ status }}
            </div>

            <form @submit.prevent="submit" class="auth-form" v-else>
                
                <div class="form-group">
                    <label for="email">Correo electrónico</label>
                    <input 
                        id="email"
                        v-model="form.email"
                        type="email" 
                        placeholder="tu@empresa.com"
                        required
                        autofocus
                    />
                </div>

                <button type="submit" class="submit-btn" @click.prevent="submit">
                    Enviar enlace
                </button>

            </form>

            <div class="auth-footer">
                <Link href="/login" class="back-link">← Volver a iniciar sesión</Link>
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
    font-size: 14px;
    color: #6b7280;
    line-height: 1.5;
}

.status-message {
    background: #ecfdf5;
    border: 1.5px solid #a7f3d0;
    color: #047857;
    padding: 16px;
    border-radius: 10px;
    font-size: 14px;
    font-weight: 500;
    text-align: center;
    line-height: 1.5;
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

.form-group label {
    font-size: 13px;
    font-weight: 600;
    color: #374151;
}

.form-group input {
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
}
.submit-btn:hover { background: #222; transform: translateY(-1px); }
.submit-btn:active { transform: translateY(0); }

.auth-footer {
    margin-top: 32px;
    text-align: center;
}
.back-link {
    font-size: 14px;
    font-weight: 600;
    color: #6b7280;
    text-decoration: none;
    transition: color 0.2s;
}
.back-link:hover { color: #0f0f0f; }

@media (max-width: 600px) {
    .auth-card { padding: 32px 24px; }
    .brand-link { position: relative; top: 0; left: 0; justify-content: center; margin-bottom: 32px; }
    .auth-wrapper { flex-direction: column; justify-content: center; }
}
</style>
