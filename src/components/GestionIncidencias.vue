<script setup>
/**
 * COMPONENTE: CrearIncidencias.vue
 * Descripción: Permite a los usuarios logeados reportar fallos técnicos.
 */
import { ref, onMounted } from 'vue'

// Recibimos la sesión desde el AdminPanel
const props = defineProps(['usuario']);

const listaEspacios = ref([]);
const listaIncidencias = ref([]);
const isLoading = ref(false);

const modeloIncidencia = ref({
    espacio_id: '',
    descripcion_problema: '',
    zusuario: 'DC4'
});

/**
 * Carga de datos necesarios
 */
const cargarDatos = async () => {
    try {
        const [resEsp, resInc] = await Promise.all([
            fetch('http://44.207.19.239:3000/espacios?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/incidencias?zusuario=DC4')
        ]);
        listaEspacios.value = await resEsp.json();
        listaIncidencias.value = await resInc.json();
    } catch (error) {
        console.error("Error al cargar datos de incidencias:", error);
    }
}

/**
 * Registro de nueva incidencia
 */
const registrarIncidencia = async () => {
    isLoading.value = true;

    // 1. Generación de ID numérico automático
    const idsExistentes = listaIncidencias.value.map(i => Number(i.id) || 0);
    // const nuevoId = (idsExistentes.length > 0 ? Math.max(...idsExistentes) : 0) + 1;
    const nuevoId= 950;

    // 2. Construcción del Payload según la estructura de la API
    const datosFinales = {
        id: nuevoId,                                     //
        espacio_id: modeloIncidencia.value.espacio_id,   //
        usuario_login: props.usuario.usuario,           // Usuario de la sesión
        descripcion_problema: modeloIncidencia.value.descripcion_problema, //
        estado_incidencia_id: 'ABI',                // Estado inicial por defecto
        responsable_resolucion_id: null,                // Vacío al crear
        comentarios_resolucion: null,                   // Vacío al crear
        fecha_resolucion: null,                         // Vacío al crear
        zfecha: new Date().toISOString(),               //
        zusuario: 'DC4'                                 //
    };

    try {
        const respuesta = await fetch('http://44.207.19.239:3000/incidencias?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            alert(`Incidencia #${nuevoId} enviada al equipo TIC.`);
            modeloIncidencia.value.descripcion_problema = '';
            modeloIncidencia.value.espacio_id = '';
            await cargarDatos();
        } else {
            const errorData = await respuesta.json();
            alert("Error al enviar: " + (errorData.error || "Datos no válidos"));
        }
    } catch (e) {
        alert("Fallo de conexión con el servidor.");
    } finally {
        isLoading.value = false;
    }
}

onMounted(cargarDatos);
</script>

<template>
    <div class="incidencias-container">
        <header class="seccion-header">
            <h3>Reportar Incidencia TIC</h3>
            <p>Usuario: <strong>{{ props.usuario.nombre }}</strong></p>
        </header>

        <form @submit.prevent="registrarIncidencia" class="incidencia-form">
            <div class="input-group">
                <label>Aula o Espacio afectado</label>
                <select v-model="modeloIncidencia.espacio_id" required>
                    <option value="" disabled>-- Seleccionar ubicación --</option>
                    <option v-for="e in listaEspacios" :key="e.id" :value="e.id">
                        {{ e.nombre }}
                    </option>
                </select>
            </div>

            <div class="input-group">
                <label>Descripción detallada del problema</label>
                <textarea v-model="modeloIncidencia.descripcion_problema"
                    placeholder="Ej: El proyector no enciende o falta un cable HDMI..." rows="4" required></textarea>
            </div>

            <button type="submit" class="btn-enviar" :disabled="isLoading">
                {{ isLoading ? 'Enviando...' : 'Enviar Incidencia' }}
            </button>
        </form>

        <div class="info-footer">
            <small>Las incidencias se crean automáticamente en estado <strong>ABIERTA</strong>.</small>
        </div>
    </div>
</template>

<style scoped>
.incidencias-container {
    max-width: 600px;
    margin: 0 auto;
    background: white;
    padding: 25px;
    border-radius: 12px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
}

.seccion-header {
    border-bottom: 2px solid #f1f5f9;
    margin-bottom: 20px;
    padding-bottom: 10px;
}

.incidencia-form {
    display: flex;
    flex-direction: column;
    gap: 15px;
}

.input-group {
    display: flex;
    flex-direction: column;
    gap: 5px;
    text-align: left;
}

.input-group label {
    font-size: 0.85rem;
    font-weight: 600;
    color: #475569;
}

select,
textarea {
    padding: 12px;
    border-radius: 8px;
    border: 1px solid #cbd5e1;
    background: #f8fafc;
    font-family: inherit;
}

.btn-enviar {
    background: #ef4444;
    /* Rojo para alertas/incidencias */
    color: white;
    padding: 14px;
    border: none;
    border-radius: 8px;
    font-weight: bold;
    cursor: pointer;
    transition: background 0.2s;
}

.btn-enviar:hover {
    background: #dc2626;
}

.btn-enviar:disabled {
    background: #94a3b8;
}

.info-footer {
    margin-top: 20px;
    color: #64748b;
    font-style: italic;
}
</style>