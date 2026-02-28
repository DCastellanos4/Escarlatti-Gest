<script setup>
/**
 * COMPONENTE: GestionEspacios.vue
 * Descripción: Mantenimiento de aulas y salas del centro con validación de zusuario.
 */
import { ref, onMounted } from 'vue'

const listaEspacios = ref([])

const modeloEspacio = ref({
    id: '',
    nombre: '',
    ubicacion_planta: '',
    capacidad_max: 0,
    equipamiento: '',
    estado_operativo: 'true',
    zusuario: 'DC4' // Incluimos zusuario en el modelo base
})

/**
 * Carga de datos con limpieza de zusuario
 */
const cargarDatos = async () => {
    try {
        // Añadimos el parámetro query string como en los componentes anteriores
        const respuesta = await fetch('http://44.207.19.239:3000/espacios?zusuario=DC4')
        const datos = await respuesta.json()

        // ORDENAMIENTO: Mantenemos la tabla estable por ID
        listaEspacios.value = datos.sort((a, b) => Number(a.id) - Number(b.id))
    } catch (error) {
        console.error("Fallo al conectar con la API de espacios:", error);
    }
}

/**
 * Alternar Operatividad con Payload Limpio
 */
const conmutarOperatividad = async (espacio) => {
    const nuevoEstado = espacio.estado_operativo === 'true' ? 'false' : 'true';

    // PAYLOAD LIMPIO: Solo enviamos lo que la tabla requiere + zusuario
    const espacioActualizado = {
        id: espacio.id,
        nombre: espacio.nombre,
        ubicacion_planta: espacio.ubicacion_planta,
        capacidad_max: espacio.capacidad_max,
        equipamiento: espacio.equipamiento,
        estado_operativo: nuevoEstado,
        zusuario: 'DC4'
    };
    try {
        const respuesta = await fetch(`http://44.207.19.239:3000/espacios/${espacio.id}?zusuario=DC4`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(espacioActualizado)
        });

        if (respuesta.ok) {
            await cargarDatos();
        }
    } catch (error) {
        console.error("Error al actualizar estado del aula:", error);
    }
}

/**
 * Guardar Nuevo Espacio con ID dinámico
 */
const guardarNuevoEspacio = async () => {
    //FUNCIONES PARA CALCULAR EL ID 
    const idsNumericos = listaEspacios.value.map(e => {
        const soloNumeros = e.id.toString().replace(/\D/g, '');
        return soloNumeros ? Number(soloNumeros) : 0;
    });

    const maxId = idsNumericos.length > 0 ? Math.max(...idsNumericos) : 0;

    // 3. Generamos el nuevo ID con el prefijo deseado
    const nuevoId = "AULA" + (maxId + 1).toString();

    // 4. Preparamos el objeto para enviar
    const datosFinales = {
        ...modeloEspacio.value,
        id: nuevoId,
        zusuario: 'DC4'
    };

    try {
        const respuesta = await fetch('http://44.207.19.239:3000/espacios?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            alert(`Aula "${datosFinales.nombre}" registrada con ID #${nuevoId}.`);

            // Reset completo del formulario
            modeloEspacio.value = {
                id: '', nombre: '', ubicacion_planta: '',
                capacidad_max: 0, equipamiento: '',
                estado_operativo: 'true', zusuario: 'DC4'
            };
            await cargarDatos();
        } else {
            const errorData = await respuesta.json();
            alert("Error de la API: " + (errorData.error || "No se pudo registrar el espacio"));
        }
    } catch (e) {
        alert("Error de red al registrar espacio.");
    }
}

const borrarRegistro = async (id) => {
    if (confirm("¿Seguro que quieres eliminar este espacio?")) {
        try {
            const respuesta = await fetch(`http://44.207.19.239:3000/espacios/${id}?zusuario=DC4`, {
                method: 'DELETE'
            });
            if (respuesta.ok) {
                await cargarDatos();
            }
        } catch (error) {
            alert("Error al intentar borrar el espacio.");
        }
    }
}

onMounted(cargarDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Espacios e Instalaciones (H6)</h3>
        </header>

        <form @submit.prevent="guardarNuevoEspacio" class="form-grid">
            <input v-model="modeloEspacio.nombre" placeholder="Nombre (ej. Aula 103)" required>
            <input v-model="modeloEspacio.ubicacion_planta" placeholder="Planta (ej. Segunda planta)" required>

            <div class="input-labeled">
                <label>Capacidad Máxima (Aforo)</label>
                <input v-model="modeloEspacio.capacidad_max" type="number" required>
            </div>

            <select v-model="modeloEspacio.estado_operativo" required>
                <option value="true">Operativo</option>
                <option value="false">No Operativo</option>
            </select>

            <input v-model="modeloEspacio.equipamiento" placeholder="Equipamiento (ej. Proyector, 20 PCs, AC)"
                class="full-width">

            <button type="submit" class="btn-success">Dar de Alta Espacio</button>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Espacio</th>
                        <th>Planta</th>
                        <th>Aforo</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="es in listaEspacios" :key="es.id">
                        <td><strong>#{{ es.id }}</strong></td>
                        <td>{{ es.nombre }}</td>
                        <td>{{ es.ubicacion_planta }}</td>
                        <td>{{ es.capacidad_max }} pax</td>
                        <td>
                            <span :class="es.estado_operativo === 'true' ? 'status-ok' : 'status-err'">
                                {{ es.estado_operativo === 'true' ? 'Disponible' : 'Inaccesible ' }}
                            </span>
                        </td>
                        <td class="td-actions">
                            <button @click="conmutarOperatividad(es)"
                                :class="es.estado_operativo === 'true' ? 'btn-warn' : 'btn-ok'">
                                {{ es.estado_operativo === 'true' ? 'Desactivar' : 'Activar' }}
                            </button>

                            <button @click="borrarRegistro(es.id)" class="btn-danger">Borrar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style scoped>
.seccion-header {
    margin-bottom: 20px;
    border-left: 5px solid #3498db;
    padding-left: 15px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    background: #fff;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
}

.full-width {
    grid-column: span 2;
}

.input-labeled {
    display: flex;
    flex-direction: column;
    text-align: left;
}

.input-labeled label {
    font-size: 0.7rem;
    color: #7f8c8d;
    margin-bottom: 2px;
    padding-left: 5px;
}

/* Estilo solicitado: fondo oscuro y texto blanco */
select,
input {
    padding: 12px;
    border: 1px solid #ccc;
    border-radius: 4px;
    color: #fff;
    background: #2c3e50;
    transition: all 0.3s;
}

input:focus {
    border-color: #3498db;
    outline: none;
}

.btn-success {
    grid-column: span 2;
    background: #27ae60;
    color: white;
    border: none;
    padding: 14px;
    cursor: pointer;
    border-radius: 4px;
    font-weight: bold;
}

.table-container {
    margin-top: 30px;
    background: white;
    padding: 15px;
    border-radius: 8px;
    color: #333;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th,
td {
    padding: 14px;
    text-align: left;
    border-bottom: 1px solid #eee;
}

th {
    background: #f9f9f9;
    text-transform: uppercase;
    font-size: 0.75rem;
    color: #7f8c8d;
}

.td-actions {
    display: flex;
    gap: 8px;
}

.status-ok {
    color: #27ae60;
    font-weight: bold;
}

.status-err {
    color: #e74c3c;
    font-weight: bold;
}

.btn-ok {
    background: #27ae60;
    color: white;
    border: none;
    padding: 8px 12px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-warn {
    background: #f39c12;
    color: white;
    border: none;
    padding: 8px 12px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-danger {
    background: #e74c3c;
    color: white;
    border: none;
    padding: 8px 12px;
    border-radius: 4px;
    cursor: pointer;
}
</style>