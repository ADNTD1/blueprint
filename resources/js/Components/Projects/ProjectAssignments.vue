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
const developers = ref([]);
const draggingTaskId = ref(null);
const savingTaskId = ref(null);
const currentUserId = ref(null);

const normalizeAssignment = (assignmentValue) => {
    if (Array.isArray(assignmentValue)) {
        return assignmentValue[0] || null;
    }

    return assignmentValue || null;
};

const normalizeTask = (task) => ({
    ...task,
    assignment: normalizeAssignment(task.task_assignments),
});

const fetchAssignmentBoard = async () => {
    loading.value = true;
    errorMsg.value = '';

    try {
        const { data: authData, error: authError } = await supabase.auth.getSession();
        if (authError) throw authError;
        currentUserId.value = authData?.session?.user?.id || null;

        const [{ data: taskData, error: taskError }, { data: memberData, error: memberError }] = await Promise.all([
            supabase
                .from('tasks')
                .select(`
                    id,
                    title,
                    description,
                    priority,
                    estimated_hours,
                    story_points,
                    due_date,
                    status_id,
                    created_at,
                    task_status (id, label),
                    task_assignments (id, developer_id, assigned_by, assigned_at)
                `)
                .eq('project_id', props.projectId)
                .order('created_at', { ascending: false }),
            supabase
                .from('project_members')
                .select(`
                    id,
                    user_id,
                    project_role,
                    profiles (id, name, email, avatar_url)
                `)
                .eq('project_id', props.projectId)
                .eq('project_role', 'developer')
                .order('created_at', { ascending: true }),
        ]);

        if (taskError) throw taskError;
        if (memberError) throw memberError;

        tasks.value = (taskData || []).map(normalizeTask);
        developers.value = memberData || [];
    } catch (err) {
        console.error('Error loading assignments:', err);
        errorMsg.value = err.message || 'No se pudo cargar el tablero de asignaciones.';
    } finally {
        loading.value = false;
    }
};

const unassignedTasks = computed(() =>
    tasks.value.filter((task) => !task.assignment?.developer_id)
);

const developerColumns = computed(() =>
    developers.value.map((developer) => ({
        ...developer,
        tasks: tasks.value.filter((task) => task.assignment?.developer_id === developer.user_id),
        hours: tasks.value
            .filter((task) => task.assignment?.developer_id === developer.user_id)
            .reduce((total, task) => total + Number(task.estimated_hours || 0), 0),
    }))
);

const assignmentSummary = computed(() => {
    const assigned = tasks.value.filter((task) => task.assignment?.developer_id).length;
    const hours = tasks.value.reduce((total, task) => total + Number(task.estimated_hours || 0), 0);
    const high = tasks.value.filter((task) => task.priority === 'high').length;

    return {
        assigned,
        unassigned: unassignedTasks.value.length,
        hours,
        high,
        coverage: tasks.value.length ? Math.round((assigned / tasks.value.length) * 100) : 0,
    };
});

const getPriorityClass = (priority) => {
    switch (priority) {
        case 'high':
            return 'priority high';
        case 'low':
            return 'priority low';
        default:
            return 'priority medium';
    }
};

const getPriorityLabel = (priority) => {
    switch (priority) {
        case 'high':
            return 'Alta';
        case 'low':
            return 'Baja';
        default:
            return 'Media';
    }
};

const formatDueDate = (value) => {
    if (!value) return 'Sin fecha';
    return new Date(`${value}T00:00:00`).toLocaleDateString();
};

const handleDragStart = (taskId) => {
    draggingTaskId.value = taskId;
};

const handleDragEnd = () => {
    draggingTaskId.value = null;
};

const persistAssignment = async (taskId, developerId) => {
    const task = tasks.value.find((item) => item.id === taskId);
    if (!task) return;

    const previousAssignment = task.assignment ? { ...task.assignment } : null;
    const previousDeveloperId = previousAssignment?.developer_id || null;
    if (previousDeveloperId === developerId) {
        draggingTaskId.value = null;
        return;
    }

    savingTaskId.value = taskId;
    errorMsg.value = '';
    const optimisticAssignedAt = new Date().toISOString();

    task.assignment = developerId
        ? {
            ...previousAssignment,
            developer_id: developerId,
            assigned_by: currentUserId.value,
            assigned_at: optimisticAssignedAt,
        }
        : null;

    try {
        if (developerId === null) {
            const { error } = await supabase
                .from('task_assignments')
                .delete()
                .eq('task_id', taskId);

            if (error) throw error;
            return;
        }

        let assignmentId = previousAssignment?.id;

        if (!assignmentId) {
            const { data: existingAssignment, error: existingAssignmentError } = await supabase
                .from('task_assignments')
                .select('id')
                .eq('task_id', taskId)
                .maybeSingle();

            if (existingAssignmentError) throw existingAssignmentError;
            assignmentId = existingAssignment?.id || null;
        }

        let data;
        let error;

        if (assignmentId) {
            const response = await supabase
                .from('task_assignments')
                .update({
                    developer_id: developerId,
                    assigned_by: currentUserId.value,
                    assigned_at: optimisticAssignedAt,
                })
                .eq('id', assignmentId);

            data = response.data?.[0] || null;
            error = response.error;
        } else {
            const response = await supabase
                .from('task_assignments')
                .insert({
                    task_id: taskId,
                    developer_id: developerId,
                    assigned_by: currentUserId.value,
                    assigned_at: optimisticAssignedAt,
                })
                ;

            data = response.data?.[0] || null;
            error = response.error;
        }

        if (error) throw error;
        task.assignment = data || {
            ...task.assignment,
            id: assignmentId || previousAssignment?.id || null,
            developer_id: developerId,
            assigned_by: currentUserId.value,
            assigned_at: optimisticAssignedAt,
        };
        await fetchAssignmentBoard();
    } catch (err) {
        console.error('Error saving assignment:', err);
        task.assignment = previousAssignment;
        errorMsg.value = err.message || 'No se pudo actualizar la asignacion.';
    } finally {
        savingTaskId.value = null;
        draggingTaskId.value = null;
    }
};

onMounted(() => {
    fetchAssignmentBoard();
});
</script>

<template>
    <div class="assignments-shell">
        <div class="assignments-header">
            <div>
                <h2>Asignacion de tareas</h2>
                <p>Reparte el trabajo del backlog entre developers y monitorea la carga antes de iniciar el sprint.</p>
            </div>
            <div class="header-pills">
                <span class="pill neutral">{{ tasks.length }} tareas</span>
                <span class="pill info">{{ developers.length }} developers</span>
            </div>
        </div>

        <div class="assignment-summary">
            <article>
                <span>Cobertura</span>
                <strong>{{ assignmentSummary.coverage }}%</strong>
                <p>{{ assignmentSummary.assigned }} tareas asignadas</p>
            </article>
            <article>
                <span>Sin asignar</span>
                <strong>{{ assignmentSummary.unassigned }}</strong>
                <p>requieren responsable</p>
            </article>
            <article>
                <span>Estimacion</span>
                <strong>{{ assignmentSummary.hours }}h</strong>
                <p>trabajo total</p>
            </article>
            <article>
                <span>Alta prioridad</span>
                <strong>{{ assignmentSummary.high }}</strong>
                <p>vigilar reparto</p>
            </article>
        </div>

        <p v-if="errorMsg" class="error-banner">{{ errorMsg }}</p>

        <div v-if="loading" class="loading-state">
            <div class="spinner"></div>
        </div>

        <div v-else class="assignment-board">
            <section
                class="assignment-column pool"
                @dragover.prevent
                @drop="persistAssignment(draggingTaskId, null)"
            >
                <div class="column-head">
                    <div>
                        <h3>Sin asignar</h3>
                        <span>Arrastra estas tareas a un developer</span>
                    </div>
                    <strong>{{ unassignedTasks.length }}</strong>
                </div>

                <div class="column-list">
                    <article
                        v-for="task in unassignedTasks"
                        :key="task.id"
                        class="task-card"
                        :class="{ dragging: draggingTaskId === task.id, saving: savingTaskId === task.id }"
                        draggable="true"
                        @dragstart="handleDragStart(task.id)"
                        @dragend="handleDragEnd"
                    >
                        <div class="task-meta">
                            <span class="status-chip">{{ task.task_status?.label || 'Pendiente' }}</span>
                            <span :class="getPriorityClass(task.priority)">{{ getPriorityLabel(task.priority) }}</span>
                        </div>
                        <h4>{{ task.title }}</h4>
                        <p>{{ task.description || 'Sin descripcion adicional.' }}</p>
                        <div class="task-stats">
                            <span>{{ Number(task.estimated_hours || 0) }}h estimadas</span>
                            <span>{{ task.story_points ?? 0 }} pts</span>
                            <span>{{ formatDueDate(task.due_date) }}</span>
                        </div>
                    </article>

                    <div v-if="unassignedTasks.length === 0" class="empty-dropzone">
                        No hay tareas pendientes por asignar.
                    </div>
                </div>
            </section>

            <section
                v-for="developer in developerColumns"
                :key="developer.user_id"
                class="assignment-column"
                @dragover.prevent
                @drop="persistAssignment(draggingTaskId, developer.user_id)"
            >
                <div class="column-head">
                    <div class="developer-block">
                        <div class="avatar">
                            {{ developer.profiles?.name?.charAt(0) || '?' }}
                        </div>
                        <div>
                            <h3>{{ developer.profiles?.name || 'Developer' }}</h3>
                            <span>{{ developer.tasks.length }} tareas | {{ developer.hours }}h</span>
                        </div>
                    </div>
                    <strong>{{ developer.tasks.length }}</strong>
                </div>

                <div class="column-list">
                    <article
                        v-for="task in developer.tasks"
                        :key="task.id"
                        class="task-card"
                        :class="{ dragging: draggingTaskId === task.id, saving: savingTaskId === task.id }"
                        draggable="true"
                        @dragstart="handleDragStart(task.id)"
                        @dragend="handleDragEnd"
                    >
                        <div class="task-meta">
                            <span class="status-chip">{{ task.task_status?.label || 'Pendiente' }}</span>
                            <span :class="getPriorityClass(task.priority)">{{ getPriorityLabel(task.priority) }}</span>
                        </div>
                        <h4>{{ task.title }}</h4>
                        <p>{{ task.description || 'Sin descripcion adicional.' }}</p>
                        <div class="task-stats">
                            <span>{{ Number(task.estimated_hours || 0) }}h estimadas</span>
                            <span>{{ task.story_points ?? 0 }} pts</span>
                            <span>{{ formatDueDate(task.due_date) }}</span>
                        </div>
                    </article>

                    <div v-if="developer.tasks.length === 0" class="empty-dropzone">
                        Suelta una tarea aqui para asignarla.
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<style scoped>
.assignments-shell {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.assignments-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 16px;
}

.assignments-header h2 {
    font-size: 28px;
    font-weight: 800;
    letter-spacing: -0.03em;
    color: #111827;
}

.assignments-header p {
    margin-top: 8px;
    max-width: 720px;
    font-size: 14px;
    line-height: 1.6;
    color: #6b7280;
}

.header-pills {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
}

.assignment-summary {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
}

.assignment-summary article {
    border: 1px solid #eef2f7;
    border-radius: 22px;
    background: #ffffff;
    padding: 18px;
    box-shadow: 0 12px 28px rgba(15, 23, 42, 0.04);
}

.assignment-summary span {
    color: #64748b;
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.08em;
    text-transform: uppercase;
}

.assignment-summary strong {
    display: block;
    margin-top: 10px;
    color: #111827;
    font-size: 30px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.assignment-summary p {
    margin-top: 2px;
    color: #94a3b8;
    font-size: 13px;
    font-weight: 700;
}

.pill {
    padding: 9px 14px;
    border-radius: 999px;
    font-size: 12px;
    font-weight: 800;
}

.pill.neutral {
    color: #1f2937;
    background: #f3f4f6;
}

.pill.info {
    color: #1d4ed8;
    background: #dbeafe;
}

.error-banner {
    background: #fef2f2;
    color: #b91c1c;
    border: 1px solid #fecaca;
    padding: 12px 14px;
    border-radius: 14px;
    font-size: 14px;
    font-weight: 600;
}

.loading-state {
    display: flex;
    justify-content: center;
    padding: 48px 0;
}

.spinner {
    width: 34px;
    height: 34px;
    border-radius: 999px;
    border: 3px solid #e5e7eb;
    border-top-color: #111827;
    animation: spin 0.8s linear infinite;
}

.assignment-board {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 18px;
    align-items: start;
}

.assignment-column {
    min-height: 520px;
    padding: 16px;
    border-radius: 28px;
    border: 1px solid #e5e7eb;
    background:
        radial-gradient(circle at top, rgba(191, 219, 254, 0.25), transparent 36%),
        linear-gradient(180deg, #ffffff, #f8fafc);
    box-shadow: 0 18px 38px rgba(15, 23, 42, 0.06);
}

.assignment-column.pool {
    background:
        radial-gradient(circle at top, rgba(253, 224, 71, 0.22), transparent 38%),
        linear-gradient(180deg, #ffffff, #fffbeb);
}

.column-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding-bottom: 16px;
}

.column-head h3 {
    font-size: 16px;
    font-weight: 800;
    color: #111827;
}

.column-head span {
    font-size: 12px;
    color: #6b7280;
}

.column-head strong {
    min-width: 38px;
    height: 38px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 14px;
    background: rgba(255, 255, 255, 0.76);
    color: #111827;
    font-size: 13px;
    font-weight: 800;
}

.developer-block {
    display: flex;
    align-items: center;
    gap: 12px;
}

.avatar {
    width: 42px;
    height: 42px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 14px;
    background: #111827;
    color: #ffffff;
    font-size: 15px;
    font-weight: 800;
    flex-shrink: 0;
}

.column-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.task-card {
    padding: 14px;
    border-radius: 20px;
    border: 1px solid #e5e7eb;
    background: rgba(255, 255, 255, 0.9);
    cursor: grab;
    transition: transform 0.15s ease, box-shadow 0.2s ease, opacity 0.2s ease;
}

.task-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 14px 30px rgba(15, 23, 42, 0.08);
}

.task-card.dragging {
    opacity: 0.45;
}

.task-card.saving {
    border-color: #2563eb;
    box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
}

.task-meta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 12px;
}

.status-chip,
.priority {
    display: inline-flex;
    align-items: center;
    border-radius: 999px;
    padding: 4px 8px;
    font-size: 10px;
    font-weight: 800;
    letter-spacing: 0.06em;
    text-transform: uppercase;
}

.status-chip {
    background: #eef2ff;
    color: #4338ca;
}

.priority.medium {
    background: #e0f2fe;
    color: #0369a1;
}

.priority.high {
    background: #fee2e2;
    color: #b91c1c;
}

.priority.low {
    background: #dcfce7;
    color: #15803d;
}

.task-card h4 {
    font-size: 15px;
    font-weight: 800;
    line-height: 1.5;
    color: #111827;
}

.task-card p {
    margin-top: 6px;
    font-size: 13px;
    line-height: 1.6;
    color: #6b7280;
}

.task-stats {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 14px;
}

.task-stats span {
    padding: 6px 8px;
    border-radius: 10px;
    background: #f8fafc;
    font-size: 11px;
    font-weight: 700;
    color: #475569;
}

.empty-dropzone {
    min-height: 112px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px dashed #cbd5e1;
    border-radius: 18px;
    padding: 18px;
    text-align: center;
    font-size: 13px;
    line-height: 1.6;
    color: #94a3b8;
    background: rgba(255, 255, 255, 0.55);
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}

@media (max-width: 720px) {
    .assignments-header {
        flex-direction: column;
    }

    .assignment-summary {
        grid-template-columns: 1fr;
    }
}
</style>
