<script setup>
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';

const props = defineProps({
    show: Boolean
});

const emit = defineEmits(['close', 'project-created']);

const form = ref({
    name: '',
    description: ''
});

const processing = ref(false);
const errorMsg = ref('');

const closeModal = () => {
    form.value.name = '';
    form.value.description = '';
    errorMsg.value = '';
    emit('close');
};

const submitProject = async () => {
    if (!form.value.name.trim()) {
        errorMsg.value = 'El nombre del proyecto es obligatorio.';
        return;
    }

    processing.value = true;
    errorMsg.value = '';

    try {
        // 1. Obtener la sesión actual para saber quién crea el proyecto
        const { data: { session }, error: sessionError } = await supabase.auth.getSession();
        if (sessionError || !session) throw new Error('No hay sesión activa. Por favor, inicia sesión nuevamente.');
        
        const userId = session.user.id;

        // 2. Insertar el Proyecto
        const { data: projectData, error: insertError } = await supabase
            .from('projects')
            .insert({
                name: form.value.name.trim(),
                description: form.value.description.trim() || null,
                status: 'active',
                created_by: userId
            })
            .select() // Pedir a Supabase que nos devuelva la fila insertada para obtener el ID
            .single();

        if (insertError) throw insertError;

        // 3. Asignar al creador como 'manager' en project_members
        const { error: memberError } = await supabase
            .from('project_members')
            .insert({
                project_id: projectData.id,
                user_id: userId,
                project_role: 'manager'
            });

        if (memberError) {
            // Rollback manual (opcional, pero buena práctica si falla el member)
            await supabase.from('projects').delete().eq('id', projectData.id);
            throw memberError;
        }

        // Éxito: Limpiar, cerrar y notificar al padre
        form.value.name = '';
        form.value.description = '';
        emit('project-created');
        emit('close');

    } catch (error) {
        console.error("Error al crear el proyecto:", error);
        errorMsg.value = error.message || 'Ocurrió un error inesperado al intentar crear el proyecto.';
    } finally {
        processing.value = false;
    }
};
</script>

<template>
    <div v-if="show" class="modal-backdrop">
        <!-- Overlay -->
        <div class="modal-overlay" @click="!processing && closeModal()"></div>

        <!-- Modal Content -->
        <div class="modal-container">
            <!-- Modal Header -->
            <div class="modal-header">
                <div class="header-icon">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 10.5v6m3-3H9m4.06-7.19-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25h-5.379a1.5 1.5 0 0 1-1.06-.44Z" />
                    </svg>
                </div>
                <div>
                    <h3 class="modal-title">Crear Nuevo Proyecto</h3>
                    <p class="modal-description">Agrega un nuevo espacio de trabajo para tu equipo.</p>
                </div>
            </div>

            <!-- Modal Body (Formulario) -->
            <div class="modal-body">
                
                <!-- Mensaje de Error -->
                <div v-if="errorMsg" class="error-alert">
                    {{ errorMsg }}
                </div>

                <div class="form-group">
                    <label for="projectName">Nombre del Proyecto <span class="required">*</span></label>
                    <input 
                        id="projectName" 
                        type="text" 
                        v-model="form.name"
                        placeholder="Ej. Rediseño de App Móvil"
                        :disabled="processing"
                        @keyup.enter="submitProject"
                        autofocus
                    />
                </div>

                <div class="form-group mt-4">
                    <label for="projectDesc">Descripción <span class="optional">(Opcional)</span></label>
                    <textarea 
                        id="projectDesc" 
                        v-model="form.description"
                        placeholder="Escribe un breve resumen de los objetivos del proyecto..."
                        rows="3"
                        :disabled="processing"
                    ></textarea>
                </div>
            </div>

            <!-- Modal Footer (Botones) -->
            <div class="modal-footer">
                <button type="button" class="btn-cancel" @click="closeModal" :disabled="processing">
                    Cancelar
                </button>
                <button type="button" class="btn-primary" @click="submitProject" :disabled="processing">
                    <span v-if="processing" class="loader"></span>
                    <span v-else>Crear Proyecto</span>
                </button>
            </div>
        </div>
    </div>
</template>

<style scoped>
/* Backdrop y Contenedor Principal */
.modal-backdrop {
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    z-index: 50;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 16px;
}

.modal-overlay {
    position: absolute;
    top: 0; left: 0; right: 0; bottom: 0;
    background-color: rgba(0, 0, 0, 0.4);
    backdrop-filter: blur(4px);
    transition: all 0.3s ease;
}

.modal-container {
    background-color: white;
    width: 100%;
    max-w-md: 480px; /* Ancho máximo premium */
    width: 480px;
    border-radius: 24px;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
    position: relative;
    z-index: 51;
    overflow: hidden;
    transform: translateY(0);
    animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slideUp {
    from { opacity: 0; transform: translateY(20px) scale(0.95); }
    to { opacity: 1; transform: translateY(0) scale(1); }
}

/* Header */
.modal-header {
    padding: 24px 32px 16px;
    display: flex;
    gap: 16px;
    align-items: flex-start;
}

.header-icon {
    width: 48px;
    height: 48px;
    flex-shrink: 0;
    background: #f3f4f6;
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #111827;
}

.header-icon svg {
    width: 24px;
    height: 24px;
}

.modal-title {
    font-size: 20px;
    font-weight: 700;
    color: #111827;
    margin: 0 0 4px 0;
    letter-spacing: -0.01em;
}

.modal-description {
    font-size: 14px;
    color: #6b7280;
    margin: 0;
    line-height: 1.5;
}

/* Body / Formulario */
.modal-body {
    padding: 16px 32px 24px;
}

.form-group label {
    display: block;
    font-size: 14px;
    font-weight: 600;
    color: #374151;
    margin-bottom: 8px;
}

.form-group .required { color: #ef4444; }
.form-group .optional { color: #9ca3af; font-weight: 400; font-size: 13px; }

.form-group input, 
.form-group textarea {
    width: 100%;
    background: #f9fafb;
    border: 1px solid #e5e7eb;
    border-radius: 12px;
    padding: 12px 16px;
    font-size: 15px;
    color: #111827;
    transition: all 0.2s;
    outline: none;
    box-sizing: border-box;
}

.form-group input:focus, 
.form-group textarea:focus {
    background: #ffffff;
    border-color: #111827;
    box-shadow: 0 0 0 4px rgba(17, 24, 39, 0.05);
}

.form-group textarea {
    resize: none;
}

.mt-4 { margin-top: 16px; }

.error-alert {
    background: #fef2f2;
    border: 1px solid #fecaca;
    color: #b91c1c;
    padding: 12px 16px;
    border-radius: 12px;
    font-size: 14px;
    margin-bottom: 16px;
    font-weight: 500;
}

/* Footer / Botones */
.modal-footer {
    padding: 20px 32px;
    background: #f9fafb;
    border-top: 1px solid #f3f4f6;
    display: flex;
    justify-content: flex-end;
    gap: 12px;
}

.btn-cancel, .btn-primary {
    padding: 10px 20px;
    border-radius: 10px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 100px;
}

.btn-cancel {
    background: white;
    border: 1px solid #d1d5db;
    color: #374151;
}

.btn-cancel:hover:not(:disabled) {
    background: #f3f4f6;
    color: #111827;
}

.btn-primary {
    background: #111827;
    border: 1px solid #111827;
    color: #ffffff;
}

.btn-primary:hover:not(:disabled) {
    background: #000000;
    transform: translateY(-1px);
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.btn-primary:disabled, .btn-cancel:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

/* Spinner animado para cargar */
.loader {
    width: 18px;
    height: 18px;
    border: 2px solid rgba(255,255,255,0.3);
    border-radius: 50%;
    border-top-color: #fff;
    animation: spin 0.8s ease-in-out infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}
</style>
