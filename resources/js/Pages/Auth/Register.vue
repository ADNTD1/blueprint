<script setup>
import { Head, Link } from '@inertiajs/vue3';
import { ref } from 'vue';
import { supabase, syncAuthenticatedProfile } from '@/lib/supabase';

const form = ref({
    name: '',
    email: '',
    password: '',
    password_confirmation: '',
});

const processing = ref(false);
const errorMessage = ref('');
const successMessage = ref('');

const submit = async () => {
    if (form.value.password !== form.value.password_confirmation) {
        errorMessage.value = 'Las contrasenas no coinciden';
        return;
    }

    processing.value = true;
    errorMessage.value = '';
    successMessage.value = '';

    try {
        const { data, error } = await supabase.auth.signUp({
            email: form.value.email,
            password: form.value.password,
            options: {
                data: {
                    full_name: form.value.name,
                }
            }
        });

        if (error) throw error;

        await syncAuthenticatedProfile(data.user);

        successMessage.value = 'Cuenta creada. Revisa tu correo para confirmar tu registro y luego inicia sesion.';
        form.value = { name: '', email: '', password: '', password_confirmation: '' };
    } catch (error) {
        errorMessage.value = error.message || 'Ocurrio un error al registrarse.';
    } finally {
        processing.value = false;
    }
};
</script>

<template>
    <Head title="Registro - Blueprint" />

    <div class="auth-wrapper flex-center">
        <Link href="/" class="brand-link">
            <img src="/images/logo.png" alt="Blueprint logo" />
            <span>Blueprint</span>
        </Link>

        <div class="auth-card">
            <div class="auth-header">
                <h2>Comienza a <br /><span class="gradient-text">gestionar mejor</span></h2>
                <p>Crea tu cuenta gratuita en segundos y organiza a tu equipo.</p>
            </div>

            <div v-if="errorMessage" class="alert alert-error">
                {{ errorMessage }}
            </div>
            <div v-if="successMessage" class="alert alert-success">
                {{ successMessage }}
            </div>

            <form v-if="!successMessage" @submit.prevent="submit" class="auth-form">
                <div class="form-group">
                    <label for="name">Nombre completo</label>
                    <input
                        id="name"
                        v-model="form.name"
                        type="text"
                        placeholder="Juan Perez"
                        required
                        autofocus
                    />
                </div>

                <div class="form-group">
                    <label for="email">Correo electronico</label>
                    <input
                        id="email"
                        v-model="form.email"
                        type="email"
                        placeholder="tu@empresa.com"
                        required
                    />
                </div>

                <div class="form-group">
                    <label for="password">Contrasena</label>
                    <input
                        id="password"
                        v-model="form.password"
                        type="password"
                        placeholder="Minimo 8 caracteres"
                        required
                    />
                </div>

                <div class="form-group">
                    <label for="password_confirmation">Confirmar contrasena</label>
                    <input
                        id="password_confirmation"
                        v-model="form.password_confirmation"
                        type="password"
                        placeholder="Repite tu contrasena"
                        required
                    />
                </div>

                <button type="submit" class="submit-btn" :disabled="processing">
                    <span v-if="processing">Procesando...</span>
                    <span v-else>Crear cuenta gratis</span>
                </button>
            </form>

            <div class="auth-footer">
                Ya tienes una cuenta?
                <Link href="/login" class="login-link">Inicia sesion</Link>
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

.alert-success {
    background: #ecfdf5;
    color: #047857;
    border: 1.5px solid #a7f3d0;
}

.auth-form {
    display: flex;
    flex-direction: column;
    gap: 18px;
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

.login-link {
    font-weight: 600;
    color: #0f0f0f;
    text-decoration: none;
    margin-left: 4px;
}

.login-link:hover { text-decoration: underline; }

@media (max-width: 600px) {
    .auth-card { padding: 32px 24px; }
    .brand-link { position: relative; top: 0; left: 0; justify-content: center; margin-bottom: 32px; }
    .auth-wrapper { flex-direction: column; justify-content: center; }
}
</style>
