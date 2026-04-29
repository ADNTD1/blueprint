<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { Head, Link } from '@inertiajs/vue3';
import { supabase } from '@/lib/supabase';
import AuthenticatedLayout from '@/Layouts/AuthenticatedLayout.vue';
import ProjectBacklog from '@/Components/Projects/ProjectBacklog.vue';
import ProjectMembers from '@/Components/Projects/ProjectMembers.vue';
import ProjectAIChat from '@/Components/Projects/ProjectAIChat.vue';
import ProjectKanban from '@/Components/Projects/ProjectKanban.vue';
import ProjectAssignments from '@/Components/Projects/ProjectAssignments.vue';
import ProjectOverview from '@/Components/Projects/ProjectOverview.vue';

const props = defineProps({
    id: String
});

const project = ref(null);
const loading = ref(true);
const userRole = ref(null);
const activeTab = ref('dashboard');
const showProjectSettings = ref(false);
const savingProjectSettings = ref(false);
const projectSettingsError = ref('');
const projectForm = ref({
    name: '',
    description: '',
    status: 'active',
});

const projectStatuses = [
    { value: 'planning', label: 'Planeacion', helper: 'Aun se esta definiendo alcance, tareas y prioridades.' },
    { value: 'active', label: 'En marcha', helper: 'El equipo esta trabajando activamente en el proyecto.' },
    { value: 'at_risk', label: 'En riesgo', helper: 'Hay bloqueos, retrasos o dependencias criticas por resolver.' },
    { value: 'completed', label: 'Completado', helper: 'El proyecto ya alcanzo sus entregables principales.' },
    { value: 'archived', label: 'Archivado', helper: 'Se conserva como referencia, sin trabajo operativo activo.' },
];

const tabs = [
    { id: 'dashboard', name: 'Resumen', subtitle: 'Salud del proyecto', icon: 'M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z' },
    { id: 'kanban', name: 'Kanban', subtitle: 'Drag and drop de tareas', icon: 'M6.75 4.5h10.5A2.25 2.25 0 0 1 19.5 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25H6.75A2.25 2.25 0 0 1 4.5 17.25V6.75A2.25 2.25 0 0 1 6.75 4.5Zm0 4.5h10.5m-6-4.5v15' },
    { id: 'assignments', name: 'Asignaciones', subtitle: 'Reparto de tareas por developer', icon: 'M7.5 6h9m-9 6h5.25m-6.75 6h11.25M3.75 6h.008v.008H3.75V6Zm0 6h.008v.008H3.75V12Zm0 6h.008v.008H3.75V18Z' },
    { id: 'backlog', name: 'Backlog', subtitle: 'Tareas y prioridades', icon: 'M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875 1.875 0 0 1 0-3.75Z' },
    { id: 'ai', name: 'Copiloto', subtitle: 'Asistente del proyecto', icon: 'M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.456-2.455l.258-1.036.259 1.036a3.375 3.375 0 0 0 2.455 2.455l1.036.259-1.036.259a3.375 3.375 0 0 0-2.455 2.456ZM16.894 20.567 16.5 22.25l-.394-1.683a1.125 1.125 0 0 0-.823-.823L13.6 19.35l1.683-.394a1.125 1.125 0 0 0 .823-.823l.394-1.683.394 1.683a1.125 1.125 0 0 0 .823.823l1.683.394-1.683.394a1.125 1.125 0 0 0-.823.823Z' },
    { id: 'members', name: 'Miembros', subtitle: 'Equipo y accesos', icon: 'M15 19.128a9.38 9.38 0 0 0 2.625.372 9.337 9.337 0 0 0 4.121-.952 4.125 4.125 0 0 0-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 0 1 8.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0 1 11.964-3.07M12 6.375a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0Zm8.25 2.25a2.625 2.625 0 1 1-5.25 0 2.625 2.625 0 0 1 5.25 0Z' },
];

const visibleTabs = computed(() => {
    if (userRole.value === 'manager') {
        return tabs;
    }

    return tabs.filter((tab) => ['dashboard', 'kanban', 'backlog'].includes(tab.id));
});

const currentStatusMeta = computed(() => {
    return projectStatuses.find((status) => status.value === project.value?.status)
        || projectStatuses.find((status) => status.value === 'active');
});

const openProjectSettings = () => {
    if (!project.value || userRole.value !== 'manager') return;

    projectForm.value = {
        name: project.value.name || '',
        description: project.value.description || '',
        status: project.value.status || 'active',
    };
    projectSettingsError.value = '';
    showProjectSettings.value = true;
};

const closeProjectSettings = () => {
    if (savingProjectSettings.value) return;
    showProjectSettings.value = false;
    projectSettingsError.value = '';
};

const saveProjectSettings = async () => {
    if (!project.value?.id) return;
    if (!projectForm.value.name.trim()) {
        projectSettingsError.value = 'El nombre del proyecto es obligatorio.';
        return;
    }

    savingProjectSettings.value = true;
    projectSettingsError.value = '';

    try {
        const payload = {
            name: projectForm.value.name.trim(),
            description: projectForm.value.description.trim() || null,
            status: projectForm.value.status,
        };

        const { data, error } = await supabase
            .from('projects')
            .update(payload)
            .eq('id', project.value.id)
            .select()
            .single();

        if (error) throw error;

        project.value = data;
        showProjectSettings.value = false;
    } catch (err) {
        console.error('Error updating project:', err);
        projectSettingsError.value = err.message || 'No se pudieron guardar los cambios del proyecto.';
    } finally {
        savingProjectSettings.value = false;
    }
};

const fetchProjectDetails = async () => {
    loading.value = true;
    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session) return;

        const userId = session.user.id;

        const { data: memberData, error: memberError } = await supabase
            .from('project_members')
            .select('project_role')
            .eq('project_id', props.id)
            .eq('user_id', userId)
            .single();

        if (memberError) throw new Error('No tienes acceso a este proyecto o no existe.');
        userRole.value = memberData.project_role;

        const { data: projectData, error: projectError } = await supabase
            .from('projects')
            .select('*')
            .eq('id', props.id)
            .single();

        if (projectError) throw projectError;
        project.value = projectData;
    } catch (err) {
        console.error(err);
    } finally {
        loading.value = false;
    }
};

onMounted(() => {
    fetchProjectDetails();
});

watch(visibleTabs, (nextTabs) => {
    if (!nextTabs.some((tab) => tab.id === activeTab.value)) {
        activeTab.value = nextTabs[0]?.id || 'dashboard';
    }
});
</script>

<template>
    <Head :title="project ? project.name : 'Cargando Proyecto...'" />

    <AuthenticatedLayout>
        <div class="project-page min-h-[calc(100vh-64px)] bg-[#fafafa]">
            <header class="compact-project-header bg-white border-b border-gray-100">
                <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
                    <div v-if="project" class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                        <div class="min-w-0">
                            <div class="mb-1 flex items-center gap-3 text-sm font-semibold text-gray-500">
                                <Link href="/dashboard" class="inline-flex items-center gap-2 text-gray-400 transition hover:text-gray-950">
                                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
                                    </svg>
                                    Dashboard
                                </Link>
                                <span class="h-1 w-1 rounded-full bg-gray-300"></span>
                                <span>Proyecto</span>
                            </div>

                            <div class="project-title-row">
                                <h1 class="truncate text-2xl font-extrabold tracking-tight text-gray-950 sm:text-3xl">{{ project.name }}</h1>
                                <button
                                    v-if="userRole === 'manager'"
                                    type="button"
                                    class="settings-trigger"
                                    @click="openProjectSettings"
                                    aria-label="Configurar proyecto"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="w-5 h-5">
                                        <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12a7.5 7.5 0 0 1 15 0m-15 0a7.5 7.5 0 0 0 15 0m-15 0H3m16.5 0H21M12 4.5V3m0 18v-1.5m5.303-12.803 1.06-1.06M5.636 18.364l1.06-1.06m0-10.607-1.06-1.06m12.728 12.728-1.06-1.06" />
                                    </svg>
                                </button>
                            </div>
                            <p class="max-w-3xl truncate text-sm text-gray-500 sm:text-base">{{ project.description || 'Sin descripcion.' }}</p>
                        </div>
                    </div>
                </div>
            </header>

            <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
                <div v-if="loading" class="flex items-center justify-center py-20">
                    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-black"></div>
                </div>

                <div v-else-if="project" class="project-layout">
                    <div class="project-pill-nav">
                        <Link href="/dashboard" class="pill-home" aria-label="Volver al dashboard">
                            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
                            </svg>
                        </Link>

                        <nav class="pill-tabs" aria-label="Navegacion del proyecto">
                            <button
                                v-for="tab in visibleTabs"
                                :key="tab.id"
                                type="button"
                                @click="activeTab = tab.id"
                                class="pill-tab"
                                :class="{ active: activeTab === tab.id }"
                                :title="tab.subtitle"
                            >
                                <span class="pill-tab-icon">
                                    <svg fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor">
                                        <path stroke-linecap="round" stroke-linejoin="round" :d="tab.icon" />
                                    </svg>
                                </span>
                                <span>{{ tab.name }}</span>
                            </button>
                        </nav>

                        <div class="pill-meta">
                            <span class="pill-status" :class="currentStatusMeta?.value">{{ currentStatusMeta?.label }}</span>
                            <span class="pill-role">{{ userRole === 'manager' ? 'Manager' : 'Developer' }}</span>
                        </div>
                    </div>

                    <section class="project-content">
                        <div v-if="activeTab === 'dashboard'">
                            <ProjectOverview :projectId="project.id" />
                        </div>

                        <div v-if="activeTab === 'kanban'">
                            <ProjectKanban
                                :projectId="project.id"
                                :canCreate="false"
                                :userRole="userRole"
                            />
                        </div>

                        <div v-if="activeTab === 'assignments' && userRole === 'manager'">
                            <ProjectAssignments :projectId="project.id" />
                        </div>

                        <div v-if="activeTab === 'backlog'">
                            <ProjectBacklog :projectId="project.id" :canCreate="userRole === 'manager'" />
                        </div>

                        <div v-if="activeTab === 'ai'">
                            <ProjectAIChat :projectId="project.id" :project="project" />
                        </div>

                        <div v-if="activeTab === 'members'">
                            <ProjectMembers :projectId="project.id" :canInvite="userRole === 'manager'" />
                        </div>
                    </section>
                </div>

                <div v-else class="text-center py-20">
                    <h3 class="text-xl font-bold text-gray-900 mb-2">Proyecto no encontrado</h3>
                    <p class="text-gray-500 mb-8">No hemos podido cargar los detalles de este proyecto.</p>
                    <Link href="/dashboard" class="bg-black text-white px-6 py-3 rounded-2xl font-bold">Volver al Dashboard</Link>
                </div>
            </main>

            <div v-if="showProjectSettings" class="settings-modal-wrap">
                <div class="settings-overlay" @click="closeProjectSettings"></div>
                <div class="settings-modal">
                    <div class="settings-header">
                        <div>
                            <div class="settings-eyebrow">Configuracion</div>
                            <h3>Editar proyecto</h3>
                            <p>Renombra el proyecto y define su estado general.</p>
                        </div>
                        <button class="settings-close" @click="closeProjectSettings">Ã—</button>
                    </div>

                    <div class="settings-body">
                        <div v-if="projectSettingsError" class="settings-error">{{ projectSettingsError }}</div>

                        <div class="settings-field">
                            <label for="project-name">Nombre del proyecto</label>
                            <input id="project-name" v-model="projectForm.name" type="text" placeholder="Nombre del proyecto" />
                        </div>

                        <div class="settings-field">
                            <label for="project-description">Descripcion</label>
                            <textarea id="project-description" v-model="projectForm.description" rows="4" placeholder="Resumen corto del proyecto"></textarea>
                        </div>

                        <div class="settings-field">
                            <label for="project-status">Estado del proyecto</label>
                            <select id="project-status" v-model="projectForm.status">
                                <option
                                    v-for="status in projectStatuses"
                                    :key="status.value"
                                    :value="status.value"
                                >
                                    {{ status.label }}
                                </option>
                            </select>
                            <p class="settings-helper">
                                {{ projectStatuses.find((status) => status.value === projectForm.status)?.helper }}
                            </p>
                        </div>
                    </div>

                    <div class="settings-footer">
                        <button class="secondary-btn" @click="closeProjectSettings" :disabled="savingProjectSettings">Cancelar</button>
                        <button class="primary-btn" @click="saveProjectSettings" :disabled="savingProjectSettings">
                            {{ savingProjectSettings ? 'Guardando...' : 'Guardar cambios' }}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </AuthenticatedLayout>
</template>

<style scoped>
.project-title-row {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 8px;
}

.settings-trigger {
    width: 38px;
    height: 38px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 12px;
    border: 1px solid #e5e7eb;
    background: #ffffff;
    color: #4b5563;
    transition: all 0.2s ease;
}

.settings-trigger:hover {
    background: #111827;
    border-color: #111827;
    color: #ffffff;
}

.project-status-badge {
    padding: 6px 12px;
    border-radius: 999px;
    font-size: 12px;
    font-weight: 700;
    letter-spacing: 0.02em;
}

.project-status-badge.planning {
    background: #fef3c7;
    color: #b45309;
}

.project-status-badge.active {
    background: #dcfce7;
    color: #15803d;
}

.project-status-badge.at_risk {
    background: #fee2e2;
    color: #b91c1c;
}

.project-status-badge.completed {
    background: #dbeafe;
    color: #1d4ed8;
}

.project-status-badge.archived {
    background: #f3f4f6;
    color: #6b7280;
}

.role-pill {
    padding: 6px 14px;
    border-radius: 12px;
    font-size: 13px;
    font-weight: 700;
    letter-spacing: -0.01em;
}

.role-pill.manager {
    background: #000000;
    color: #ffffff;
}

.role-pill.developer {
    background: #f3f4f6;
    color: #374151;
}

.project-layout {
    display: flex;
    flex-direction: column;
    gap: 24px;
}

.project-pill-nav {
    position: relative;
    z-index: 1;
    display: flex;
    align-items: center;
    gap: 14px;
    width: 100%;
    min-height: 76px;
    padding: 8px;
    border: 1px solid rgba(255, 255, 255, 0.18);
    border-radius: 999px;
    background: #191919;
    box-shadow: 0 14px 32px rgba(15, 23, 42, 0.13);
}

.pill-home {
    display: flex;
    height: 52px;
    width: 52px;
    flex: none;
    align-items: center;
    justify-content: center;
    border-radius: 999px;
    background: #ffffff;
    color: #111827;
    transition: transform 0.2s ease, background 0.2s ease;
}

.pill-home:hover {
    transform: translateX(-2px);
    background: #f3f4f6;
}

.pill-tabs {
    display: flex;
    min-width: 0;
    flex: 1;
    align-items: center;
    gap: 4px;
    overflow-x: auto;
    scrollbar-width: none;
}

.pill-tabs::-webkit-scrollbar {
    display: none;
}

.pill-tab {
    display: inline-flex;
    height: 48px;
    flex: none;
    align-items: center;
    gap: 8px;
    border-radius: 999px;
    padding: 0 16px;
    color: rgba(255, 255, 255, 0.78);
    font-size: 14px;
    font-weight: 700;
    letter-spacing: -0.01em;
    transition: background 0.2s ease, color 0.2s ease, transform 0.2s ease;
}

.pill-tab:hover {
    background: rgba(255, 255, 255, 0.08);
    color: #ffffff;
}

.pill-tab.active {
    background: #ffffff;
    color: #111827;
    transform: translateY(-1px);
}

.pill-tab-icon {
    display: flex;
    height: 22px;
    width: 22px;
    align-items: center;
    justify-content: center;
}

.pill-tab-icon svg {
    height: 19px;
    width: 19px;
}

.pill-meta {
    display: flex;
    flex: none;
    align-items: center;
    gap: 8px;
}

.pill-status,
.pill-role {
    display: inline-flex;
    height: 48px;
    align-items: center;
    border-radius: 999px;
    padding: 0 18px;
    white-space: nowrap;
    font-size: 14px;
    font-weight: 800;
}

.pill-role {
    background: #ffffff;
    color: #111827;
}

.pill-status.planning {
    background: #fef3c7;
    color: #92400e;
}

.pill-status.active {
    background: #dcfce7;
    color: #166534;
}

.pill-status.at_risk {
    background: #fee2e2;
    color: #991b1b;
}

.pill-status.completed {
    background: #dbeafe;
    color: #1e40af;
}

.pill-status.archived {
    background: #f3f4f6;
    color: #4b5563;
}

.project-content {
    min-width: 0;
}

.settings-modal-wrap {
    position: fixed;
    inset: 0;
    z-index: 60;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 24px;
}

.settings-overlay {
    position: absolute;
    inset: 0;
    background: rgba(15, 23, 42, 0.38);
    backdrop-filter: blur(4px);
}

.settings-modal {
    position: relative;
    width: min(100%, 620px);
    background: #ffffff;
    border-radius: 28px;
    box-shadow: 0 30px 80px rgba(15, 23, 42, 0.24);
    overflow: hidden;
}

.settings-header,
.settings-body,
.settings-footer {
    padding-left: 28px;
    padding-right: 28px;
}

.settings-header {
    padding-top: 24px;
    padding-bottom: 20px;
    display: flex;
    justify-content: space-between;
    gap: 20px;
}

.settings-eyebrow {
    font-size: 11px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: #6366f1;
    margin-bottom: 8px;
}

.settings-header h3 {
    font-size: 26px;
    font-weight: 800;
    letter-spacing: -0.03em;
    color: #111827;
}

.settings-header p {
    margin-top: 8px;
    font-size: 14px;
    color: #6b7280;
}

.settings-close {
    width: 38px;
    height: 38px;
    border-radius: 12px;
    border: 1px solid #e5e7eb;
    background: #fff;
    font-size: 24px;
    line-height: 1;
    color: #6b7280;
}

.settings-body {
    padding-top: 8px;
    padding-bottom: 24px;
    display: flex;
    flex-direction: column;
    gap: 18px;
}

.settings-field {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.settings-field label {
    font-size: 13px;
    font-weight: 700;
    color: #374151;
}

.settings-field input,
.settings-field textarea,
.settings-field select {
    width: 100%;
    border: 1px solid #d1d5db;
    border-radius: 14px;
    padding: 12px 14px;
    font-size: 14px;
    color: #111827;
    background: #fff;
    outline: none;
}

.settings-field textarea {
    resize: vertical;
}

.settings-field input:focus,
.settings-field textarea:focus,
.settings-field select:focus {
    border-color: #818cf8;
    box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.12);
}

.settings-helper {
    font-size: 12px;
    color: #6b7280;
    line-height: 1.5;
}

.settings-error {
    background: #fef2f2;
    border: 1px solid #fecaca;
    color: #b91c1c;
    padding: 12px 14px;
    border-radius: 14px;
    font-size: 13px;
    font-weight: 600;
}

.settings-footer {
    padding-top: 18px;
    padding-bottom: 24px;
    background: #f8fafc;
    display: flex;
    justify-content: flex-end;
    gap: 12px;
}

.secondary-btn,
.primary-btn {
    border-radius: 14px;
    padding: 12px 16px;
    font-size: 14px;
    font-weight: 700;
}

.secondary-btn {
    border: 1px solid #d1d5db;
    background: #fff;
    color: #374151;
}

.primary-btn {
    border: 1px solid #111827;
    background: #111827;
    color: #fff;
}

@media (max-width: 960px) {
    .project-pill-nav {
        align-items: flex-start;
        border-radius: 28px;
        flex-wrap: wrap;
    }

    .pill-tabs {
        order: 3;
        flex-basis: 100%;
    }

    .pill-meta {
        margin-left: auto;
    }
}

@media (max-width: 640px) {
    .project-pill-nav {
        gap: 8px;
        padding: 8px;
        border-radius: 24px;
    }

    .pill-home {
        height: 48px;
        width: 48px;
    }

    .pill-tab {
        height: 46px;
        padding: 0 14px;
        font-size: 14px;
    }

    .pill-status {
        display: none;
    }

    .pill-role {
        height: 48px;
        padding: 0 14px;
        font-size: 13px;
    }

    .settings-modal-wrap {
        padding: 16px;
    }

    .settings-header,
    .settings-body,
    .settings-footer {
        padding-left: 20px;
        padding-right: 20px;
    }

    .settings-footer {
        flex-direction: column;
    }
}
</style>
