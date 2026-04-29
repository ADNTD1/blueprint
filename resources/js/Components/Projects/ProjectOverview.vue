<script setup>
import { computed, onMounted, ref } from 'vue';
import { supabase } from '@/lib/supabase';

const props = defineProps({
    projectId: {
        type: String,
        required: true,
    },
});

const loading = ref(true);
const errorMsg = ref('');
const tasks = ref([]);
const members = ref([]);

const priorityLabels = {
    low: 'Baja',
    medium: 'Media',
    high: 'Alta',
};

const statusLabels = {
    pending: 'Pendiente',
    in_progress: 'En progreso',
    completed: 'Completada',
};

const normalizeStatus = (label) => {
    const normalized = label?.toLowerCase?.().trim() || '';

    if (normalized === 'pending' || normalized === 'to do' || normalized === 'todo') return 'Pendiente';
    if (normalized === 'in progress' || normalized === 'in_progress') return 'En progreso';
    if (normalized === 'completed' || normalized === 'complete' || normalized === 'done') return 'Completada';

    return label || 'Sin estado';
};

const normalizeAssignment = (assignmentValue) => {
    if (Array.isArray(assignmentValue)) {
        return assignmentValue[0] || null;
    }

    return assignmentValue || null;
};

const memberMap = computed(() =>
    new Map(
        members.value.map((member) => [
            member.user_id,
            {
                name: member.profiles?.name || member.profiles?.email || 'Developer',
                email: member.profiles?.email || '',
                role: member.project_role,
            },
        ])
    )
);

const totalTasks = computed(() => tasks.value.length);
const completedTasks = computed(() => tasks.value.filter((task) => task.status_id === 3).length);
const inProgressTasks = computed(() => tasks.value.filter((task) => task.status_id === 2).length);
const pendingTasks = computed(() => tasks.value.filter((task) => task.status_id === 1).length);
const assignedTasks = computed(() => tasks.value.filter((task) => task.assignment?.developer_id).length);
const highPriorityTasks = computed(() => tasks.value.filter((task) => task.priority === 'high').length);
const estimatedHours = computed(() =>
    tasks.value.reduce((total, task) => total + Number(task.estimated_hours || 0), 0)
);
const storyPoints = computed(() =>
    tasks.value.reduce((total, task) => total + Number(task.story_points || 0), 0)
);

const completionPercentage = computed(() => {
    if (!totalTasks.value) return 0;
    return Math.round((completedTasks.value / totalTasks.value) * 100);
});

const assignmentPercentage = computed(() => {
    if (!totalTasks.value) return 0;
    return Math.round((assignedTasks.value / totalTasks.value) * 100);
});

const overdueTasks = computed(() => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return tasks.value.filter((task) => {
        if (!task.due_date || task.status_id === 3) return false;
        return new Date(`${task.due_date}T00:00:00`) < today;
    }).length;
});

const statusBreakdown = computed(() => {
    const base = [
        { id: 1, label: 'Pendiente', count: pendingTasks.value, color: '#f59e0b' },
        { id: 2, label: 'En progreso', count: inProgressTasks.value, color: '#3b82f6' },
        { id: 3, label: 'Completada', count: completedTasks.value, color: '#ec4899' },
    ];

    return base.map((item) => ({
        ...item,
        width: totalTasks.value ? Math.max(6, Math.round((item.count / totalTasks.value) * 100)) : 0,
    }));
});

const priorityBreakdown = computed(() => {
    return ['high', 'medium', 'low'].map((priority) => {
        const count = tasks.value.filter((task) => task.priority === priority).length;

        return {
            key: priority,
            label: priorityLabels[priority],
            count,
            width: totalTasks.value ? Math.max(6, Math.round((count / totalTasks.value) * 100)) : 0,
        };
    });
});

const workload = computed(() => {
    const buckets = new Map();

    members.value.forEach((member) => {
        buckets.set(member.user_id, {
            id: member.user_id,
            name: member.profiles?.name || member.profiles?.email || 'Developer',
            role: member.project_role,
            count: 0,
            hours: 0,
        });
    });

    tasks.value.forEach((task) => {
        const developerId = task.assignment?.developer_id;
        if (!developerId) return;

        const bucket = buckets.get(developerId) || {
            id: developerId,
            name: memberMap.value.get(developerId)?.name || 'Developer',
            role: 'developer',
            count: 0,
            hours: 0,
        };

        bucket.count += 1;
        bucket.hours += Number(task.estimated_hours || 0);
        buckets.set(developerId, bucket);
    });

    return [...buckets.values()]
        .filter((member) => member.role === 'developer' || member.count > 0)
        .sort((a, b) => b.count - a.count)
        .slice(0, 5);
});

const recentTasks = computed(() => {
    return [...tasks.value]
        .sort((a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0))
        .slice(0, 5);
});

const weeklyActivity = computed(() => {
    const labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    const buckets = labels.map((label) => ({ label, total: 0, done: 0 }));

    tasks.value.forEach((task) => {
        const date = task.created_at ? new Date(task.created_at) : null;
        const index = date && !Number.isNaN(date.getTime()) ? (date.getDay() + 6) % 7 : 0;
        buckets[index].total += 1;
        if (task.status_id === 3) buckets[index].done += 1;
    });

    const maxTotal = Math.max(...buckets.map((bucket) => bucket.total), 1);

    return buckets.map((bucket) => ({
        ...bucket,
        height: bucket.total ? Math.max(24, Math.round((bucket.total / maxTotal) * 118)) : 18,
    }));
});

const metrics = computed(() => [
    {
        label: 'Progreso',
        value: `${completionPercentage.value}%`,
        helper: `${completedTasks.value} de ${totalTasks.value} tareas`,
        tone: 'dark',
    },
    {
        label: 'Tareas activas',
        value: pendingTasks.value + inProgressTasks.value,
        helper: `${inProgressTasks.value} en progreso`,
        tone: 'blue',
    },
    {
        label: 'Asignacion',
        value: `${assignmentPercentage.value}%`,
        helper: `${assignedTasks.value} tareas asignadas`,
        tone: 'green',
    },
    {
        label: 'Riesgo',
        value: overdueTasks.value + highPriorityTasks.value,
        helper: `${overdueTasks.value} vencidas, ${highPriorityTasks.value} alta prioridad`,
        tone: 'orange',
    },
]);

const fetchOverview = async () => {
    loading.value = true;
    errorMsg.value = '';

    try {
        const [{ data: taskData, error: taskError }, { data: memberData, error: memberError }] = await Promise.all([
            supabase
                .from('tasks')
                .select(`
                    id,
                    title,
                    description,
                    status_id,
                    priority,
                    estimated_hours,
                    story_points,
                    due_date,
                    created_at,
                    task_status (id, label),
                    task_assignments (id, developer_id, assigned_at)
                `)
                .eq('project_id', props.projectId)
                .order('created_at', { ascending: false }),
            supabase
                .from('project_members')
                .select(`
                    user_id,
                    project_role,
                    profiles (name, email)
                `)
                .eq('project_id', props.projectId),
        ]);

        if (taskError) throw taskError;
        if (memberError) throw memberError;

        members.value = memberData || [];
        tasks.value = (taskData || []).map((task) => ({
            ...task,
            task_status: task.task_status
                ? { ...task.task_status, label: normalizeStatus(task.task_status.label) }
                : task.task_status,
            assignment: normalizeAssignment(task.task_assignments),
        }));
    } catch (err) {
        console.error('Error loading project overview:', err);
        errorMsg.value = err.message || 'No se pudo cargar el resumen del proyecto.';
    } finally {
        loading.value = false;
    }
};

const getAssignee = (task) => {
    if (!task.assignment?.developer_id) return 'Sin asignar';
    return memberMap.value.get(task.assignment.developer_id)?.name || 'Developer';
};

const getStatusLabel = (task) => {
    return normalizeStatus(task.task_status?.label) || statusLabels[task.task_status?.code] || 'Sin estado';
};

const getPriorityLabel = (priority) => priorityLabels[priority] || 'Media';

const formatDate = (value) => {
    if (!value) return 'Sin fecha';
    return new Date(`${value}T00:00:00`).toLocaleDateString('es-MX', {
        day: 'numeric',
        month: 'short',
    });
};

onMounted(() => {
    fetchOverview();
});
</script>

<template>
    <div class="overview-shell">
        <div v-if="loading" class="overview-loading">
            <div class="spinner"></div>
        </div>

        <p v-else-if="errorMsg" class="overview-error">{{ errorMsg }}</p>

        <template v-else>
            <section class="overview-hero">
                <div>
                    <span class="hero-eyebrow">Resumen operativo</span>
                    <h2>Salud del proyecto</h2>
                    <p>
                        Progreso, carga del equipo y prioridades actuales en una sola vista para tomar decisiones rapido.
                    </p>
                </div>

                <div class="progress-orb">
                    <svg viewBox="0 0 120 120">
                        <circle cx="60" cy="60" r="48" class="orb-track" />
                        <circle
                            cx="60"
                            cy="60"
                            r="48"
                            class="orb-fill"
                            :style="{ strokeDashoffset: 302 - (302 * completionPercentage) / 100 }"
                        />
                    </svg>
                    <div>
                        <strong>{{ completionPercentage }}%</strong>
                        <span>completo</span>
                    </div>
                </div>
            </section>

            <section class="metrics-grid">
                <article v-for="metric in metrics" :key="metric.label" class="metric-card" :class="metric.tone">
                    <span>{{ metric.label }}</span>
                    <strong>{{ metric.value }}</strong>
                    <p>{{ metric.helper }}</p>
                </article>
            </section>

            <section class="overview-grid">
                <article class="panel-card span-7">
                    <div class="panel-heading">
                        <div>
                            <h3>Flujo de tareas</h3>
                            <p>Distribucion actual del tablero por etapa.</p>
                        </div>
                        <span>{{ totalTasks }} tareas</span>
                    </div>

                    <div class="stacked-bar">
                        <div
                            v-for="item in statusBreakdown"
                            :key="item.label"
                            :style="{ width: `${item.width}%`, background: item.color }"
                        ></div>
                    </div>

                    <div class="status-list">
                        <div v-for="item in statusBreakdown" :key="item.id">
                            <span class="status-dot" :style="{ background: item.color }"></span>
                            <span>{{ item.label }}</span>
                            <strong>{{ item.count }}</strong>
                        </div>
                    </div>
                </article>

                <article class="panel-card span-5">
                    <div class="panel-heading">
                        <div>
                            <h3>Actividad semanal</h3>
                            <p>Tareas creadas por dia.</p>
                        </div>
                    </div>

                    <div class="activity-chart">
                        <div v-for="(day, index) in weeklyActivity" :key="`${day.label}-${index}`" class="activity-day">
                            <div class="activity-bar" :style="{ height: `${day.height}px` }">
                                <span>{{ day.total }}</span>
                            </div>
                            <small>{{ day.label }}</small>
                        </div>
                    </div>
                </article>

                <article class="panel-card span-5">
                    <div class="panel-heading">
                        <div>
                            <h3>Prioridad</h3>
                            <p>Que tan sensible esta el backlog.</p>
                        </div>
                    </div>

                    <div class="priority-list">
                        <div v-for="item in priorityBreakdown" :key="item.key" class="priority-row" :class="item.key">
                            <div>
                                <span>{{ item.label }}</span>
                                <strong>{{ item.count }}</strong>
                            </div>
                            <div class="mini-track">
                                <div :style="{ width: `${item.width}%` }"></div>
                            </div>
                        </div>
                    </div>
                </article>

                <article class="panel-card span-7">
                    <div class="panel-heading">
                        <div>
                            <h3>Carga por responsable</h3>
                            <p>Tareas y horas estimadas asignadas.</p>
                        </div>
                        <span>{{ estimatedHours }}h</span>
                    </div>

                    <div v-if="workload.length" class="workload-list">
                        <div v-for="member in workload" :key="member.id" class="workload-row">
                            <div class="member-avatar">{{ member.name.charAt(0) }}</div>
                            <div class="member-copy">
                                <strong>{{ member.name }}</strong>
                                <span>{{ member.count }} tareas | {{ member.hours }}h estimadas</span>
                            </div>
                            <div class="workload-meter">
                                <div :style="{ width: `${totalTasks ? Math.max(8, Math.round((member.count / totalTasks) * 100)) : 0}%` }"></div>
                            </div>
                        </div>
                    </div>
                    <p v-else class="soft-empty">Aun no hay tareas asignadas al equipo.</p>
                </article>

                <article class="panel-card span-12">
                    <div class="panel-heading">
                        <div>
                            <h3>Actividad reciente</h3>
                            <p>Ultimas tareas registradas en el proyecto.</p>
                        </div>
                        <span>{{ storyPoints }} pts</span>
                    </div>

                    <div v-if="recentTasks.length" class="recent-list">
                        <div v-for="task in recentTasks" :key="task.id" class="recent-task">
                            <div>
                                <strong>{{ task.title }}</strong>
                                <span>{{ getStatusLabel(task) }} | {{ getAssignee(task) }}</span>
                            </div>
                            <div class="recent-meta">
                                <span :class="['priority-chip', task.priority]">{{ getPriorityLabel(task.priority) }}</span>
                                <span>{{ formatDate(task.due_date) }}</span>
                            </div>
                        </div>
                    </div>
                    <p v-else class="soft-empty">Aun no hay tareas para mostrar. Crea tareas desde Backlog o Kanban.</p>
                </article>
            </section>
        </template>
    </div>
</template>

<style scoped>
.overview-shell {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.overview-loading {
    display: flex;
    justify-content: center;
    padding: 72px 0;
}

.spinner {
    height: 36px;
    width: 36px;
    border: 3px solid #e5e7eb;
    border-top-color: #111827;
    border-radius: 999px;
    animation: spin 0.8s linear infinite;
}

.overview-error {
    border: 1px solid #fecaca;
    border-radius: 18px;
    background: #fef2f2;
    color: #b91c1c;
    padding: 14px 16px;
    font-weight: 700;
}

.overview-hero,
.metric-card,
.panel-card {
    border: 1px solid #eef2f7;
    background: #ffffff;
    box-shadow: 0 18px 42px rgba(15, 23, 42, 0.05);
}

.overview-hero {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
    border-radius: 30px;
    padding: 28px;
    background:
        radial-gradient(circle at top left, rgba(121, 169, 212, 0.22), transparent 34%),
        linear-gradient(135deg, #ffffff, #f8fafc);
}

.hero-eyebrow {
    display: inline-block;
    margin-bottom: 10px;
    color: #64748b;
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.14em;
    text-transform: uppercase;
}

.overview-hero h2 {
    color: #0f172a;
    font-size: 34px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.overview-hero p {
    margin-top: 8px;
    max-width: 620px;
    color: #64748b;
    font-size: 15px;
    line-height: 1.6;
}

.progress-orb {
    position: relative;
    height: 132px;
    width: 132px;
    flex: none;
}

.progress-orb svg {
    height: 100%;
    width: 100%;
    transform: rotate(-90deg);
}

.orb-track,
.orb-fill {
    fill: none;
    stroke-width: 12;
}

.orb-track {
    stroke: #e5e7eb;
}

.orb-fill {
    stroke: #111827;
    stroke-linecap: round;
    stroke-dasharray: 302;
    transition: stroke-dashoffset 0.7s ease;
}

.progress-orb div {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-direction: column;
}

.progress-orb strong {
    color: #0f172a;
    font-size: 28px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.progress-orb span {
    color: #64748b;
    font-size: 12px;
    font-weight: 800;
}

.metrics-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 16px;
}

.metric-card {
    border-radius: 24px;
    padding: 20px;
}

.metric-card span,
.panel-heading p,
.soft-empty {
    color: #64748b;
}

.metric-card span {
    font-size: 13px;
    font-weight: 800;
}

.metric-card strong {
    display: block;
    margin-top: 14px;
    color: #0f172a;
    font-size: 32px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.metric-card p {
    margin-top: 4px;
    color: #94a3b8;
    font-size: 13px;
    font-weight: 700;
}

.metric-card.dark {
    background: #111827;
}

.metric-card.dark span,
.metric-card.dark p {
    color: rgba(255, 255, 255, 0.7);
}

.metric-card.dark strong {
    color: #ffffff;
}

.metric-card.blue {
    background: #eff6ff;
}

.metric-card.green {
    background: #ecfdf5;
}

.metric-card.orange {
    background: #fff7ed;
}

.overview-grid {
    display: grid;
    grid-template-columns: repeat(12, minmax(0, 1fr));
    gap: 16px;
}

.panel-card {
    border-radius: 26px;
    padding: 22px;
}

.span-5 {
    grid-column: span 5;
}

.span-7 {
    grid-column: span 7;
}

.span-12 {
    grid-column: span 12;
}

.panel-heading {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 16px;
    margin-bottom: 20px;
}

.panel-heading h3 {
    color: #0f172a;
    font-size: 20px;
    font-weight: 900;
    letter-spacing: -0.03em;
}

.panel-heading p {
    margin-top: 4px;
    font-size: 13px;
}

.panel-heading > span {
    border-radius: 999px;
    background: #f1f5f9;
    color: #334155;
    padding: 8px 12px;
    white-space: nowrap;
    font-size: 12px;
    font-weight: 900;
}

.stacked-bar {
    display: flex;
    height: 20px;
    overflow: hidden;
    border-radius: 999px;
    background: #f1f5f9;
}

.status-list,
.priority-list,
.workload-list,
.recent-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.status-list {
    margin-top: 18px;
}

.status-list > div {
    display: grid;
    grid-template-columns: 16px 1fr auto;
    align-items: center;
    gap: 10px;
    color: #475569;
    font-size: 14px;
    font-weight: 800;
}

.status-dot {
    height: 10px;
    width: 10px;
    border-radius: 999px;
}

.activity-chart {
    display: flex;
    min-height: 158px;
    align-items: flex-end;
    justify-content: space-between;
    gap: 10px;
}

.activity-day {
    display: flex;
    flex: 1;
    align-items: center;
    flex-direction: column;
    gap: 8px;
}

.activity-bar {
    display: flex;
    width: 100%;
    max-width: 34px;
    align-items: flex-start;
    justify-content: center;
    border-radius: 999px;
    background: linear-gradient(180deg, #111827, #79a9d4);
    padding-top: 8px;
    color: #ffffff;
    font-size: 11px;
    font-weight: 900;
}

.activity-day small {
    color: #64748b;
    font-size: 12px;
    font-weight: 900;
}

.priority-row > div:first-child {
    display: flex;
    justify-content: space-between;
    margin-bottom: 8px;
    color: #334155;
    font-size: 14px;
    font-weight: 900;
}

.mini-track,
.workload-meter {
    height: 8px;
    overflow: hidden;
    border-radius: 999px;
    background: #f1f5f9;
}

.mini-track div,
.workload-meter div {
    height: 100%;
    border-radius: inherit;
}

.priority-row.high .mini-track div {
    background: #ef4444;
}

.priority-row.medium .mini-track div {
    background: #f59e0b;
}

.priority-row.low .mini-track div {
    background: #6366f1;
}

.workload-row {
    display: grid;
    grid-template-columns: 44px minmax(0, 1fr) minmax(120px, 0.6fr);
    align-items: center;
    gap: 12px;
}

.member-avatar {
    display: flex;
    height: 44px;
    width: 44px;
    align-items: center;
    justify-content: center;
    border-radius: 14px;
    background: #111827;
    color: #ffffff;
    font-weight: 900;
}

.member-copy {
    min-width: 0;
}

.member-copy strong {
    display: block;
    overflow: hidden;
    color: #0f172a;
    font-size: 14px;
    font-weight: 900;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.member-copy span {
    color: #64748b;
    font-size: 12px;
    font-weight: 700;
}

.workload-meter div {
    background: #111827;
}

.recent-task {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    border: 1px solid #eef2f7;
    border-radius: 18px;
    padding: 14px;
}

.recent-task strong {
    display: block;
    color: #0f172a;
    font-size: 14px;
    font-weight: 900;
}

.recent-task span {
    color: #64748b;
    font-size: 12px;
    font-weight: 700;
}

.recent-meta {
    display: flex;
    flex: none;
    align-items: center;
    gap: 8px;
}

.priority-chip {
    border-radius: 999px;
    padding: 6px 9px;
    font-size: 11px;
    font-weight: 900;
}

.priority-chip.high {
    background: #fee2e2;
    color: #991b1b;
}

.priority-chip.medium {
    background: #fef3c7;
    color: #92400e;
}

.priority-chip.low {
    background: #e0e7ff;
    color: #3730a3;
}

.soft-empty {
    border: 1px dashed #cbd5e1;
    border-radius: 18px;
    padding: 18px;
    text-align: center;
    font-size: 14px;
    font-weight: 700;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}

@media (max-width: 1024px) {
    .metrics-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .span-5,
    .span-7 {
        grid-column: span 12;
    }
}

@media (max-width: 720px) {
    .overview-hero {
        align-items: flex-start;
        flex-direction: column;
    }

    .metrics-grid {
        grid-template-columns: 1fr;
    }

    .workload-row,
    .recent-task {
        align-items: flex-start;
        grid-template-columns: 44px minmax(0, 1fr);
        flex-direction: column;
    }

    .workload-meter {
        grid-column: 1 / -1;
        width: 100%;
    }

    .recent-meta {
        width: 100%;
        justify-content: space-between;
    }
}
</style>
