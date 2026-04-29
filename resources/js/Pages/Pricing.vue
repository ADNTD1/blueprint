<script setup>
import { Head, Link } from '@inertiajs/vue3'
import Navbar from '@/Components/Navbar.vue'
import { ref } from 'vue'

const billing = ref('monthly') // 'monthly' | 'yearly'

const plans = [
    {
        name: 'Gratis',
        price: { monthly: 0, yearly: 0 },
        description: 'Para equipos pequeños que quieren empezar a organizarse.',
        cta: 'Empezar gratis',
        ctaHref: '/register',
        highlighted: false,
        badge: null,
        features: [
            { text: '1 proyecto activo', included: true },
            { text: 'Hasta 3 miembros por equipo', included: true },
            { text: 'Tablero Kanban básico', included: true },
            { text: 'Generación de tareas con IA (10/mes)', included: true },
            { text: 'Historial de actividad (7 días)', included: true },
            { text: 'Soporte por correo', included: true },
            { text: 'Proyectos ilimitados', included: false },
            { text: 'Integraciones externas', included: false },
            { text: 'Métricas avanzadas de sprint', included: false },
            { text: 'Roles personalizados', included: false },
        ],
    },
    {
        name: 'Pro',
        price: { monthly: 12, yearly: 9 },
        description: 'Para equipos en crecimiento que necesitan más potencia de IA.',
        cta: 'Comenzar con Pro',
        ctaHref: '/register',
        highlighted: true,
        badge: 'Más popular',
        features: [
            { text: 'Proyectos ilimitados', included: true },
            { text: 'Hasta 15 miembros por equipo', included: true },
            { text: 'Tablero Kanban con arrastrar y soltar', included: true },
            { text: 'Generación de tareas con IA ilimitada', included: true },
            { text: 'Historial de actividad (90 días)', included: true },
            { text: 'Priorización inteligente con IA', included: true },
            { text: 'Métricas del sprint en tiempo real', included: true },
            { text: 'Roles y permisos personalizados', included: true },
            { text: 'Soporte prioritario', included: true },
            { text: 'Integraciones externas', included: false },
        ],
    },
    {
        name: 'Empresa',
        price: { monthly: 39, yearly: 29 },
        description: 'Para organizaciones que necesitan control total y escalabilidad.',
        cta: 'Contactar ventas',
        ctaHref: '/support',
        highlighted: false,
        badge: null,
        features: [
            { text: 'Todo lo de Pro, más:', included: true },
            { text: 'Miembros ilimitados', included: true },
            { text: 'IA con contexto del proyecto completo', included: true },
            { text: 'Integraciones (Slack, GitHub, Jira)', included: true },
            { text: 'Dashboard ejecutivo con KPIs', included: true },
            { text: 'Auditoría y logs de acceso', included: true },
            { text: 'SSO / SAML', included: true },
            { text: 'SLA garantizado 99.9%', included: true },
            { text: 'Gerente de cuenta dedicado', included: true },
            { text: 'Onboarding personalizado', included: true },
        ],
    },
]
</script>

<template>
    <Head title="Precios — Blueprint" />

    <div class="pricing-wrapper">
        <Navbar />

        <!-- Header -->
        <section class="pricing-header">
            <div class="section-label">Precios</div>
            <h1 class="pricing-title">Simple, transparente,<br /><span class="gradient-text">sin sorpresas</span></h1>
            <p class="pricing-subtitle">Empieza gratis y escala cuando tu equipo lo necesite.</p>

            <!-- Toggle -->
            <div class="billing-toggle">
                <button
                    :class="['toggle-btn', billing === 'monthly' ? 'active' : '']"
                    @click="billing = 'monthly'"
                >Mensual</button>
                <button
                    :class="['toggle-btn', billing === 'yearly' ? 'active' : '']"
                    @click="billing = 'yearly'"
                >Anual <span class="save-badge">Ahorra 25%</span></button>
            </div>
        </section>

        <!-- Plans Grid -->
        <section class="plans-section">
            <div class="plans-grid">
                <div
                    v-for="plan in plans"
                    :key="plan.name"
                    :class="['plan-card', plan.highlighted ? 'plan-highlighted' : '']"
                >
                    <div v-if="plan.badge" class="plan-badge">{{ plan.badge }}</div>

                    <div class="plan-header">
                        <h2 class="plan-name">{{ plan.name }}</h2>
                        <div class="plan-price">
                            <span class="price-currency">$</span>
                            <span class="price-amount">{{ plan.price[billing] }}</span>
                            <span class="price-period" v-if="plan.price[billing] > 0">/mes</span>
                            <span class="price-period" v-else>para siempre</span>
                        </div>
                        <p class="plan-desc">{{ plan.description }}</p>
                    </div>

                    <Link :href="plan.ctaHref" :class="['plan-cta', plan.highlighted ? 'plan-cta-primary' : 'plan-cta-secondary']">
                        {{ plan.cta }}
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="cta-icon">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                        </svg>
                    </Link>

                    <ul class="features-list">
                        <li
                            v-for="feature in plan.features"
                            :key="feature.text"
                            :class="['feature-item', !feature.included ? 'feature-excluded' : '']"
                        >
                            <!-- Check icon -->
                            <svg v-if="feature.included" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="feat-icon feat-check">
                                <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                            </svg>
                            <!-- X icon -->
                            <svg v-else xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="feat-icon feat-x">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
                            </svg>
                            {{ feature.text }}
                        </li>
                    </ul>
                </div>
            </div>
        </section>

        <!-- FAQ / reassurance -->
        <section class="faq-section">
            <h2 class="faq-title">Preguntas frecuentes</h2>
            <div class="faq-grid">
                <div class="faq-item">
                    <h3>¿Necesito tarjeta de crédito para el plan Gratis?</h3>
                    <p>No. El plan Gratis es 100% gratuito para siempre, sin datos de pago requeridos.</p>
                </div>
                <div class="faq-item">
                    <h3>¿Puedo cambiar de plan en cualquier momento?</h3>
                    <p>Sí. Puedes actualizar o degradar tu plan cuando quieras desde la configuración de tu cuenta.</p>
                </div>
                <div class="faq-item">
                    <h3>¿Qué pasa si cancelo mi suscripción?</h3>
                    <p>Tus datos se conservan durante 30 días. Después puedes exportarlos o reactivar tu plan.</p>
                </div>
                <div class="faq-item">
                    <h3>¿Ofrecen descuentos para estudiantes o startups?</h3>
                    <p>Sí, contáctanos por soporte y evaluamos descuentos especiales para educación y startups en etapa temprana.</p>
                </div>
            </div>
        </section>

        <!-- CTA -->
        <section class="cta-section">
            <div class="cta-box">
                <h2>¿Todavía tienes dudas?</h2>
                <p>Empieza gratis hoy — no necesitas tarjeta de crédito.</p>
                <Link href="/register" class="btn-primary btn-large">
                    Crear cuenta gratis
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="btn-icon">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                    </svg>
                </Link>
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

.pricing-wrapper {
    font-family: 'Inter', sans-serif;
    background: #ffffff;
    color: #0f0f0f;
    overflow-x: hidden;
}

/* ---- HEADER ---- */
.pricing-header {
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

.pricing-title {
    font-size: clamp(36px, 6vw, 60px);
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

.pricing-subtitle {
    font-size: 18px;
    color: #6b7280;
    margin-bottom: 36px;
}

/* Toggle */
.billing-toggle {
    display: inline-flex;
    background: #f3f4f6;
    border-radius: 10px;
    padding: 4px;
    gap: 4px;
}

.toggle-btn {
    padding: 8px 20px;
    border-radius: 7px;
    border: none;
    background: transparent;
    font-size: 14px;
    font-weight: 600;
    color: #6b7280;
    cursor: pointer;
    transition: background 0.2s, color 0.2s;
    display: flex;
    align-items: center;
    gap: 8px;
}
.toggle-btn.active {
    background: #fff;
    color: #0f0f0f;
    box-shadow: 0 1px 4px rgba(0,0,0,0.1);
}

.save-badge {
    font-size: 11px;
    font-weight: 700;
    background: #dcfce7;
    color: #16a34a;
    padding: 2px 7px;
    border-radius: 100px;
}

/* ---- PLANS ---- */
.plans-section {
    max-width: 1100px;
    margin: 0 auto;
    padding: 0 24px 80px;
}

.plans-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    align-items: start;
}

.plan-card {
    border: 1.5px solid #e5e7eb;
    border-radius: 20px;
    padding: 32px 28px;
    background: #fff;
    position: relative;
    transition: box-shadow 0.2s, transform 0.2s;
}
.plan-card:hover {
    box-shadow: 0 12px 40px rgba(0,0,0,0.08);
    transform: translateY(-2px);
}

.plan-highlighted {
    border-color: #a78bfa;
    background: linear-gradient(160deg, #faf5ff 0%, #fff 60%);
    box-shadow: 0 8px 30px rgba(139, 92, 246, 0.12);
}

.plan-badge {
    position: absolute;
    top: -13px;
    left: 50%;
    transform: translateX(-50%);
    background: linear-gradient(135deg, #6366f1, #8b5cf6);
    color: #fff;
    font-size: 12px;
    font-weight: 700;
    padding: 4px 16px;
    border-radius: 100px;
    white-space: nowrap;
}

.plan-header { margin-bottom: 24px; }

.plan-name {
    font-size: 20px;
    font-weight: 800;
    margin-bottom: 12px;
    color: #0f0f0f;
}

.plan-price {
    display: flex;
    align-items: baseline;
    gap: 4px;
    margin-bottom: 12px;
}

.price-currency {
    font-size: 22px;
    font-weight: 700;
    color: #6b7280;
    align-self: flex-start;
    margin-top: 6px;
}

.price-amount {
    font-size: 56px;
    font-weight: 900;
    letter-spacing: -0.03em;
    line-height: 1;
    color: #0f0f0f;
}

.price-period {
    font-size: 14px;
    color: #9ca3af;
    font-weight: 500;
}

.plan-desc {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.6;
}

/* CTA buttons */
.plan-cta {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    width: 100%;
    padding: 13px 20px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 15px;
    text-decoration: none;
    margin-bottom: 28px;
    transition: transform 0.15s, background 0.2s;
}
.plan-cta:hover { transform: translateY(-1px); }

.plan-cta-primary {
    background: #0f0f0f;
    color: #fff;
}
.plan-cta-primary:hover { background: #1e1b4b; }

.plan-cta-secondary {
    background: #f3f4f6;
    color: #0f0f0f;
    border: 1.5px solid #e5e7eb;
}
.plan-cta-secondary:hover { background: #e5e7eb; }

.cta-icon { width: 16px; height: 16px; }

/* Features list */
.features-list {
    list-style: none;
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.feature-item {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 14px;
    color: #374151;
}

.feature-excluded {
    color: #d1d5db;
}

.feat-icon {
    width: 17px;
    height: 17px;
    flex-shrink: 0;
}

.feat-check { color: #22c55e; }
.feat-x     { color: #d1d5db; }

/* ---- FAQ ---- */
.faq-section {
    max-width: 900px;
    margin: 0 auto;
    padding: 0 24px 80px;
}

.faq-title {
    font-size: 28px;
    font-weight: 800;
    text-align: center;
    margin-bottom: 40px;
    letter-spacing: -0.02em;
}

.faq-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(380px, 1fr));
    gap: 20px;
}

.faq-item {
    border: 1.5px solid #e5e7eb;
    border-radius: 14px;
    padding: 24px;
}

.faq-item h3 {
    font-size: 15px;
    font-weight: 700;
    margin-bottom: 8px;
    color: #111;
}

.faq-item p {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.7;
}

/* ---- CTA ---- */
.cta-section {
    padding: 0 24px 80px;
    text-align: center;
}

.cta-box {
    background: linear-gradient(135deg, #0f0f0f, #1e1b4b);
    border-radius: 24px;
    padding: 64px 40px;
    max-width: 700px;
    margin: 0 auto;
    color: #fff;
}

.cta-box h2 { font-size: clamp(22px, 4vw, 34px); font-weight: 800; margin-bottom: 12px; }
.cta-box p  { font-size: 16px; color: #a5b4fc; margin-bottom: 32px; }

.btn-primary {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    background: #fff;
    color: #0f0f0f;
    padding: 14px 28px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 15px;
    text-decoration: none;
    transition: background 0.2s, transform 0.15s;
}
.btn-primary:hover { background: #f1f5f9; transform: translateY(-1px); }
.btn-large { padding: 16px 36px; font-size: 16px; }
.btn-icon { width: 16px; height: 16px; }

/* ---- FOOTER ---- */
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
