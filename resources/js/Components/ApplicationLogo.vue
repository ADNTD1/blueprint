<template>
    <div class="brand-logo">
        <img src="/images/logo.png" alt="Blueprint logo" />
        <span class="brand-name">Blueprint</span>
    </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@800&display=swap');

.brand-logo {
    display: flex;
    align-items: center;
    gap: 8px;
}
.brand-logo img {
    width: 32px;
    height: 32px;
    object-fit: contain;
}
.brand-name {
    font-family: 'Inter', sans-serif;
    font-size: 20px;
    font-weight: 800;
    color: #0f0f0f;
    letter-spacing: -0.02em;
}
</style>
