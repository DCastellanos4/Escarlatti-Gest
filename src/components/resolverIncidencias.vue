<script setup>
/**
 * COMPONENTE: GestionIncidencias.vue
 * Descripción: CRUD de resolución de incidencias (Solo edición y borrado).
 */
import { ref, onMounted } from 'vue'

const props = defineProps(['usuario']);

const incidencias = ref([]);
const espacios = ref([]);
const estados = ref([]);
const incidenciaEnEdicion = ref(null);

/**
 * Carga de datos para visualización
 */
const cargarDatos = async () => {
    try {
        const [resInc, resEsp, resEst] = await Promise.all([
            fetch('http://44.207.19.239:3000/incidencias?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/espacios?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/estados_incidencia?zusuario=DC4')
        ]);
        incidencias.value = await resInc.json();
        espacios.value = await resEsp.json();
        estados.value = await resEst.json();
    } catch (error) {
        console.error("Error al sincronizar panel TIC:", error);
    }
}

/**
 * Prepara la incidencia para ser editada
 */
const editarIncidencia = (inc) => {
    incidenciaEnEdicion.value = {
        ...inc,
        // Al empezar a editar, el usuario logeado se asigna como responsable
        responsable_resolucion_id: props.usuario.usuario
    };
}

/**
 * Guarda los cambios (Resolución o Cambio de estado)
 */
const actualizarIncidencia = async () => {
    const id = incidenciaEnEdicion.value.id;

    // Si el estado pasa a RESUELTA, registramos la fecha actual
    const fechaRes = incidenciaEnEdicion.value.estado_incidencia_id === 'RESUELTA'
        ? new Date().toISOString().split('T')[0]
        : null;

    const payload = {
        ...incidenciaEnEdicion.value,
        fecha_resolucion: fechaRes, //
        zfecha: new Date().toISOString(),
        zusuario: 'DC4'
    };

    try {
        const respuesta = await fetch(`http://44.207.19.239:3000/incidencias/${id}?zusuario=DC4`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (respuesta.ok) {
            alert(`Incidencia #${id} actualizada.`);
            incidenciaEnEdicion.value = null;
            await cargarDatos();
        }
    } catch (e) {
        alert("Error al actualizar la incidencia.");
    }
}

const eliminarIncidencia = async (id) => {
    if (confirm(`¿Eliminar definitivamente la incidencia #${id}?`)) {
        await fetch(`http://44.207.19.239:3000/incidencias/${id}?zusuario=DC4`, { method: 'DELETE' });
        await cargarDatos();
    }
}

onMounted(cargarDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Panel de Resolución de Incidencias</h3>
        </header>

        <div v-if="incidenciaEnEdicion" class="edit-card">
            <h4>Gestionar Incidencia #{{ incidenciaEnEdicion.id }}</h4>
            <div class="form-grid">
                <div class="field">
                    <label>Estado Actual</label>
                    <select v-model="incidenciaEnEdicion.estado_incidencia_id">
                        <option v-for="est in estados" :key="est.id" :value="est.id">
                            {{ est.nombre }}
                        </option>
                    </select>
                </div>
                <div class="field">
                    <label>Responsable</label>
                    <input v-model="incidenciaEnEdicion.responsable_resolucion_id" readonly>
                </div>
                <div class="field full">
                    <label>Notas de Resolución</label>
                    <textarea v-model="incidenciaEnEdicion.comentarios_resolucion"
                        placeholder="Explique qué se ha hecho..."></textarea>
                </div>
            </div>
            <div class="actions">
                <button @click="actualizarIncidencia" class="btn-save">Guardar Cambios</button>
                <button @click="incidenciaEnEdicion = null" class="btn-cancel">Cancelar</button>
            </div>
        </div>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Espacio</th>
                        <th>Problema</th>
                        <th>Estado</th>
                        <th>Usuario</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="inc in incidencias" :key="inc.id">
                        <td><strong>{{ inc.id }}</strong></td>
                        <td>{{espacios.find(e => e.id === inc.espacio_id)?.nombre || inc.espacio_id}}</td>
                        <td class="desc-cell">{{ inc.descripcion_problema }}</td>
                        <td>
                            <span :class="['badge', inc.estado_incidencia_id]">
                                {{ inc.estado_incidencia_id }}
                            </span>
                        </td>
                        <td><small>{{ inc.usuario_login }}</small></td>
                        <td class="ops">
                            <button @click="editarIncidencia(inc)" class="btn-edit">Gestionar</button>
                            <button v-if="props.usuario.rol === 'Administrador'" @click="eliminarIncidencia(inc.id)"
                                class="btn-del">Borrar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
.seccion-header {
    border-left: 5px solid #ef4444;
    padding-left: 15px;
    margin-bottom: 20px;
}

.edit-card {
    background: #f8fafc;
    padding: 20px;
    border-radius: 8px;
    border: 1px solid #e2e8f0;
    margin-bottom: 20px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    text-align: left;
}

.full {
    grid-column: span 2;
}

label {
    font-size: 0.75rem;
    font-weight: bold;
    color: #64748b;
}

input,
select,
textarea {
    width: 100%;
    padding: 8px;
    border-radius: 4px;
    border: 1px solid #cbd5e1;
    margin-top: 5px;
}

.actions {
    margin-top: 15px;
    display: flex;
    gap: 10px;
}

.btn-save {
    background: #10b981;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-cancel {
    background: #94a3b8;
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 4px;
    cursor: pointer;
}

/* Tabla y Badges */
.table-container {
    background: white;
    border-radius: 8px;
    overflow: hidden;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.9rem;
}

th,
td {
    padding: 12px;
    border-bottom: 1px solid #f1f5f9;
    text-align: left;
}

.desc-cell {
    max-width: 200px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.badge {
    padding: 4px 8px;
    border-radius: 12px;
    font-size: 0.7rem;
    font-weight: bold;
    color: black;
}

.ABI {
    background: #ef4444;
}

.PRO {
    background: #f59e0b;
}

.RES {
    background: #10b981;
}

.ops {
    display: flex;
    gap: 5px;
}

.btn-edit {
    background: #6366f1;
    color: white;
    border: none;
    padding: 5px 10px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-del {
    background: #fee2e2;
    color: #ef4444;
    border: none;
    padding: 5px 10px;
    border-radius: 4px;
    cursor: pointer;
}
</style>