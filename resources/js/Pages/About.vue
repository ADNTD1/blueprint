<script setup>
import { Head, Link } from '@inertiajs/vue3'
import Navbar from '@/Components/Navbar.vue'

const values = [
    {
        title: 'Claridad antes que ruido',
        description: 'Disenamos Blueprint para que cada equipo vea que sigue, quien esta bloqueado y que merece atencion ahora mismo.',
    },
    {
        title: 'IA con criterio de equipo',
        description: 'La IA no reemplaza decisiones humanas. Ayuda a priorizar, ordenar y acelerar el trabajo sin quitar contexto.',
    },
    {
        title: 'Colaboracion sin friccion',
        description: 'Queremos menos mensajes perdidos, menos hojas sueltas y mas trabajo alineado dentro del mismo flujo.',
    },
]

const milestones = [
    {
        year: '2023',
        title: 'La idea inicial',
        description: 'Nacimos como un experimento interno para convertir briefs desordenados en planes accionables para equipos pequenos.',
    },
    {
        year: '2024',
        title: 'Primeros equipos piloto',
        description: 'Equipos de producto, desarrollo y agencias comenzaron a usar Blueprint para planear sprints y repartir trabajo con IA.',
    },
    {
        year: '2025',
        title: 'Blueprint se vuelve plataforma',
        description: 'Consolidamos tableros, permisos, backlog inteligente y colaboracion en tiempo real en una experiencia unificada.',
    },
]

const team = [
    {
        name: 'Hansel Flores (Tesila)',
        role: 'Product Strategy',
        bio: 'Aporta vision de producto y ayuda a convertir ideas ambiciosas en flujos de trabajo claros y aterrizados.',
    },
    {
        name: 'Raul Roberto',
        role: 'Operations Lead',
        bio: 'Se enfoca en que cada proceso dentro de Blueprint se sienta ordenado, eficiente y facil de ejecutar en equipo.',
    },
    {
        name: 'Johan Quinones',
        role: 'Engineering',
        bio: 'Trabaja en la base tecnica del producto para que la experiencia sea rapida, estable y lista para escalar.',
    },
    {
        name: 'Adrian Montes',
        role: 'Customer Experience',
        bio: 'Cuida que la plataforma conecte con las necesidades reales de los usuarios y que cada detalle se sienta intuitivo.',
    },
]
</script>

<template>
    <Head title="Nosotros - Blueprint" />

    <div class="about-wrapper">
        <Navbar />

        <section class="about-hero">
            <div class="section-label">About Us</div>
            <h1 class="about-title">
                Construimos herramientas para que los equipos
                <span class="gradient-text">trabajen con mas enfoque</span>
            </h1>
            <p class="about-subtitle">
                Blueprint nacio con una idea simple: convertir el caos de planear proyectos en un sistema claro,
                colaborativo y potenciado por IA. Inventamos menos burocracia para que tu equipo pueda crear mas.
            </p>

            <div class="hero-stats">
                <div class="stat-card">
                    <strong>12k+</strong>
                    <span>tareas generadas con IA cada semana</span>
                </div>
                <div class="stat-card featured">
                    <strong>320+</strong>
                    <span>equipos coordinando su trabajo en Blueprint</span>
                </div>
                <div class="stat-card">
                    <strong>37%</strong>
                    <span>menos tiempo en planeacion manual</span>
                </div>
            </div>
        </section>

        <section class="story-section">
            <div class="story-grid">
                <div class="story-card story-featured">
                    <div class="mini-label">Nuestra mision</div>
                    <h2>Ayudar a los equipos a pasar de idea a ejecucion sin perder contexto.</h2>
                    <p>
                        Vimos demasiados proyectos frenarse por briefs dispersos, prioridades ambiguas y tareas mal definidas.
                        Por eso mezclamos IA, tableros visuales y colaboracion en tiempo real en una sola plataforma.
                    </p>
                </div>

                <div class="story-card">
                    <div class="mini-label">Lo que creemos</div>
                    <p>
                        Un buen sistema de trabajo debe ser facil de entender, flexible para crecer y lo bastante inteligente
                        para ayudarte antes de que aparezcan los cuellos de botella.
                    </p>
                </div>
            </div>
        </section>

        <section class="values-section">
            <div class="section-label">Nuestros valores</div>
            <h2 class="section-title">Principios que guian cada decision</h2>
            <p class="section-subtitle">
                Desde producto hasta soporte, buscamos construir una experiencia util, rapida y honesta.
            </p>

            <div class="values-grid">
                <div v-for="value in values" :key="value.title" class="value-card">
                    <div class="value-icon">
                        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                        </svg>
                    </div>
                    <h3>{{ value.title }}</h3>
                    <p>{{ value.description }}</p>
                </div>
            </div>
        </section>

        <section class="timeline-section">
            <div class="section-label">Camino</div>
            <h2 class="section-title">Como hemos crecido</h2>
            <div class="timeline-list">
                <div v-for="item in milestones" :key="item.year" class="timeline-item">
                    <div class="timeline-year">{{ item.year }}</div>
                    <div class="timeline-content">
                        <h3>{{ item.title }}</h3>
                        <p>{{ item.description }}</p>
                    </div>
                </div>
            </div>
        </section>

        <section class="team-section">
            <div class="section-label">Equipo</div>
            <h2 class="section-title">Las personas detras de Blueprint</h2>
            <p class="section-subtitle">
                Somos un equipo pequeno que mezcla producto, ingenieria y cercania con el cliente para construir algo realmente util.
            </p>

            <div class="team-grid">
                <div v-for="member in team" :key="member.name" class="team-card">
                    <div class="avatar">{{ member.name.charAt(0) }}</div>
                    <h3>{{ member.name }}</h3>
                    <div class="role">{{ member.role }}</div>
                    <p>{{ member.bio }}</p>
                </div>
            </div>
        </section>

        <section class="cta-section">
            <div class="cta-box">
                <h2>Queremos que planear deje de sentirse pesado</h2>
                <p>Prueba Blueprint y mira como tu equipo puede organizar mejor su trabajo desde el primer proyecto.</p>
                <Link href="/register" class="btn-primary btn-large">
                    Empezar gratis
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="btn-icon">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" />
                    </svg>
                </Link>
            </div>
        </section>

        <footer class="landing-footer">
            <div class="footer-brand">
                <span class="footer-logo">Blueprint</span>
                <span class="footer-tagline">Gestion de proyectos con IA para equipos modernos</span>
            </div>
            <div class="footer-links">
                <Link href="/pricing">Precios</Link>
                <Link href="/about">Nosotros</Link>
                <Link href="/support">Soporte</Link>
                <Link href="/login">Iniciar sesion</Link>
            </div>
            <p class="footer-copy">(c) 2025 Blueprint. Todos los derechos reservados.</p>
        </footer>
    </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }

.about-wrapper {
    font-family: 'Inter', sans-serif;
    background: #ffffff;
    color: #0f0f0f;
    overflow-x: hidden;
}

.about-hero {
    max-width: 900px;
    margin: 0 auto;
    padding: 72px 24px 56px;
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

.about-title {
    font-size: clamp(38px, 6vw, 64px);
    font-weight: 900;
    line-height: 1.08;
    letter-spacing: -0.03em;
    margin-bottom: 18px;
}

.gradient-text {
    display: block;
    background: linear-gradient(135deg, #6366f1, #8b5cf6, #06b6d4);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
}

.about-subtitle {
    max-width: 760px;
    margin: 0 auto;
    font-size: 18px;
    color: #6b7280;
    line-height: 1.7;
}

.hero-stats {
    margin-top: 40px;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 16px;
}

.stat-card {
    border: 1.5px solid #e5e7eb;
    border-radius: 18px;
    padding: 24px;
    background: #fff;
    text-align: left;
}

.stat-card.featured {
    border-color: #a78bfa;
    background: linear-gradient(160deg, #faf5ff, #fff);
}

.stat-card strong {
    display: block;
    font-size: 34px;
    font-weight: 900;
    letter-spacing: -0.03em;
    margin-bottom: 8px;
}

.stat-card span {
    font-size: 14px;
    line-height: 1.6;
    color: #6b7280;
}

.story-section,
.values-section,
.timeline-section,
.team-section {
    max-width: 1100px;
    margin: 0 auto;
    padding: 0 24px 80px;
}

.story-grid {
    display: grid;
    grid-template-columns: 1.5fr 1fr;
    gap: 20px;
}

.story-card {
    border: 1.5px solid #e5e7eb;
    border-radius: 22px;
    padding: 32px;
    background: #fff;
}

.story-featured {
    background: linear-gradient(135deg, #0f0f0f, #1e1b4b);
    color: #fff;
    border: none;
}

.story-featured p {
    color: #c7d2fe;
}

.mini-label {
    display: inline-block;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    padding: 5px 10px;
    border-radius: 999px;
    margin-bottom: 18px;
    background: #f3f4f6;
    color: #6366f1;
}

.story-featured .mini-label {
    background: rgba(255,255,255,0.12);
    color: #c4b5fd;
}

.story-card h2 {
    font-size: clamp(26px, 4vw, 38px);
    line-height: 1.2;
    letter-spacing: -0.03em;
    margin-bottom: 16px;
}

.story-card p {
    font-size: 15px;
    color: #6b7280;
    line-height: 1.8;
}

.section-title {
    font-size: clamp(28px, 4vw, 44px);
    font-weight: 800;
    letter-spacing: -0.02em;
    margin-bottom: 14px;
    text-align: center;
}

.section-subtitle {
    font-size: 16px;
    color: #6b7280;
    text-align: center;
    max-width: 720px;
    margin: 0 auto 42px;
    line-height: 1.7;
}

.values-grid,
.team-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 20px;
}

.value-card,
.team-card {
    border: 1.5px solid #e5e7eb;
    border-radius: 18px;
    padding: 28px;
    background: #fff;
    transition: box-shadow 0.2s, transform 0.2s;
}

.value-card:hover,
.team-card:hover {
    box-shadow: 0 10px 32px rgba(0,0,0,0.08);
    transform: translateY(-2px);
}

.value-icon {
    width: 44px;
    height: 44px;
    color: #6366f1;
    margin-bottom: 16px;
}

.value-icon svg {
    width: 100%;
    height: 100%;
}

.value-card h3,
.team-card h3,
.timeline-content h3 {
    font-size: 18px;
    font-weight: 700;
    margin-bottom: 10px;
    color: #111827;
}

.value-card p,
.team-card p,
.timeline-content p {
    font-size: 14px;
    color: #6b7280;
    line-height: 1.7;
}

.timeline-list {
    max-width: 820px;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    gap: 18px;
}

.timeline-item {
    display: grid;
    grid-template-columns: 100px 1fr;
    gap: 20px;
    border: 1.5px solid #e5e7eb;
    border-radius: 18px;
    padding: 24px;
    background: #fff;
}

.timeline-year {
    font-size: 24px;
    font-weight: 900;
    color: #6366f1;
    letter-spacing: -0.03em;
}

.avatar {
    width: 52px;
    height: 52px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    font-weight: 800;
    color: #fff;
    background: linear-gradient(135deg, #6366f1, #8b5cf6);
    margin-bottom: 18px;
}

.role {
    display: inline-block;
    margin-bottom: 12px;
    font-size: 12px;
    font-weight: 700;
    color: #7c3aed;
    background: #ede9fe;
    padding: 5px 10px;
    border-radius: 999px;
}

.cta-section {
    padding: 0 24px 80px;
    text-align: center;
}

.cta-box {
    background: linear-gradient(135deg, #0f0f0f, #1e1b4b);
    border-radius: 24px;
    padding: 64px 40px;
    max-width: 760px;
    margin: 0 auto;
    color: #fff;
}

.cta-box h2 { font-size: clamp(24px, 4vw, 36px); font-weight: 800; margin-bottom: 14px; }
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

@media (max-width: 820px) {
    .story-grid,
    .timeline-item {
        grid-template-columns: 1fr;
    }

    .timeline-item {
        gap: 10px;
    }
}

@media (max-width: 640px) {
    .about-hero {
        padding-top: 56px;
    }

    .cta-box,
    .story-card {
        padding: 36px 24px;
    }
}
</style>
