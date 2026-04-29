<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { supabase } from '@/lib/supabase';

const props = defineProps({
    projectId: {
        type: String,
        required: true,
    },
    canCreate: {
        type: Boolean,
        default: true,
    },
    userRole: {
        type: String,
        default: 'developer',
    },
});

const loading = ref(true);
const tasks = ref([]);
const statuses = ref([]);
const members = ref([]);
const currentUserId = ref(null);
const newTaskTitle = ref('');
const isAddingTask = ref(false);
const isDeletingTask = ref(false);
const movingTaskId = ref(null);
const draggingTaskId = ref(null);
const taskToDelete = ref(null);
const errorMsg = ref('');
let boardChannel = null;

const priorityLabels = {
    low: 'Baja',
    medium: 'Media',
    high: 'Alta',
};

const fallbackStatuses = [
    { id: 1, label: 'Pendiente' },
    { id: 2, label: 'En progreso' },
    { id: 3, label: 'Completada' },
];

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
            },
        ])
    )
);

const visibleTasks = computed(() => {
    if (props.userRole === 'manager') {
        return tasks.value;
    }

    return tasks.value.filter((task) => task.assignment?.developer_id === currentUserId.value);
});

const groupedColumns = computed(() => {
    const baseStatuses = statuses.value.length ? statuses.value : fallbackStatuses;
    const missingStatuses = visibleTasks.value
        .filter((task) => task.status_id && !baseStatuses.some((status) => status.id === task.status_id))
        .map((task) => ({
            id: task.status_id,
            label: task.task_status?.label || `Estado ${task.status_id}`,
        }));

    const allStatuses = [...baseStatuses];
    missingStatuses.forEach((status) => {
        if (!allStatuses.some((item) => item.id === status.id)) {
            allStatuses.push(status);
        }
    });

    return allStatuses.map((status) => ({
        ...status,
        tasks: visibleTasks.value.filter((task) => task.status_id === status.id),
    }));
});

const boardSummary = computed(() => {
    if (props.userRole === 'manager') {
        return 'Vista general del proyecto con todas las tareas activas y su responsable.';
    }

    return 'Aqui ves unicamente las tareas que te fueron asignadas para moverlas entre estados.';
});

const translateStatusLabel = (label) => {
    const normalized = label?.toLowerCase?.().trim() || '';

    if (normalized === 'to do' || normalized === 'todo' || normalized === 'pending') {
        return 'Pendiente';
    }

    if (normalized === 'in progress' || normalized === 'in_progress') {
        return 'En progreso';
    }

    if (normalized === 'done' || normalized === 'completed' || normalized === 'complete') {
        return 'Completada';
    }

    return label || 'Sin estado';
};

const fetchBoard = async ({ silent = false } = {}) => {
    if (!silent) {
        loading.value = true;
    }

    errorMsg.value = '';

    try {
        const { data: authData, error: authError } = await supabase.auth.getSession();
        if (authError) throw authError;
        currentUserId.value = authData?.session?.user?.id || null;

        const [{ data: statusData, error: statusError }, { data: memberData, error: memberError }] = await Promise.all([
            supabase
                .from('task_status')
                .select('id, label')
                .order('id', { ascending: true }),
            supabase
                .from('project_members')
                .select(`
                    user_id,
                    profiles (name, email)
                `)
                .eq('project_id', props.projectId),
        ]);

        if (statusError) throw statusError;
        if (memberError) throw memberError;

        statuses.value = statusData?.length
            ? statusData.map((status) => ({
                ...status,
                label: translateStatusLabel(status.label),
            }))
            : fallbackStatuses;
        members.value = memberData || [];

        let taskData = [];
        let assignmentMap = new Map();

        if (props.userRole === 'manager') {
            const [{ data: fetchedTasks, error: taskError }, { data: assignmentData, error: assignmentError }] = await Promise.all([
                supabase
                    .from('tasks')
                    .select(`
                        *,
                        task_status (id, label)
                    `)
                    .eq('project_id', props.projectId)
                    .order('created_at', { ascending: false }),
                supabase
                    .from('task_assignments')
                    .select('id, task_id, developer_id, assigned_at'),
            ]);

            if (taskError) throw taskError;
            if (assignmentError) throw assignmentError;

            taskData = fetchedTasks || [];
            assignmentMap = new Map((assignmentData || []).map((assignment) => [assignment.task_id, assignment]));
        } else {
            const { data: myAssignments, error: myAssignmentsError } = await supabase
                .from('task_assignments')
                .select('id, task_id, developer_id, assigned_at')
                .eq('developer_id', currentUserId.value);

            if (myAssignmentsError) throw myAssignmentsError;

            const assignedTaskIds = (myAssignments || []).map((assignment) => assignment.task_id);
            assignmentMap = new Map((myAssignments || []).map((assignment) => [assignment.task_id, assignment]));

            if (assignedTaskIds.length > 0) {
                const { data: fetchedTasks, error: taskError } = await supabase
                    .from('tasks')
                    .select(`
                        *,
                        task_status (id, label)
                    `)
                    .eq('project_id', props.projectId)
                    .in('id', assignedTaskIds)
                    .order('created_at', { ascending: false });

                if (taskError) throw taskError;
                taskData = fetchedTasks || [];
            }
        }

        tasks.value = taskData.map((task) => ({
            ...task,
            task_status: task.task_status
                ? {
                    ...task.task_status,
                    label: translateStatusLabel(task.task_status.label),
                }
                : task.task_status,
            assignment: assignmentMap.get(task.id) || normalizeAssignment(task.task_assignments),
        }));
    } catch (err) {
        console.error('Error loading kanban:', err);
        errorMsg.value = err.message || 'No se pudo cargar el tablero kanban.';
    } finally {
        if (!silent) {
            loading.value = false;
        }
    }
};

const addTask = async () => {
    if (!newTaskTitle.value.trim() || !props.canCreate) return;

    isAddingTask.value = true;
    errorMsg.value = '';

    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session?.user) throw new Error('No hay sesion activa.');

        const defaultStatusId = statuses.value[0]?.id || 1;

        const { error } = await supabase
            .from('tasks')
            .insert({
                project_id: props.projectId,
                title: newTaskTitle.value.trim(),
                status_id: defaultStatusId,
                created_by: session.user.id,
            });

        if (error) throw error;

        newTaskTitle.value = '';
        await fetchBoard();
    } catch (err) {
        console.error('Error creating task:', err);
        errorMsg.value = err.message || 'No se pudo crear la tarea.';
    } finally {
        isAddingTask.value = false;
    }
};

const handleDragStart = (taskId) => {
    draggingTaskId.value = taskId;
};

const handleDragEnd = () => {
    draggingTaskId.value = null;
};

const moveTask = async (taskId, targetStatusId) => {
    const task = tasks.value.find((item) => item.id === taskId);
    if (!task || task.status_id === targetStatusId) return;

    movingTaskId.value = taskId;
    errorMsg.value = '';

    const previousStatusId = task.status_id;
    task.status_id = targetStatusId;
    const targetStatus = statuses.value.find((item) => item.id === targetStatusId);
    task.task_status = targetStatus ? { id: targetStatus.id, label: targetStatus.label } : task.task_status;

    try {
        const { error } = await supabase
            .from('tasks')
            .update({ status_id: targetStatusId })
            .eq('id', taskId);

        if (error) throw error;
    } catch (err) {
        console.error('Error moving task:', err);
        task.status_id = previousStatusId;
        const previousStatus = statuses.value.find((item) => item.id === previousStatusId);
        task.task_status = previousStatus ? { id: previousStatus.id, label: previousStatus.label } : task.task_status;
        errorMsg.value = err.message || 'No se pudo mover la tarea.';
    } finally {
        movingTaskId.value = null;
        draggingTaskId.value = null;
    }
};

const openDeleteConfirmation = (task) => {
    if (props.userRole !== 'manager') return;

    errorMsg.value = '';
    taskToDelete.value = task;
};

const closeDeleteConfirmation = () => {
    if (isDeletingTask.value) return;
    taskToDelete.value = null;
};

const deleteTask = async () => {
    if (props.userRole !== 'manager' || !taskToDelete.value) return;

    isDeletingTask.value = true;
    errorMsg.value = '';

    try {
        const { error } = await supabase
            .from('tasks')
            .delete()
            .eq('id', taskToDelete.value.id)
            .eq('project_id', props.projectId);

        if (error) {
            if (error.code === '42501') {
                throw new Error('Solo un manager puede eliminar tareas. Revisa la politica delete de tasks en Supabase.');
            }

            throw error;
        }

        taskToDelete.value = null;
        await fetchBoard({ silent: true });
    } catch (err) {
        console.error('Error deleting task:', err);
        errorMsg.value = err.message || 'No se pudo eliminar la tarea.';
    } finally {
        isDeletingTask.value = false;
    }
};

const getAssignee = (task) => {
    if (!task.assignment?.developer_id) {
        return props.userRole === 'manager' ? 'Sin asignar' : 'Sin responsable';
    }

    return memberMap.value.get(task.assignment.developer_id)?.name || 'Developer';
};

const getPriorityClass = (priority) => {
    switch (priority) {
        case 'high':
            return 'priority-badge high';
        case 'low':
            return 'priority-badge low';
        default:
            return 'priority-badge medium';
    }
};

const getPriorityLabel = (priority) => priorityLabels[priority] || 'Media';

const getColumnAccent = (label) => {
    const normalized = label?.toLowerCase?.() || '';

    if (normalized.includes('progress') || normalized.includes('progreso')) return 'blue';
    if (normalized.includes('done') || normalized.includes('complete') || normalized.includes('complet')) return 'pink';
    if (normalized.includes('pend') || normalized.includes('to do')) return 'amber';

    return 'indigo';
};

const formatDueDate = (value) => {
    if (!value) return 'Sin fecha';
    return new Date(`${value}T00:00:00`).toLocaleDateString();
};

onMounted(() => {
    fetchBoard();

    boardChannel = supabase
        .channel(`project-kanban-${props.projectId}`)
        .on(
            'postgres_changes',
            {
                event: '*',
                schema: 'public',
                table: 'tasks',
            },
            () => {
                fetchBoard({ silent: true });
            }
        )
        .on(
            'postgres_changes',
            {
                event: '*',
                schema: 'public',
                table: 'task_assignments',
            },
            () => {
                fetchBoard({ silent: true });
            }
        )
        .subscribe();
});

onUnmounted(() => {
    if (boardChannel) {
        supabase.removeChannel(boardChannel);
        boardChannel = null;
    }
});
</script>

<template>
    <div class="kanban-container">
        <div class="board-hero" :class="{ developer: userRole !== 'manager' }">
            <div>
                <h2 class="board-title">{{ userRole === 'manager' ? 'Tablero Kanban' : 'Mis tareas asignadas' }}</h2>
                <p class="board-subtitle">{{ boardSummary }}</p>
            </div>
            <div class="board-meta-wrap">
                <div class="board-meta">{{ visibleTasks.length }} tareas visibles</div>
                <div v-if="userRole !== 'manager'" class="board-meta ghost">Solo tus asignaciones</div>
            </div>
        </div>

        <div v-if="canCreate" class="create-task-bar">
            <input
                v-model="newTaskTitle"
                type="text"
                placeholder="Escribe una tarea nueva para el proyecto..."
                class="task-input"
                @keyup.enter="addTask"
                :disabled="isAddingTask"
            />
            <button
                @click="addTask"
                class="create-btn"
                :disabled="!newTaskTitle.trim() || isAddingTask"
            >
                {{ isAddingTask ? 'Creando...' : 'Nueva tarea' }}
            </button>
        </div>

        <p v-if="errorMsg" class="error-banner">{{ errorMsg }}</p>

        <Teleport to="body">
            <div v-if="userRole === 'manager' && taskToDelete" class="delete-modal-wrap">
                <div class="delete-overlay" @click="closeDeleteConfirmation"></div>

                <div class="delete-modal">
                    <div class="delete-icon">
                        <svg fill="none" viewBox="0 0 24 24" stroke-width="1.9" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166M19.228 5.79 18.16 19.673A2.25 2.25 0 0 1 15.916 21H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
                        </svg>
                    </div>
                    <h3>Eliminar tarea</h3>
                    <p>
                        Vas a eliminar <strong>{{ taskToDelete.title }}</strong>. Tambien se quitaran sus asignaciones y no se puede deshacer.
                    </p>
                    <div class="delete-actions">
                        <button type="button" class="cancel-delete-btn" @click="closeDeleteConfirmation" :disabled="isDeletingTask">
                            Cancelar
                        </button>
                        <button type="button" class="confirm-delete-btn" @click="deleteTask" :disabled="isDeletingTask">
                            {{ isDeletingTask ? 'Eliminando...' : 'Eliminar tarea' }}
                        </button>
                    </div>
                </div>
            </div>
        </Teleport>

        <div v-if="loading" class="loading-state">
            <div class="spinner"></div>
        </div>

        <div v-else-if="visibleTasks.length === 0" class="empty-state">
            <h3>{{ userRole === 'manager' ? 'No hay tareas en el tablero' : 'Aun no tienes tareas asignadas' }}</h3>
            <p>{{ userRole === 'manager' ? 'Crea la primera tarea o asignala desde el panel de asignaciones.' : 'Aun asi puedes ver el tablero completo para ubicar en que etapa iran apareciendo tus tareas.' }}</p>
        </div>

        <div v-if="!loading" class="kanban-board">
            <section
                v-for="column in groupedColumns"
                :key="column.id"
                class="kanban-column"
                :class="getColumnAccent(column.label)"
                @dragover.prevent
                @drop="moveTask(draggingTaskId, column.id)"
            >
                <div class="column-header">
                    <div class="column-title">
                        <span class="column-dot"></span>
                        <h3>{{ column.label }}</h3>
                    </div>
                    <span class="column-count">{{ column.tasks.length }}</span>
                </div>

                <div class="column-body">
                    <article
                        v-for="task in column.tasks"
                        :key="task.id"
                        class="task-card"
                        :class="{ dragging: draggingTaskId === task.id, moving: movingTaskId === task.id }"
                        draggable="true"
                        @dragstart="handleDragStart(task.id)"
                        @dragend="handleDragEnd"
                    >
                        <div class="task-topline">
                            <span class="task-chip">{{ task.task_status?.label || column.label }}</span>
                            <span :class="getPriorityClass(task.priority)">{{ getPriorityLabel(task.priority) }}</span>
                        </div>

                        <h4>{{ task.title }}</h4>
                        <p>{{ task.description || 'Sin descripcion adicional.' }}</p>

                        <div class="task-assignee">
                            <div class="assignee-avatar">
                                {{ getAssignee(task).charAt(0) }}
                            </div>
                            <div>
                                <strong>{{ getAssignee(task) }}</strong>
                                <small>{{ task.assignment?.assigned_at ? 'Asignada anteriormente' : 'Pendiente de asignacion' }}</small>
                            </div>
                        </div>

                        <div class="task-stats">
                            <span>{{ formatDueDate(task.due_date) }}</span>
                            <span>{{ Number(task.estimated_hours || 0) }}h estimadas</span>
                            <span>{{ task.story_points ?? 0 }}/3 pts</span>
                        </div>

                        <div class="task-footer">
                            <span>{{ task.assignment?.assigned_at ? 'Asignada' : 'Sin asignar' }}</span>
                            <span>{{ new Date(task.created_at).toLocaleDateString() }}</span>
                        </div>

                        <button
                            v-if="userRole === 'manager'"
                            type="button"
                            class="delete-task-btn"
                            @click.stop="openDeleteConfirmation(task)"
                            @mousedown.stop
                            draggable="false"
                            aria-label="Eliminar tarea"
                        >
                            <svg fill="none" viewBox="0 0 24 24" stroke-width="1.9" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166M19.228 5.79 18.16 19.673A2.25 2.25 0 0 1 15.916 21H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
                            </svg>
                        </button>
                    </article>

                    <div v-if="column.tasks.length === 0" class="empty-column">
                        {{ userRole === 'manager' ? 'Suelta una tarea aqui' : 'No tienes tareas en esta etapa todavia' }}
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<style scoped>
.kanban-container {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.board-hero {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding: 16px 18px;
    border: 1px solid #eef2f7;
    border-radius: 22px;
    background: #ffffff;
    color: #111827;
    box-shadow: 0 10px 24px rgba(15, 23, 42, 0.04);
}

.board-hero.developer {
    background: #ffffff;
}

.board-title {
    font-size: 20px;
    font-weight: 800;
    letter-spacing: -0.03em;
}

.board-subtitle {
    margin-top: 3px;
    max-width: 720px;
    font-size: 13px;
    line-height: 1.45;
    color: #64748b;
}

.board-meta-wrap {
    display: flex;
    gap: 10px;
    flex-wrap: wrap;
}

.board-meta {
    padding: 8px 13px;
    border-radius: 999px;
    background: #f1f5f9;
    color: #334155;
    font-size: 12px;
    font-weight: 800;
}

.board-meta.ghost {
    background: #ecfdf5;
    color: #166534;
}

.create-task-bar {
    display: flex;
    gap: 12px;
    background: #ffffff;
    border: 1px solid #eef2f7;
    border-radius: 22px;
    padding: 12px;
    box-shadow: 0 10px 24px rgba(15, 23, 42, 0.04);
}

.task-input {
    flex: 1;
    border: none;
    outline: none;
    background: transparent;
    padding: 10px 12px;
    font-size: 14px;
    color: #111827;
}

.create-btn {
    background: #111827;
    color: #ffffff;
    border: none;
    border-radius: 16px;
    padding: 12px 18px;
    font-size: 14px;
    font-weight: 700;
    cursor: pointer;
}

.create-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
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

.empty-state {
    padding: 54px 24px;
    border: 1px dashed #cbd5e1;
    border-radius: 28px;
    background: linear-gradient(180deg, #ffffff, #f8fafc);
    text-align: center;
}

.empty-state h3 {
    font-size: 22px;
    font-weight: 800;
    color: #111827;
}

.empty-state p {
    margin-top: 8px;
    font-size: 14px;
    color: #6b7280;
}

.kanban-board {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 18px;
    align-items: start;
}

.kanban-column {
    min-height: 480px;
    padding: 16px;
    border-radius: 26px;
    border: 1px solid #e5e7eb;
    background:
        radial-gradient(circle at top, rgba(191, 219, 254, 0.22), transparent 34%),
        linear-gradient(180deg, #ffffff, #f8fafc);
    box-shadow: 0 16px 32px rgba(15, 23, 42, 0.05);
}

.kanban-column.amber {
    background:
        radial-gradient(circle at top, rgba(251, 191, 36, 0.18), transparent 36%),
        linear-gradient(180deg, #ffffff, #f8fafc);
}

.kanban-column.blue {
    background:
        radial-gradient(circle at top, rgba(96, 165, 250, 0.18), transparent 36%),
        linear-gradient(180deg, #ffffff, #f8fafc);
}

.kanban-column.pink {
    background:
        radial-gradient(circle at top, rgba(244, 114, 182, 0.16), transparent 36%),
        linear-gradient(180deg, #ffffff, #f8fafc);
}

.kanban-column.indigo {
    background:
        radial-gradient(circle at top, rgba(129, 140, 248, 0.16), transparent 36%),
        linear-gradient(180deg, #ffffff, #f8fafc);
}

.column-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding-bottom: 14px;
}

.column-title {
    display: inline-flex;
    align-items: center;
    gap: 10px;
}

.column-dot {
    width: 10px;
    height: 10px;
    border-radius: 999px;
    background: #818cf8;
    box-shadow: 0 0 0 6px rgba(129, 140, 248, 0.12);
}

.kanban-column.amber .column-dot {
    background: #f59e0b;
    box-shadow: 0 0 0 6px rgba(245, 158, 11, 0.14);
}

.kanban-column.blue .column-dot {
    background: #3b82f6;
    box-shadow: 0 0 0 6px rgba(59, 130, 246, 0.14);
}

.kanban-column.pink .column-dot {
    background: #ec4899;
    box-shadow: 0 0 0 6px rgba(236, 72, 153, 0.14);
}

.column-header h3 {
    font-size: 16px;
    font-weight: 800;
    color: #111827;
}

.column-count {
    min-width: 30px;
    height: 30px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 999px;
    background: #eef2ff;
    color: #4338ca;
    font-size: 12px;
    font-weight: 800;
}

.column-body {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.task-card {
    position: relative;
    background: rgba(255, 255, 255, 0.95);
    border: 1px solid #e5e7eb;
    border-radius: 22px;
    padding: 16px;
    cursor: grab;
    transition: transform 0.15s ease, box-shadow 0.2s ease, opacity 0.2s ease;
}

.task-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 16px 30px rgba(15, 23, 42, 0.08);
}

.task-card.dragging {
    opacity: 0.45;
}

.task-card.moving {
    border-color: #818cf8;
    box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.14);
}

.delete-task-btn {
    position: absolute;
    right: 12px;
    bottom: 12px;
    display: inline-flex;
    height: 34px;
    width: 34px;
    align-items: center;
    justify-content: center;
    border: 1px solid #fee2e2;
    border-radius: 12px;
    background: #fff7f7;
    color: #dc2626;
    opacity: 0;
    transition: opacity 0.2s ease, background 0.2s ease, color 0.2s ease, transform 0.2s ease;
}

.task-card:hover .delete-task-btn {
    opacity: 1;
}

.delete-task-btn:hover {
    transform: translateY(-1px);
    background: #dc2626;
    color: #ffffff;
}

.delete-task-btn svg {
    height: 17px;
    width: 17px;
}

.task-topline {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 10px;
}

.task-chip,
.priority-badge {
    display: inline-flex;
    align-items: center;
    border-radius: 999px;
    padding: 4px 9px;
    font-size: 10px;
    font-weight: 800;
    letter-spacing: 0.06em;
    text-transform: uppercase;
}

.task-chip {
    background: #eef2ff;
    color: #4338ca;
}

.priority-badge.medium {
    background: #fef3c7;
    color: #b45309;
}

.priority-badge.high {
    background: #fee2e2;
    color: #b91c1c;
}

.priority-badge.low {
    background: #e0e7ff;
    color: #4338ca;
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

.task-assignee {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-top: 14px;
}

.assignee-avatar {
    width: 36px;
    height: 36px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 12px;
    background: #111827;
    color: #ffffff;
    font-size: 13px;
    font-weight: 800;
    flex-shrink: 0;
}

.task-assignee strong {
    display: block;
    font-size: 13px;
    font-weight: 800;
    color: #111827;
}

.task-assignee small {
    font-size: 11px;
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

.task-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-top: 14px;
    padding-right: 36px;
    padding-top: 12px;
    border-top: 1px solid #eef2f7;
    font-size: 11px;
    font-weight: 700;
    color: #64748b;
}

.empty-column {
    border: 1px dashed #d1d5db;
    border-radius: 18px;
    padding: 18px 12px;
    text-align: center;
    color: #9ca3af;
    font-size: 13px;
}

.delete-modal-wrap {
    position: fixed;
    inset: 0;
    z-index: 80;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 22px;
}

.delete-overlay {
    position: absolute;
    inset: 0;
    background: rgba(15, 23, 42, 0.42);
    backdrop-filter: blur(5px);
}

.delete-modal {
    position: relative;
    z-index: 1;
    width: min(100%, 460px);
    border: 1px solid #fee2e2;
    border-radius: 28px;
    background: #ffffff;
    padding: 26px;
    box-shadow: 0 30px 90px rgba(15, 23, 42, 0.28);
}

.delete-icon {
    display: flex;
    height: 52px;
    width: 52px;
    align-items: center;
    justify-content: center;
    border-radius: 18px;
    background: #fef2f2;
    color: #dc2626;
}

.delete-icon svg {
    height: 24px;
    width: 24px;
}

.delete-modal h3 {
    margin-top: 18px;
    color: #111827;
    font-size: 24px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.delete-modal p {
    margin-top: 10px;
    color: #64748b;
    font-size: 14px;
    line-height: 1.6;
}

.delete-modal strong {
    color: #111827;
}

.delete-actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    margin-top: 22px;
}

.cancel-delete-btn,
.confirm-delete-btn {
    border-radius: 14px;
    padding: 12px 16px;
    font-size: 14px;
    font-weight: 800;
}

.cancel-delete-btn {
    border: 1px solid #d1d5db;
    background: #ffffff;
    color: #374151;
}

.confirm-delete-btn {
    border: 1px solid #dc2626;
    background: #dc2626;
    color: #ffffff;
}

.cancel-delete-btn:disabled,
.confirm-delete-btn:disabled {
    cursor: not-allowed;
    opacity: 0.6;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}

@media (max-width: 720px) {
    .board-hero,
    .create-task-bar {
        flex-direction: column;
        align-items: stretch;
    }

    .board-meta-wrap {
        width: 100%;
    }

    .delete-task-btn {
        position: static;
        width: 100%;
        margin-top: 12px;
        opacity: 1;
    }

    .task-footer {
        padding-right: 0;
    }

    .delete-actions {
        flex-direction: column;
    }
}
</style>
