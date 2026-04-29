<script setup>
import { computed } from 'vue';

const props = defineProps({
    projectsCount: {
        type: Number,
        default: 0,
    },
    activeProjectsCount: {
        type: Number,
        default: 0,
    },
    tasksCount: {
        type: Number,
        default: 0,
    },
    completedTasksCount: {
        type: Number,
        default: 0,
    },
    loading: {
        type: Boolean,
        default: false,
    },
});

const completionPercentage = computed(() => {
    if (props.tasksCount === 0) return 0;
    return Math.round((props.completedTasksCount / props.tasksCount) * 100);
});

const metrics = computed(() => [
    {
        label: 'Proyectos activos',
        value: props.activeProjectsCount,
        detail: `de ${props.projectsCount} en total`,
        accent: 'bg-[#e24d2e]',
        icon: 'M3.75 6A2.25 2.25 0 0 1 6 3.75h2.25A2.25 2.25 0 0 1 10.5 6v2.25a2.25 2.25 0 0 1-2.25 2.25H6a2.25 2.25 0 0 1-2.25-2.25V6ZM13.5 6a2.25 2.25 0 0 1 2.25-2.25H18A2.25 2.25 0 0 1 20.25 6v2.25A2.25 2.25 0 0 1 18 10.5h-2.25a2.25 2.25 0 0 1-2.25-2.25V6ZM3.75 15.75A2.25 2.25 0 0 1 6 13.5h2.25a2.25 2.25 0 0 1 2.25 2.25V18a2.25 2.25 0 0 1-2.25 2.25H6A2.25 2.25 0 0 1 3.75 18v-2.25ZM13.5 15.75a2.25 2.25 0 0 1 2.25-2.25H18a2.25 2.25 0 0 1 2.25 2.25V18A2.25 2.25 0 0 1 18 20.25h-2.25A2.25 2.25 0 0 1 13.5 18v-2.25Z',
    },
    {
        label: 'Tareas registradas',
        value: props.tasksCount,
        detail: `${props.completedTasksCount} completadas`,
        accent: 'bg-[#79a9d4]',
        icon: 'M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z',
    },
    {
        label: 'Avance general',
        value: `${completionPercentage.value}%`,
        detail: 'progreso operativo',
        accent: 'bg-[#22293a]',
        icon: 'M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z',
    },
]);
</script>

<template>
    <div class="metrics-grid">
        <div v-for="metric in metrics" :key="metric.label" class="metric-card">
            <div class="flex items-center justify-between gap-4">
                <div class="metric-icon" :class="metric.accent">
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" :d="metric.icon" />
                    </svg>
                </div>
                <span class="rounded-full bg-gray-100 px-3 py-1 text-xs font-bold uppercase tracking-[0.16em] text-gray-400">
                    KPI
                </span>
            </div>

            <div class="mt-7">
                <div v-if="loading" class="h-10 w-24 animate-pulse rounded-xl bg-gray-100"></div>
                <div v-else class="text-4xl font-bold tracking-tight text-gray-950">{{ metric.value }}</div>
                <p class="mt-2 text-sm font-semibold text-gray-500">{{ metric.label }}</p>
                <p class="mt-1 text-sm text-gray-400">{{ metric.detail }}</p>
            </div>
        </div>
    </div>
</template>

<style scoped>
.metrics-grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 24px;
}

.metric-card {
    min-height: 180px;
    border: 1px solid rgba(255, 255, 255, 0.68);
    border-radius: 28px;
    background: rgba(255, 255, 255, 0.84);
    padding: 24px;
    box-shadow: 0 18px 45px rgba(15, 23, 42, 0.06);
}

.metric-icon {
    display: flex;
    height: 48px;
    width: 48px;
    align-items: center;
    justify-content: center;
    border-radius: 14px;
    color: #fff;
}

@media (max-width: 1024px) {
    .metrics-grid {
        grid-template-columns: 1fr;
    }
}
</style>
