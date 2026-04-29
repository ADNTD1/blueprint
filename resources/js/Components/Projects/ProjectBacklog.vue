<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import DatePicker from '@/Components/DatePicker.vue';
import { supabase } from '@/lib/supabase';

const props = defineProps({
    projectId: {
        type: String,
        required: true,
    },
    canCreate: {
        type: Boolean,
        default: false,
    },
});

const fallbackStatuses = [
    { id: 1, code: 'pending', label: 'Pendiente', sort_order: 1 },
    { id: 2, code: 'in_progress', label: 'En progreso', sort_order: 2 },
    { id: 3, code: 'completed', label: 'Completada', sort_order: 3 },
];

const priorityOptions = [
    { value: 'low', label: 'Baja' },
    { value: 'medium', label: 'Media' },
    { value: 'high', label: 'Alta' },
];

const createEmptyTaskForm = () => ({
    title: '',
    description: '',
    priority: 'medium',
    estimated_hours: 1,
    story_points: '',
    due_date: '',
    status_id: null,
});

const tasks = ref([]);
const statuses = ref([]);
const loading = ref(true);
const isAddingTask = ref(false);
const isDeletingTask = ref(false);
const showTaskForm = ref(false);
const errorMsg = ref('');
const successMsg = ref('');
const taskForm = ref(createEmptyTaskForm());
const taskToDelete = ref(null);
const searchQuery = ref('');
const selectedPriority = ref('all');
const selectedStatus = ref('all');
let backlogChannel = null;

const availableStatuses = computed(() =>
    statuses.value.length > 0 ? statuses.value : fallbackStatuses
);

const statusMap = computed(() =>
    new Map(availableStatuses.value.map((status) => [status.id, status]))
);

const backlogSummary = computed(() => ({
    total: tasks.value.length,
    high: tasks.value.filter((task) => task.priority === 'high').length,
    pending: tasks.value.filter((task) => {
        const label = getTaskStatus(task)?.label?.toLowerCase?.() || '';
        return label.includes('pending') || label.includes('pendiente');
    }).length,
    hours: tasks.value.reduce((total, task) => total + Number(task.estimated_hours || 0), 0),
}));

const filteredTasks = computed(() => {
    const query = searchQuery.value.trim().toLowerCase();

    return tasks.value.filter((task) => {
        const status = getTaskStatus(task);
        const matchesQuery = !query
            || task.title?.toLowerCase?.().includes(query)
            || task.description?.toLowerCase?.().includes(query);
        const matchesPriority = selectedPriority.value === 'all' || task.priority === selectedPriority.value;
        const matchesStatus = selectedStatus.value === 'all' || task.status_id === Number(selectedStatus.value);

        return matchesQuery && matchesPriority && matchesStatus && status;
    });
});

const setDefaultStatus = () => {
    if (taskForm.value.status_id) return;

    const pendingStatus = availableStatuses.value.find((status) => status.code === 'pending');
    taskForm.value.status_id = pendingStatus?.id || availableStatuses.value[0]?.id || 1;
};

const resetTaskForm = () => {
    taskForm.value = createEmptyTaskForm();
    setDefaultStatus();
};

const getTaskStatus = (task) => {
    return task.task_status || statusMap.value.get(task.status_id) || null;
};

const fetchBacklog = async () => {
    loading.value = true;
    errorMsg.value = '';

    try {
        const [{ data: taskData, error: taskError }, { data: statusData, error: statusError }] = await Promise.all([
            supabase
                .from('tasks')
                .select(`
                    *,
                    task_status (label)
                `)
                .eq('project_id', props.projectId)
                .order('created_at', { ascending: false }),
            supabase
                .from('task_status')
                .select('id, code, label, sort_order')
                .order('sort_order', { ascending: true }),
        ]);

        if (taskError) throw taskError;
        if (statusError) throw statusError;

        tasks.value = taskData || [];
        statuses.value = statusData?.length ? statusData : fallbackStatuses;
        setDefaultStatus();
    } catch (err) {
        console.error('Error fetching backlog:', err);
        errorMsg.value = err.message || 'No se pudo cargar el backlog.';
    } finally {
        loading.value = false;
    }
};

const addTask = async () => {
    if (!props.canCreate || !taskForm.value.title.trim()) return;

    isAddingTask.value = true;
    errorMsg.value = '';
    successMsg.value = '';

    try {
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        if (sessionError) throw sessionError;
        if (!session?.user) throw new Error('No hay sesion activa.');

        const estimatedHours = Number(taskForm.value.estimated_hours);
        const storyPoints = taskForm.value.story_points === '' ? null : Number(taskForm.value.story_points);

        if (Number.isNaN(estimatedHours) || estimatedHours < 0) {
            throw new Error('Las horas estimadas deben ser un numero mayor o igual a 0.');
        }

        if (storyPoints !== null && (Number.isNaN(storyPoints) || storyPoints < 0)) {
            throw new Error('Los story points deben ser un numero mayor o igual a 0.');
        }

        if (isPastDate(taskForm.value.due_date)) {
            throw new Error('La fecha limite no puede ser anterior a hoy.');
        }

        const payload = {
            project_id: props.projectId,
            title: taskForm.value.title.trim(),
            description: taskForm.value.description.trim() || null,
            priority: taskForm.value.priority,
            estimated_hours: estimatedHours,
            story_points: storyPoints,
            due_date: taskForm.value.due_date || null,
            status_id: taskForm.value.status_id || availableStatuses.value[0]?.id || 1,
            created_by: session.user.id,
        };

        const { error } = await supabase
            .from('tasks')
            .insert(payload);

        if (error) throw error;

        successMsg.value = 'La tarea se agrego correctamente al backlog.';
        resetTaskForm();
        showTaskForm.value = false;
        await fetchBacklog();
    } catch (err) {
        console.error('Error creating task:', err);
        errorMsg.value = err.message || 'No se pudo crear la tarea.';
    } finally {
        isAddingTask.value = false;
    }
};

const openDeleteConfirmation = (task) => {
    if (!props.canCreate) return;

    errorMsg.value = '';
    successMsg.value = '';
    taskToDelete.value = task;
};

const closeDeleteConfirmation = () => {
    if (isDeletingTask.value) return;
    taskToDelete.value = null;
};

const deleteTask = async () => {
    if (!props.canCreate || !taskToDelete.value) return;

    isDeletingTask.value = true;
    errorMsg.value = '';
    successMsg.value = '';

    try {
        const deletedTitle = taskToDelete.value.title;

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

        successMsg.value = `La tarea "${deletedTitle}" fue eliminada.`;
        taskToDelete.value = null;
        await fetchBacklog();
    } catch (err) {
        console.error('Error deleting task:', err);
        errorMsg.value = err.message || 'No se pudo eliminar la tarea.';
    } finally {
        isDeletingTask.value = false;
    }
};

const getStatusClass = (statusLabel) => {
    switch (statusLabel?.toLowerCase()) {
        case 'pending':
        case 'pendiente':
            return 'status-pill pending';
        case 'in progress':
        case 'en progreso':
            return 'status-pill progress';
        case 'completed':
        case 'completada':
            return 'status-pill completed';
        default:
            return 'status-pill neutral';
    }
};

const getPriorityClass = (priority) => {
    switch (priority) {
        case 'high':
            return 'priority-chip high';
        case 'low':
            return 'priority-chip low';
        default:
            return 'priority-chip medium';
    }
};

const getPriorityLabel = (priority) => {
    return priorityOptions.find((option) => option.value === priority)?.label || 'Media';
};

const isPastDate = (value) => {
    if (!value) return false;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const selected = new Date(`${value}T00:00:00`);
    selected.setHours(0, 0, 0, 0);

    return selected < today;
};

const formatDueDate = (value) => {
    if (!value) return 'Sin fecha';
    return new Date(`${value}T00:00:00`).toLocaleDateString();
};

onMounted(() => {
    fetchBacklog();

    backlogChannel = supabase
        .channel(`project-backlog-${props.projectId}`)
        .on(
            'postgres_changes',
            {
                event: '*',
                schema: 'public',
                table: 'tasks',
                filter: `project_id=eq.${props.projectId}`,
            },
            () => {
                fetchBacklog();
            }
        )
        .on(
            'postgres_changes',
            {
                event: '*',
                schema: 'public',
                table: 'task_status',
            },
            () => {
                fetchBacklog();
            }
        )
        .subscribe();
});

onUnmounted(() => {
    if (backlogChannel) {
        supabase.removeChannel(backlogChannel);
        backlogChannel = null;
    }
});
</script>

<template>
    <div class="backlog-container">
        <div class="section-header">
            <div>
                <h2>Backlog del proyecto</h2>
                <p>Captura, filtra y prepara tareas completas antes de asignarlas al equipo.</p>
            </div>
            <div class="header-actions">
                <span class="tasks-counter">{{ filteredTasks.length }} visibles</span>
                <button
                    v-if="canCreate"
                    type="button"
                    class="toggle-form-btn"
                    @click="showTaskForm = !showTaskForm"
                >
                    {{ showTaskForm ? 'Cerrar formulario' : 'Nueva tarea completa' }}
                </button>
            </div>
        </div>

        <div class="summary-grid">
            <article>
                <span>Total</span>
                <strong>{{ backlogSummary.total }}</strong>
                <p>tareas registradas</p>
            </article>
            <article>
                <span>Alta prioridad</span>
                <strong>{{ backlogSummary.high }}</strong>
                <p>requieren atencion</p>
            </article>
            <article>
                <span>Pendientes</span>
                <strong>{{ backlogSummary.pending }}</strong>
                <p>listas para iniciar</p>
            </article>
            <article>
                <span>Estimacion</span>
                <strong>{{ backlogSummary.hours }}h</strong>
                <p>trabajo planeado</p>
            </article>
        </div>

        <Teleport to="body">
            <div v-if="canCreate && showTaskForm" class="task-modal-wrap">
                <div class="task-modal-overlay" @click="!isAddingTask && (showTaskForm = false)"></div>

                <div class="task-form-card task-modal">
                    <div class="form-heading">
                        <div>
                            <span>Nueva tarea</span>
                            <h3>Crear tarea para el backlog</h3>
                            <p>Completa la informacion necesaria antes de asignarla al equipo.</p>
                        </div>
                        <button
                            type="button"
                            class="close-modal-btn"
                            @click="showTaskForm = false"
                            :disabled="isAddingTask"
                            aria-label="Cerrar formulario"
                        >
                            <svg fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
                            </svg>
                        </button>
                    </div>

                    <div class="form-grid">
                        <label class="field field-wide">
                            <span>Titulo</span>
                            <input
                                v-model="taskForm.title"
                                type="text"
                                placeholder="Ej. Implementar autenticacion con Supabase"
                                :disabled="isAddingTask"
                            />
                        </label>

                        <label class="field field-wide">
                            <span>Descripcion</span>
                            <textarea
                                v-model="taskForm.description"
                                rows="4"
                                placeholder="Describe el alcance, criterios de aceptacion o notas tecnicas."
                                :disabled="isAddingTask"
                            ></textarea>
                        </label>

                        <label class="field">
                            <span>Estado</span>
                            <select v-model="taskForm.status_id" :disabled="isAddingTask">
                                <option v-for="status in availableStatuses" :key="status.id" :value="status.id">
                                    {{ status.label }}
                                </option>
                            </select>
                        </label>

                        <label class="field">
                            <span>Prioridad</span>
                            <select v-model="taskForm.priority" :disabled="isAddingTask">
                                <option v-for="option in priorityOptions" :key="option.value" :value="option.value">
                                    {{ option.label }}
                                </option>
                            </select>
                        </label>

                        <label class="field">
                            <span>Horas estimadas</span>
                            <input
                                v-model="taskForm.estimated_hours"
                                type="number"
                                min="0"
                                step="0.5"
                                :disabled="isAddingTask"
                            />
                        </label>

                        <label class="field">
                            <span>Story points</span>
                            <input
                                v-model="taskForm.story_points"
                                type="number"
                                min="0"
                                step="1"
                                placeholder="Opcional"
                                :disabled="isAddingTask"
                            />
                        </label>

                        <label class="field">
                            <span>Fecha limite</span>
                            <DatePicker
                                v-model="taskForm.due_date"
                                placeholder="Selecciona una fecha"
                                :disabled="isAddingTask"
                            />
                        </label>
                    </div>

                    <div class="form-footer">
                        <button type="button" class="secondary-btn" @click="resetTaskForm" :disabled="isAddingTask">
                            Limpiar
                        </button>
                        <button
                            type="button"
                            class="primary-btn"
                            @click="addTask"
                            :disabled="!taskForm.title.trim() || isAddingTask"
                        >
                            {{ isAddingTask ? 'Guardando...' : 'Guardar tarea' }}
                        </button>
                    </div>
                </div>
            </div>
        </Teleport>

        <Teleport to="body">
            <div v-if="canCreate && taskToDelete" class="task-modal-wrap">
                <div class="task-modal-overlay" @click="closeDeleteConfirmation"></div>

                <div class="delete-modal">
                    <div class="delete-icon">
                        <svg fill="none" viewBox="0 0 24 24" stroke-width="1.9" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166M19.228 5.79 18.16 19.673A2.25 2.25 0 0 1 15.916 21H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
                        </svg>
                    </div>
                    <h3>Eliminar tarea</h3>
                    <p>
                        Vas a eliminar <strong>{{ taskToDelete.title }}</strong>. Esta accion tambien quitara sus asignaciones y no se puede deshacer.
                    </p>

                    <div class="delete-actions">
                        <button type="button" class="secondary-btn" @click="closeDeleteConfirmation" :disabled="isDeletingTask">
                            Cancelar
                        </button>
                        <button type="button" class="danger-btn" @click="deleteTask" :disabled="isDeletingTask">
                            {{ isDeletingTask ? 'Eliminando...' : 'Eliminar tarea' }}
                        </button>
                    </div>
                </div>
            </div>
        </Teleport>

        <div v-if="!canCreate" class="readonly-banner">
            Solo un manager puede crear tareas manuales. Tu vista sigue mostrando el backlog completo del proyecto.
        </div>

        <p v-if="errorMsg" class="feedback error">{{ errorMsg }}</p>
        <p v-if="successMsg" class="feedback success">{{ successMsg }}</p>

        <div class="filters-card">
            <div class="search-box">
                <svg fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="m21 21-4.35-4.35M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z" />
                </svg>
                <input v-model="searchQuery" type="search" placeholder="Buscar por titulo o descripcion..." />
            </div>
            <select v-model="selectedPriority">
                <option value="all">Todas las prioridades</option>
                <option v-for="option in priorityOptions" :key="option.value" :value="option.value">
                    Prioridad {{ option.label }}
                </option>
            </select>
            <select v-model="selectedStatus">
                <option value="all">Todos los estados</option>
                <option v-for="status in availableStatuses" :key="status.id" :value="status.id">
                    {{ status.label }}
                </option>
            </select>
        </div>

        <div v-if="loading" class="loading-state">
            <div class="spinner"></div>
        </div>

        <div v-else-if="filteredTasks.length > 0" class="tasks-list">
            <article v-for="task in filteredTasks" :key="task.id" class="task-row">
                <div class="task-main">
                    <div class="task-topline">
                        <span :class="getStatusClass(getTaskStatus(task)?.label)">
                            {{ getTaskStatus(task)?.label || 'Sin estado' }}
                        </span>
                        <span :class="getPriorityClass(task.priority)">
                            {{ getPriorityLabel(task.priority) }}
                        </span>
                    </div>

                    <h4>{{ task.title }}</h4>
                    <p>{{ task.description || 'Sin descripcion adicional.' }}</p>

                    <div class="task-meta">
                        <span>{{ Number(task.estimated_hours || 0) }}h estimadas</span>
                        <span>{{ task.story_points ?? 0 }} pts</span>
                        <span>{{ formatDueDate(task.due_date) }}</span>
                        <span>Creada el {{ new Date(task.created_at).toLocaleDateString() }}</span>
                    </div>
                </div>
                <button
                    v-if="canCreate"
                    type="button"
                    class="delete-task-btn"
                    @click="openDeleteConfirmation(task)"
                    aria-label="Eliminar tarea"
                >
                    <svg fill="none" viewBox="0 0 24 24" stroke-width="1.9" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166M19.228 5.79 18.16 19.673A2.25 2.25 0 0 1 15.916 21H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
                    </svg>
                </button>
            </article>
        </div>

        <div v-else class="empty-state">
            <h4>{{ tasks.length ? 'Sin resultados' : 'Tu backlog esta vacio' }}</h4>
            <p>{{ tasks.length ? 'Ajusta los filtros para volver a ver tareas.' : 'Crea la primera tarea completa desde el formulario para empezar a estructurar el trabajo.' }}</p>
        </div>
    </div>
</template>

<style scoped>
.backlog-container {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.section-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 16px;
}

.section-header h2 {
    font-size: 28px;
    font-weight: 800;
    color: #111827;
    letter-spacing: -0.03em;
}

.section-header p {
    margin-top: 8px;
    max-width: 720px;
    font-size: 14px;
    line-height: 1.6;
    color: #6b7280;
}

.header-actions {
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
}

.summary-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
}

.summary-grid article {
    border: 1px solid #eef2f7;
    border-radius: 22px;
    background: #ffffff;
    padding: 18px;
    box-shadow: 0 12px 28px rgba(15, 23, 42, 0.04);
}

.summary-grid span {
    color: #64748b;
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.08em;
    text-transform: uppercase;
}

.summary-grid strong {
    display: block;
    margin-top: 10px;
    color: #111827;
    font-size: 30px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.summary-grid p {
    margin-top: 2px;
    color: #94a3b8;
    font-size: 13px;
    font-weight: 700;
}

.tasks-counter {
    padding: 8px 12px;
    border-radius: 999px;
    background: #f3f4f6;
    color: #374151;
    font-size: 13px;
    font-weight: 700;
}

.filters-card {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 210px 200px;
    gap: 12px;
    border: 1px solid #e5e7eb;
    border-radius: 22px;
    background: #ffffff;
    padding: 12px;
    box-shadow: 0 12px 28px rgba(15, 23, 42, 0.04);
}

.search-box {
    display: flex;
    align-items: center;
    gap: 10px;
    border-radius: 16px;
    background: #f8fafc;
    padding: 0 14px;
}

.search-box svg {
    height: 18px;
    width: 18px;
    color: #64748b;
}

.search-box input,
.filters-card select {
    width: 100%;
    border: 0;
    background: transparent;
    color: #111827;
    font-size: 14px;
    outline: none;
}

.filters-card select {
    border-radius: 16px;
    background: #f8fafc;
    padding: 12px 40px 12px 14px;
    font-weight: 700;
}

.filters-card select,
.field select {
    appearance: none;
    background-image:
        linear-gradient(45deg, transparent 50%, #64748b 50%),
        linear-gradient(135deg, #64748b 50%, transparent 50%);
    background-position:
        calc(100% - 18px) calc(50% - 3px),
        calc(100% - 13px) calc(50% - 3px);
    background-size: 5px 5px, 5px 5px;
    background-repeat: no-repeat;
    cursor: pointer;
}

.filters-card select option,
.field select option {
    background: #ffffff;
    color: #111827;
}

.toggle-form-btn,
.primary-btn,
.secondary-btn {
    border-radius: 14px;
    padding: 12px 16px;
    font-size: 14px;
    font-weight: 700;
}

.toggle-form-btn,
.primary-btn {
    border: 1px solid #111827;
    background: #111827;
    color: #ffffff;
}

.secondary-btn {
    border: 1px solid #d1d5db;
    background: #ffffff;
    color: #374151;
}

.danger-btn {
    border-radius: 14px;
    border: 1px solid #dc2626;
    background: #dc2626;
    color: #ffffff;
    padding: 12px 16px;
    font-size: 14px;
    font-weight: 800;
}

.danger-btn:disabled {
    cursor: not-allowed;
    opacity: 0.6;
}

.task-form-card,
.readonly-banner,
.task-row,
.empty-state {
    background: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 24px;
    box-shadow: 0 12px 28px rgba(15, 23, 42, 0.04);
}

.task-form-card {
    padding: 24px;
}

.task-modal-wrap {
    position: fixed;
    inset: 0;
    z-index: 80;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 22px;
}

.task-modal-overlay {
    position: absolute;
    inset: 0;
    background: rgba(15, 23, 42, 0.42);
    backdrop-filter: blur(5px);
}

.task-modal {
    position: relative;
    z-index: 1;
    width: min(100%, 760px);
    max-height: min(86vh, 820px);
    overflow-y: auto;
    border-radius: 30px;
    box-shadow: 0 30px 90px rgba(15, 23, 42, 0.28);
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

.form-heading {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 18px;
}

.form-heading span {
    color: #64748b;
    font-size: 11px;
    font-weight: 900;
    letter-spacing: 0.14em;
    text-transform: uppercase;
}

.form-heading h3 {
    margin-top: 8px;
    font-size: 20px;
    font-weight: 900;
    color: #111827;
    letter-spacing: -0.03em;
}

.form-heading p {
    margin-top: 8px;
    font-size: 14px;
    color: #6b7280;
}

.close-modal-btn {
    display: flex;
    height: 42px;
    width: 42px;
    flex: none;
    align-items: center;
    justify-content: center;
    border: 1px solid #e5e7eb;
    border-radius: 14px;
    background: #ffffff;
    color: #475569;
    transition: background 0.2s ease, color 0.2s ease;
}

.close-modal-btn:hover:not(:disabled) {
    background: #111827;
    color: #ffffff;
}

.close-modal-btn svg {
    height: 19px;
    width: 19px;
}

.form-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
    margin-top: 20px;
}

.field {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.field-wide {
    grid-column: 1 / -1;
}

.field span {
    font-size: 13px;
    font-weight: 700;
    color: #374151;
}

.field input,
.field select,
.field textarea {
    width: 100%;
    border: 1px solid #d1d5db;
    border-radius: 14px;
    padding: 12px 40px 12px 14px;
    background: #ffffff;
    color: #111827;
    outline: none;
}

.field textarea {
    resize: vertical;
    padding-right: 14px;
}

.field input:focus,
.field select:focus,
.field textarea:focus {
    border-color: #818cf8;
    box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.12);
}

.form-footer {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    margin-top: 20px;
}

.readonly-banner {
    padding: 16px 18px;
    font-size: 14px;
    line-height: 1.6;
    color: #4b5563;
}

.feedback {
    padding: 12px 14px;
    border-radius: 14px;
    font-size: 14px;
    font-weight: 600;
}

.feedback.error {
    background: #fef2f2;
    border: 1px solid #fecaca;
    color: #b91c1c;
}

.feedback.success {
    background: #ecfdf5;
    border: 1px solid #a7f3d0;
    color: #047857;
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

.tasks-list {
    display: flex;
    flex-direction: column;
    gap: 14px;
}

.task-row {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: 14px;
    align-items: start;
    padding: 18px;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.task-row:hover {
    transform: translateY(-2px);
    box-shadow: 0 16px 34px rgba(15, 23, 42, 0.07);
}

.task-main {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.task-topline {
    display: flex;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
}

.status-pill,
.priority-chip {
    display: inline-flex;
    align-items: center;
    padding: 4px 10px;
    border-radius: 999px;
    font-size: 11px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.status-pill.pending {
    background: #fef3c7;
    color: #b45309;
}

.status-pill.progress {
    background: #dbeafe;
    color: #1d4ed8;
}

.status-pill.completed {
    background: #dcfce7;
    color: #15803d;
}

.status-pill.neutral {
    background: #f3f4f6;
    color: #4b5563;
}

.priority-chip.high {
    background: #fee2e2;
    color: #b91c1c;
}

.priority-chip.medium {
    background: #e0f2fe;
    color: #0369a1;
}

.priority-chip.low {
    background: #dcfce7;
    color: #15803d;
}

.task-row h4 {
    font-size: 18px;
    font-weight: 800;
    color: #111827;
}

.task-row p {
    font-size: 14px;
    line-height: 1.6;
    color: #6b7280;
}

.task-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
}

.task-meta span {
    padding: 6px 10px;
    border-radius: 10px;
    background: #f8fafc;
    font-size: 12px;
    font-weight: 700;
    color: #475569;
}

.delete-task-btn {
    display: inline-flex;
    height: 42px;
    width: 42px;
    align-items: center;
    justify-content: center;
    border: 1px solid #fee2e2;
    border-radius: 14px;
    background: #fff7f7;
    color: #dc2626;
    transition: background 0.2s ease, color 0.2s ease, transform 0.2s ease;
}

.delete-task-btn:hover {
    transform: translateY(-1px);
    background: #dc2626;
    color: #ffffff;
}

.delete-task-btn svg {
    height: 19px;
    width: 19px;
}

.empty-state {
    padding: 48px 24px;
    text-align: center;
}

.empty-state h4 {
    font-size: 18px;
    font-weight: 800;
    color: #111827;
}

.empty-state p {
    margin-top: 8px;
    font-size: 14px;
    color: #6b7280;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}

@media (max-width: 720px) {
    .section-header,
    .form-footer {
        flex-direction: column;
    }

    .header-actions {
        width: 100%;
    }

    .toggle-form-btn,
    .primary-btn,
    .secondary-btn,
    .danger-btn {
        width: 100%;
    }

    .form-grid {
        grid-template-columns: 1fr;
    }

    .summary-grid,
    .filters-card {
        grid-template-columns: 1fr;
    }

    .task-modal-wrap {
        align-items: flex-end;
        padding: 12px;
    }

    .task-modal {
        max-height: 92vh;
        border-radius: 24px;
    }

    .task-row {
        grid-template-columns: 1fr;
    }

    .delete-actions {
        flex-direction: column;
    }

    .delete-task-btn {
        width: 100%;
    }
}
</style>
