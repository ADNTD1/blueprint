<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';

const props = defineProps({
    modelValue: {
        type: String,
        default: '',
    },
    placeholder: {
        type: String,
        default: 'Selecciona una fecha',
    },
    disabled: {
        type: Boolean,
        default: false,
    },
});

const emit = defineEmits(['update:modelValue']);

const rootRef = ref(null);
const isOpen = ref(false);
const today = new Date();
today.setHours(0, 0, 0, 0);

const toDateParts = (value) => {
    if (!value) return null;

    const [year, month, day] = value.split('-').map(Number);
    if (!year || !month || !day) return null;

    return new Date(year, month - 1, day);
};

const selectedDate = ref(toDateParts(props.modelValue));
const visibleMonth = ref(selectedDate.value ? new Date(selectedDate.value) : new Date(today.getFullYear(), today.getMonth(), 1));

watch(() => props.modelValue, (value) => {
    selectedDate.value = toDateParts(value);

    if (selectedDate.value) {
        visibleMonth.value = new Date(selectedDate.value);
    }
});

const monthLabel = computed(() =>
    visibleMonth.value.toLocaleDateString('es-MX', {
        month: 'long',
        year: 'numeric',
    })
);

const formattedValue = computed(() => {
    if (!props.modelValue) return '';

    return toDateParts(props.modelValue)?.toLocaleDateString('es-MX', {
        day: '2-digit',
        month: 'long',
        year: 'numeric',
    }) || '';
});

const weekdayLabels = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

const sameDay = (left, right) =>
    left
    && right
    && left.getFullYear() === right.getFullYear()
    && left.getMonth() === right.getMonth()
    && left.getDate() === right.getDate();

const isBeforeToday = (date) => {
    const current = new Date(date);
    current.setHours(0, 0, 0, 0);
    return current < today;
};

const days = computed(() => {
    const year = visibleMonth.value.getFullYear();
    const month = visibleMonth.value.getMonth();
    const firstDay = new Date(year, month, 1);
    const startOffset = (firstDay.getDay() + 6) % 7;
    const startDate = new Date(year, month, 1 - startOffset);

    return Array.from({ length: 42 }, (_, index) => {
        const date = new Date(startDate);
        date.setDate(startDate.getDate() + index);

        return {
            key: `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`,
            date,
            label: date.getDate(),
            isCurrentMonth: date.getMonth() === month,
            isToday: sameDay(date, today),
            isSelected: sameDay(date, selectedDate.value),
            isDisabled: isBeforeToday(date),
        };
    });
});

const toIsoDate = (date) => {
    const year = date.getFullYear();
    const month = `${date.getMonth() + 1}`.padStart(2, '0');
    const day = `${date.getDate()}`.padStart(2, '0');

    return `${year}-${month}-${day}`;
};

const toggle = () => {
    if (props.disabled) return;
    isOpen.value = !isOpen.value;
};

const close = () => {
    isOpen.value = false;
};

const previousMonth = () => {
    visibleMonth.value = new Date(visibleMonth.value.getFullYear(), visibleMonth.value.getMonth() - 1, 1);
};

const nextMonth = () => {
    visibleMonth.value = new Date(visibleMonth.value.getFullYear(), visibleMonth.value.getMonth() + 1, 1);
};

const selectDate = (date) => {
    if (isBeforeToday(date)) return;

    emit('update:modelValue', toIsoDate(date));
    selectedDate.value = new Date(date);
    visibleMonth.value = new Date(date);
    close();
};

const clearDate = () => {
    emit('update:modelValue', '');
    selectedDate.value = null;
};

const selectToday = () => {
    selectDate(today);
};

const handleDocumentClick = (event) => {
    if (!rootRef.value?.contains(event.target)) {
        close();
    }
};

onMounted(() => {
    document.addEventListener('click', handleDocumentClick);
});

onBeforeUnmount(() => {
    document.removeEventListener('click', handleDocumentClick);
});
</script>

<template>
    <div ref="rootRef" class="date-picker" :class="{ disabled }">
        <button type="button" class="date-trigger" :disabled="disabled" @click="toggle">
            <span :class="['date-value', { placeholder: !modelValue }]">
                {{ modelValue ? formattedValue : placeholder }}
            </span>
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor" class="date-icon">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 2.25v3m7.5-3v3M3.75 8.25h16.5M4.5 5.25h15A2.25 2.25 0 0 1 21.75 7.5v11.25A2.25 2.25 0 0 1 19.5 21H4.5A2.25 2.25 0 0 1 2.25 18.75V7.5A2.25 2.25 0 0 1 4.5 5.25Z" />
            </svg>
        </button>

        <div v-if="isOpen" class="calendar-popover">
            <div class="calendar-header">
                <button type="button" class="nav-btn" @click="previousMonth" aria-label="Mes anterior">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
                    </svg>
                </button>
                <strong>{{ monthLabel }}</strong>
                <button type="button" class="nav-btn" @click="nextMonth" aria-label="Mes siguiente">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
                    </svg>
                </button>
            </div>

            <div class="weekday-row">
                <span v-for="label in weekdayLabels" :key="label">{{ label }}</span>
            </div>

            <div class="day-grid">
                <button
                    v-for="day in days"
                    :key="day.key"
                    type="button"
                    class="day-cell"
                    :class="{
                        muted: !day.isCurrentMonth,
                        today: day.isToday,
                        selected: day.isSelected,
                        disabled: day.isDisabled,
                    }"
                    :disabled="day.isDisabled"
                    @click="selectDate(day.date)"
                >
                    {{ day.label }}
                </button>
            </div>

            <div class="calendar-footer">
                <button type="button" class="footer-btn subtle" @click="clearDate">Limpiar</button>
                <button type="button" class="footer-btn" @click="selectToday">Hoy</button>
            </div>
        </div>
    </div>
</template>

<style scoped>
.date-picker {
    position: relative;
}

.date-picker.disabled {
    opacity: 0.7;
}

.date-trigger {
    width: 100%;
    min-height: 48px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 12px 14px;
    border: 1px solid #d1d5db;
    border-radius: 14px;
    background: #ffffff;
    color: #111827;
    text-align: left;
}

.date-trigger:focus {
    border-color: #818cf8;
    box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.12);
}

.date-value {
    font-size: 14px;
    color: #111827;
}

.date-value.placeholder {
    color: #9ca3af;
}

.date-icon {
    width: 18px;
    height: 18px;
    flex-shrink: 0;
    color: #6b7280;
}

.calendar-popover {
    position: absolute;
    top: calc(100% + 10px);
    left: 0;
    z-index: 30;
    width: min(100%, 320px);
    min-width: 300px;
    padding: 18px;
    border: 1px solid #e5e7eb;
    border-radius: 24px;
    background:
        radial-gradient(circle at top, rgba(191, 219, 254, 0.32), transparent 34%),
        linear-gradient(180deg, #ffffff, #f8fafc);
    box-shadow: 0 24px 60px rgba(15, 23, 42, 0.14);
}

.calendar-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 18px;
}

.calendar-header strong {
    font-size: 16px;
    font-weight: 800;
    text-transform: capitalize;
    color: #111827;
}

.nav-btn {
    width: 34px;
    height: 34px;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border: 1px solid #e5e7eb;
    border-radius: 12px;
    background: rgba(255, 255, 255, 0.8);
    color: #374151;
}

.nav-btn svg {
    width: 16px;
    height: 16px;
}

.weekday-row,
.day-grid {
    display: grid;
    grid-template-columns: repeat(7, minmax(0, 1fr));
    gap: 6px;
}

.weekday-row {
    margin-bottom: 10px;
}

.weekday-row span {
    text-align: center;
    font-size: 11px;
    font-weight: 800;
    text-transform: uppercase;
    color: #64748b;
}

.day-cell {
    aspect-ratio: 1;
    border: 1px solid transparent;
    border-radius: 14px;
    background: transparent;
    font-size: 13px;
    font-weight: 700;
    color: #0f172a;
}

.day-cell:hover {
    background: #eef2ff;
    color: #4338ca;
}

.day-cell.muted {
    color: #94a3b8;
}

.day-cell.disabled {
    color: #cbd5e1;
    cursor: not-allowed;
    background: #f8fafc;
}

.day-cell.disabled:hover {
    background: #f8fafc;
    color: #cbd5e1;
}

.day-cell.today {
    border-color: #c7d2fe;
    color: #4338ca;
}

.day-cell.selected {
    background: linear-gradient(135deg, #111827, #312e81);
    color: #ffffff;
    box-shadow: 0 10px 20px rgba(49, 46, 129, 0.2);
}

.calendar-footer {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    margin-top: 16px;
}

.footer-btn {
    border: none;
    background: transparent;
    color: #2563eb;
    font-size: 13px;
    font-weight: 800;
}

.footer-btn.subtle {
    color: #64748b;
}

@media (max-width: 640px) {
    .calendar-popover {
        min-width: 100%;
        width: 100%;
    }
}
</style>
