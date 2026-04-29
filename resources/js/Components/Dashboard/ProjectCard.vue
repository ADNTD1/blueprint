<script setup>
import { computed } from 'vue';
import { Link } from '@inertiajs/vue3';

const props = defineProps({
    project: {
        type: Object,
        required: true,
    },
    variant: {
        type: String,
        default: 'default',
    },
});

const isCompact = computed(() => props.variant === 'compact');

const formatDate = (dateString) => {
    if (!dateString) return 'Sin fecha';
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('es-MX', { dateStyle: 'medium' }).format(date);
};

const statusLabels = {
    planning: 'Planeacion',
    active: 'En marcha',
    at_risk: 'En riesgo',
    completed: 'Completado',
    archived: 'Archivado',
};

const statusClasses = {
    planning: 'bg-amber-100 text-amber-700',
    active: 'bg-emerald-100 text-emerald-700',
    at_risk: 'bg-rose-100 text-rose-700',
    completed: 'bg-sky-100 text-sky-700',
    archived: 'bg-slate-200 text-slate-600',
};

const initials = computed(() => {
    const words = (props.project.name || 'BP').trim().split(/\s+/).slice(0, 2);
    return words.map((word) => word[0]).join('').toUpperCase();
});

const projectTone = computed(() => {
    const tones = ['bg-[#e24d2e]', 'bg-[#79a9d4]', 'bg-[#22293a]', 'bg-[#96b6a5]', 'bg-[#d0b25f]'];
    const seed = String(props.project.id || props.project.name || '').length;
    return tones[seed % tones.length];
});
</script>

<template>
    <Link
        :href="`/projects/${project.id}`"
        class="project-card group"
        :class="{ compact: isCompact }"
    >
        <div class="project-mark" :class="projectTone">
            {{ initials }}
        </div>

        <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2">
                <h3 class="truncate text-base font-bold text-gray-950">
                    {{ project.name }}
                </h3>
                <span
                    class="rounded-full px-2.5 py-1 text-xs font-semibold"
                    :class="statusClasses[project.status] || 'bg-gray-100 text-gray-600'"
                >
                    {{ statusLabels[project.status] || project.status || 'Sin estado' }}
                </span>
            </div>

            <p v-if="!isCompact" class="mt-3 line-clamp-2 text-sm leading-5 text-gray-500">
                {{ project.description || 'Sin descripcion disponible.' }}
            </p>

            <div class="mt-3 flex flex-wrap items-center gap-3 text-sm text-gray-500">
                <span>{{ formatDate(project.created_at) }}</span>
                <span class="h-1 w-1 rounded-full bg-gray-300"></span>
                <span>Abrir proyecto</span>
            </div>
        </div>

        <div class="project-arrow">
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="m9 5 7 7-7 7" />
            </svg>
        </div>
    </Link>
</template>

<style scoped>
.project-card {
    display: flex;
    min-height: 154px;
    align-items: flex-start;
    gap: 16px;
    border: 1px solid #edf0f2;
    border-radius: 24px;
    background: #fff;
    padding: 18px;
    transition: transform 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
}

.project-card:hover {
    border-color: #111827;
    box-shadow: 0 18px 35px rgba(15, 23, 42, 0.08);
    transform: translateY(-2px);
}

.project-card.compact {
    min-height: auto;
    border: 0;
    border-radius: 0;
    background: transparent;
    padding: 18px 0;
    box-shadow: none;
}

.project-card.compact:hover {
    transform: none;
}

.project-mark {
    display: flex;
    height: 48px;
    width: 48px;
    flex: none;
    align-items: center;
    justify-content: center;
    border-radius: 12px;
    color: #fff;
    font-weight: 800;
    letter-spacing: 0;
}

.project-arrow {
    display: flex;
    height: 38px;
    width: 38px;
    flex: none;
    align-items: center;
    justify-content: center;
    border-radius: 999px;
    background: #edf0f2;
    color: #374151;
    transition: background 0.2s ease, color 0.2s ease;
}

.project-card:hover .project-arrow {
    background: #111827;
    color: #fff;
}
</style>
