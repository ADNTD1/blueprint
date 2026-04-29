<script setup>
import { computed, ref, onMounted } from 'vue';
import { supabase } from '@/lib/supabase';

const props = defineProps({
    projectId: {
        type: String,
        required: true
    },
    canInvite: {
        type: Boolean,
        default: true
    }
});

const members = ref([]);
const loading = ref(true);
const inviteEmail = ref('');
const isInviting = ref(false);
const isRemoving = ref(false);
const memberToRemove = ref(null);
const currentUserId = ref(null);
const errorMsg = ref('');
const successMsg = ref('');

const managersCount = computed(() => members.value.filter((member) => member.project_role === 'manager').length);
const developersCount = computed(() => members.value.filter((member) => member.project_role === 'developer').length);

const formatDate = (value) => {
    if (!value) return 'Sin fecha';
    return new Date(value).toLocaleDateString('es-MX', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
    });
};

const fetchMembers = async () => {
    loading.value = true;
    errorMsg.value = '';

    try {
        const { data: { session } } = await supabase.auth.getSession();
        currentUserId.value = session?.user?.id || null;

        const { data, error } = await supabase
            .from('project_members')
            .select(`
                *,
                profiles (name, email, avatar_url)
            `)
            .eq('project_id', props.projectId);

        if (error) throw error;
        members.value = data || [];
    } catch (err) {
        console.error('Error fetching members:', err);
        errorMsg.value = 'No se pudo cargar el equipo del proyecto.';
    } finally {
        loading.value = false;
    }
};

const openRemoveConfirmation = (member) => {
    if (!props.canInvite) return;

    errorMsg.value = '';
    successMsg.value = '';
    memberToRemove.value = member;
};

const closeRemoveConfirmation = () => {
    if (isRemoving.value) return;
    memberToRemove.value = null;
};

const removeMember = async () => {
    if (!memberToRemove.value || !props.canInvite) return;

    if (memberToRemove.value.project_role === 'manager' && managersCount.value <= 1) {
        errorMsg.value = 'No puedes quitar al ultimo manager del proyecto.';
        memberToRemove.value = null;
        return;
    }

    isRemoving.value = true;
    errorMsg.value = '';
    successMsg.value = '';

    try {
        const removedName = memberToRemove.value.profiles?.name || memberToRemove.value.profiles?.email || 'El usuario';

        const { error } = await supabase
            .from('project_members')
            .delete()
            .eq('id', memberToRemove.value.id)
            .eq('project_id', props.projectId);

        if (error) {
            if (error.code === '42501') {
                throw new Error('No tienes permisos para quitar miembros. Revisa la politica de delete en project_members.');
            }

            throw error;
        }

        successMsg.value = `${removedName} fue removido del proyecto.`;
        memberToRemove.value = null;
        await fetchMembers();
    } catch (err) {
        errorMsg.value = err.message || 'No se pudo quitar al miembro del proyecto.';
    } finally {
        isRemoving.value = false;
    }
};

const inviteMember = async () => {
    if (!inviteEmail.value.trim() || !props.canInvite) return;

    isInviting.value = true;
    errorMsg.value = '';
    successMsg.value = '';

    try {
        const normalizedEmail = inviteEmail.value.trim().toLowerCase();

        const { data: profile, error: profileError } = await supabase
            .from('profiles')
            .select('id, name, email')
            .ilike('email', normalizedEmail)
            .maybeSingle();

        if (profileError) throw profileError;

        if (!profile) {
            throw new Error('No se encontro ningun usuario con ese correo. Asegurate de que ya tenga cuenta registrada.');
        }

        const isAlreadyMember = members.value.some((member) => member.user_id === profile.id);
        if (isAlreadyMember) {
            throw new Error('Este usuario ya forma parte del proyecto.');
        }

        const { error: insertError } = await supabase
            .from('project_members')
            .insert({
                project_id: props.projectId,
                user_id: profile.id,
                project_role: 'developer'
            });

        if (insertError) {
            if (insertError.code === '23505') {
                throw new Error('Este usuario ya estaba agregado en el proyecto.');
            }

            if (insertError.code === '42501') {
                throw new Error('No tienes permisos para agregar miembros. Revisa las politicas de Supabase para project_members.');
            }

            throw insertError;
        }

        successMsg.value = `${profile.name || profile.email} ha sido anadido al proyecto.`;
        inviteEmail.value = '';
        await fetchMembers();
    } catch (err) {
        errorMsg.value = err.message || 'No se pudo agregar al usuario al proyecto.';
    } finally {
        isInviting.value = false;
    }
};

onMounted(() => {
    fetchMembers();
});
</script>

<template>
    <div class="members-container">
        <div class="members-hero">
            <div>
                <span>Equipo</span>
                <h2>Gestion de miembros</h2>
                <p>Administra accesos del proyecto, roles y colaboradores activos.</p>
            </div>
            <div class="member-stats">
                <article>
                    <strong>{{ members.length }}</strong>
                    <span>miembros</span>
                </article>
                <article>
                    <strong>{{ managersCount }}</strong>
                    <span>managers</span>
                </article>
                <article>
                    <strong>{{ developersCount }}</strong>
                    <span>developers</span>
                </article>
            </div>
        </div>

        <div v-if="canInvite" class="invite-card">
            <div>
                <h3>Invitar colaborador</h3>
                <p>Agrega usuarios registrados como developers del proyecto.</p>
            </div>

            <div class="invite-form">
                <input
                    v-model="inviteEmail"
                    type="email"
                    placeholder="correo@ejemplo.com"
                    class="flex-grow bg-gray-50 border-gray-100 rounded-2xl px-4 py-3 text-sm focus:ring-black focus:border-black"
                    @keyup.enter="inviteMember"
                    :disabled="isInviting"
                />
                <button
                    @click="inviteMember"
                    class="bg-black text-white px-8 py-3 rounded-2xl text-sm font-bold hover:bg-gray-800 transition disabled:opacity-50"
                    :disabled="!inviteEmail.trim() || isInviting"
                >
                    {{ isInviting ? 'Invitando...' : 'Anadir al equipo' }}
                </button>
            </div>

            <p v-if="errorMsg" class="mt-4 text-red-600 text-sm font-medium">{{ errorMsg }}</p>
            <p v-if="successMsg" class="mt-4 text-green-600 text-sm font-medium">{{ successMsg }}</p>
        </div>

        <div v-else class="invite-card readonly">
            <div>
                <h3>Equipo del proyecto</h3>
                <p>Solo un manager puede agregar o quitar personas del proyecto.</p>
            </div>
        </div>

        <div v-if="loading" class="text-center py-10">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-black mx-auto"></div>
        </div>

        <div v-else-if="members.length" class="members-table">
            <div class="table-head">
                <span>Persona</span>
                <span>Rol</span>
                <span>Ingreso</span>
                <span>Acciones</span>
            </div>
            <div v-for="member in members" :key="member.id" class="member-card">
                <div class="member-person">
                    <div class="avatar-placeholder">
                        <span class="text-lg font-bold">{{ member.profiles?.name?.charAt(0) || '?' }}</span>
                    </div>
                    <div>
                        <h4 class="font-bold text-gray-900 leading-tight">{{ member.profiles?.name || 'Usuario' }}</h4>
                        <p class="text-xs text-gray-500">{{ member.profiles?.email || 'Sin correo visible' }}</p>
                    </div>
                </div>
                <div class="role-badge" :class="member.project_role">
                    {{ member.project_role === 'manager' ? 'Manager' : 'Developer' }}
                </div>
                <div class="joined-date">{{ formatDate(member.created_at) }}</div>
                <div class="member-actions">
                    <button
                        v-if="canInvite && member.user_id !== currentUserId"
                        type="button"
                        class="remove-member-btn"
                        @click="openRemoveConfirmation(member)"
                    >
                        Quitar
                    </button>
                    <span v-else class="muted-action">Sin acciones</span>
                </div>
            </div>
        </div>

        <div v-else class="empty-members">
            <h3>No hay miembros todavia</h3>
            <p>Invita al primer developer para empezar a repartir tareas.</p>
        </div>

        <div v-if="memberToRemove" class="confirm-wrap">
            <div class="confirm-overlay" @click="closeRemoveConfirmation"></div>
            <div class="confirm-modal">
                <div class="confirm-icon">
                    <svg fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m0 3.75h.008v.008H12v-.008ZM10.29 3.86 1.82 18a2.25 2.25 0 0 0 1.93 3.38h16.5A2.25 2.25 0 0 0 22.18 18L13.71 3.86a2.25 2.25 0 0 0-3.42 0Z" />
                    </svg>
                </div>
                <h3>Quitar miembro del proyecto</h3>
                <p>
                    Estas seguro de quitar a
                    <strong>{{ memberToRemove.profiles?.name || memberToRemove.profiles?.email || 'este usuario' }}</strong>
                    del proyecto? Perdera acceso a esta vista y a sus tareas del proyecto.
                </p>
                <div class="confirm-actions">
                    <button class="cancel-btn" @click="closeRemoveConfirmation" :disabled="isRemoving">Cancelar</button>
                    <button class="danger-btn" @click="removeMember" :disabled="isRemoving">
                        {{ isRemoving ? 'Quitando...' : 'Si, quitar' }}
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.members-container {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.members-hero,
.invite-card,
.members-table,
.empty-members {
    border: 1px solid #eef2f7;
    background: #ffffff;
    box-shadow: 0 18px 42px rgba(15, 23, 42, 0.05);
}

.members-hero {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 24px;
    border-radius: 30px;
    padding: 26px;
    background:
        radial-gradient(circle at top right, rgba(121, 169, 212, 0.2), transparent 34%),
        #ffffff;
}

.members-hero span {
    color: #64748b;
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.12em;
    text-transform: uppercase;
}

.members-hero h2 {
    margin-top: 8px;
    color: #111827;
    font-size: 32px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.members-hero p {
    margin-top: 8px;
    color: #64748b;
    font-size: 14px;
}

.member-stats {
    display: flex;
    gap: 12px;
}

.member-stats article {
    min-width: 104px;
    border-radius: 20px;
    background: #f8fafc;
    padding: 16px;
}

.member-stats strong {
    display: block;
    color: #111827;
    font-size: 28px;
    font-weight: 900;
    letter-spacing: -0.04em;
}

.invite-card {
    display: grid;
    grid-template-columns: minmax(0, 0.42fr) minmax(0, 0.58fr);
    gap: 18px;
    align-items: center;
    border-radius: 26px;
    padding: 22px;
}

.invite-card h3 {
    color: #111827;
    font-size: 20px;
    font-weight: 900;
    letter-spacing: -0.03em;
}

.invite-card p {
    margin-top: 6px;
    color: #64748b;
    font-size: 14px;
}

.invite-form {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    gap: 10px;
}

.invite-form input {
    border: 1px solid #e2e8f0;
    border-radius: 16px;
    background: #f8fafc;
    padding: 12px 14px;
    font-size: 14px;
    outline: none;
}

.invite-form input:focus {
    border-color: #111827;
}

.invite-form button {
    border-radius: 16px;
    background: #111827;
    color: #fff;
    padding: 12px 18px;
    font-size: 14px;
    font-weight: 800;
}

.invite-form button:disabled {
    opacity: 0.55;
}

.members-table {
    overflow: hidden;
    border-radius: 26px;
}

.table-head,
.member-card {
    display: grid;
    grid-template-columns: minmax(260px, 1fr) 140px 150px 120px;
    align-items: center;
    gap: 16px;
}

.table-head {
    background: #f8fafc;
    padding: 14px 18px;
    color: #64748b;
    font-size: 12px;
    font-weight: 900;
    letter-spacing: 0.08em;
    text-transform: uppercase;
}

.member-card {
    border-top: 1px solid #eef2f7;
    padding: 16px 18px;
}

.member-actions {
    display: flex;
    align-items: center;
    gap: 10px;
}

.member-person {
    display: flex;
    min-width: 0;
    align-items: center;
    gap: 14px;
}

.avatar-placeholder {
    width: 44px;
    height: 44px;
    border-radius: 14px;
    background: #f9fafb;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #111827;
}

.role-badge {
    padding: 4px 10px;
    border-radius: 9999px;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.02em;
}

.role-badge.manager {
    background: #000000;
    color: #ffffff;
}

.role-badge.developer {
    background: #eff6ff;
    color: #1e40af;
}

.joined-date,
.muted-action {
    color: #64748b;
    font-size: 13px;
    font-weight: 700;
}

.remove-member-btn {
    border: 1px solid #fee2e2;
    border-radius: 999px;
    background: #fff;
    color: #b91c1c;
    padding: 6px 10px;
    font-size: 12px;
    font-weight: 800;
    transition: all 0.2s ease;
}

.remove-member-btn:hover {
    background: #fef2f2;
}

.confirm-wrap {
    position: fixed;
    inset: 0;
    z-index: 70;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}

.confirm-overlay {
    position: absolute;
    inset: 0;
    background: rgba(15, 23, 42, 0.42);
    backdrop-filter: blur(4px);
}

.confirm-modal {
    position: relative;
    width: min(100%, 460px);
    border: 1px solid #fee2e2;
    border-radius: 28px;
    background: #fff;
    padding: 26px;
    box-shadow: 0 30px 80px rgba(15, 23, 42, 0.24);
}

.confirm-icon {
    display: flex;
    height: 48px;
    width: 48px;
    align-items: center;
    justify-content: center;
    border-radius: 16px;
    background: #fef2f2;
    color: #b91c1c;
}

.confirm-icon svg {
    height: 24px;
    width: 24px;
}

.confirm-modal h3 {
    margin-top: 18px;
    color: #111827;
    font-size: 22px;
    font-weight: 900;
    letter-spacing: -0.03em;
}

.confirm-modal p {
    margin-top: 10px;
    color: #6b7280;
    font-size: 14px;
    line-height: 1.6;
}

.confirm-modal strong {
    color: #111827;
}

.confirm-actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    margin-top: 24px;
}

.cancel-btn,
.danger-btn {
    border-radius: 14px;
    padding: 11px 15px;
    font-size: 14px;
    font-weight: 800;
}

.cancel-btn {
    border: 1px solid #d1d5db;
    background: #fff;
    color: #374151;
}

.danger-btn {
    border: 1px solid #dc2626;
    background: #dc2626;
    color: #fff;
}

.cancel-btn:disabled,
.danger-btn:disabled {
    opacity: 0.6;
}

.empty-members {
    border-radius: 26px;
    padding: 46px 24px;
    text-align: center;
}

.empty-members h3 {
    color: #111827;
    font-size: 20px;
    font-weight: 900;
}

.empty-members p {
    margin-top: 8px;
    color: #64748b;
    font-size: 14px;
}

@media (max-width: 640px) {
    .members-hero,
    .invite-card {
        align-items: flex-start;
        grid-template-columns: 1fr;
        flex-direction: column;
    }

    .member-stats {
        width: 100%;
        flex-direction: column;
    }

    .invite-form {
        grid-template-columns: 1fr;
    }

    .table-head {
        display: none;
    }

    .member-card {
        align-items: flex-start;
        grid-template-columns: 1fr;
        gap: 14px;
    }

    .member-actions {
        width: 100%;
        justify-content: space-between;
    }

    .confirm-actions {
        flex-direction: column;
    }
}
</style>
