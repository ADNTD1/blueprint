<script setup>
import { Head, Link } from '@inertiajs/vue3'
import Navbar from '@/Components/Navbar.vue'
import { ref } from 'vue'

const form = ref({
    name: '',
    email: '',
    category: '',
    subject: '',
    message: '',
})

const submitted = ref(false)

function submitTicket() {
    // Future: conectar con backend
    submitted.value = true
}

const faqs = [
    {
        question: '¿Cómo invito a miembros a mi equipo?',
        answer: 'Ve a Configuración del proyecto → Miembros → Invitar. Ingresa el correo y el rol. Recibirán un enlace de invitación.',
        open: ref(false),
    },
    {
        question: '¿Cómo funciona la generación de tareas con IA?',
        answer: 'Describe tu proyecto en lenguaje natural en el asistente de IA. Blueprint analiza el texto y genera un backlog completo con tareas, prioridades y estimaciones.',
        open: ref(false),
    },
    {
        question: '¿Puedo exportar mis proyectos?',
        answer: 'Sí. En el plan Pro y Empresa puedes exportar tu backlog y tableros en formato CSV o JSON desde Configuración → Exportar datos.',
        open: ref(false),
    },
    {
        question: '¿Qué pasa si supero el límite del plan Gratis?',
        answer: 'Recibirás una notificación antes de alcanzar el límite. Puedes actualizar a Pro en cualquier momento desde Configuración → Plan.',
        open: ref(false),
    },
    {
        question: '¿Blueprint tiene aplicación móvil?',
        answer: 'Actualmente Blueprint es una plataforma web optimizada para móvil. La aplicación nativa para iOS y Android está en desarrollo.',
        open: ref(false),
    },
    {
        question: '¿Cómo cancelo mi suscripción?',
        answer: 'Ve a Configuración → Plan → Cancelar suscripción. Tu cuenta seguirá activa hasta el final del período facturado.',
        open: ref(false),
    },
]

function toggle(faq) {
    faq.open.value = !faq.open.value
}
</script>

<template>
    <Head title="Soporte — Blueprint" />

    <div class="support-wrapper">
        <Navbar />

        <!-- Hero -->
        <section class="support-hero">
            <div class="section-label">Centro de Ayuda</div>
            <h1 class="support-title">¿En qué podemos<br /><span class="gradient-text">ayudarte hoy?</span></h1>
            <p class="support-subtitle">Nuestro equipo está disponible para resolver tus dudas. Elige el canal que prefieras.</p>
        </section>

        <!-- Contact Channels -->
        <section class="channels-section">
            <div class="channels-grid">

                <div class="channel-card">
                    <div class="channel-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75" />
                        </svg>
                    </div>
                    <h3>Correo electrónico</h3>
                    <p>Respuesta en menos de 24 horas en días hábiles.</p>
                    <a href="mailto:soporte@blueprint.app" class="channel-link">soporte@blueprint.app</a>
                    <div class="channel-badge">Disponible siempre</div>
                </div>

                <div class="channel-card channel-featured">
                    <div class="channel-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z" />
                        </svg>
                    </div>
                    <div class="featured-badge">Más rápido</div>
                    <h3>Chat en vivo</h3>
                    <p>Habla con un agente en tiempo real. Disponible en horario de oficina.</p>
                    <button class="channel-link channel-btn">Iniciar chat →</button>
                    <div class="channel-badge badge-green">Lun–Vie · 9am–6pm</div>
                </div>

                <div class="channel-card">
                    <div class="channel-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.042A8.967 8.967 0 0 0 6 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 0 1 6 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 0 1 6-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0 0 18 18a8.967 8.967 0 0 0-6 2.292m0-14.25v14.25" />
                        </svg>
                    </div>
                    <h3>Documentación</h3>
                    <p>Guías paso a paso, tutoriales en video y referencias de la API.</p>
                    <a href="#" class="channel-link">Ver documentación →</a>
                    <div class="channel-badge">Autoservicio 24/7</div>
                </div>

            </div>
        </section>

        <!-- Status Banner -->
        <section class="status-section">
            <div class="status-banner">
                <span class="status-dot"></span>
                <span class="status-text">Todos los sistemas operando con normalidad</span>
                <a href="#" class="status-link">Ver página de estado →</a>
            </div>
        </section>

        <!-- FAQ -->
        <section class="faq-section">
            <div class="section-label">FAQ</div>
            <h2 class="faq-title">Preguntas frecuentes</h2>
            <p class="faq-subtitle">Encuentra respuestas rápidas a las dudas más comunes.</p>

            <div class="faq-list">
                <div
                    v-for="(faq, i) in faqs"
                    :key="i"
                    class="faq-item"
                    :class="{ 'faq-open': faq.open.value }"
                    @click="toggle(faq)"
                >
                    <div class="faq-header">
                        <span class="faq-question">{{ faq.question }}</span>
                        <svg class="faq-chevron" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                        </svg>
                    </div>
                    <div class="faq-answer" v-if="faq.open.value">
                        {{ faq.answer }}
                    </div>
                </div>
            </div>
        </section>

        <!-- Ticket Form -->
        <section class="ticket-section">
            <div class="ticket-box">
                <div class="ticket-header">
                    <div class="section-label" style="color:#a78bfa;">Formulario de Soporte</div>
                    <h2 class="ticket-title">Envía un ticket</h2>
                    <p class="ticket-subtitle">No encontraste respuesta? Cuéntanos tu problema y te respondemos en 24h.</p>
                </div>

                <div v-if="!submitted" class="ticket-form">
                    <div class="form-row">
                        <div class="form-group">
                            <label>Nombre completo</label>
                            <input v-model="form.name" type="text" placeholder="Tu nombre" />
                        </div>
                        <div class="form-group">
                            <label>Correo electrónico</label>
                            <input v-model="form.email" type="email" placeholder="tuemail@ejemplo.com" />
                        </div>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label>Categoría</label>
                            <select v-model="form.category">
                                <option value="" disabled>Selecciona una categoría</option>
                                <option>Facturación y planes</option>
                                <option>Problema técnico</option>
                                <option>Funcionalidad de la IA</option>
                                <option>Gestión de equipo</option>
                                <option>Otro</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Asunto</label>
                            <input v-model="form.subject" type="text" placeholder="Describe brevemente tu problema" />
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Descripción detallada</label>
                        <textarea v-model="form.message" rows="5" placeholder="Incluye todos los detalles que puedan ayudarnos a resolver tu caso más rápido..."></textarea>
                    </div>
                    <button class="submit-btn" @click="submitTicket">
                        Enviar ticket
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="btn-icon">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                        </svg>
                    </button>
                </div>

                <div v-else class="success-box">
                    <div class="success-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                        </svg>
                    </div>
                    <h3>¡Ticket enviado!</h3>
                    <p>Te responderemos en las próximas 24 horas a <strong>{{ form.email }}</strong>.</p>
                    <button class="submit-btn" style="margin-top:16px;" @click="submitted = false; form = { name:'', email:'', category:'', subject:'', message:'' }">Enviar otro ticket</button>
                </div>
            </div>
        </section>

        <!-- Footer -->
        <footer class="landing-footer">
            <div class="footer-brand">
                <span class="footer-logo">Blueprint</span>
                <span class="footer-tagline">Gestión de proyectos con IA para equipos modernos</span>
            </div>
            <div class="footer-links">
                <Link href="/pricing">Precios</Link>
                <Link href="/about">Nosotros</Link>
                <Link href="/support">Soporte</Link>
                <Link href="/login">Iniciar sesión</Link>
            </div>
            <p class="footer-copy">© 2025 Blueprint. Todos los derechos reservados.</p>
        </footer>
    </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }

.support-wrapper {
    font-family: 'Inter', sans-serif;
    background: #ffffff;
    color: #0f0f0f;
    overflow-x: hidden;
}

/* HERO */
.support-hero {
    max-width: 720px;
    margin: 0 auto;
    padding: 72px 24px 48px;
    text-align: center;
}

.section-label {
    font-size: 13px;
    font-weight: 700;
    color: #6366f1;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    margin-bottom: 12px;
}

.support-title {
    font-size: clamp(36px, 6vw, 58px);
    font-weight: 900;
    line-height: 1.1;
    letter-spacing: -0.03em;
    margin-bottom: 18px;
}

.gradient-text {
    background: linear-gradient(135deg, #6366f1, #8b5cf6, #06b6d4);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
}

.support-subtitle {
    font-size: 18px;
    color: #6b7280;
    line-height: 1.6;
}

/* CHANNELS */
.channels-section {
    max-width: 1100px;
    margin: 0 auto;
    padding: 0 24px 64px;
}

.channels-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 20px;
}

.channel-card {
    border: 1.5px solid #e5e7eb;
    border-radius: 20px;
    padding: 32px 28px;
    display: flex;
    flex-direction: column;
    gap: 10px;
    position: relative;
    transition: box-shadow 0.2s, transform 0.2s;
    background: #fff;
}
.channel-card:hover { box-shadow: 0 10px 36px rgba(0,0,0,0.08); transform: translateY(-2px); }

.channel-featured {
    border-color: #a78bfa;
    background: linear-gradient(160deg, #faf5ff, #fff);
}

.featured-badge {
    position: absolute;
    top: -13px;
    left: 28px;
    background: linear-gradient(135deg, #6366f1, #8b5cf6);
    color: #fff;
    font-size: 11px;
    font-weight: 700;
    padding: 3px 12px;
    border-radius: 100px;
}

.channel-icon {
    width: 44px;
    height: 44px;
    color: #6366f1;
}
.channel-featured .channel-icon { color: #7c3aed; }
.channel-icon svg { width: 100%; height: 100%; }

.channel-card h3 {
    font-size: 18px;
    font-weight: 700;
    color: #0f0f0f;
}

.channel-card p {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.6;
}

.channel-link {
    font-size: 14px;
    font-weight: 600;
    color: #6366f1;
    text-decoration: none;
    background: none;
    border: none;
    cursor: pointer;
    padding: 0;
    text-align: left;
    transition: color 0.2s;
}
.channel-link:hover { color: #4f46e5; }

.channel-btn {
    font-family: 'Inter', sans-serif;
}

.channel-badge {
    display: inline-block;
    font-size: 11px;
    font-weight: 600;
    background: #f3f4f6;
    color: #6b7280;
    padding: 3px 10px;
    border-radius: 100px;
    width: fit-content;
    margin-top: 4px;
}
.badge-green { background: #dcfce7; color: #16a34a; }

/* STATUS */
.status-section {
    max-width: 1100px;
    margin: 0 auto;
    padding: 0 24px 64px;
}

.status-banner {
    display: flex;
    align-items: center;
    gap: 12px;
    background: #f0fdf4;
    border: 1.5px solid #bbf7d0;
    border-radius: 14px;
    padding: 16px 24px;
    flex-wrap: wrap;
}

.status-dot {
    width: 10px;
    height: 10px;
    border-radius: 50%;
    background: #22c55e;
    flex-shrink: 0;
    box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.2);
    animation: pulse 2s infinite;
}

@keyframes pulse {
    0%, 100% { box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.2); }
    50%       { box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.1); }
}

.status-text {
    font-size: 14px;
    font-weight: 600;
    color: #15803d;
    flex: 1;
}

.status-link {
    font-size: 13px;
    font-weight: 600;
    color: #6366f1;
    text-decoration: none;
    white-space: nowrap;
}
.status-link:hover { text-decoration: underline; }

/* FAQ */
.faq-section {
    max-width: 800px;
    margin: 0 auto;
    padding: 0 24px 80px;
    text-align: center;
}

.faq-title {
    font-size: clamp(26px, 4vw, 38px);
    font-weight: 800;
    letter-spacing: -0.02em;
    margin-bottom: 12px;
}

.faq-subtitle {
    font-size: 16px;
    color: #6b7280;
    margin-bottom: 40px;
}

.faq-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
    text-align: left;
}

.faq-item {
    border: 1.5px solid #e5e7eb;
    border-radius: 14px;
    padding: 20px 24px;
    cursor: pointer;
    transition: border-color 0.2s, box-shadow 0.2s;
    user-select: none;
}

.faq-item:hover { border-color: #a78bfa; }
.faq-open { border-color: #a78bfa; box-shadow: 0 4px 16px rgba(139,92,246,0.08); }

.faq-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 16px;
}

.faq-question {
    font-size: 15px;
    font-weight: 600;
    color: #111;
}

.faq-chevron {
    width: 18px;
    height: 18px;
    color: #9ca3af;
    flex-shrink: 0;
    transition: transform 0.2s;
}
.faq-open .faq-chevron { transform: rotate(180deg); color: #6366f1; }

.faq-answer {
    margin-top: 14px;
    font-size: 14px;
    color: #6b7280;
    line-height: 1.7;
    border-top: 1px solid #f3f4f6;
    padding-top: 14px;
}

/* TICKET FORM */
.ticket-section {
    padding: 0 24px 80px;
}

.ticket-box {
    max-width: 820px;
    margin: 0 auto;
    background: linear-gradient(160deg, #0f0f0f, #1e1b4b);
    border-radius: 24px;
    padding: 56px 48px;
    color: #fff;
}

@media (max-width: 600px) {
    .ticket-box { padding: 36px 24px; }
}

.ticket-header { margin-bottom: 36px; }
.ticket-title {
    font-size: clamp(24px, 4vw, 34px);
    font-weight: 800;
    margin-bottom: 10px;
}
.ticket-subtitle {
    font-size: 15px;
    color: #a5b4fc;
    line-height: 1.6;
}

.ticket-form { display: flex; flex-direction: column; gap: 20px; }

.form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
}
@media (max-width: 600px) {
    .form-row { grid-template-columns: 1fr; }
}

.form-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.form-group label {
    font-size: 13px;
    font-weight: 600;
    color: #c4b5fd;
}

.form-group input,
.form-group select,
.form-group textarea {
    background: rgba(255,255,255,0.07);
    border: 1.5px solid rgba(255,255,255,0.12);
    border-radius: 10px;
    padding: 12px 14px;
    font-size: 14px;
    color: #fff;
    outline: none;
    font-family: 'Inter', sans-serif;
    resize: vertical;
    transition: border-color 0.2s;
}
.form-group input::placeholder,
.form-group textarea::placeholder { color: #6b7280; }
.form-group input:focus,
.form-group select:focus,
.form-group textarea:focus { border-color: #a78bfa; }
.form-group select option { background: #1e1b4b; color: #fff; }

.submit-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    background: #fff;
    color: #0f0f0f;
    padding: 14px 32px;
    border-radius: 10px;
    font-weight: 700;
    font-size: 15px;
    border: none;
    cursor: pointer;
    transition: background 0.2s, transform 0.15s;
    font-family: 'Inter', sans-serif;
    width: fit-content;
}
.submit-btn:hover { background: #e0e7ff; transform: translateY(-1px); }
.btn-icon { width: 16px; height: 16px; }

/* SUCCESS */
.success-box {
    text-align: center;
    padding: 40px 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
}

.success-icon {
    width: 64px;
    height: 64px;
    background: rgba(34,197,94,0.15);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 8px;
}
.success-icon svg {
    width: 32px;
    height: 32px;
    color: #22c55e;
}
.success-box h3 { font-size: 24px; font-weight: 800; }
.success-box p  { font-size: 15px; color: #a5b4fc; }

/* FOOTER */
.landing-footer {
    border-top: 1.5px solid #e5e7eb;
    padding: 40px 24px;
    text-align: center;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 20px;
}

.footer-brand { display: flex; flex-direction: column; gap: 4px; }
.footer-logo { font-size: 18px; font-weight: 800; color: #0f0f0f; }
.footer-tagline { font-size: 13px; color: #9ca3af; }

.footer-links {
    display: flex;
    gap: 24px;
    flex-wrap: wrap;
    justify-content: center;
}

.footer-links a {
    font-size: 14px;
    color: #6b7280;
    text-decoration: none;
    transition: color 0.2s;
}
.footer-links a:hover { color: #0f0f0f; }
.footer-copy { font-size: 12px; color: #9ca3af; }
</style>
