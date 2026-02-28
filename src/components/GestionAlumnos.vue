<script setup>
/**
 * COMPONENTE: GestionAlumnos.vue
 * Descripción: CRUD de alumnos con integración de estados por código (ACT, BAJ, etc.)
 */
import { ref, onMounted } from 'vue'

const listaAlumnos = ref([])
const listaCursos = ref([])
const listaEstados = ref([]) // Nueva lista para los estados
const cargando = ref(false)

const mostrarModalBorrado = ref(false)
const alumnoSeleccionado = ref(null)

// Modelo inicializado con el código correcto "ACT"
const modeloAlumno = ref({
    nia: '',
    nombre: '',
    apellidos: '',
    curso_id: '',
    correo_electronico: '',
    tutor_legal_contacto: '',
    estado_id: 'ACT', // Ajustado a tu estructura
    zfecha: new Date().toISOString(),
    zusuario: "DC4"
})

/**
 * Carga de datos maestros (Alumnos, Cursos y Estados)
 */
const cargarInformacion = async () => {
    cargando.value = true
    try {
        const [resAlu, resCur, resEst] = await Promise.all([
            fetch('http://44.207.19.239:3000/alumnos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/cursos?zusuario=DC4'),
            fetch('http://44.207.19.239:3000/estados_usuario?zusuario=DC4') // Cargamos tus códigos ACT, BAJ...
        ]);

        const alumnosBrutos = await resAlu.json();
        listaAlumnos.value = alumnosBrutos.sort((a, b) => a.nia.localeCompare(b.nia, undefined, { numeric: true }));

        listaCursos.value = await resCur.json();
        listaEstados.value = await resEst.json();
    } catch (error) {
        console.error("Error de sincronización:", error);
    } finally {
        cargando.value = false
    }
}

/**
 * Alternar estado usando los códigos de tu estructura
 */
const conmutarEstado = async (alumno) => {
    // Lógica: Si está ACT (Activo) lo pasamos a BAJ (Baja), y viceversa
    const nuevoEstado = alumno.estado_id === 'ACT' ? 'BAJ' : 'ACT';

    const datosActualizados = {
        nia: alumno.nia,
        nombre: alumno.nombre,
        apellidos: alumno.apellidos,
        curso_id: alumno.curso_id,
        correo_electronico: alumno.correo_electronico,
        tutor_legal_contacto: alumno.tutor_legal_contacto,
        estado_id: nuevoEstado,
        zusuario: "DC4"
    };

    try {
        const res = await fetch(`http://44.207.19.239:3000/alumnos/${alumno.nia}?zusuario=DC4`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosActualizados)
        });

        if (res.ok) await cargarInformacion();
    } catch (error) {
        console.error("Error al cambiar estado:", error);
    }
}

/**
 * Registro de alumno con validación y payload limpio
 */
const registrarAlumno = async () => {
    const duplicado = listaAlumnos.value.find(a => a.nia === modeloAlumno.value.nia);
    if (duplicado) {
        alert("El NIA ya existe.");
        return;
    }

    const datosFinales = {
        ...modeloAlumno.value,
        zusuario: "DC4"
    };

    try {
        const res = await fetch('http://44.207.19.239:3000/alumnos?zusuario=DC4', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(datosFinales)
        });

        if (res.ok) {
            modeloAlumno.value = {
                nia: '', nombre: '', apellidos: '', curso_id: '',
                correo_electronico: '', tutor_legal_contacto: '',
                estado_id: 'ACT', zusuario: "DC4"
            };
            await cargarInformacion();
            alert("Alumno registrado.");
        }
    } catch (error) {
        alert("Error de conexión.");
    }
}

const borrarDefinitivamente = async () => {
    await fetch(`http://44.207.19.239:3000/alumnos/${alumnoSeleccionado.value.nia}?zusuario=DC4`, { method: 'DELETE' });
    mostrarModalBorrado.value = false;
    await cargarInformacion();
}

onMounted(cargarInformacion);
</script>

<template>
    <div class="gestion-container">
        <header class="seccion-header">
            <h3>Gestión de Alumnado (H4)</h3>
        </header>

        <form @submit.prevent="registrarAlumno" class="form-grid">
            <input v-model="modeloAlumno.nia" placeholder="NIA" required>
            <input v-model="modeloAlumno.nombre" placeholder="Nombre" required>
            <input v-model="modeloAlumno.apellidos" placeholder="Apellidos" required>
            <input v-model="modeloAlumno.correo_electronico" type="email" placeholder="Email" required>
            <input v-model="modeloAlumno.tutor_legal_contacto" placeholder="Email Tutor Legal" required>

            <select v-model="modeloAlumno.curso_id" required>
                <option value="" disabled>Seleccionar Curso...</option>
                <option v-for="c in listaCursos" :key="c.id" :value="c.id">{{ c.nombre_curso }}</option>
            </select>

            <select v-model="modeloAlumno.estado_id" required>
                <option v-for="est in listaEstados" :key="est.id" :value="est.id">
                    {{ est.nombre }}
                </option>
            </select>

            <button type="submit" class="btn-success">Añadir Alumno</button>
        </form>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>NIA</th>
                        <th>Nombre</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="alu in listaAlumnos" :key="alu.nia">
                        <td><strong>{{ alu.nia }}</strong></td>
                        <td>{{ alu.nombre }} {{ alu.apellidos }}</td>
                        <td>
                            <span :class="alu.estado_id === 'ACT' ? 'status-active' : 'status-inactive'">
                                {{listaEstados.find(e => e.id === alu.estado_id)?.nombre || alu.estado_id}}
                            </span>
                        </td>
                        <td class="td-actions">
                            <button @click="conmutarEstado(alu)"
                                :class="alu.estado_id === 'ACT' ? 'btn-warn' : 'btn-ok'">
                                {{ alu.estado_id === 'ACT' ? 'Dar de Baja' : 'Activar' }}
                            </button>
                            <button @click="alumnoSeleccionado = alu; mostrarModalBorrado = true"
                                class="btn-danger">Eliminar</button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div v-if="mostrarModalBorrado" class="modal-overlay">
            <div class="modal-box">
                <h4>Confirmar Borrado</h4>
                <p>¿Borrar a {{ alumnoSeleccionado.nombre }}?</p>
                <div class="modal-actions">
                    <button @click="borrarDefinitivamente" class="btn-danger">Eliminar</button>
                    <button @click="mostrarModalBorrado = false" class="btn-sec">Cancelar</button>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
/* Estilos mantenidos según tu diseño oscuro DAW */
select,
input {
    padding: 12px;
    border-radius: 6px;
    color: #fff;
    background: #2c3e50;
    border: 1px solid #ddd;
    margin-bottom: 5px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 15px;
    background: #fff;
    padding: 20px;
    border-radius: 8px;
}

.btn-success {
    grid-column: span 2;
    background: #27ae60;
    color: white;
    padding: 14px;
    border: none;
    cursor: pointer;
    font-weight: bold;
    border-radius: 6px;
}

.status-active {
    color: #27ae60;
    font-weight: bold;
}

.status-inactive {
    color: #e74c3c;
    font-weight: bold;
}

.table-container {
    background: white;
    padding: 15px;
    border-radius: 8px;
    color: #333;
    margin-top: 20px;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th,
td {
    padding: 12px;
    text-align: left;
    border-bottom: 1px solid #eee;
}

.td-actions {
    display: flex;
    gap: 10px;
}

.btn-warn {
    background: #f39c12;
    color: white;
    border: none;
    padding: 6px 10px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-ok {
    background: #27ae60;
    color: white;
    border: none;
    padding: 6px 10px;
    border-radius: 4px;
    cursor: pointer;
}

.btn-danger {
    background: #e74c3c;
    color: white;
    border: none;
    padding: 6px 10px;
    border-radius: 4px;
    cursor: pointer;
}

.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.7);
    display: flex;
    justify-content: center;
    align-items: center;
}

.modal-box {
    background: white;
    padding: 30px;
    border-radius: 12px;
    text-align: center;
    color: #333;
}
</style>