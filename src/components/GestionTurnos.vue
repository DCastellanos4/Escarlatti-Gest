<script setup>
/**
 * COMPONENTE: GestionTurnos.vue
 * Descripción: Mantenimiento de los turnos horarios del centro .
 * Incluye validación de integridad referencial con la tabla de Cursos.
 */
import { ref, onMounted } from 'vue'

const listaTurnos = ref([])
const listaCursos = ref([])
const turnoEnEdicion = ref(null)

const modeloTurno = ref({ id: '', nombre: '', horario_referencia: '', zfecha: new Date().toISOString(), zusuario: "DC4" })

/**
 * Carga masiva de datos desde la API.
 * Usamos Promise.all para que las peticiones no se bloqueen entre sí.
 */
const sincronizarDatos = async () => {
    try {
        const [resTur, resCur] = await Promise.all([
            fetch('http://44.207.19.239:3000/turnos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/cursos?zusuario=DC4')
        ]);

        const datosTurnos = await resTur.json();
        // Ordenamiento por ID para que la tabla sea estable visualmente
        listaTurnos.value = datosTurnos.sort((a, b) => Number(a.id) - Number(b.id));

        listaCursos.value = await resCur.json();
    } catch (error) {
        console.error("Fallo crítico en la carga de turnos:", error);
    }
}

/**
 * Procesa el formulario. Decide si registrar uno nuevo (POST) o actualizar (PUT).
 */
const procesarFormulario = async () => {
    const esEdicion = !!turnoEnEdicion.value;
    const metodo = esEdicion ? 'PUT' : 'POST';
    const url = esEdicion
        ? `http://44.207.19.239:3000/turnos/${turnoEnEdicion.value.id}?zusuario=DC4`
        : 'http://44.207.19.239:3000/turnos?zusuario=DC4';

    const origen = esEdicion ? turnoEnEdicion.value : modeloTurno.value;

    // CONSTRUCCIÓN DEL PAYLOAD (El cuerpo del mensaje)
    const datosFinales = {
        nombre: origen.nombre,
        horario_referencia: origen.horario_referencia,
        zusuario: "DC4"
    };

    if (esEdicion) {
        datosFinales.id = origen.id;
    } else {
        // Generamos el ID manual solo si tu API no lo hace sola
        const idsNumericos = listaTurnos.value.map(t => Number(t.id));
        const maxIdExistente = idsNumericos.length > 0 ? Math.max(...idsNumericos) : 0;
        datosFinales.id = (maxIdExistente + 1).toString();
    }

    try {
        const respuesta = await fetch(url, {
            method: metodo,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (respuesta.ok) {
            alert(esEdicion ? "Turno actualizado" : "Nuevo turno registrado");
            cancelarAccion();
            await sincronizarDatos();
        } else {
            const errorData = await respuesta.json();
            console.error("Error detallado:", errorData);
            alert("Error del servidor: " + (errorData.error || "Desconocido"));
        }
    } catch (error) {
        alert("Error de comunicación con la API.");
    }
}

/**
 * Lógica de borrado con protección -> No se borra si hay cursos vinculados.
 */
const eliminarTurno = async (id) => {
    // Comprobamos si algún curso depende de este turno_id
    const tieneViculos = listaCursos.value.some(c => Number(c.turno_id) === Number(id));

    if (tieneViculos) {
        alert("Acción bloqueada: No se puede eliminar un turno con cursos asociados.");
        return;
    }

    if (confirm("¿Estás seguro de eliminar este turno de la base de datos?")) {
        await fetch(`http://44.207.19.239:3000/turnos/${id}?zusuario=DC4`, { method: 'DELETE' });
        await sincronizarDatos();
    }
}

// --- GESTIÓN DE UI ---
const iniciarEdicion = (turno) => { turnoEnEdicion.value = { ...turno }; }
const cancelarAccion = () => {
    turnoEnEdicion.value = null;
    modeloTurno.value = { id: '', nombre: '', horario_referencia: '', zfecha: new Date().toISOString(), zusuario: "DC4" };
}

onMounted(sincronizarDatos);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Turnos Horarios (H9)</h3>
        </header>

        <form @submit.prevent="procesarFormulario" class="form-grid">

            <div class="form-inputs">
                <input v-if="!turnoEnEdicion" v-model="modeloTurno.nombre" placeholder="Nombre (ej. Mañana)" required>
                <input v-else v-model="turnoEnEdicion.nombre" placeholder="Nombre del turno" required>

                <input v-if="!turnoEnEdicion" v-model="modeloTurno.horario_referencia"
                    placeholder="Horario (ej. 08:00-14:00)" required>
                <input v-else v-model="turnoEnEdicion.horario_referencia" placeholder="Rango horario" required>
            </div>

            <div class="form-actions">
                <button type="submit" class="btn-success">
                    {{ turnoEnEdicion ? 'Guardar Cambios' : 'Registrar Turno' }}
                </button>
                <button v-if="turnoEnEdicion" type="button" @click="cancelarAccion" class="btn-sec">
                    Cancelar
                </button>
            </div>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Denominación</th>
                        <th>Horario de Referencia</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="t in listaTurnos" :key="t.id">
                        <td><strong>#{{ t.id }}</strong></td>
                        <td>{{ t.nombre }}</td>
                        <td>{{ t.horario_referencia }}</td>
                        <td class="td-actions">
                            <button @click="iniciarEdicion(t)" class="btn-accent">Editar</button>
                            <button @click="eliminarTurno(t.id)" class="btn-danger">Borrar</button>
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
    border-left: 5px solid #27ae60;
    padding-left: 15px;
}

.form-grid {
    background: #fff;
    padding: 20px;
    border-radius: 8px;
    margin-bottom: 25px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
}

.form-inputs {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    margin-bottom: 15px;
}

/* Inputs estilo oscuro DAW solicitados */
input {
    padding: 12px;
    border: 1px solid #ccc;
    border-radius: 6px;
    color: #fff;
    background: #2c3e50;
}

.form-actions {
    display: flex;
    gap: 10px;
}

.btn-success {
    background: #27ae60;
    color: white;
    border: none;
    padding: 12px;
    border-radius: 4px;
    font-weight: bold;
    flex: 2;
    cursor: pointer;
}

.btn-sec {
    background: #95a5a6;
    color: white;
    border: none;
    padding: 12px;
    border-radius: 4px;
    flex: 1;
    cursor: pointer;
}

.btn-accent {
    background: #f39c12;
    color: white;
    border: none;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-danger {
    background: #e74c3c;
    color: white;
    border: none;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
}

.td-actions {
    display: flex;
    gap: 8px;
}

.table-container {
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
    border-bottom: 1px solid #f1f1f1;
}

th {
    background: #f9f9f9;
    text-transform: uppercase;
    font-size: 0.8rem;
    color: #7f8c8d;
}
</style>