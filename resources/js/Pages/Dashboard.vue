<script setup>
import { computed, onMounted, ref } from 'vue';
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout.vue';
import { Head } from '@inertiajs/vue3';
import { supabase } from '@/lib/supabase';
import ProjectMetrics from '@/Components/Dashboard/ProjectMetrics.vue';
import CreateProjectModal from '@/Components/Dashboard/CreateProjectModal.vue';
import ProjectCard from '@/Components/Dashboard/ProjectCard.vue';

const loading = ref(true);
const isModalOpen = ref(false);
const projectsList = ref([]);
const tasksList = ref([]);
const error = ref('');
const hoveredWeekIndex = ref(null);

const metrics = ref({
    projectsCount: 0,
    activeProjectsCount: 0,
    tasksCount: 0,
    completedTasksCount: 0,
});

const statusLabels = {
    planning: 'Planeacion',
    active: 'En marcha',
    at_risk: 'En riesgo',
    completed: 'Completado',
    archived: 'Archivado',
};

const completionPercentage = computed(() => {
    if (metrics.value.tasksCount === 0) return 0;
    return Math.round((metrics.value.completedTasksCount / metrics.value.tasksCount) * 100);
});

const activePercentage = computed(() => {
    if (metrics.value.projectsCount === 0) return 0;
    return Math.round((metrics.value.activeProjectsCount / metrics.value.projectsCount) * 100);
});

const recentProjects = computed(() => {
    return [...projectsList.value]
        .sort((a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0))
        .slice(0, 4);
});

const statusSummary = computed(() => {
    return Object.entries(statusLabels)
        .map(([key, label]) => ({
            key,
            label,
            count: projectsList.value.filter((project) => project.status === key).length,
        }))
        .filter((item) => item.count > 0);
});

const weeklyBars = computed(() => {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    const dayNames = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
    const projectNames = new Map(projectsList.value.map((project) => [project.id, project.name]));
    const buckets = labels.map((label, index) => ({
        label,
        dayName: dayNames[index],
        total: 0,
        completed: 0,
        projectIds: new Set(),
    }));
    const todayIndex = (new Date().getDay() + 6) % 7;

    tasksList.value.forEach((task) => {
        const date = task.created_at ? new Date(task.created_at) : null;
        const index = date && !Number.isNaN(date.getTime()) ? (date.getDay() + 6) % 7 : 0;
        buckets[index].total += 1;
        if (task.status_id === 3) buckets[index].completed += 1;
        if (task.project_id) buckets[index].projectIds.add(task.project_id);
    });

    const maxTotal = Math.max(...buckets.map((bucket) => bucket.total), 1);

    return buckets.map((bucket, index) => {
        const pending = Math.max(bucket.total - bucket.completed, 0);
        const relatedProjects = [...bucket.projectIds]
            .map((projectId) => projectNames.get(projectId))
            .filter(Boolean);

        return {
            label: bucket.label,
            dayName: bucket.dayName,
            total: bucket.total,
            completed: bucket.completed,
            pending,
            relatedProjects,
            completionRate: bucket.total ? Math.round((bucket.completed / bucket.total) * 100) : 0,
            height: bucket.total ? Math.max(32, Math.round((bucket.total / maxTotal) * 128)) : 28,
            active: index === todayIndex,
        };
    });
});

const formatDate = (dateString) => {
    if (!dateString) return 'Sin fecha';
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('es-MX', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
    }).format(date);
};

const resetDashboard = () => {
    projectsList.value = [];
    tasksList.value = [];
    metrics.value = {
        projectsCount: 0,
        activeProjectsCount: 0,
        tasksCount: 0,
        completedTasksCount: 0,
    };
};

const fetchMetrics = async () => {
    loading.value = true;
    error.value = '';

    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) {
            resetDashboard();
            return;
        }

        const userId = session.user.id;

        const { data: projectMembers, error: pmError } = await supabase
            .from('project_members')
            .select('project_id')
            .eq('user_id', userId);

        if (pmError) throw pmError;

        const projectIds = (projectMembers || []).map((pm) => pm.project_id);

        if (projectIds.length === 0) {
            resetDashboard();
            return;
        }

        const { data: projects, error: pError } = await supabase
            .from('projects')
            .select('id, name, description, status, created_at')
            .in('id', projectIds);

        if (pError) throw pError;

        const { data: tasks, error: tError } = await supabase
            .from('tasks')
            .select('id, project_id, status_id, created_at')
            .in('project_id', projectIds);

        if (tError) throw tError;

        projectsList.value = projects || [];
        tasksList.value = tasks || [];
        metrics.value = {
            projectsCount: projectsList.value.length,
            activeProjectsCount: projectsList.value.filter((project) => project.status === 'active').length,
            tasksCount: tasksList.value.length,
            completedTasksCount: tasksList.value.filter((task) => task.status_id === 3).length,
        };
    } catch (err) {
        console.error('Error al cargar metricas:', err);
        error.value = 'No se pudieron cargar las metricas en este momento.';
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    fetchMetrics();
});

const handleProjectCreated = () => {
    fetchMetrics();
};
</script>

<template>
    <Head title="Panel General | Blueprint" />

    <AuthenticatedLayout>
        <template #header>
            <div class="flex items-center justify-between gap-4">
                <div>
                    <p class="text-xs font-semibold uppercase tracking-[0.24em] text-gray-400">Blueprint</p>
                    <h2 class="text-2xl font-bold leading-tight tracking-tight text-gray-950">
                        Panel General
                    </h2>
                </div>

                <button
                    @click="isModalOpen = true"
                    class="inline-flex items-center gap-2 rounded-full bg-gray-950 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-gray-800"
                >
                    <span class="text-lg leading-none">+</span>
                    Nuevo Proyecto
                </button>
            </div>
        </template>

        <CreateProjectModal
            :show="isModalOpen"
            @close="isModalOpen = false"
            @project-created="handleProjectCreated"
        />

        <div class="dashboard-shell py-8 sm:py-10">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <div v-if="error" class="mb-6 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-red-700">
                    {{ error }}
                </div>

                <div v-if="loading" class="grid gap-6 lg:grid-cols-[1.15fr_0.85fr]">
                    <div class="h-[430px] animate-pulse rounded-[2rem] bg-white/80"></div>
                    <div class="h-[430px] animate-pulse rounded-[2rem] bg-white/70"></div>
                    <div class="h-40 animate-pulse rounded-[2rem] bg-white/70 lg:col-span-2"></div>
                </div>

                <template v-else>
                    <section v-if="projectsList.length > 0" class="grid gap-6 lg:grid-cols-[1.15fr_0.85fr]">
                        <div class="hero-card min-h-[430px]">
                            <div class="flex flex-wrap items-start justify-between gap-4">
                                <div>
                                    <div class="mb-5 flex h-11 w-11 items-center justify-center rounded-2xl bg-gray-100 text-gray-800">
                                        <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M3 13.5h4.5l2-6 4 12 2-6H21" />
                                        </svg>
                                    </div>
                                    <h3 class="text-4xl font-semibold tracking-tight text-gray-950 sm:text-5xl">Avance general</h3>
                                    <p class="mt-3 max-w-xl text-base leading-6 text-gray-500">
                                        Lectura rapida del trabajo completado, proyectos activos y movimiento reciente del equipo.
                                    </p>
                                </div>
                                <div class="rounded-full border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-600 shadow-sm">
                                    Esta semana
                                </div>
                            </div>

                            <div class="mt-12 grid gap-8 lg:grid-cols-[0.45fr_0.55fr]">
                                <div class="flex flex-col justify-end">
                                    <div class="text-5xl font-bold tracking-tight text-gray-950">+{{ completionPercentage }}%</div>
                                    <p class="mt-4 max-w-xs text-sm leading-5 text-gray-500">
                                        {{ metrics.completedTasksCount }} de {{ metrics.tasksCount }} tareas estan completadas.
                                    </p>
                                    <div class="mt-8 h-2 overflow-hidden rounded-full bg-gray-100">
                                        <div class="h-full rounded-full bg-gray-950 transition-all duration-700" :style="{ width: `${completionPercentage}%` }"></div>
                                    </div>
                                </div>

                                <div class="flex min-h-[210px] items-end justify-between gap-3 sm:gap-5">
                                    <div
                                        v-for="(bar, index) in weeklyBars"
                                        :key="`${bar.label}-${index}`"
                                        class="weekly-bar-item flex flex-1 flex-col items-center gap-3"
                                        tabindex="0"
                                        @mouseenter="hoveredWeekIndex = index"
                                        @mouseleave="hoveredWeekIndex = null"
                                        @focus="hoveredWeekIndex = index"
                                        @blur="hoveredWeekIndex = null"
                                    >
                                        <div class="relative flex h-36 w-full items-end justify-center">
                                            <div class="w-px rounded-full bg-gray-300" :style="{ height: `${bar.height}px` }"></div>
                                            <div
                                                class="absolute rounded-full"
                                                :class="bar.active ? 'h-4 w-4 bg-gray-950 ring-[14px] ring-gray-100' : 'h-3 w-3 bg-blue-400'"
                                                :style="{ bottom: `${bar.height - 6}px` }"
                                            ></div>
                                            <div v-if="hoveredWeekIndex === index" class="weekly-tooltip">
                                                <div class="tooltip-title">{{ bar.dayName }}</div>
                                                <div class="tooltip-grid">
                                                    <span>Creadas</span>
                                                    <strong>{{ bar.total }}</strong>
                                                    <span>Completadas</span>
                                                    <strong>{{ bar.completed }}</strong>
                                                    <span>Pendientes</span>
                                                    <strong>{{ bar.pending }}</strong>
                                                    <span>Avance</span>
                                                    <strong>{{ bar.completionRate }}%</strong>
                                                </div>
                                                <p>
                                                    {{ bar.relatedProjects.length ? bar.relatedProjects.slice(0, 2).join(', ') : 'Sin tareas registradas' }}
                                                </p>
                                            </div>
                                        </div>
                                        <div
                                            class="flex h-11 w-11 items-center justify-center rounded-full text-sm font-semibold"
                                            :class="bar.active ? 'bg-gray-950 text-white' : 'bg-gray-200 text-gray-700'"
                                        >
                                            {{ bar.label }}
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <aside class="panel-card">
                            <div class="mb-7 flex items-center justify-between gap-4">
                                <div>
                                    <h3 class="text-2xl font-semibold tracking-tight text-gray-950">Proyectos recientes</h3>
                                    <p class="mt-1 text-sm text-gray-500">Mostrando {{ recentProjects.length }} de {{ projectsList.length }}</p>
                                </div>
                                <span class="rounded-full bg-gray-200 px-4 py-2 text-sm font-semibold text-gray-600">{{ activePercentage }}% activos</span>
                            </div>

                            <div class="divide-y divide-gray-200/80">
                                <ProjectCard
                                    v-for="project in recentProjects"
                                    :key="project.id"
                                    :project="project"
                                    variant="compact"
                                />
                            </div>
                        </aside>
                    </section>

                    <ProjectMetrics
                        v-if="projectsList.length > 0"
                        class="mt-6"
                        :projectsCount="metrics.projectsCount"
                        :activeProjectsCount="metrics.activeProjectsCount"
                        :tasksCount="metrics.tasksCount"
                        :completedTasksCount="metrics.completedTasksCount"
                        :loading="loading"
                    />

                    <section v-if="projectsList.length > 0" class="mt-6 grid gap-6 lg:grid-cols-[0.62fr_0.38fr]">
                        <div class="panel-card">
                            <div class="mb-6">
                                <h3 class="text-2xl font-semibold tracking-tight text-gray-950">Todos tus proyectos</h3>
                                <p class="mt-1 text-sm text-gray-500">Vista completa de los espacios donde participas.</p>
                            </div>

                            <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                                <ProjectCard
                                    v-for="project in projectsList"
                                    :key="project.id"
                                    :project="project"
                                />
                            </div>
                        </div>

                        <div class="panel-card">
                            <h3 class="text-2xl font-semibold tracking-tight text-gray-950">Estado del portafolio</h3>
                            <p class="mt-1 text-sm text-gray-500">Distribucion actual por fase.</p>

                            <div class="mt-8 space-y-5">
                                <div v-for="item in statusSummary" :key="item.key">
                                    <div class="mb-2 flex items-center justify-between text-sm">
                                        <span class="font-semibold text-gray-700">{{ item.label }}</span>
                                        <span class="text-gray-500">{{ item.count }}</span>
                                    </div>
                                    <div class="h-2 overflow-hidden rounded-full bg-gray-100">
                                        <div
                                            class="h-full rounded-full bg-gray-950"
                                            :style="{ width: `${Math.max(8, Math.round((item.count / metrics.projectsCount) * 100))}%` }"
                                        ></div>
                                    </div>
                                </div>
                            </div>

                            <div class="mt-8 rounded-[1.5rem] bg-gray-100 p-5">
                                <div class="text-sm font-semibold text-gray-500">Siguiente revision</div>
                                <div class="mt-2 text-2xl font-bold tracking-tight text-gray-950">{{ formatDate(recentProjects[0]?.created_at) }}</div>
                                <p class="mt-2 text-sm leading-5 text-gray-500">Basado en el proyecto mas reciente registrado en tu espacio.</p>
                            </div>
                        </div>
                    </section>

                    <div v-if="projectsList.length === 0 && !error" class="empty-state">
                        <div class="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-gray-100 text-gray-400">
                            <svg class="h-7 w-7" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M10.125 2.25h-4.5c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125v-9M10.125 2.25h.375a9 9 0 0 1 9 9v.375" />
                            </svg>
                        </div>
                        <h3 class="text-2xl font-bold tracking-tight text-gray-950">Comienza a construir</h3>
                        <p class="mx-auto mt-3 max-w-md text-gray-500">
                            Aun no formas parte de ningun proyecto. Crea uno nuevo para colaborar con tu equipo y gestionar tareas.
                        </p>
                        <button
                            @click="isModalOpen = true"
                            class="mt-7 rounded-full bg-gray-950 px-5 py-3 text-sm font-bold text-white transition hover:bg-gray-800"
                        >
                            Crear primer proyecto
                        </button>
                    </div>
                </template>
            </div>
        </div>
    </AuthenticatedLayout>
</template>

<style scoped>
.dashboard-shell {
    background: #e8ebee;
}

.hero-card,
.panel-card,
.empty-state {
    border: 1px solid rgba(255, 255, 255, 0.68);
    background: rgba(255, 255, 255, 0.84);
    box-shadow: 0 24px 60px rgba(15, 23, 42, 0.08);
}

.hero-card,
.panel-card {
    border-radius: 32px;
    padding: 28px;
}

.empty-state {
    margin-top: 24px;
    border-radius: 32px;
    padding: 56px 24px;
    text-align: center;
}

h2,
h3 {
    font-family: 'Inter', sans-serif;
    letter-spacing: -0.02em;
}

.weekly-bar-item {
    position: relative;
    min-width: 0;
    outline: none;
}

.weekly-tooltip {
    position: absolute;
    bottom: calc(100% + 14px);
    left: 50%;
    z-index: 20;
    width: 190px;
    transform: translateX(-50%);
    border: 1px solid rgba(15, 23, 42, 0.08);
    border-radius: 16px;
    background: #111827;
    color: #ffffff;
    padding: 12px;
    box-shadow: 0 18px 38px rgba(15, 23, 42, 0.22);
}

.weekly-tooltip::after {
    content: '';
    position: absolute;
    left: 50%;
    bottom: -6px;
    width: 12px;
    height: 12px;
    transform: translateX(-50%) rotate(45deg);
    background: #111827;
}

.tooltip-title {
    font-size: 13px;
    font-weight: 800;
    margin-bottom: 8px;
}

.tooltip-grid {
    display: grid;
    grid-template-columns: 1fr auto;
    gap: 5px 12px;
    font-size: 12px;
}

.tooltip-grid span,
.weekly-tooltip p {
    color: rgba(255, 255, 255, 0.68);
}

.tooltip-grid strong {
    font-weight: 800;
}

.weekly-tooltip p {
    margin-top: 9px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    font-size: 11px;
}

@media (max-width: 640px) {
    .hero-card,
    .panel-card {
        border-radius: 24px;
        padding: 20px;
    }

    .weekly-tooltip {
        width: 170px;
    }
}
</style>
