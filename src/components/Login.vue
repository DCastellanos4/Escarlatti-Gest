<script setup>
import { ref } from 'vue'

const emit = defineEmits(['login-exitoso'])


const userField = ref('')
const passField = ref('')
const hasError = ref(false)
const errorMessage = ref('')
const isLoading = ref(false)

const realizarLogin = async () => {
    hasError.value = false;
    isLoading.value = true;

    try {
        const url = `http://100.27.173.196:3000/auth/login?zusuario=DC4`;

        const respuesta = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                login: userField.value,   
                password: passField.value, 
                zusuario: "DC4"            
            })
        });

        const data = await respuesta.json();

        if (respuesta.ok) {
            console.log("✅ Acceso concedido a:", data.nombre);
            emit('login-exitoso', data);
        } else {
            hasError.value = true;
            errorMessage.value = data.motivo || data.error || "Fallo en la autenticación";
        }
    } catch (err) {
        console.error("Fallo de red:", err);
        errorMessage.value = "Error de conexión con el servidor.";
    } finally {
        isLoading.value = false;
    }
}
</script>

<template>
    <div class="login-container">
        <div class="login-box">
            <header class="login-header">
                <div class="logo-icon">E</div>
                <h2>Escarlatti<span>Gest</span></h2>
                <p>Sprint 3 - Control de Acceso</p>
            </header>

            <form @submit.prevent="realizarLogin" class="login-form">
                <div class="input-group">
                    <label>Usuario</label>
                    <input v-model="userField" type="text" placeholder="admin.david" required>
                </div>

                <div class="input-group">
                    <label>Contraseña</label>
                    <input v-model="passField" type="password" placeholder="••••••••" required>
                </div>

                <button type="submit" class="btn-login" :disabled="isLoading">
                    {{ isLoading ? 'Comprobando...' : 'Entrar al Sistema' }}
                </button>
            </form>

            <Transition name="slide-up">
                <div v-if="hasError" class="error-message">
                    <span class="icon">⚠️</span> {{ errorMessage }}
                </div>
            </Transition>
        </div>
    </div>
</template>
<style scoped>
/* Paleta de colores Sprint 3 - Escarlatti Indigo */
.login-container {
    --primary: #6366f1;       /* Indigo */
    --primary-hover: #4f46e5;
    --accent: #10b981;        /* Emerald (Éxito) */
    --dark-bg: #0f172a;       /* Slate 900 */
    --text-main: #1e293b;
    --text-muted: #64748b;
    --error-bg: #fef2f2;
    --error-text: #ef4444;

    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 90vh; /* Para que quede bien centrado verticalmente */
}

.login-box {
    background: #ffffff;
    padding: 3rem 2.5rem;
    border-radius: 20px;
    box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.15);
    width: 100%;
    max-width: 400px;
    text-align: center;
    border: 1px solid #f1f5f9;
}

/* Header y Logo */
.login-header {
    margin-bottom: 2.5rem;
}

.logo-icon {
    background: linear-gradient(135deg, var(--primary), var(--accent));
    width: 55px;
    height: 55px;
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 1.2rem;
    color: white;
    font-weight: 800;
    font-size: 1.6rem;
    box-shadow: 0 10px 15px -3px rgba(99, 102, 241, 0.3);
}

.login-header h2 {
    color: var(--dark-bg);
    font-size: 1.8rem;
    margin: 0;
    letter-spacing: -0.5px;
}

.login-header h2 span {
    color: var(--primary);
}

.login-header p {
    color: var(--text-muted);
    font-size: 0.95rem;
    margin-top: 0.4rem;
    font-weight: 500;
}

/* Formulario e Inputs */
.login-form {
    text-align: left;
}

.input-group {
    margin-bottom: 1.5rem;
}

.input-group label {
    display: block;
    margin-bottom: 0.6rem;
    color: var(--text-main);
    font-weight: 600;
    font-size: 0.85rem;
}

input {
    width: 100%;
    padding: 14px;
    border: 2px solid #f1f5f9;
    border-radius: 12px;
    background: #f8fafc;
    color: var(--dark-bg);
    font-size: 1rem;
    transition: all 0.2s ease;
    box-sizing: border-box; /* Fundamental para que el padding no rompa el ancho */
}

input:focus {
    outline: none;
    border-color: var(--primary);
    background: #ffffff;
    box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.1);
}

/* Botón Entrar */
.btn-login {
    width: 100%;
    padding: 14px;
    background: var(--dark-bg);
    color: white;
    border: none;
    border-radius: 12px;
    font-size: 1rem;
    font-weight: 700;
    cursor: pointer;
    transition: all 0.3s ease;
    margin-top: 1rem;
}

.btn-login:hover:not(:disabled) {
    background: var(--primary);
    transform: translateY(-2px);
    box-shadow: 0 10px 15px -3px rgba(99, 102, 241, 0.3);
}

.btn-login:disabled {
    opacity: 0.7;
    cursor: not-allowed;
}

/* Mensaje de Error (Bloqueados, etc.) */
.error-message {
    margin-top: 1.5rem;
    padding: 14px;
    background: var(--error-bg);
    color: var(--error-text);
    border-radius: 12px;
    font-size: 0.85rem;
    font-weight: 600;
    border: 1px solid #fee2e2;
    display: flex;
    align-items: center;
    gap: 8px;
    justify-content: center;
}

/* Animaciones */
.slide-up-enter-active, .slide-up-leave-active {
    transition: all 0.3s ease-out;
}

.slide-up-enter-from {
    opacity: 0;
    transform: translateY(10px);
}

.slide-up-leave-to {
    opacity: 0;
    transform: translateY(-10px);
}
</style>