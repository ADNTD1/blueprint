<script setup>
import { Head, Link } from '@inertiajs/vue3'
import Navbar from '@/Components/Navbar.vue'

function scrollToFeatures(e) {
    e.preventDefault()
    document.getElementById('features')?.scrollIntoView({ behavior: 'smooth' })
}
</script>

<template>
    <Head title="Blueprint — Gestión de Proyectos con IA" />

    <div class="landing-wrapper">
        <Navbar />   
     <section class="hero-section">
            <div class="hero-badge">✦ Potenciado por Inteligencia Artificial</div>
            <h1 class="hero-title">
                Enfócate en crear.<br />
                <span class="gradient-text">La IA planifica por ti.</span>
            </h1>
            <p class="hero-subtitle">
                Genera tareas con IA, organiza tu equipo en tableros Kanban en tiempo real<br />
                y entrega proyectos más rápido — sin cuellos de botella.
            </p>
            <div class="hero-actions">
                <Link href="/register" class="btn-primary">
                    Comenzar gratis
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="btn-icon">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                    </svg>
                </Link>
                <a href="#features" class="btn-secondary" @click="scrollToFeatures">Ver características</a>
            </div>
            <p class="hero-note">Sin tarjeta de crédito · Configuración en 2 minutos</p>

            <!-- Kanban Preview -->
            <div class="kanban-preview">
                <div class="kanban-preview-header">
                    <span class="dot red"></span><span class="dot yellow"></span><span class="dot green"></span>
                    <span class="preview-title">Blueprint — Sprint Actual</span>
                </div>
                <div class="kanban-preview-body">
                    <div class="kanban-col">
                        <div class="col-label pending">Por hacer</div>
                        <div class="kanban-card">
                            <span class="ai-badge">✦ IA</span>
                            <p>Diseñar modelo de datos para módulo de usuarios</p>
                            <div class="card-meta"><span>Alta prioridad</span><span>@luis</span></div>
                        </div>
                        <div class="kanban-card">
                            <span class="ai-badge">✦ IA</span>
                            <p>Crear endpoints REST para autenticación</p>
                            <div class="card-meta"><span>Media prioridad</span><span>@ana</span></div>
                        </div>
                    </div>
                    <div class="kanban-col">
                        <div class="col-label progress">En progreso</div>
                        <div class="kanban-card active">
                            <span class="ai-badge">✦ IA</span>
                            <p>Implementar tablero Kanban con drag & drop</p>
                            <div class="card-meta"><span>Alta prioridad</span><span>@carlos</span></div>
                        </div>
                    </div>
                    <div class="kanban-col">
                        <div class="col-label done">Completado</div>
                        <div class="kanban-card done-card">
                            <p>Configurar entorno de desarrollo</p>
                            <div class="card-meta"><span>✓ Listo</span><span>@equipo</span></div>
                        </div>
                        <div class="kanban-card done-card">
                            <p>Definir arquitectura del proyecto</p>
                            <div class="card-meta"><span>✓ Listo</span><span>@luis</span></div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <!-- Features Section -->
        <section id="features" class="features-section">
            <div class="section-label">Características</div>
            <h2 class="section-title">Todo lo que tu equipo necesita</h2>
            <p class="section-subtitle">Desde la idea hasta la entrega, Blueprint gestiona cada paso con la potencia de la IA.</p>

            <div class="features-grid">
                <div class="feature-card featured">
                    <div class="feature-icon">
                        <!-- Sparkles / IA -->
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456Z" />
                        </svg>
                    </div>
                    <h3>Generación de Tareas con IA</h3>
                    <p>Describe tu proyecto y la IA desglosará automáticamente el trabajo en tareas concretas, estimaciones y asignaciones para cada miembro del equipo.</p>
                    <div class="feature-tag">Núcleo de Blueprint</div>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">
                        <!-- View Columns / Kanban -->
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 4.5v15m6-15v15m-10.875 0h15.75c.621 0 1.125-.504 1.125-1.125V5.625c0-.621-.504-1.125-1.125-1.125H4.125C3.504 4.5 3 5.004 3 5.625v12.75c0 .621.504 1.125 1.125 1.125Z" />
                        </svg>
                    </div>
                    <h3>Kanban en Tiempo Real</h3>
                    <p>Tableros visuales que se actualizan al instante para todos los miembros. Arrastra tareas entre columnas y el equipo lo ve de inmediato.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">
                        <!-- Users -->
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z" />
                        </svg>
                    </div>
                    <h3>Colaboración en Equipo</h3>
                    <p>Invita a tu equipo, asigna tareas, deja comentarios y menciona a compañeros. Todo en un solo lugar sin cambiar de app.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">
                        <!-- Lock / Roles -->
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 1 0-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 0 0 2.25-2.25v-6.75a2.25 2.25 0 0 0-2.25-2.25H6.75a2.25 2.25 0 0 0-2.25 2.25v6.75a2.25 2.25 0 0 0 2.25 2.25Z" />
                        </svg>
                    </div>
                    <h3>Roles y Permisos</h3>
                    <p>Define roles como Administrador, Desarrollador o Observador. Cada miembro accede solo a lo que le corresponde.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">
                        <!-- Light Bulb / Priorización -->
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 18v-5.25m0 0a6.01 6.01 0 0 0 1.5-.189m-1.5.189a6.01 6.01 0 0 1-1.5-.189m3.75 7.478a12.06 12.06 0 0 1-4.5 0m3.75 2.355a7.5 7.5 0 0 1-3 0M12 3a6 6 0 0 1 6 6c0 2.04-.807 3.891-2.12 5.273A4.5 4.5 0 0 1 12 15.75a4.5 4.5 0 0 1-3.88-1.477A6 6 0 0 1 6 9a6 6 0 0 1 6-6Z" />
                        </svg>
                    </div>
                    <h3>Priorización Inteligente</h3>
                    <p>La IA analiza tu backlog y sugiere qué tareas atacar primero según dependencias, impacto y capacidad del equipo.</p>
                </div>

                <div class="feature-card">
                    <div class="feature-icon">
                        <!-- Chart Bar / Métricas -->
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z" />
                        </svg>
                    </div>
                    <h3>Métricas del Sprint</h3>
                    <p>Dashboards visuales con velocidad del equipo, tareas completadas, bloqueos activos y progreso del sprint en tiempo real.</p>
                </div>
            </div>
        </section>

        <!-- How it Works Section -->
        <section class="how-section">
            <div class="section-label">¿Cómo funciona?</div>
            <h2 class="section-title">En 3 pasos tu equipo ya trabaja</h2>
            <div class="steps-grid">
                <div class="step-card">
                    <div class="step-number">01</div>
                    <h3>Crea tu proyecto</h3>
                    <p>Describe tu idea o proyecto con tus propias palabras. Sin formularios complicados.</p>
                </div>
                <div class="step-connector">→</div>
                <div class="step-card">
                    <div class="step-number">02</div>
                    <h3>La IA genera las tareas</h3>
                    <p>Blueprint analiza tu descripción y crea automáticamente un backlog con tareas detalladas y listas para asignar.</p>
                </div>
                <div class="step-connector">→</div>
                <div class="step-card">
                    <div class="step-number">03</div>
                    <h3>Tu equipo ejecuta</h3>
                    <p>Asigna tareas a cada desarrollador y sigue el progreso en el Kanban en tiempo real.</p>
                </div>
            </div>
        </section>

        <!-- CTA Section -->
        <section class="cta-section">
            <div class="cta-box">
                <h2>¿Listo para trabajar más inteligente?</h2>
                <p>Únete a los equipos que ya entregan proyectos más rápido con la ayuda de la IA.</p>
                <Link href="/register" class="btn-primary btn-large">
                    Empezar gratis ahora
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

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

.landing-wrapper {
    font-family: 'Inter', sans-serif;
    background: #ffffff;
    color: #0f0f0f;
    overflow-x: hidden;
}

/* ---- HERO ---- */
.hero-section {
    max-width: 960px;
    margin: 0 auto;
    padding: 80px 24px 60px;
    text-align: center;
}

.hero-badge {
    display: inline-block;
    background: #f0f0f0;
    color: #444;
    font-size: 13px;
    font-weight: 600;
    padding: 6px 16px;
    border-radius: 100px;
    margin-bottom: 28px;
    letter-spacing: 0.02em;
}

.hero-title {
    font-size: clamp(42px, 7vw, 72px);
    font-weight: 900;
    line-height: 1.1;
    letter-spacing: -0.03em;
    margin-bottom: 24px;
    color: #0f0f0f;
}

.gradient-text {
    background: linear-gradient(135deg, #6366f1, #8b5cf6, #06b6d4);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
}

.hero-subtitle {
    font-size: 18px;
    color: #555;
    line-height: 1.7;
    margin-bottom: 36px;
}

.hero-actions {
    display: flex;
    gap: 12px;
    justify-content: center;
    flex-wrap: wrap;
    margin-bottom: 16px;
}

.btn-primary {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    background: #0f0f0f;
    color: #fff;
    padding: 14px 28px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 15px;
    text-decoration: none;
    transition: background 0.2s, transform 0.15s;
}
.btn-primary:hover { background: #222; transform: translateY(-1px); }

.btn-secondary {
    display: inline-flex;
    align-items: center;
    background: #fff;
    color: #0f0f0f;
    padding: 14px 28px;
    border-radius: 10px;
    font-weight: 600;
    font-size: 15px;
    text-decoration: none;
    border: 1.5px solid #d1d5db;
    transition: border-color 0.2s, transform 0.15s;
}
.btn-secondary:hover { border-color: #9ca3af; transform: translateY(-1px); }

.btn-icon { width: 16px; height: 16px; }

.btn-large { padding: 16px 36px; font-size: 16px; }

.hero-note { font-size: 13px; color: #888; margin-top: 4px; }

/* Kanban Preview */
.kanban-preview {
    margin-top: 56px;
    border: 1.5px solid #e5e7eb;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,0.08);
    text-align: left;
}

.kanban-preview-header {
    background: #f9fafb;
    border-bottom: 1.5px solid #e5e7eb;
    padding: 12px 20px;
    display: flex;
    align-items: center;
    gap: 8px;
}
.dot { width: 12px; height: 12px; border-radius: 50%; display: inline-block; }
.dot.red { background: #ef4444; }
.dot.yellow { background: #f59e0b; }
.dot.green { background: #22c55e; }
.preview-title { font-size: 13px; color: #6b7280; margin-left: 8px; font-weight: 500; }

.kanban-preview-body {
    display: flex;
    gap: 0;
    padding: 20px;
    gap: 16px;
    background: #fafafa;
    overflow-x: auto;
}

.kanban-col { flex: 1; min-width: 200px; display: flex; flex-direction: column; gap: 10px; }

.col-label {
    font-size: 12px;
    font-weight: 700;
    padding: 4px 10px;
    border-radius: 6px;
    width: fit-content;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}
.col-label.pending  { background: #f3f4f6; color: #6b7280; }
.col-label.progress { background: #ede9fe; color: #7c3aed; }
.col-label.done     { background: #dcfce7; color: #16a34a; }

.kanban-card {
    background: #fff;
    border: 1.5px solid #e5e7eb;
    border-radius: 10px;
    padding: 12px 14px;
    font-size: 13px;
    color: #374151;
    line-height: 1.5;
    display: flex;
    flex-direction: column;
    gap: 8px;
    transition: box-shadow 0.2s;
}
.kanban-card.active { border-color: #a78bfa; box-shadow: 0 0 0 3px rgba(139,92,246,0.1); }
.kanban-card.done-card { opacity: 0.65; }

.ai-badge {
    font-size: 10px;
    font-weight: 700;
    color: #7c3aed;
    background: #ede9fe;
    padding: 2px 7px;
    border-radius: 4px;
    width: fit-content;
}

.card-meta {
    display: flex;
    justify-content: space-between;
    font-size: 11px;
    color: #9ca3af;
}

/* ---- FEATURES ---- */
.features-section {
    max-width: 1100px;
    margin: 0 auto;
    padding: 80px 24px;
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

.section-title {
    font-size: clamp(28px, 4vw, 44px);
    font-weight: 800;
    letter-spacing: -0.02em;
    margin-bottom: 16px;
}

.section-subtitle {
    font-size: 17px;
    color: #6b7280;
    margin-bottom: 48px;
}

.features-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    text-align: left;
}

.feature-card {
    border: 1.5px solid #e5e7eb;
    border-radius: 16px;
    padding: 28px;
    transition: box-shadow 0.2s, transform 0.2s;
    background: #fff;
}
.feature-card:hover { box-shadow: 0 8px 30px rgba(0,0,0,0.08); transform: translateY(-2px); }
.feature-card.featured {
    border-color: #a78bfa;
    background: linear-gradient(135deg, #faf5ff, #ede9fe);
    grid-column: span 2;
}

@media (max-width: 700px) {
    .feature-card.featured { grid-column: span 1; }
}

.feature-icon {
    width: 44px;
    height: 44px;
    margin-bottom: 16px;
    color: #6366f1;
}
.feature-icon svg {
    width: 100%;
    height: 100%;
}
.feature-card.featured .feature-icon {
    color: #7c3aed;
}

.feature-card h3 {
    font-size: 18px;
    font-weight: 700;
    margin-bottom: 10px;
    color: #111;
}

.feature-card p {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.7;
}

.feature-tag {
    margin-top: 16px;
    font-size: 11px;
    font-weight: 700;
    color: #7c3aed;
    background: #ede9fe;
    padding: 4px 10px;
    border-radius: 6px;
    width: fit-content;
}

/* ---- HOW IT WORKS ---- */
.how-section {
    background: #f9fafb;
    padding: 80px 24px;
    text-align: center;
}

.steps-grid {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 16px;
    margin-top: 48px;
    flex-wrap: wrap;
}

.step-card {
    background: #fff;
    border: 1.5px solid #e5e7eb;
    border-radius: 16px;
    padding: 32px 28px;
    max-width: 260px;
    text-align: left;
    flex: 1;
    min-width: 220px;
}

.step-number {
    font-size: 36px;
    font-weight: 900;
    color: #e5e7eb;
    margin-bottom: 14px;
    letter-spacing: -0.03em;
}

.step-card h3 { font-size: 17px; font-weight: 700; margin-bottom: 10px; }

.step-card p { font-size: 14px; color: #6b7280; line-height: 1.6; }

.step-connector { font-size: 24px; color: #d1d5db; }

/* ---- CTA ---- */
.cta-section {
    padding: 80px 24px;
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

.cta-box h2 { font-size: clamp(24px, 4vw, 36px); font-weight: 800; margin-bottom: 14px; }
.cta-box p  { font-size: 16px; color: #a5b4fc; margin-bottom: 32px; }

.cta-box .btn-primary {
    background: #fff;
    color: #0f0f0f;
    font-size: 15px;
}
.cta-box .btn-primary:hover { background: #f1f5f9; }

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