<script setup>
import axios from 'axios';
import { computed, nextTick, onMounted, ref, watch } from 'vue';
import { supabase } from '@/lib/supabase';

const props = defineProps({
    projectId: {
        type: String,
        required: true,
    },
    project: {
        type: Object,
        default: null,
    },
});

const messages = ref([
    {
        role: 'assistant',
        content: 'Hola. Soy tu copiloto de proyecto. Puedo ayudarte a convertir ideas en tareas, detectar riesgos, preparar una revision de sprint o redactar criterios de aceptacion.',
        meta: 'Blueprint AI',
    },
]);

const newMessage = ref('');
const isTyping = ref(false);
const chatContainer = ref(null);
const composerTextarea = ref(null);
const taskActionState = ref({});
const projectContext = ref(null);
const contextLoading = ref(false);

const suggestions = [
    {
        label: 'Resume el estado del proyecto',
        prompt: 'Resume el estado actual del proyecto con base en el contexto. Incluye avance, tareas por estado, prioridades, carga del equipo, proximos pasos y alertas. No inventes datos.',
    },
    {
        label: 'Genera tareas para el backlog',
        prompt: 'Genera tareas nuevas para el backlog tomando en cuenta las tareas existentes del contexto. Evita duplicar tareas iguales o muy similares. Devuelve solo JSON valido con el formato requerido para guardar en la tabla tasks.',
    },
    {
        label: 'Detecta riesgos del sprint',
        prompt: 'Detecta riesgos del sprint o del trabajo actual usando el contexto del proyecto. Agrupa por riesgo, impacto, senales tempranas y accion recomendada. Si ves tareas vencidas, sin asignar, de alta prioridad o bloqueos potenciales, mencionalos.',
    },
    {
        label: 'Escribe criterios de aceptacion',
        prompt: 'Escribe criterios de aceptacion profesionales para las tareas principales del proyecto segun el contexto. Usa formato Given/When/Then cuando aplique y evita crear tareas nuevas salvo que el usuario lo pida.',
    },
];

const capabilities = [
    {
        title: 'Backlog',
        description: 'Desglosa requerimientos en tareas claras con prioridad, estimacion y alcance.',
        icon: 'M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 0 1 0 3.75H5.625a1.875 1.875 0 0 1 0-3.75Z',
    },
    {
        title: 'Riesgos',
        description: 'Identifica bloqueos probables, dependencias y tareas sensibles.',
        icon: 'M12 9v3.75m0 3.75h.008v.008H12v-.008ZM10.29 3.86 1.82 18a2.25 2.25 0 0 0 1.93 3.38h16.5A2.25 2.25 0 0 0 22.18 18L13.71 3.86a2.25 2.25 0 0 0-3.42 0Z',
    },
    {
        title: 'Entrega',
        description: 'Prepara notas ejecutivas para seguimiento, demos y revisiones.',
        icon: 'M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z',
    },
];

const conversationCount = computed(() => messages.value.filter((message) => message.role === 'user').length);
const storageKey = computed(() => `blueprint-ai-chat:${props.projectId}`);
const taskActionStorageKey = computed(() => `blueprint-ai-task-actions:${props.projectId}`);
const contextSummary = computed(() => {
    if (contextLoading.value) return 'Actualizando contexto...';
    if (!projectContext.value) return 'Contexto pendiente';

    return `${projectContext.value.tasks.length} tareas, ${projectContext.value.members.length} miembros`;
});

const extractTasks = (content) => {
    if (!content || typeof content !== 'string') return null;

    const cleaned = content
        .trim()
        .replace(/^```json\s*/i, '')
        .replace(/^```\s*/i, '')
        .replace(/```$/i, '')
        .trim();

    const parsePayload = (value) => {
        try {
            const payload = JSON.parse(value);

            if (Array.isArray(payload)) return payload;
            if (Array.isArray(payload?.tasks)) return payload.tasks;

            return null;
        } catch {
            return null;
        }
    };

    const candidates = [cleaned];

    if (/^"title"\s*:/i.test(cleaned)) {
        candidates.push(`{"tasks":[{${cleaned}`);
    }

    const firstArray = cleaned.indexOf('[');
    const lastArray = cleaned.lastIndexOf(']');
    if (firstArray !== -1 && lastArray > firstArray) {
        candidates.push(cleaned.slice(firstArray, lastArray + 1));
    }

    const firstObject = cleaned.indexOf('{');
    const lastObject = cleaned.lastIndexOf('}');
    if (firstObject !== -1 && lastObject > firstObject) {
        candidates.push(cleaned.slice(firstObject, lastObject + 1));
    }

    for (const candidate of candidates) {
        const tasks = parsePayload(candidate);

        if (Array.isArray(tasks) && tasks.some((task) => task?.title)) {
            return tasks;
        }
    }

    return null;
};

const escapeHtml = (value) => String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');

const formatMarkdownText = (content) => {
    const escaped = escapeHtml(content);

    return escaped
        .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
        .replace(/\*(.+?)\*/g, '<em>$1</em>')
        .replace(/`(.+?)`/g, '<code>$1</code>')
        .replace(/^\s*[-*]\s+(.+)$/gm, '<span class="chat-list-item">$1</span>')
        .replace(/\n/g, '<br>');
};

const getPriorityLabel = (priority) => {
    const labels = {
        high: 'Alta',
        medium: 'Media',
        low: 'Baja',
    };

    return labels[priority] || 'Media';
};

const hashText = (value) => {
    const text = String(value || '');
    let hash = 0;

    for (let index = 0; index < text.length; index += 1) {
        hash = ((hash << 5) - hash) + text.charCodeAt(index);
        hash |= 0;
    }

    return Math.abs(hash).toString(36);
};

const getTaskActionKey = (message) => `tasks-${hashText(message?.content)}`;

const getTaskAction = (message) => taskActionState.value[getTaskActionKey(message)] || null;

const normalizeGeneratedTasks = (tasks) => {
    const allowedPriorities = ['low', 'medium', 'high'];

    return tasks.map((task) => ({
        title: String(task.title || '').trim(),
        description: String(task.description || '').trim() || null,
        priority: allowedPriorities.includes(task.priority) ? task.priority : 'medium',
        estimated_hours: Number.isFinite(Number(task.estimated_hours))
            ? Math.max(0, Number(task.estimated_hours))
            : 0,
        story_points: task.story_points === null || task.story_points === undefined
            ? null
            : Math.max(0, Number.parseInt(task.story_points, 10) || 0),
        due_date: !task.due_date || String(task.due_date).toLowerCase() === 'null' ? null : task.due_date,
        status_id: 1,
    })).filter((task) => task.title);
};

const normalizeAssignment = (assignment) => {
    if (Array.isArray(assignment)) return assignment[0] || null;
    return assignment || null;
};

const normalizeStatusLabel = (label, statusId) => {
    const labels = {
        1: 'Pendiente',
        2: 'En progreso',
        3: 'Completada',
    };

    return label || labels[statusId] || 'Sin estado';
};

const loadProjectContext = async () => {
    contextLoading.value = true;

    try {
        const [{ data: projectData }, { data: taskData, error: taskError }, { data: memberData, error: memberError }] = await Promise.all([
            props.project
                ? Promise.resolve({ data: props.project })
                : supabase
                    .from('projects')
                    .select('id, name, description, status, start_date, end_date, created_at')
                    .eq('id', props.projectId)
                    .single(),
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
                    task_status (label),
                    task_assignments (
                        developer_id,
                        profiles (name, email)
                    )
                `)
                .eq('project_id', props.projectId)
                .order('created_at', { ascending: false })
                .limit(80),
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

        projectContext.value = {
            project: {
                id: props.projectId,
                name: projectData?.name || 'Proyecto sin nombre',
                description: projectData?.description || null,
                status: projectData?.status || null,
                start_date: projectData?.start_date || null,
                end_date: projectData?.end_date || null,
            },
            tasks: (taskData || []).map((task) => {
                const assignment = normalizeAssignment(task.task_assignments);

                return {
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    status_id: task.status_id,
                    status: normalizeStatusLabel(task.task_status?.label, task.status_id),
                    priority: task.priority,
                    estimated_hours: Number(task.estimated_hours || 0),
                    story_points: task.story_points,
                    due_date: task.due_date,
                    assigned_to: assignment?.profiles?.name || assignment?.profiles?.email || null,
                };
            }),
            members: (memberData || []).map((member) => ({
                role: member.project_role,
                name: member.profiles?.name || member.profiles?.email || 'Sin nombre',
            })),
        };
    } catch (error) {
        console.error('Error loading AI context:', error);
        projectContext.value = {
            project: props.project || { id: props.projectId },
            tasks: [],
            members: [],
            context_error: 'No se pudo cargar el contexto completo del proyecto.',
        };
    } finally {
        contextLoading.value = false;
    }
};

const acceptGeneratedTasks = async (tasks, message) => {
    const actionKey = getTaskActionKey(message);

    if (taskActionState.value[actionKey]?.status === 'saving') return;

    taskActionState.value = {
        ...taskActionState.value,
        [actionKey]: { status: 'saving', message: 'Guardando tareas...' },
    };

    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session?.user?.id) {
            throw new Error('Tu sesion expiro. Inicia sesion nuevamente.');
        }

        const payload = normalizeGeneratedTasks(tasks).map((task) => ({
            ...task,
            project_id: props.projectId,
            created_by: session.user.id,
        }));

        if (!payload.length) {
            throw new Error('No hay tareas validas para guardar.');
        }

        const { error } = await supabase
            .from('tasks')
            .insert(payload);

        if (error) throw error;

        taskActionState.value = {
            ...taskActionState.value,
            [actionKey]: { status: 'accepted', message: `${payload.length} tareas agregadas al backlog.` },
        };
        await loadProjectContext();
    } catch (error) {
        taskActionState.value = {
            ...taskActionState.value,
            [actionKey]: { status: 'error', message: error.message || 'No se pudieron guardar las tareas.' },
        };
    }
};

const rejectGeneratedTasks = (message) => {
    const actionKey = getTaskActionKey(message);

    taskActionState.value = {
        ...taskActionState.value,
        [actionKey]: { status: 'rejected', message: 'Propuesta descartada.' },
    };
};

const scrollToBottom = async () => {
    await nextTick();
    if (chatContainer.value) {
        chatContainer.value.scrollTo({
            top: chatContainer.value.scrollHeight,
            behavior: 'smooth',
        });
    }
};

const resizeComposer = async () => {
    await nextTick();
    if (!composerTextarea.value) return;

    composerTextarea.value.style.height = 'auto';
    composerTextarea.value.style.height = `${Math.min(composerTextarea.value.scrollHeight, 148)}px`;
};

const sendMessage = async (preset = '') => {
    const presetConfig = typeof preset === 'object' && preset !== null ? preset : null;
    const content = (presetConfig?.prompt || preset || newMessage.value).trim();
    const visibleContent = (presetConfig?.label || content).trim();
    if (!content || isTyping.value) return;

    messages.value.push({
        role: 'user',
        content: visibleContent,
        meta: 'Tu',
    });
    newMessage.value = '';
    await resizeComposer();
    await scrollToBottom();

    isTyping.value = true;
    await scrollToBottom();

    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (!session?.access_token) {
            throw new Error('Tu sesion expiro. Inicia sesion nuevamente para usar el copiloto.');
        }

        const history = messages.value
            .filter((message) => ['user', 'assistant'].includes(message.role))
            .slice(0, -1)
            .slice(-8)
            .map((message) => ({
                role: message.role,
                content: message.content,
            }));

        const { data } = await axios.post(
            `/projects/${props.projectId}/ai-chat`,
            {
                message: content,
                messages: history,
            },
            {
                headers: {
                    Authorization: `Bearer ${session.access_token}`,
                },
            },
        );

        messages.value.push({
            role: 'assistant',
            content: data.reply,
            meta: 'Blueprint AI',
        });
        await loadProjectContext();
    } catch (error) {
        messages.value.push({
            role: 'assistant',
            content: error.response?.data?.message || error.message || 'No pude conectar con Groq en este momento.',
            meta: 'Blueprint AI',
        });
    } finally {
        isTyping.value = false;
        await scrollToBottom();
    }
};

onMounted(() => {
    try {
        const storedMessages = JSON.parse(sessionStorage.getItem(storageKey.value) || '[]');

        if (Array.isArray(storedMessages) && storedMessages.length) {
            messages.value = storedMessages
                .filter((message) => ['user', 'assistant'].includes(message.role) && typeof message.content === 'string')
                .slice(-30);
        }
    } catch {
        sessionStorage.removeItem(storageKey.value);
    }

    try {
        const storedTaskActions = JSON.parse(sessionStorage.getItem(taskActionStorageKey.value) || '{}');

        if (storedTaskActions && typeof storedTaskActions === 'object' && !Array.isArray(storedTaskActions)) {
            taskActionState.value = storedTaskActions;
        }
    } catch {
        sessionStorage.removeItem(taskActionStorageKey.value);
    }

    loadProjectContext();
    scrollToBottom();
});

watch(messages, (nextMessages) => {
    sessionStorage.setItem(storageKey.value, JSON.stringify(nextMessages.slice(-30)));
    scrollToBottom();
}, { deep: true });

watch(taskActionState, (nextState) => {
    sessionStorage.setItem(taskActionStorageKey.value, JSON.stringify(nextState));
}, { deep: true });

watch(isTyping, () => {
    scrollToBottom();
});
</script>

<template>
    <div class="ai-workspace">
        <aside class="ai-sidebar">
            <div class="assistant-card">
                <div class="assistant-mark">
                    <svg fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09Z" />
                    </svg>
                </div>
                <span>Copiloto del proyecto</span>
                <h2>Blueprint AI</h2>
                <p>Asistente para planear, revisar y comunicar el trabajo del equipo.</p>
            </div>

            <div class="ai-panel">
                <div class="panel-heading">
                    <h3>Capacidades</h3>
                    <span>Beta</span>
                </div>

                <div class="capability-list">
                    <article v-for="item in capabilities" :key="item.title" class="capability-item">
                        <div>
                            <svg fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" :d="item.icon" />
                            </svg>
                        </div>
                        <section>
                            <strong>{{ item.title }}</strong>
                            <p>{{ item.description }}</p>
                        </section>
                    </article>
                </div>
            </div>

            <div class="ai-panel compact">
                <span class="metric-label">Interacciones</span>
                <strong>{{ conversationCount }}</strong>
                <p>mensajes enviados en esta sesion</p>
            </div>
        </aside>

        <section class="chat-shell">
            <header class="chat-header">
                <div>
                    <span class="status-dot"></span>
                    <span class="status-text">Disponible</span>
                    <h3>Analista de proyecto</h3>
                    <p>Pregunta sobre tareas, riesgos, backlog o seguimiento ejecutivo.</p>
                </div>
                <div class="header-badge">
                    {{ contextSummary }}
                </div>
            </header>

            <div class="suggestion-row">
                <button
                    v-for="suggestion in suggestions"
                    :key="suggestion.label"
                    type="button"
                    @click="sendMessage(suggestion)"
                    :disabled="isTyping"
                >
                    {{ suggestion.label }}
                </button>
            </div>

            <div ref="chatContainer" class="messages-pane">
                <article
                    v-for="(message, index) in messages"
                    :key="`${message.role}-${index}`"
                    class="message-row"
                    :class="message.role"
                >
                    <div class="message-avatar">
                        {{ message.role === 'user' ? 'T' : 'AI' }}
                    </div>
                    <div class="message-bubble">
                        <div class="message-meta">
                            <strong>{{ message.meta }}</strong>
                            <span>{{ message.role === 'assistant' ? 'respuesta' : 'consulta' }}</span>
                        </div>
                        <div v-if="message.role === 'assistant' && extractTasks(message.content)" class="task-response">
                            <div class="task-response-head">
                                <div>
                                    <strong>Backlog sugerido</strong>
                                    <span>{{ extractTasks(message.content).length }} tareas generadas</span>
                                </div>
                                <small>JSON listo para guardar</small>
                            </div>

                            <div class="task-preview-list">
                                <article
                                    v-for="(task, taskIndex) in extractTasks(message.content)"
                                    :key="`${task.title}-${taskIndex}`"
                                    class="task-preview-card"
                                >
                                    <div class="task-preview-top">
                                        <span class="task-number">{{ taskIndex + 1 }}</span>
                                        <span class="task-priority" :class="task.priority">{{ getPriorityLabel(task.priority) }}</span>
                                    </div>
                                    <h4>{{ task.title }}</h4>
                                    <p>{{ task.description }}</p>
                                    <div class="task-preview-meta">
                                        <span>{{ Number(task.estimated_hours || 0) }}h</span>
                                        <span>{{ task.story_points ?? 0 }} pts</span>
                                        <span>{{ task.due_date || 'Sin fecha' }}</span>
                                    </div>
                                </article>
                            </div>

                            <div class="task-actions">
                                <p
                                    v-if="getTaskAction(message)?.message"
                                    class="task-action-message"
                                    :class="getTaskAction(message).status"
                                >
                                    {{ getTaskAction(message).message }}
                                </p>
                                <div v-if="!['accepted', 'rejected'].includes(getTaskAction(message)?.status)" class="task-action-buttons">
                                    <button
                                        type="button"
                                        class="reject-tasks-btn"
                                        @click="rejectGeneratedTasks(message)"
                                        :disabled="getTaskAction(message)?.status === 'saving'"
                                    >
                                        Rechazar
                                    </button>
                                    <button
                                        type="button"
                                        class="accept-tasks-btn"
                                        @click="acceptGeneratedTasks(extractTasks(message.content), message)"
                                        :disabled="getTaskAction(message)?.status === 'saving'"
                                    >
                                        {{ getTaskAction(message)?.status === 'saving' ? 'Guardando...' : 'Aceptar y guardar' }}
                                    </button>
                                </div>
                            </div>
                        </div>
                        <div
                            v-else
                            class="formatted-message"
                            v-html="formatMarkdownText(message.content)"
                        ></div>
                    </div>
                </article>

                <article v-if="isTyping" class="message-row assistant">
                    <div class="message-avatar">AI</div>
                    <div class="message-bubble typing-bubble">
                        <span></span>
                        <span></span>
                        <span></span>
                    </div>
                </article>
            </div>

            <footer class="composer">
                <div class="composer-input">
                    <textarea
                        ref="composerTextarea"
                        v-model="newMessage"
                        rows="1"
                        placeholder="Pide un resumen, tareas sugeridas o riesgos del proyecto..."
                        :disabled="isTyping"
                        @input="resizeComposer"
                        @keydown.enter.exact.prevent="sendMessage()"
                    ></textarea>
                </div>
                <button
                    type="button"
                    class="send-btn"
                    @click="sendMessage()"
                    :disabled="!newMessage.trim() || isTyping"
                    aria-label="Enviar mensaje"
                >
                    <svg fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 12 3.269 3.125A59.769 59.769 0 0 1 21.485 12 59.768 59.768 0 0 1 3.27 20.875L5.999 12Zm0 0h7.5" />
                    </svg>
                </button>
            </footer>
        </section>
    </div>
</template>

<style scoped>
.ai-workspace {
    display: grid;
    grid-template-columns: minmax(260px, 0.34fr) minmax(0, 1fr);
    align-items: start;
    gap: 20px;
}

.ai-sidebar,
.chat-shell {
    min-width: 0;
}

.ai-sidebar {
    display: flex;
    flex-direction: column;
    gap: 16px;
}

.assistant-card,
.ai-panel,
.chat-shell {
    border: 1px solid #eef2f7;
    background: #ffffff;
    box-shadow: 0 18px 42px rgba(15, 23, 42, 0.05);
}

.assistant-card {
    border-radius: 30px;
    padding: 24px;
    background:
        radial-gradient(circle at top right, rgba(121, 169, 212, 0.3), transparent 36%),
        linear-gradient(135deg, #111827, #1f2937);
    color: #ffffff;
}

.assistant-mark {
    display: flex;
    height: 52px;
    width: 52px;
    align-items: center;
    justify-content: center;
    border-radius: 17px;
    background: rgba(255, 255, 255, 0.12);
}

.assistant-mark svg {
    height: 25px;
    width: 25px;
}

.assistant-card span {
    display: block;
    margin-top: 22px;
    color: rgba(255, 255, 255, 0.68);
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.12em;
    text-transform: uppercase;
}

.assistant-card h2 {
    margin-top: 8px;
    font-size: 34px;
    font-weight: 900;
    letter-spacing: -0.05em;
}

.assistant-card p {
    margin-top: 10px;
    color: rgba(255, 255, 255, 0.72);
    font-size: 14px;
    line-height: 1.6;
}

.ai-panel {
    border-radius: 26px;
    padding: 20px;
}

.panel-heading {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;
}

.panel-heading h3 {
    color: #0f172a;
    font-size: 18px;
    font-weight: 900;
    letter-spacing: -0.03em;
}

.panel-heading span {
    border-radius: 999px;
    background: #ecfdf5;
    color: #166534;
    padding: 6px 10px;
    font-size: 11px;
    font-weight: 900;
}

.capability-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.capability-item {
    display: grid;
    grid-template-columns: 40px minmax(0, 1fr);
    gap: 12px;
    border-radius: 18px;
    background: #f8fafc;
    padding: 12px;
}

.capability-item > div {
    display: flex;
    height: 40px;
    width: 40px;
    align-items: center;
    justify-content: center;
    border-radius: 13px;
    background: #ffffff;
    color: #111827;
}

.capability-item svg {
    height: 20px;
    width: 20px;
}

.capability-item strong {
    color: #0f172a;
    font-size: 14px;
    font-weight: 900;
}

.capability-item p,
.ai-panel.compact p,
.chat-header p,
.message-meta span {
    color: #64748b;
}

.capability-item p {
    margin-top: 4px;
    font-size: 12px;
    line-height: 1.45;
}

.ai-panel.compact strong {
    display: block;
    margin-top: 8px;
    color: #0f172a;
    font-size: 34px;
    font-weight: 900;
    letter-spacing: -0.05em;
}

.metric-label {
    color: #64748b;
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.12em;
    text-transform: uppercase;
}

.ai-panel.compact p {
    font-size: 13px;
    font-weight: 700;
}

.chat-shell {
    display: flex;
    height: clamp(620px, calc(100vh - 230px), 760px);
    min-height: 0;
    max-height: 760px;
    overflow: hidden;
    flex-direction: column;
    border-radius: 30px;
}

.chat-header {
    display: flex;
    flex: none;
    align-items: flex-start;
    justify-content: space-between;
    gap: 20px;
    border-bottom: 1px solid #eef2f7;
    padding: 22px 24px;
}

.status-dot {
    display: inline-block;
    height: 9px;
    width: 9px;
    border-radius: 999px;
    background: #22c55e;
    box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.14);
}

.status-text {
    margin-left: 10px;
    color: #166534;
    font-size: 12px;
    font-weight: 900;
}

.chat-header h3 {
    margin-top: 8px;
    color: #0f172a;
    font-size: 26px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.chat-header p {
    margin-top: 4px;
    font-size: 14px;
}

.header-badge {
    border-radius: 999px;
    background: #f1f5f9;
    color: #334155;
    padding: 10px 14px;
    white-space: nowrap;
    font-size: 12px;
    font-weight: 900;
}

.suggestion-row {
    display: flex;
    flex: none;
    gap: 10px;
    overflow-x: auto;
    border-bottom: 1px solid #eef2f7;
    padding: 14px 24px;
    scrollbar-width: none;
}

.suggestion-row::-webkit-scrollbar {
    display: none;
}

.suggestion-row button {
    flex: none;
    border-radius: 999px;
    background: #f8fafc;
    color: #334155;
    padding: 10px 14px;
    font-size: 13px;
    font-weight: 800;
    transition: background 0.2s ease, color 0.2s ease;
}

.suggestion-row button:hover:not(:disabled) {
    background: #111827;
    color: #ffffff;
}

.suggestion-row button:disabled {
    opacity: 0.55;
}

.messages-pane {
    display: flex;
    flex: 1;
    min-height: 0;
    flex-direction: column;
    gap: 18px;
    overflow-y: auto;
    background: #fbfdff;
    padding: 24px;
    scroll-behavior: smooth;
}

.message-row {
    display: grid;
    grid-template-columns: 42px minmax(0, 0.78fr);
    gap: 12px;
    animation: fade-in 0.24s ease;
}

.message-row.user {
    grid-template-columns: minmax(0, 0.78fr) 42px;
    align-self: end;
}

.message-row.user .message-avatar {
    grid-column: 2;
    grid-row: 1;
    background: #ffffff;
    color: #111827;
}

.message-row.user .message-bubble {
    grid-column: 1;
    background: #111827;
    color: #ffffff;
}

.message-row.user .message-meta span,
.message-row.user .message-meta strong {
    color: rgba(255, 255, 255, 0.72);
}

.message-avatar {
    display: flex;
    height: 42px;
    width: 42px;
    align-items: center;
    justify-content: center;
    border-radius: 14px;
    background: #111827;
    color: #ffffff;
    font-size: 12px;
    font-weight: 900;
}

.message-bubble {
    border: 1px solid #eef2f7;
    border-radius: 22px;
    background: #ffffff;
    padding: 16px;
}

.message-meta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 8px;
}

.message-meta strong {
    color: #0f172a;
    font-size: 12px;
    font-weight: 900;
}

.message-meta span {
    font-size: 11px;
    font-weight: 800;
}

.message-bubble p,
.formatted-message {
    white-space: pre-line;
    font-size: 14px;
    line-height: 1.65;
}

.formatted-message :deep(strong) {
    font-weight: 900;
}

.formatted-message :deep(em) {
    font-style: italic;
}

.formatted-message :deep(code) {
    border-radius: 6px;
    background: rgba(15, 23, 42, 0.08);
    padding: 2px 5px;
    color: #0f172a;
    font-size: 0.92em;
    font-weight: 700;
}

.message-row.user .formatted-message :deep(code) {
    background: rgba(255, 255, 255, 0.16);
    color: #ffffff;
}

.formatted-message :deep(.chat-list-item) {
    display: block;
    position: relative;
    padding-left: 18px;
}

.formatted-message :deep(.chat-list-item)::before {
    content: '';
    position: absolute;
    left: 4px;
    top: 0.78em;
    width: 5px;
    height: 5px;
    border-radius: 999px;
    background: currentColor;
}

.task-response {
    display: flex;
    flex-direction: column;
    gap: 14px;
}

.task-response-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 14px;
    border-radius: 16px;
    background: #f8fafc;
    padding: 12px;
}

.task-response-head strong {
    display: block;
    color: #0f172a;
    font-size: 14px;
    font-weight: 900;
}

.task-response-head span,
.task-response-head small {
    color: #64748b;
    font-size: 12px;
    font-weight: 800;
}

.task-preview-list {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 10px;
}

.task-preview-card {
    border: 1px solid #e2e8f0;
    border-radius: 18px;
    background: #ffffff;
    padding: 13px;
}

.task-preview-top {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 10px;
}

.task-number {
    display: flex;
    height: 26px;
    width: 26px;
    align-items: center;
    justify-content: center;
    border-radius: 999px;
    background: #111827;
    color: #ffffff;
    font-size: 12px;
    font-weight: 900;
}

.task-priority {
    border-radius: 999px;
    padding: 5px 8px;
    font-size: 11px;
    font-weight: 900;
}

.task-priority.high {
    background: #fee2e2;
    color: #991b1b;
}

.task-priority.medium {
    background: #fef3c7;
    color: #92400e;
}

.task-priority.low {
    background: #e0e7ff;
    color: #3730a3;
}

.task-preview-card h4 {
    color: #0f172a;
    font-size: 14px;
    font-weight: 900;
    line-height: 1.35;
}

.task-preview-card p {
    margin-top: 6px;
    color: #64748b;
    font-size: 12px;
    line-height: 1.5;
}

.task-preview-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-top: 10px;
}

.task-preview-meta span {
    border-radius: 999px;
    background: #f1f5f9;
    color: #475569;
    padding: 5px 8px;
    font-size: 11px;
    font-weight: 800;
}

.task-actions {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    border-top: 1px solid #eef2f7;
    padding-top: 14px;
}

.task-action-buttons {
    display: flex;
    gap: 10px;
    margin-left: auto;
}

.accept-tasks-btn,
.reject-tasks-btn {
    border-radius: 14px;
    padding: 10px 14px;
    font-size: 13px;
    font-weight: 900;
    transition: opacity 0.2s ease, transform 0.2s ease;
}

.accept-tasks-btn {
    background: #111827;
    color: #ffffff;
}

.reject-tasks-btn {
    border: 1px solid #e2e8f0;
    background: #ffffff;
    color: #475569;
}

.accept-tasks-btn:hover:not(:disabled),
.reject-tasks-btn:hover:not(:disabled) {
    transform: translateY(-1px);
}

.accept-tasks-btn:disabled,
.reject-tasks-btn:disabled {
    cursor: not-allowed;
    opacity: 0.55;
}

.task-action-message {
    margin: 0;
    border-radius: 999px;
    padding: 8px 11px;
    font-size: 12px;
    font-weight: 900;
}

.task-action-message.accepted {
    background: #ecfdf5;
    color: #166534;
}

.task-action-message.rejected {
    background: #f1f5f9;
    color: #475569;
}

.task-action-message.error {
    background: #fef2f2;
    color: #991b1b;
}

.task-action-message.saving {
    background: #eff6ff;
    color: #1d4ed8;
}

.typing-bubble {
    display: inline-flex;
    width: max-content;
    gap: 6px;
}

.typing-bubble span {
    height: 8px;
    width: 8px;
    border-radius: 999px;
    background: #94a3b8;
    animation: bounce 0.9s infinite ease-in-out;
}

.typing-bubble span:nth-child(2) {
    animation-delay: 0.12s;
}

.typing-bubble span:nth-child(3) {
    animation-delay: 0.24s;
}

.composer {
    display: grid;
    flex: none;
    grid-template-columns: minmax(0, 1fr) 54px;
    gap: 12px;
    border-top: 1px solid #eef2f7;
    background: #ffffff;
    padding: 16px;
}

.composer-input {
    border: 1px solid #e2e8f0;
    border-radius: 20px;
    background: #f8fafc;
    padding: 13px 16px;
}

.composer-input textarea {
    display: block;
    width: 100%;
    min-height: 24px;
    max-height: 148px;
    resize: none;
    border: 0;
    background: transparent;
    color: #0f172a;
    font-size: 14px;
    line-height: 1.5;
    outline: none;
}

.send-btn {
    display: flex;
    height: 54px;
    width: 54px;
    align-items: center;
    justify-content: center;
    border-radius: 18px;
    background: #111827;
    color: #ffffff;
    transition: transform 0.2s ease, opacity 0.2s ease;
}

.send-btn:hover:not(:disabled) {
    transform: translateY(-1px);
}

.send-btn:disabled {
    opacity: 0.45;
}

.send-btn svg {
    height: 22px;
    width: 22px;
}

@keyframes fade-in {
    from {
        opacity: 0;
        transform: translateY(8px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

@keyframes bounce {
    0%,
    80%,
    100% {
        transform: translateY(0);
    }
    40% {
        transform: translateY(-5px);
    }
}

@media (max-width: 1024px) {
    .ai-workspace {
        grid-template-columns: 1fr;
    }

    .ai-sidebar {
        display: grid;
        grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr);
    }

    .ai-panel.compact {
        grid-column: 1 / -1;
    }
}

@media (max-width: 720px) {
    .ai-sidebar {
        display: flex;
    }

    .chat-shell {
        height: min(720px, calc(100vh - 180px));
        min-height: 0;
        border-radius: 24px;
    }

    .chat-header {
        flex-direction: column;
    }

    .message-row,
    .message-row.user {
        grid-template-columns: 36px minmax(0, 1fr);
        align-self: stretch;
    }

    .message-row.user .message-avatar {
        grid-column: 1;
    }

    .message-row.user .message-bubble {
        grid-column: 2;
    }

    .message-avatar {
        height: 36px;
        width: 36px;
    }

    .task-preview-list {
        grid-template-columns: 1fr;
    }

    .task-response-head {
        align-items: flex-start;
        flex-direction: column;
    }

    .task-actions,
    .task-action-buttons {
        align-items: stretch;
        flex-direction: column;
        width: 100%;
    }
}
</style>
